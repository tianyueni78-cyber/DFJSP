clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

stage12 = run_stage_b_combination_contract();
result = run_stage_b_step_13_analysis(stage12);
config = stage_b_step_13_config(projectRoot);

assert(result.is_validated);
assert(result.step == 13);
assert(isequal(config.seeds, [11, 22, 33, 42, 55]));
assert(~result.multiseed_search_executed);
assert(result.weight_sensitivity.is_search_reused);
assert(result.weight_sensitivity.weight_count == 11);
assert(result.right_shift_audit.is_validated);
assert(result.right_shift_audit.split_commitment_respected);
assert(result.right_shift_audit.repair_interval_respected);
assert(result.right_shift_audit.energy_audit_complete);
assert(result.right_shift_energy_candidate.is_energy_evaluated);
assert(result.right_shift_energy_candidate. ...
    energy_evaluation.repair_gap_excluded_from_work);
assert(all([result.complete_reschedule_audits.is_validated]));
assert(all([result.complete_reschedule_audits. ...
    split_commitment_respected]));
assert(result.all_constraint_audits_validated);
assert(result.all_energy_audits_complete);

fprintf('test_stage_b_step_13_contract passed\n');
