function result = run_stage_cseq2_step_14_multiseed(stage13)
%RUN_STAGE_CSEQ2_STEP_14_MULTISEED Run repeated C-SEQ2 formal searches.

if nargin < 1 || ~strcmp(stage13.step, 'C-SEQ2.13') || ...
        ~stage13.is_validated
    error('run_stage_cseq2_step_14_multiseed:InvalidInput', ...
        'A validated C-SEQ2 Step 13 result is required.');
end
projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_cseq2_step_14_config(projectRoot);
currentView = attach_current_plan_energy( ...
    stage13.next_fault_state.current_plan_view, stage13);
rightShift = evaluate_stage_c_right_shift_energy( ...
    currentView, stage13.cseq2_linked_right_shift);
coreFrozen = stage13.cseq2_frozen_problem;
coreFrozen.stage = 'C';
coreFrozen.step = 9;
runs = repmat(run_template(), 1, numel(config.seeds));
for index = 1:numel(config.seeds)
    seed = config.seeds(index);
    rng(seed);
    search = search_stage_c_simultaneous_complete_reschedule( ...
        currentView, coreFrozen, search_options(config));
    search.stage = 'C-SEQ2';
    selection = select_stage_c_combined_strategy( ...
        currentView, stage13.next_fault_state.state, rightShift, ...
        search, combination_config(config));
    runs(index) = summarize_run(seed, search, selection);
end

result = struct();
result.stage = 'C-SEQ2';
result.step = 14;
result.config = config;
result.runs = runs;
result.run_count = numel(runs);
result.multiseed_search_executed = true;
result.is_validated = all([runs.is_validated]);
result.output_directory = create_unique_output_directory( ...
    config.output_root);
save_outputs(result.output_directory, result, config);
fprintf('C-SEQ2 Step 14 multiseed experiment completed.\n');
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

function currentView = attach_current_plan_energy(currentView, scenario)
if isfield(currentView, 'agvEnergy') && ...
        isscalar(currentView.agvEnergy) && isfinite(currentView.agvEnergy)
    return
end
activePlan = scenario.plan_version_history.versions(end).plan;
currentView.agvEnergy = activePlan.agv_energy;
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
