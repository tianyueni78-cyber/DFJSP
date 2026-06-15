clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_simultaneous_fault_scenario();
selected = scenario.selected_candidate;

assert(scenario.is_validated);
assert(strcmp(scenario.stage, 'C'));
assert(scenario.step == 4);
assert(strcmp(scenario.baseline_source, 'original_normal_baseline'));
assert(~scenario.additional_problem_data_generated);
assert(~scenario.impact_propagated);
assert(~scenario.is_rescheduled);
assert(scenario.screening.candidate_count > 0);
assert(scenario.selected_candidate_rank == 1);
assert(numel(selected.machine_ids) == 2);
assert(numel(unique(selected.machine_ids)) == 2);
assert(selected.directly_affected_operations == 2);
assert(selected.repair_overlap_operations >= 2);
assert(selected.active_window_start < selected.fault_time);
assert(selected.fault_time < selected.active_window_end);
assert(all([selected.interrupted_operations.start] < ...
    selected.fault_time));
assert(all(selected.fault_time < ...
    [selected.interrupted_operations.end]));
assert(numel(scenario.faults) == 2);
assert(all([scenario.faults.event_group] == 1));
assert(all(strcmp({scenario.faults.interruption_rule}, ...
    'resume_remaining')));
assert(scenario.state.counts.fault_in_progress_operations == 2);
assert(isequal(sort([scenario.state.fault_in_progress_operations. ...
    machine_id]), sort(selected.machine_ids)));
assert(numel(scenario.unavailability.intervals) == 2);

for index = 1:numel(scenario.screening.candidates) - 1
    current = scenario.screening.candidates(index);
    next = scenario.screening.candidates(index + 1);
    assert(is_ranked_before(current, next));
end

fprintf('test_stage_c_simultaneous_fault_scenario passed\n');

function result = is_ranked_before(current, next)
currentKey = [-current.repair_overlap_operations, ...
    -current.active_window_duration, current.fault_time, ...
    current.machine_ids];
nextKey = [-next.repair_overlap_operations, ...
    -next.active_window_duration, next.fault_time, ...
    next.machine_ids];
firstDifference = find(abs(currentKey - nextKey) > 1e-9, 1);
result = isempty(firstDifference) || ...
    currentKey(firstDifference) < nextKey(firstDifference);
end
