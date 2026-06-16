clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cseq2_machine_right_shift();
candidate = scenario.cseq2_machine_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-SEQ2.4'));
assert(strcmp(scenario.substep, '4'));
assert(scenario.is_machine_right_shift_built);
assert(~scenario.is_agv_impact_identified);
assert(~scenario.is_agv_rescheduled);
assert(~scenario.is_search_executed_in_cseq2_step_4);
assert(candidate.is_validated);
assert(candidate.is_machine_validated);
assert(~candidate.is_agv_updated);
assert(~candidate.is_agv_validated);
assert(~candidate.is_fully_validated);
assert(strcmp(candidate.stage, 'C-SEQ2'));
assert(strcmp(candidate.step, '4'));
assert(candidate.history_unchanged);
assert(~candidate.is_plan_modified);
assert(~candidate.is_rescheduled);

assert(numel(candidate.operation_records) == ...
    sum(scenario.baseline.problem.operaNumVec));
assert(numel(candidate.interrupted_commitments) == 1);
assert(candidate.cumulative_unavailability.is_validated);
assert(numel(candidate.unavailable_intervals) == 1);
assert(candidate.cumulative_unavailability.fault_count == ...
    scenario.cseq2_impact_context.counts.cumulative_faults);
assert(numel(candidate.overlap_relationships) == ...
    scenario.cseq2_impact_context.counts.overlap_relationships);
assert(isequaln(candidate.AGVTable, ...
    scenario.next_fault_state.current_plan_view.AGVTable));

assert_machine_non_overlap(candidate.processing_segments, tolerance);
assert_repair_intervals(candidate.processing_segments, ...
    scenario.next_fault, tolerance);
assert_affected_times(candidate.operation_records, ...
    scenario.cseq2_impact_context.merged_affected_operations, ...
    tolerance);

fprintf('test_stage_cseq2_machine_right_shift passed\n');

function assert_machine_non_overlap(segments, tolerance)
for machineId = unique([segments.machine_id])
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
end

function assert_repair_intervals(segments, faults, tolerance)
for faultIndex = 1:numel(faults)
    fault = faults(faultIndex);
    records = segments([segments.machine_id] == fault.machine_id);
    for index = 1:numel(records)
        overlap = records(index).start < ...
            fault.repair_end_time - tolerance && ...
            fault.start_time < records(index).end - tolerance;
        assert(~overlap);
    end
end
end

function assert_affected_times(operations, affected, tolerance)
for index = 1:numel(affected)
    source = affected(index);
    match = find([operations.job] == source.job & ...
        [operations.operation] == source.operation);
    assert(numel(match) == 1);
    assert(abs(operations(match).start - ...
        source.projected_start) <= tolerance);
    assert(abs(operations(match).end - ...
        source.projected_end) <= tolerance);
end
end
