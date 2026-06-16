clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

stage11 = run_stage_cs2_combination_contract();
result = run_stage_cs2_step_12_analysis(stage11);
config = stage_cs2_step_12_config(projectRoot);

assert(result.is_validated);
assert(strcmp(result.stage, 'C-S2'));
assert(result.step == 12);
assert(isequal(config.seeds, [11, 22, 33, 42, 55]));
assert(strcmp(config.output_root, fullfile(projectRoot, 'outputs', ...
    'stage_cs2_step_12_robustness')));
assert(exist('run_stage_cs2_step_12_multiseed', 'file') == 2);
assert(~result.multiseed_search_executed);
assert(result.restart_from_zero);
assert(result.weight_sensitivity.is_search_reused);
assert(result.weight_sensitivity.weight_count == 11);
rows = result.weight_sensitivity.rows;
assert(abs(rows(1).completion_time_weight) <= 1e-12);
assert(abs(rows(end).completion_time_weight - 1) <= 1e-12);
assert(result.right_shift_audit.is_validated);
assert(result.right_shift_audit.restart_commitments_respected);
assert(result.right_shift_audit.restart_from_zero);
assert(~result.right_shift_audit.progress_preserved);
assert(result.right_shift_audit.lost_processing_time > 0);
assert(result.right_shift_audit.repair_intervals_respected);
assert(result.right_shift_audit.energy_audit_complete);
assert(result.right_shift_energy_candidate.is_energy_evaluated);
assert(all([result.complete_reschedule_audits.is_validated]));
assert(all([result.complete_reschedule_audits. ...
    restart_commitments_respected]));
assert(all([result.complete_reschedule_audits.restart_from_zero]));
assert(~any([result.complete_reschedule_audits.progress_preserved]));
assert(result.all_constraint_audits_validated);
assert(result.all_energy_audits_complete);

fprintf('test_stage_cs2_step_12_contract passed\n');
