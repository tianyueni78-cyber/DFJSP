clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_simultaneous_machine_right_shift();
candidate = scenario.machine_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 6);
assert(scenario.is_machine_right_shift_built);
assert(scenario.is_rescheduled);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(~candidate.is_agv_updated);
assert(~candidate.is_agv_validated);
assert(~candidate.is_fully_validated);
assert(scenario.source_machine_table_unchanged);
assert(scenario.source_agv_table_unchanged);
assert(isequaln(candidate.AGVTable, scenario.baseline.AGVTable));

expectedOperations = sum(scenario.baseline.problem.operaNumVec);
rootCount = numel(scenario.state.fault_in_progress_operations);
assert(numel(candidate.operation_records) == expectedOperations);
assert(numel(candidate.processing_segments) == ...
    expectedOperations + rootCount);
assert(numel(candidate.interrupted_commitments) == rootCount);
assert(numel(candidate.unavailable_intervals) == ...
    numel(scenario.faults));

for index = 1:numel(candidate.interrupted_commitments)
    commitment = candidate.interrupted_commitments(index);
    assert(commitment.is_validated);
    assert(abs(commitment.completed_segment.processing_time + ...
        commitment.resumed_segment.processing_time - ...
        commitment.original_duration) <= tolerance);
    assert(strcmp(commitment.completed_segment.segment_type, ...
        'processed_before_fault'));
    assert(strcmp(commitment.resumed_segment.segment_type, ...
        'resumed_after_repair'));
    fault = scenario.faults( ...
        [scenario.faults.machine_id] == commitment.machine_id);
    assert(numel(fault) == 1);
    assert(abs(commitment.completed_segment.end - ...
        fault.start_time) <= tolerance);
    assert(abs(commitment.resumed_segment.start - ...
        fault.repair_end_time) <= tolerance);
end

for index = 1:numel(scenario.impact.affected_operations)
    affected = scenario.impact.affected_operations(index);
    match = find([candidate.operation_records.job] == affected.job & ...
        [candidate.operation_records.operation] == affected.operation);
    assert(numel(match) == 1);
    record = candidate.operation_records(match);
    assert(record.is_affected);
    assert(~record.is_interrupted);
    assert(abs(record.start - affected.projected_start) <= tolerance);
    assert(abs(record.end - affected.projected_end) <= tolerance);
    assert(isequal(record.source_event_ids, ...
        affected.source_event_ids));
end

for faultIndex = 1:numel(scenario.faults)
    fault = scenario.faults(faultIndex);
    selected = candidate.processing_segments( ...
        [candidate.processing_segments.machine_id] == ...
        fault.machine_id);
    for index = 1:numel(selected)
        overlaps = selected(index).start < ...
            fault.repair_end_time - tolerance && ...
            fault.start_time < selected(index).end - tolerance;
        assert(~overlaps);
    end
end

validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

reversedCandidate = build_stage_c_simultaneous_machine_right_shift( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.state, scenario.impact);
assert(isequaln(candidate.operation_records, ...
    reversedCandidate.operation_records));
assert(isequaln(candidate.processing_segments, ...
    reversedCandidate.processing_segments));
assert(isequaln(candidate.machineTable, ...
    reversedCandidate.machineTable));

fprintf('test_stage_c_simultaneous_machine_right_shift passed\n');
