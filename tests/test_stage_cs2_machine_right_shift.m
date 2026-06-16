clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cs2_machine_right_shift();
candidate = scenario.cs2_machine_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.extension, 'C-S2'));
assert(strcmp(scenario.step, 'C-S2.3'));
assert(scenario.is_machine_right_shift_built);
assert(scenario.is_rescheduled);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(strcmp(candidate.stage, 'C-S2'));
assert(candidate.step == 3);
assert(candidate.restart_from_zero);
assert(~candidate.progress_preserved);
assert(~candidate.is_agv_updated);
assert(~candidate.is_fully_validated);
assert(scenario.source_machine_table_unchanged);
assert(scenario.source_agv_table_unchanged);
assert(isequaln(candidate.AGVTable, scenario.baseline.AGVTable));

expectedOperations = sum(scenario.baseline.problem.operaNumVec);
rootCount = numel(scenario.cs2_restart_commitments);
assert(numel(candidate.operation_records) == expectedOperations);
assert(numel(candidate.processing_segments) == ...
    expectedOperations + rootCount);
assert(numel(candidate.interrupted_commitments) == rootCount);
assert(numel(candidate.unavailable_intervals) == numel(scenario.faults));

for index = 1:numel(scenario.cs2_restart_commitments)
    commitment = scenario.cs2_restart_commitments(index);
    rootIndex = find([candidate.operation_records.job] == ...
        commitment.job & ...
        [candidate.operation_records.operation] == ...
        commitment.operation);
    assert(numel(rootIndex) == 1);
    root = candidate.operation_records(rootIndex);
    assert(root.is_interrupted);
    assert(root.is_restart_from_zero);
    assert(root.is_affected);
    assert(root.machine_id == commitment.machine_id);
    assert(abs(root.end - ...
        commitment.revised_completion_time) <= tolerance);
    assert(abs(root.processing_duration - ...
        commitment.original_duration) <= tolerance);
    assert(abs(root.lost_processing_time - ...
        commitment.lost_processing_time) <= tolerance);

    segments = candidate.processing_segments( ...
        [candidate.processing_segments.job] == commitment.job & ...
        [candidate.processing_segments.operation] == ...
        commitment.operation);
    assert(numel(segments) == 2);
    [~, order] = sort([segments.segment_order]);
    segments = segments(order);
    assert(strcmp(segments(1).segment_type, ...
        'lost_processing_before_fault'));
    assert(strcmp(segments(2).segment_type, ...
        'restart_after_repair'));
    assert(~segments(1).contributes_to_completion);
    assert(segments(2).contributes_to_completion);
    assert(abs(segments(1).processing_time - ...
        commitment.lost_processing_time) <= tolerance);
    assert(abs(segments(2).processing_time - ...
        commitment.original_duration) <= tolerance);
    assert(abs(sum([segments.processing_time]) - ...
        commitment.total_machine_processing_time) <= tolerance);
end

for index = 1:numel(scenario.cs2_impact.affected_operations)
    affected = scenario.cs2_impact.affected_operations(index);
    match = find([candidate.operation_records.job] == affected.job & ...
        [candidate.operation_records.operation] == affected.operation);
    assert(numel(match) == 1);
    record = candidate.operation_records(match);
    assert(record.is_affected);
    assert(~record.is_interrupted);
    assert(abs(record.start - affected.projected_start) <= tolerance);
    assert(abs(record.end - affected.projected_end) <= tolerance);
    assert(isequal(record.source_event_ids, affected.source_event_ids));
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

reversedCandidate = build_stage_cs2_machine_right_shift( ...
    scenario.baseline, scenario.faults(end:-1:1), scenario.state, ...
    scenario.cs2_restart_commitments(end:-1:1), scenario.cs2_impact);
assert(isequaln(candidate.operation_records, ...
    reversedCandidate.operation_records));
assert(isequaln(candidate.processing_segments, ...
    reversedCandidate.processing_segments));
assert(isequaln(candidate.machineTable, reversedCandidate.machineTable));

fprintf('test_stage_cs2_machine_right_shift passed\n');
