clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_br_machine_right_shift();
candidate = scenario.machine_right_shift;
baselineMachineTable = scenario.baseline.machineTable;
baselineAGVTable = scenario.baseline.AGVTable;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.stage, 'B-R'));
assert(scenario.step == 3);
assert(scenario.is_machine_right_shift_built);
assert(scenario.is_rescheduled);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(strcmp(candidate.stage, 'B-R'));
assert(candidate.step == 3);
assert(candidate.restart_from_zero);
assert(~candidate.is_agv_updated);
assert(~candidate.is_fully_validated);
assert(isequaln(scenario.baseline.machineTable, baselineMachineTable));
assert(isequaln(scenario.baseline.AGVTable, baselineAGVTable));
assert(isequaln(candidate.AGVTable, baselineAGVTable));

expectedOperationCount = sum(scenario.baseline.problem.operaNumVec);
assert(numel(candidate.operation_records) == expectedOperationCount);
assert(numel(candidate.processing_segments) == ...
    expectedOperationCount + 1);

plan = scenario.restart_plan;
rootIndex = find([candidate.operation_records.job] == plan.job & ...
    [candidate.operation_records.operation] == plan.operation);
assert(numel(rootIndex) == 1);
root = candidate.operation_records(rootIndex);
assert(root.is_interrupted);
assert(root.is_restart_from_zero);
assert(root.is_affected);
assert(root.machine_id == plan.machine_id);
assert(abs(root.end - plan.revised_completion_time) <= tolerance);
assert(abs(root.processing_duration - ...
    plan.original_duration) <= tolerance);
assert(abs(root.lost_processing_time - ...
    plan.lost_processing_time) <= tolerance);

segments = candidate.processing_segments( ...
    [candidate.processing_segments.job] == plan.job & ...
    [candidate.processing_segments.operation] == plan.operation);
assert(numel(segments) == 2);
[~, order] = sort([segments.segment_order]);
segments = segments(order);
assert(strcmp(segments(1).segment_type, ...
    'lost_processing_before_fault'));
assert(strcmp(segments(2).segment_type, ...
    'restart_after_repair'));
assert(abs(segments(1).processing_time - ...
    plan.lost_processing_time) <= tolerance);
assert(abs(segments(2).processing_time - ...
    plan.original_duration) <= tolerance);
assert(abs(sum([segments.processing_time]) - ...
    plan.total_machine_processing_time) <= tolerance);

for index = 1:numel(scenario.impact.affected_operations)
    affected = scenario.impact.affected_operations(index);
    match = find([candidate.operation_records.job] == affected.job & ...
        [candidate.operation_records.operation] == affected.operation);
    assert(numel(match) == 1);
    assert(abs(candidate.operation_records(match).start - ...
        affected.projected_start) <= tolerance);
    assert(abs(candidate.operation_records(match).end - ...
        affected.projected_end) <= tolerance);
end

failedSegments = candidate.processing_segments( ...
    [candidate.processing_segments.machine_id] == ...
    scenario.fault.machine_id);
for index = 1:numel(failedSegments)
    overlapsRepair = failedSegments(index).start < ...
        scenario.fault.repair_end_time - tolerance && ...
        scenario.fault.start_time < ...
        failedSegments(index).end - tolerance;
    assert(~overlapsRepair);
end

validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

fprintf('test_stage_br_machine_right_shift passed\n');
