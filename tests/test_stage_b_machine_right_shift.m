clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_machine_right_shift();
candidate = scenario.machine_right_shift;
baselineMachineTable = scenario.baseline.machineTable;
baselineAGVTable = scenario.baseline.AGVTable;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 4);
assert(scenario.is_machine_right_shift_built);
assert(scenario.is_rescheduled);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(~candidate.is_agv_updated);
assert(~candidate.is_agv_validated);
assert(~candidate.is_fully_validated);
assert(isequaln(scenario.baseline.machineTable, baselineMachineTable));
assert(isequaln(scenario.baseline.AGVTable, baselineAGVTable));
assert(isequaln(candidate.AGVTable, baselineAGVTable));

expectedOperationCount = sum(scenario.baseline.problem.operaNumVec);
assert(numel(candidate.operation_records) == expectedOperationCount);
assert(numel(candidate.processing_segments) == ...
    expectedOperationCount + 1);

resumePlan = scenario.resume_plan;
rootIndex = find([candidate.operation_records.job] == ...
    resumePlan.job & ...
    [candidate.operation_records.operation] == resumePlan.operation);
assert(numel(rootIndex) == 1);
root = candidate.operation_records(rootIndex);
assert(root.is_interrupted);
assert(root.is_affected);
assert(root.machine_id == resumePlan.machine_id);
assert(abs(root.start - resumePlan.original_start) <= tolerance);
assert(abs(root.end - resumePlan.revised_completion_time) <= tolerance);
assert(abs(root.processing_duration - ...
    resumePlan.original_duration) <= tolerance);
assert(abs(root.calendar_span - ...
    (resumePlan.revised_completion_time - ...
    resumePlan.original_start)) <= tolerance);

rootSegments = candidate.processing_segments( ...
    [candidate.processing_segments.job] == resumePlan.job & ...
    [candidate.processing_segments.operation] == resumePlan.operation);
assert(numel(rootSegments) == 2);
[~, order] = sort([rootSegments.segment_order]);
rootSegments = rootSegments(order);
assert(strcmp(rootSegments(1).segment_type, ...
    'processed_before_fault'));
assert(strcmp(rootSegments(2).segment_type, ...
    'resumed_after_repair'));
assert(abs(rootSegments(1).end - ...
    scenario.fault.start_time) <= tolerance);
assert(abs(rootSegments(2).start - ...
    scenario.fault.repair_end_time) <= tolerance);
assert(abs(sum([rootSegments.processing_time]) - ...
    resumePlan.original_duration) <= tolerance);

for index = 1:numel(scenario.impact.affected_operations)
    affected = scenario.impact.affected_operations(index);
    match = find([candidate.operation_records.job] == affected.job & ...
        [candidate.operation_records.operation] == ...
        affected.operation);
    assert(numel(match) == 1);
    assert(candidate.operation_records(match).is_affected);
    assert(~candidate.operation_records(match).is_interrupted);
    assert(abs(candidate.operation_records(match).start - ...
        affected.projected_start) <= tolerance);
    assert(abs(candidate.operation_records(match).end - ...
        affected.projected_end) <= tolerance);
end

failedMachineSegments = candidate.processing_segments( ...
    [candidate.processing_segments.machine_id] == ...
    scenario.fault.machine_id);
for index = 1:numel(failedMachineSegments)
    overlapsRepair = failedMachineSegments(index).start < ...
        scenario.fault.repair_end_time - tolerance && ...
        scenario.fault.start_time < ...
        failedMachineSegments(index).end - tolerance;
    assert(~overlapsRepair);
end

validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

fprintf('test_stage_b_machine_right_shift passed\n');
