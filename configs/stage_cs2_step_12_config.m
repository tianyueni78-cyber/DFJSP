function config = stage_cs2_step_12_config(projectRoot)
%STAGE_CS2_STEP_12_CONFIG Configure robustness and audit work.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
searchConfig = stage_cs2_complete_search_config(projectRoot);
combinationConfig = stage_c_combination_config();
config = searchConfig;
config.completion_time_weight = ...
    combinationConfig.completion_time_weight;
config.sequence_deviation_weight = ...
    combinationConfig.sequence_deviation_weight;
config.tie_tolerance = combinationConfig.tie_tolerance;
config.seeds = [11, 22, 33, 42, 55];
config.completion_time_weights = 0:0.1:1;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_cs2_step_12_robustness');
end
