clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_cs2_restart_commitments();
commitments = scenario.cs2_restart_commitments;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.extension, 'C-S2'));
assert(strcmp(scenario.step, 'C-S2.1'));
assert(strcmp(scenario.interruption_rule, 'restart_from_zero'));
assert(scenario.restart_commitments_built);
assert(~scenario.impact_propagated);
assert(~scenario.is_rescheduled);
assert(all(strcmp({scenario.faults.interruption_rule}, ...
    'restart_from_zero')));
assert(numel(commitments) == numel(scenario.faults));
assert(numel(commitments) == ...
    scenario.state.counts.fault_in_progress_operations);

for index = 1:numel(commitments)
    commitment = commitments(index);
    source = find_interrupted_source(scenario.state, commitment);
    fault = find_fault(scenario.faults, commitment);

    assert(commitment.is_validated);
    assert(strcmp(commitment.rule, 'restart_from_zero'));
    assert(commitment.restart_from_zero);
    assert(~commitment.progress_preserved);
    assert(~commitment.machine_migration_allowed);
    assert(strcmp(commitment.lost_processing_segment.segment_type, ...
        'lost_processing_before_fault'));
    assert(strcmp(commitment.restart_segment.segment_type, ...
        'restart_after_repair'));
    assert(~commitment.lost_processing_segment.contributes_to_completion);
    assert(commitment.restart_segment.contributes_to_completion);

    assert(abs(commitment.lost_processing_segment.start - ...
        source.start) <= tolerance);
    assert(abs(commitment.lost_processing_segment.end - ...
        fault.start_time) <= tolerance);
    assert(abs(commitment.lost_processing_time - ...
        source.elapsed_processing_time) <= tolerance);
    assert(abs(commitment.restart_segment.start - ...
        fault.repair_end_time) <= tolerance);
    assert(abs(commitment.restart_segment.processing_time - ...
        source.original_duration) <= tolerance);
    assert(abs(commitment.restart_segment.end - ...
        commitment.revised_completion_time) <= tolerance);
    assert(abs(commitment.total_machine_processing_time - ...
        commitment.lost_processing_time - ...
        commitment.original_duration) <= tolerance);
    assert(abs(commitment.effective_completion_processing_time - ...
        commitment.original_duration) <= tolerance);
    assert(commitment.completion_delay > 0);
end

reversed = build_stage_c_simultaneous_restart_commitments( ...
    scenario.faults(end:-1:1), scenario.state);
assert(isequaln(commitments, reversed));

fprintf('test_stage_cs2_restart_commitments passed\n');

function source = find_interrupted_source(state, commitment)
matches = find([state.fault_in_progress_operations.job] == ...
    commitment.job & ...
    [state.fault_in_progress_operations.operation] == ...
    commitment.operation);
assert(numel(matches) == 1);
source = state.fault_in_progress_operations(matches);
end

function fault = find_fault(faults, commitment)
matches = find([faults.machine_id] == commitment.machine_id & ...
    ismember([faults.event_id], commitment.event_ids));
assert(numel(matches) == 1);
fault = faults(matches);
end
