function scenario = run_stage_a_step_13_search_and_selection(stage12)
%RUN_STAGE_A_STEP_13_SEARCH_AND_SELECTION Search, evaluate, and save.

if nargin < 1
    error('run_stage_a_step_13_search_and_selection:MissingInput', ...
        'The formal Stage A Step 12 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));
require_scheduling_dependency();

validate_stage12(stage12);
config = stage_a_step_13_config(projectRoot);
options = search_options(config);

rng(config.seed);
search = search_stage_a_complete_reschedule( ...
    stage12.baseline, stage12.frozen_problem, options);
combinationConfig = combination_config(config);
selection = select_stage_a_combined_strategy( ...
    stage12.baseline, stage12.state, ...
    stage12.linked_right_shift, search, combinationConfig);

scenario = stage12;
scenario.step = 13;
scenario.complete_reschedule_search = search;
scenario.combination_config = combinationConfig;
scenario.combined_selection = selection;
scenario.step_13_config = config;
scenario.is_search_executed = true;
scenario.is_combination_evaluated = true;
scenario.is_contract_run = false;
scenario.is_formal_run = true;
scenario.is_validated = stage12.is_validated && ...
    search.is_validated && ...
    selection.is_validated;

outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_outputs(outputDirectory, scenario, config);

fprintf('Stage A Step 13 search and selection completed.\n');
fprintf('Output directory: %s\n', outputDirectory);
fprintf('stop reason: %s, completed generations: %d\n', ...
    search.stop_reason, search.completed_generations);
fprintf('Pareto solutions: %d\n', numel(search.pareto_front));
fprintf('selected strategy: %s\n', selection.selected_strategy);
fprintf('selected tD: %.6g, SD: %d, Y: %.6g\n', ...
    selection.selected_metrics.tD, ...
    selection.selected_metrics.SD, ...
    selection.selected_metrics.Y);
end

function require_scheduling_dependency()
if exist('spare_transfer_time_compute', 'file') ~= 2
    error(['run_stage_a_step_13_search_and_selection:', ...
        'SchedulingDependency'], ...
        'spare_transfer_time_compute must be available during search.');
end
end

function validate_stage12(stage12)
required = {'step', 'baseline', 'fault', 'state', ...
    'linked_right_shift', 'frozen_problem', 'is_validated', ...
    'is_search_executed'};
for index = 1:numel(required)
    if ~isfield(stage12, required{index})
        error('run_stage_a_step_13_search_and_selection:InputField', ...
            'stage12.%s is required.', required{index});
    end
end
if stage12.step ~= 12 || ~stage12.is_validated || ...
        stage12.is_search_executed || ...
        ~stage12.linked_right_shift.is_fully_validated || ...
        ~stage12.frozen_problem.is_validated
    error('run_stage_a_step_13_search_and_selection:InvalidInput', ...
        'A validated, unsearched Step 12 scenario is required.');
end
end

function options = search_options(config)
options = struct();
options.population_size = config.population_size;
options.generations = config.generations;
options.crossover_probability = config.crossover_probability;
options.mutation_probability = config.mutation_probability;
options.tournament_size = config.tournament_size;
options.no_improvement_generations = ...
    config.no_improvement_generations;
options.max_runtime_seconds = config.max_runtime_seconds;
options.improvement_tolerance = config.improvement_tolerance;
end

function value = combination_config(config)
value = struct();
value.completion_time_weight = config.completion_time_weight;
value.sequence_deviation_weight = ...
    config.sequence_deviation_weight;
value.tie_tolerance = config.tie_tolerance;
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

function save_outputs(outputDirectory, scenario, config)
save(fullfile(outputDirectory, 'result.mat'), ...
    'scenario', 'config', '-v7');
save_pareto(outputDirectory, scenario.complete_reschedule_search);
save_history(outputDirectory, scenario.complete_reschedule_search);
save_evaluations(outputDirectory, scenario.combined_selection);
write_summary(fullfile(outputDirectory, 'run_summary.txt'), scenario);
end

function save_pareto(outputDirectory, search)
objectives = reshape([search.pareto_front.objectives], 2, []).';
value = table((1:size(objectives, 1)).', ...
    objectives(:, 1), objectives(:, 2), ...
    'VariableNames', {'solution_id', ...
    'final_unload_makespan', 'total_energy'});
writetable(value, fullfile(outputDirectory, ...
    'pareto_objectives.csv'));
end

function save_history(outputDirectory, search)
history = search.history;
value = table([history.generation].', ...
    [history.minimum_final_unload_makespan].', ...
    [history.minimum_total_energy].', ...
    [history.pareto_count].', ...
    'VariableNames', {'generation', ...
    'minimum_final_unload_makespan', ...
    'minimum_total_energy', 'pareto_count'});
writetable(value, fullfile(outputDirectory, 'search_history.csv'));
end

function save_evaluations(outputDirectory, selection)
evaluations = selection.evaluations;
strategies = {evaluations.strategy}.';
value = table((1:numel(evaluations)).', ...
    strategies, ...
    [evaluations.candidate_makespan].', ...
    [evaluations.tD].', [evaluations.SD].', [evaluations.Y].', ...
    'VariableNames', {'candidate_id', 'strategy', ...
    'final_unload_makespan', 'tD', 'SD', 'Y'});
writetable(value, fullfile(outputDirectory, ...
    'combination_evaluations.csv'));
end

function write_summary(filePath, scenario)
search = scenario.complete_reschedule_search;
selection = scenario.combined_selection;
fault = scenario.fault;
fileId = fopen(filePath, 'w');
if fileId < 0
    error('run_stage_a_step_13_search_and_selection:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

fprintf(fileId, 'Stage A Step 13 formal search and selection\n');
fprintf(fileId, 'baseline_makespan=%.12g\n', ...
    scenario.baseline.makespan);
fprintf(fileId, 'fault_trigger=J%d-O%d\n', ...
    fault.trigger_job, fault.trigger_operation);
fprintf(fileId, 'fault_machine=%d\n', fault.machine_id);
fprintf(fileId, 'fault_time=%.12g\n', fault.start_time);
fprintf(fileId, 'repair_duration=%.12g\n', fault.repair_duration);
fprintf(fileId, 'reschedulable_operations=%d\n', ...
    scenario.frozen_problem.counts.reschedulable_operations);
fprintf(fileId, 'completed_generations=%d\n', ...
    search.completed_generations);
fprintf(fileId, 'stop_reason=%s\n', search.stop_reason);
fprintf(fileId, 'runtime_seconds=%.6f\n', search.runtime_seconds);
fprintf(fileId, 'pareto_solution_count=%d\n', ...
    numel(search.pareto_front));
fprintf(fileId, 'selected_strategy=%s\n', ...
    selection.selected_strategy);
fprintf(fileId, 'selected_final_unload_makespan=%.12g\n', ...
    selection.selected_metrics.candidate_makespan);
fprintf(fileId, 'selected_tD=%.12g\n', ...
    selection.selected_metrics.tD);
fprintf(fileId, 'selected_SD=%d\n', ...
    selection.selected_metrics.SD);
fprintf(fileId, 'selected_Y=%.12g\n', ...
    selection.selected_metrics.Y);
end
