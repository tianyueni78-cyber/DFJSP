function config = stage_a_step_13_config(projectRoot)
%STAGE_A_STEP_13_CONFIG Configure fair search and combination selection.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

searchConfig = stage_a_confirmation_search_config(projectRoot);
combinationConfig = stage_a_combination_config();

config = searchConfig;
config.completion_time_weight = ...
    combinationConfig.completion_time_weight;
config.sequence_deviation_weight = ...
    combinationConfig.sequence_deviation_weight;
config.tie_tolerance = combinationConfig.tie_tolerance;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_a_step_13_search_and_selection');
end
