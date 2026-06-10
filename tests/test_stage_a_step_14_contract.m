clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

stage13Contract = run_stage_a_step_13_contract();
stage13Contract.is_formal_run = true;
result = run_stage_a_step_14_analysis(stage13Contract);
config = stage_a_step_14_config(projectRoot);

assert(result.is_validated);
assert(result.step == 14);
assert(isequal(size(config.seeds), [1, 5]));
assert(numel(unique(config.seeds)) == 5);
assert(any(config.seeds == 42));
assert(~result.multiseed_search_executed);
assert(result.weight_sensitivity.is_search_reused);
assert(result.weight_sensitivity.weight_count == 11);
assert(result.right_shift_audit.is_validated);
assert(all([result.complete_reschedule_audits.is_validated]));
assert(result.all_constraint_audits_validated);
assert(all([result.complete_reschedule_audits.energy_audit_complete]));

fprintf('test_stage_a_step_14_contract passed\n');

clear stage13Contract result
