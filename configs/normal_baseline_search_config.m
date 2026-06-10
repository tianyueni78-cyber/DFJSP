function config = normal_baseline_search_config(projectRoot)
%NORMAL_BASELINE_SEARCH_CONFIG Match the Stage A post-fault search budget.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

stageConfig = stage_a_confirmation_search_config(projectRoot);
config = stageConfig;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'normal_baseline_search');
config.baseline_selection_rule = ...
    'minimum_makespan_then_minimum_energy';
end
