function config = stage_cseq2_step_14_config(projectRoot)
%STAGE_CSEQ2_STEP_14_CONFIG Configure C-SEQ2 sensitivity and audit work.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
searchConfig = stage_cseq2_complete_search_config(projectRoot);
combinationConfig = stage_c_combination_config();
config = searchConfig;
config.completion_time_weight = ...
    combinationConfig.completion_time_weight;
config.sequence_deviation_weight = ...
    combinationConfig.sequence_deviation_weight;
config.tie_tolerance = combinationConfig.tie_tolerance;
config.completion_time_weights = 0:0.1:1;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_cseq2_step_14_robustness');
end
