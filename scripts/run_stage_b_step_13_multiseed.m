function result = run_stage_b_step_13_multiseed(stage12)
%RUN_STAGE_B_STEP_13_MULTISEED Run the formal repeated Stage B search.
%   This function runs five searches and writes a new output directory.

if nargin < 1 || stage12.step ~= 12 || ~stage12.is_validated
    error('run_stage_b_step_13_multiseed:InvalidInput', ...
        'A validated Stage B Step 12 result is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_b_step_13_config(projectRoot);
frozenScenario = run_stage_b_frozen_problem(stage12.baseline);
validate_same_scenario(stage12, frozenScenario);
runs = repmat(run_template(), 1, numel(config.seeds));
for index = 1:numel(config.seeds)
    seed = config.seeds(index);
    rng(seed);
    search = search_stage_b_complete_reschedule( ...
        stage12.baseline, frozenScenario.frozen_problem, ...
        search_options(config));
    selection = select_stage_b_combined_strategy( ...
        stage12.baseline, stage12.state, ...
        stage12.linked_right_shift, search, ...
        combination_config(config));
    runs(index) = summarize_run(seed, search, selection);
end

result = struct();
result.stage = 'B';
result.step = 13;
result.config = config;
result.runs = runs;
result.run_count = numel(runs);
result.multiseed_search_executed = true;
result.is_validated = all([runs.is_validated]);
result.output_directory = create_unique_output_directory( ...
    config.output_root);
save_outputs(result.output_directory, result, config);
fprintf('Stage B Step 13 multiseed experiment completed.\n');
fprintf('Output directory: %s\n', result.output_directory);
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

function validate_same_scenario(stage12, frozenScenario)
sameFault = stage12.fault.machine_id == ...
    frozenScenario.fault.machine_id && ...
    abs(stage12.fault.start_time - ...
    frozenScenario.fault.start_time) <= 1e-9 && ...
    abs(stage12.fault.repair_end_time - ...
    frozenScenario.fault.repair_end_time) <= 1e-9;
sameInterrupted = stage12.resume_plan.job == ...
    frozenScenario.resume_plan.job && ...
    stage12.resume_plan.operation == ...
    frozenScenario.resume_plan.operation;
if ~sameFault || ~sameInterrupted
    error('run_stage_b_step_13_multiseed:ScenarioMismatch', ...
        'The rebuilt frozen problem does not match Stage B Step 12.');
end
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
