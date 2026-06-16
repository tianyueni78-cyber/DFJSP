function result = run_stage_cs2_step_12_multiseed(stage11)
%RUN_STAGE_CS2_STEP_12_MULTISEED Run the formal repeated C-S2 search.
%   This function runs five searches and writes a new output directory.

if nargin < 1 || ~strcmp(stage11.step, 'C-S2.11') || ...
        ~stage11.is_validated
    error('run_stage_cs2_step_12_multiseed:InvalidInput', ...
        'A validated C-S2 Step 11 result is required.');
end
projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_cs2_step_12_config(projectRoot);
frozenScenario = run_stage_cs2_frozen_problem(stage11.baseline);
validate_same_scenario(stage11, frozenScenario);
runs = repmat(run_template(), 1, numel(config.seeds));
for index = 1:numel(config.seeds)
    seed = config.seeds(index);
    rng(seed);
    search = search_stage_cs2_complete_reschedule( ...
        stage11.baseline, frozenScenario.cs2_frozen_problem, ...
        search_options(config));
    selection = select_stage_c_combined_strategy( ...
        stage11.baseline, stage11.state, ...
        stage11.cs2_linked_right_shift, search, ...
        combination_config(config));
    runs(index) = summarize_run(seed, search, selection);
end

result = struct();
result.stage = 'C-S2';
result.step = 12;
result.config = config;
result.runs = runs;
result.run_count = numel(runs);
result.restart_from_zero = true;
result.multiseed_search_executed = true;
result.is_validated = all([runs.is_validated]);
result.output_directory = create_unique_output_directory( ...
    config.output_root);
save_outputs(result.output_directory, result, config);
fprintf('C-S2 Step 12 multiseed experiment completed.\n');
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
value.restart_from_zero = search.restart_from_zero;
value.is_validated = search.is_validated && selection.is_validated;
end

function value = run_template()
value = struct('seed', [], 'stop_reason', '', ...
    'completed_generations', [], 'runtime_seconds', [], ...
    'pareto_count', [], 'selected_strategy', '', ...
    'selected_final_unload_makespan', [], 'selected_tD', [], ...
    'selected_SD', [], 'selected_Y', [], ...
    'restart_from_zero', false, 'is_validated', false);
end

function validate_same_scenario(stage11, frozenScenario)
if numel(stage11.faults) ~= numel(frozenScenario.faults) || ...
        numel(stage11.cs2_frozen_problem.interrupted_commitments) ~= ...
        numel(frozenScenario.cs2_frozen_problem.interrupted_commitments)
    error('run_stage_cs2_step_12_multiseed:ScenarioMismatch', ...
        'The rebuilt C-S2 frozen problem has a different size.');
end
for index = 1:numel(stage11.faults)
    left = stage11.faults(index);
    right = frozenScenario.faults(index);
    sameFault = left.event_id == right.event_id && ...
        left.machine_id == right.machine_id && ...
        abs(left.start_time - right.start_time) <= 1e-9 && ...
        abs(left.repair_end_time - right.repair_end_time) <= 1e-9 && ...
        strcmp(left.interruption_rule, 'restart_from_zero') && ...
        strcmp(right.interruption_rule, 'restart_from_zero');
    if ~sameFault
        error('run_stage_cs2_step_12_multiseed:ScenarioMismatch', ...
            'The rebuilt C-S2 fault group does not match Step 11.');
    end
end
for index = 1:numel(stage11.cs2_frozen_problem.interrupted_commitments)
    left = stage11.cs2_frozen_problem.interrupted_commitments(index);
    right = frozenScenario.cs2_frozen_problem.interrupted_commitments(index);
    sameCommitment = left.job == right.job && ...
        left.operation == right.operation && ...
        left.machine_id == right.machine_id && ...
        left.restart_from_zero && right.restart_from_zero && ...
        ~left.progress_preserved && ~right.progress_preserved && ...
        abs(left.lost_processing_time - ...
        right.lost_processing_time) <= 1e-9;
    if ~sameCommitment
        error('run_stage_cs2_step_12_multiseed:ScenarioMismatch', ...
            'The rebuilt C-S2 restart commitments do not match Step 11.');
    end
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
    [runs.selected_Y].', [runs.restart_from_zero].', ...
    'VariableNames', {'seed', 'stop_reason', ...
    'completed_generations', 'runtime_seconds', 'pareto_count', ...
    'selected_strategy', 'selected_final_unload_makespan', ...
    'selected_tD', 'selected_SD', 'selected_Y', ...
    'restart_from_zero'});
writetable(value, fullfile(outputDirectory, 'multiseed_summary.csv'));
end
