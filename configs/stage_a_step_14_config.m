function config = stage_a_step_14_config(projectRoot)
%STAGE_A_STEP_14_CONFIG Configure robustness and sensitivity analysis.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = stage_a_step_13_config(projectRoot);
config.seeds = [11, 22, 33, 42, 55];
config.completion_time_weights = 0:0.1:1;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_a_step_14_robustness');
end
