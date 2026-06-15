testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_br_combination_contract();
selection = scenario.combined_selection;

assert(selection.is_validated);
assert(strcmp(scenario.stage, 'B-R'));
assert(scenario.is_combination_evaluated);
assert(scenario.step == 11);
assert(selection.weights.completion_time_weight == 0.9);
assert(selection.weights.sequence_deviation_weight == 0.1);
assert(numel(selection.evaluations) == ...
    1 + numel(scenario.complete_reschedule_search.pareto_front));
assert(strcmp(selection.evaluations(1).strategy, ...
    'partial_right_shift'));
assert(selection.evaluations(1).SD == 0);

for index = 1:numel(selection.evaluations)
    evaluation = selection.evaluations(index);
    expectedTD = evaluation.candidate_makespan - ...
        scenario.baseline.makespan;
    expectedY = 0.9 * evaluation.tD + 0.1 * evaluation.SD;
    assert(abs(evaluation.tD - expectedTD) <= 1e-9);
    assert(abs(evaluation.Y - expectedY) <= 1e-9);
    assert(evaluation.SD >= 0);
    assert(evaluation.SD == floor(evaluation.SD));
end

scores = [selection.evaluations.Y];
assert(selection.selected_metrics.Y <= min(scores) + 1e-9);
assert(strcmp(selection.selected_strategy, ...
    selection.evaluations(selection.selected_index).strategy));
assert(scenario.complete_reschedule_search.is_restart_operation_evaluated);
assert(scenario.complete_reschedule_search.restart_from_zero);
assert(scenario.linked_right_shift.restart_from_zero);
assert(~scenario.restart_plan.progress_preserved);

fprintf('test_stage_br_combination_contract passed\n');

