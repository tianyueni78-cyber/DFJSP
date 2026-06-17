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
stage13 = run_stage_cseq2_combination_selection(scenario);
result = run_stage_cseq2_step_14_analysis(stage13);
config = stage_cseq2_step_14_config(projectRoot);

assert(result.is_validated);
assert(strcmp(result.stage, 'C-SEQ2'));
assert(result.step == 14);
assert(isequal(config.completion_time_weights, 0:0.1:1));
assert(strcmp(config.output_root, fullfile(projectRoot, 'outputs', ...
    'stage_cseq2_step_14_robustness')));
assert(~result.multiseed_search_executed);
assert(result.weight_sensitivity.is_search_reused);
assert(result.weight_sensitivity.weight_count == 11);
rows = result.weight_sensitivity.rows;
assert(abs(rows(1).completion_time_weight) <= 1e-12);
assert(abs(rows(end).completion_time_weight - 1) <= 1e-12);
assert(result.right_shift_audit.is_validated);
assert(result.right_shift_audit.repair_intervals_respected);
assert(result.right_shift_audit.interrupted_commitments_respected);
assert(result.right_shift_audit.energy_audit_complete);
assert(result.right_shift_energy_candidate.is_energy_evaluated);
assert(all([result.complete_reschedule_audits.is_validated]));
assert(all([result.complete_reschedule_audits. ...
    repair_intervals_respected]));
assert(all([result.complete_reschedule_audits. ...
    interrupted_commitments_respected]));
assert(result.all_constraint_audits_validated);
assert(result.all_energy_audits_complete);

provenance = result.data_provenance;
assert(provenance.is_validated);
assert(provenance.source_data_only);
assert(~provenance.raw_code_modified);
assert(~provenance.synthetic_problem_data_created);
assert(contains(provenance.instance_path, fullfile('raw_code', 'fjsp')));
assert(contains(provenance.machine_data_path, 'raw_code'));
assert(contains(provenance.agv_data_path, 'raw_code'));
assert(provenance.problem_operation_count > 0);

fprintf('test_stage_cseq2_step_14_contract passed\n');
