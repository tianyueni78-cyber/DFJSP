clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));

config = stage_c_final_audit_matrix_config(projectRoot);
scenarios = config.scenarios;

assert(config.is_validated);
assert(strcmp(config.step, '17.1'));
assert(strcmp(config.audit_scope, 'stage_c_final_scenario_matrix'));
assert(isequal(config.random_seeds, [11, 22, 33, 42, 55]));
assert(config.formal_population_size == 10);
assert(config.formal_generations == 100);
assert(config.no_improvement_generations == 10);
assert(config.max_runtime_seconds == 30);
assert(abs(config.completion_time_weight + ...
    config.sequence_deviation_weight - 1) <= 1e-9);
assert(strcmp(config.output_root, fullfile(projectRoot, ...
    'outputs', 'stage_c_final_audit_matrix')));

assert(numel(scenarios) == 4);
assert(isequal({scenarios.id}, {'C-S1', 'C-S2', 'C-SEQ1', 'C-SEQ2'}));
assert(isequal([scenarios.run_ready], [true, false, true, false]));
assert(strcmp(scenarios(1).implementation_status, 'implemented'));
assert(strcmp(scenarios(2).implementation_status, 'not_implemented'));
assert(strcmp(scenarios(3).implementation_status, 'implemented'));
assert(strcmp(scenarios(4).implementation_status, 'planned'));
assert(strcmp(scenarios(1).interruption_rule, 'resume_remaining'));
assert(strcmp(scenarios(2).interruption_rule, 'restart_from_zero'));
assert(strcmp(scenarios(3).fault_relation, ...
    'sequential_faults_non_overlapping_repairs'));
assert(strcmp(scenarios(4).fault_relation, ...
    'sequential_faults_overlapping_repairs'));

requiredAudits = config.required_audits;
assert(any(strcmp(requiredAudits, 'repair_intervals')));
assert(any(strcmp(requiredAudits, 'interrupted_commitments')));
assert(any(strcmp(requiredAudits, 'energy_closure')));
assert(any(strcmp(requiredAudits, 'combined_selection')));

fprintf('test_stage_c_final_audit_matrix_config passed\n');
