function result = run_stage_a_step_14_multiseed(stage12)
%RUN_STAGE_A_STEP_14_MULTISEED Run the formal repeated-search experiment.

if nargin < 1 || stage12.step ~= 12 || ~stage12.is_validated
    error('run_stage_a_step_14_multiseed:InvalidInput', ...
        'A validated formal Stage 12 scenario is required.');
end
if isfield(stage12, 'is_search_executed') && stage12.is_search_executed
    error('run_stage_a_step_14_multiseed:UnexpectedSearchState', ...
        'Stage A Step 12 input must not contain a completed search.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_a_step_14_config(projectRoot);
runs = repmat(run_template(), 1, numel(config.seeds));
for index = 1:numel(config.seeds)
    seed = config.seeds(index);
    options = search_options(config);
    rng(seed);
    search = search_stage_a_complete_reschedule( ...
        stage12.baseline, stage12.frozen_problem, options);
    combination = select_stage_a_combined_strategy( ...
        stage12.baseline, stage12.state, ...
        stage12.linked_right_shift, search, combination_config(config));
    runs(index) = summarize_run(seed, search, combination);
end

result = struct();
result.stage = 'A';
result.step = 14;
result.config = config;
result.runs = runs;
result.run_count = numel(runs);
result.multiseed_search_executed = true;
result.is_validated = all([runs.is_validated]);

outputDirectory = create_unique_output_directory(config.output_root);
result.output_directory = outputDirectory;
save_outputs(outputDirectory, result, config);
fprintf('Stage A Step 14 multiseed experiment completed.\n');
fprintf('Output directory: %s\n', outputDirectory);
end

function options = search_options(config)
fields = {'population_size', 'generations', ...
    'crossover_probability', 'mutation_probability', ...
    'tournament_size', 'no_improvement_generations', ...
    'max_runtime_seconds', 'improvement_tolerance'};
options = struct();
for index = 1:numel(fields)
    options.(fields{index}) = config.(fields{index});
end
end

function value = combination_config(config)
value = struct('completion_time_weight', ...
    config.completion_time_weight, ...
    'sequence_deviation_weight', ...
    config.sequence_deviation_weight, ...
    'tie_tolerance', config.tie_tolerance);
end

function value = summarize_run(seed, search, selection)
value = run_template();
value.seed = seed;
value.stop_reason = search.stop_reason;
value.completed_generations = search.completed_generations;
value.runtime_seconds = search.runtime_seconds;
value.pareto_count = numel(search.pareto_front);
value.selected_strategy = selection.selected_strategy;
value.selected_final_unload_makespan = ...
    selection.selected_metrics.candidate_makespan;
value.selected_tD = selection.selected_metrics.tD;
value.selected_SD = selection.selected_metrics.SD;
value.selected_Y = selection.selected_metrics.Y;
value.is_validated = search.is_validated && selection.is_validated;
end

function value = run_template()
value = struct('seed', [], 'stop_reason', '', ...
    'completed_generations', [], 'runtime_seconds', [], ...
    'pareto_count', [], 'selected_strategy', '', ...
    'selected_final_unload_makespan', [], 'selected_tD', [], ...
    'selected_SD', [], 'selected_Y', [], 'is_validated', false);
end

function outputDirectory = create_unique_output_directory(outputRoot)
if ~exist(outputRoot, 'dir')
    mkdir(outputRoot);
end
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
outputDirectory = fullfile(outputRoot, timestamp);
suffix = 1;
while exist(outputDirectory, 'dir')
    outputDirectory = fullfile(outputRoot, ...
        sprintf('%s_%02d', timestamp, suffix));
    suffix = suffix + 1;
end
mkdir(outputDirectory);
end

function save_outputs(outputDirectory, result, config)
save(fullfile(outputDirectory, 'result.mat'), ...
    'result', 'config', '-v7');
runs = result.runs;
value = table([runs.seed].', {runs.stop_reason}.', ...
    [runs.completed_generations].', [runs.runtime_seconds].', ...
    [runs.pareto_count].', {runs.selected_strategy}.', ...
    [runs.selected_final_unload_makespan].', ...
    [runs.selected_tD].', [runs.selected_SD].', ...
    [runs.selected_Y].', ...
    'VariableNames', {'seed', 'stop_reason', ...
    'completed_generations', 'runtime_seconds', 'pareto_count', ...
    'selected_strategy', 'selected_final_unload_makespan', ...
    'selected_tD', 'selected_SD', 'selected_Y'});
writetable(value, fullfile(outputDirectory, 'multiseed_summary.csv'));
end
