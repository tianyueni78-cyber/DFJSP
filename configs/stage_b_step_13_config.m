function config = stage_b_step_13_config(projectRoot)
%STAGE_B_STEP_13_CONFIG Configure robustness and audit work.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

searchConfig = stage_b_complete_search_config(projectRoot);
combinationConfig = stage_b_combination_config();
config = searchConfig;
config.completion_time_weight = ...
    combinationConfig.completion_time_weight;
config.sequence_deviation_weight = ...
    combinationConfig.sequence_deviation_weight;
config.tie_tolerance = combinationConfig.tie_tolerance;
config.seeds = [11, 22, 33, 42, 55];
config.completion_time_weights = 0:0.1:1;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_b_step_13_robustness');
end
