function config = stage_c_final_audit_multiseed_config(projectRoot)
%STAGE_C_FINAL_AUDIT_MULTISEED_CONFIG Configure Stage C Step 17.2.
%   The final audit multiseed run only includes scenarios that already
%   have implemented search and combination-selection flows.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

matrixConfig = stage_c_final_audit_matrix_config(projectRoot);
runnableScenarios = matrixConfig.scenarios([matrixConfig.scenarios.run_ready]);

config = struct();
config.step = '17.2';
config.audit_scope = 'stage_c_final_multiseed_runnable_scenarios';
config.scenarios = runnableScenarios;
config.scenario_ids = {runnableScenarios.id};
config.random_seeds = matrixConfig.random_seeds;
config.population_size = matrixConfig.formal_population_size;
config.generations = matrixConfig.formal_generations;
config.crossover_probability = 0.8;
config.mutation_probability = 0.2;
config.tournament_size = 2;
config.no_improvement_generations = ...
    matrixConfig.no_improvement_generations;
config.max_runtime_seconds = matrixConfig.max_runtime_seconds;
config.improvement_tolerance = 1e-9;
config.completion_time_weight = matrixConfig.completion_time_weight;
config.sequence_deviation_weight = matrixConfig.sequence_deviation_weight;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_c_final_audit_multiseed');
config.is_validated = validate_config(config);
end

function result = validate_config(config)
result = isequal(config.scenario_ids, {'C-S1', 'C-SEQ1'}) && ...
    isequal(config.random_seeds, [11, 22, 33, 42, 55]) && ...
    config.population_size == 10 && ...
    config.generations == 100 && ...
    config.no_improvement_generations == 10 && ...
    config.max_runtime_seconds == 30 && ...
    config.tournament_size == 2 && ...
    config.crossover_probability > 0 && ...
    config.crossover_probability <= 1 && ...
    config.mutation_probability >= 0 && ...
    config.mutation_probability <= 1 && ...
    abs(config.completion_time_weight + ...
    config.sequence_deviation_weight - 1) <= 1e-9 && ...
    ischar(config.output_root) && ~isempty(config.output_root);
if ~result
    error('stage_c_final_audit_multiseed_config:InvalidConfig', ...
        'Stage C final multiseed audit configuration is inconsistent.');
end
end
