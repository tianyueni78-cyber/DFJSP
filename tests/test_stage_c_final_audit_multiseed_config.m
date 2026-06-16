clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

config = stage_c_final_audit_multiseed_config(projectRoot);

assert(config.is_validated);
assert(strcmp(config.step, '17.2'));
assert(strcmp(config.audit_scope, ...
    'stage_c_final_multiseed_runnable_scenarios'));
assert(isequal(config.scenario_ids, {'C-S1', 'C-SEQ1'}));
assert(isequal(config.random_seeds, [11, 22, 33, 42, 55]));
assert(config.population_size == 10);
assert(config.generations == 100);
assert(config.no_improvement_generations == 10);
assert(config.max_runtime_seconds == 30);
assert(config.tournament_size == 2);
assert(strcmp(config.output_root, fullfile(projectRoot, ...
    'outputs', 'stage_c_final_audit_multiseed')));

scenarios = config.scenarios;
assert(numel(scenarios) == 2);
assert(all([scenarios.run_ready]));
assert(strcmp(scenarios(1).id, 'C-S1'));
assert(strcmp(scenarios(2).id, 'C-SEQ1'));
assert(strcmp(scenarios(1).implementation_status, 'implemented'));
assert(strcmp(scenarios(2).implementation_status, 'implemented'));

assert(exist('run_stage_c_final_audit_multiseed', 'file') == 2);
assert(exist('run_stage_c_simultaneous_frozen_problem', 'file') == 2);
assert(exist('run_stage_c_sequential_frozen_problem', 'file') == 2);
assert(exist('search_stage_c_simultaneous_complete_reschedule', ...
    'file') == 2);
assert(exist('run_stage_c_combination_selection', 'file') == 2);
assert(exist('run_stage_c_sequential_combination_selection', ...
    'file') == 2);

fprintf('test_stage_c_final_audit_multiseed_config passed\n');
