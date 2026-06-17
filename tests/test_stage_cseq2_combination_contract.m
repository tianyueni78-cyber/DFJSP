clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

scenario = run_stage_cseq2_restricted_search_contract();
scenario.cseq2_complete_reschedule_search = ...
    scenario.cseq2_restricted_search;
combined = run_stage_cseq2_combination_selection(scenario);
selection = combined.combined_selection;
baselineMakespan = ...
    combined.next_fault_state.current_plan_view.current_plan_makespan;

assert(combined.is_validated);
assert(strcmp(combined.step, 'C-SEQ2.13'));
assert(strcmp(combined.substep, '13'));
assert(combined.is_combination_evaluated);
assert(selection.is_validated);
assert(selection.weights.completion_time_weight == 0.9);
assert(selection.weights.sequence_deviation_weight == 0.1);
assert(numel(selection.evaluations) == ...
    1 + numel(combined.cseq2_complete_reschedule_search.pareto_front));
assert(strcmp(selection.evaluations(1).strategy, ...
    'partial_right_shift'));
assert(selection.evaluations(1).SD == 0);

for index = 1:numel(selection.evaluations)
    evaluation = selection.evaluations(index);
    assert(abs(evaluation.baseline_makespan - ...
        baselineMakespan) <= 1e-9);
    assert(abs(evaluation.tD - ...
        (evaluation.candidate_makespan - baselineMakespan)) <= 1e-9);
    assert(abs(evaluation.Y - ...
        (0.9 * evaluation.tD + 0.1 * evaluation.SD)) <= 1e-9);
    assert(evaluation.SD >= 0 && evaluation.SD == floor(evaluation.SD));
end

assert(selection.selected_metrics.Y <= ...
    min([selection.evaluations.Y]) + 1e-9);
assert(combined.right_shift_audit.is_validated);
assert(combined.right_shift_audit.repair_intervals_respected);
assert(combined.right_shift_audit.interrupted_commitments_respected);
assert(combined.right_shift_audit.energy_audit_complete);
assert(all([combined.complete_reschedule_audits.is_validated]));
assert(all([combined.complete_reschedule_audits. ...
    repair_intervals_respected]));
assert(all([combined.complete_reschedule_audits. ...
    interrupted_commitments_respected]));
assert(combined.all_constraint_audits_validated);
assert(combined.all_energy_audits_complete);

fprintf('test_stage_cseq2_combination_contract passed\n');
