clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_combination_contract();
selection = scenario.combined_selection;

assert(scenario.is_validated);
assert(scenario.step == 11);
assert(scenario.is_combination_evaluated);
assert(selection.is_validated);
assert(selection.weights.completion_time_weight == 0.9);
assert(selection.weights.sequence_deviation_weight == 0.1);
assert(numel(selection.evaluations) == ...
    1 + numel(scenario.complete_reschedule_search.pareto_front));
assert(strcmp(selection.evaluations(1).strategy, ...
    'partial_right_shift'));
assert(selection.evaluations(1).SD == 0);

for index = 1:numel(selection.evaluations)
    evaluation = selection.evaluations(index);
    assert(abs(evaluation.tD - ...
        (evaluation.candidate_makespan - ...
        scenario.baseline.makespan)) <= 1e-9);
    assert(abs(evaluation.Y - ...
        (0.9 * evaluation.tD + 0.1 * evaluation.SD)) <= 1e-9);
    assert(evaluation.SD >= 0 && ...
        evaluation.SD == floor(evaluation.SD));
end

assert(selection.selected_metrics.Y <= ...
    min([selection.evaluations.Y]) + 1e-9);
assert(scenario.right_shift_audit.is_validated);
assert(scenario.right_shift_audit.repair_intervals_respected);
assert(scenario.right_shift_audit.interrupted_commitments_respected);
assert(scenario.right_shift_audit.energy_audit_complete);
assert(all([scenario.complete_reschedule_audits.is_validated]));
assert(all([scenario.complete_reschedule_audits. ...
    repair_intervals_respected]));
assert(all([scenario.complete_reschedule_audits. ...
    interrupted_commitments_respected]));
assert(scenario.all_constraint_audits_validated);
assert(scenario.all_energy_audits_complete);

fprintf('test_stage_c_combination_contract passed\n');
