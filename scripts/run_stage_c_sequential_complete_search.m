function scenario = run_stage_c_sequential_complete_search(stage16)
%RUN_STAGE_C_SEQUENTIAL_COMPLETE_SEARCH Run and save Stage C Step 16.4.
%   This entry creates a unique output directory and must only be called
%   after explicit approval to run MATLAB and generate outputs.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_c_sequential_complete_search_config(projectRoot);
if nargin < 1
    stage16 = run_stage_c_sequential_frozen_problem();
end
if stage16.step ~= 16 || ~strcmp(stage16.substep, '16.1') || ...
        ~stage16.is_validated
    error('run_stage_c_sequential_complete_search:InvalidInput', ...
        'A validated Stage C Step 16.1 scenario is required.');
end

options = search_options(config);
currentView = stage16.next_fault_state.current_plan_view;
rng(config.seed);
runStart = tic;
search = search_stage_c_simultaneous_complete_reschedule( ...
    currentView, stage16.sequential_frozen_problem, options);

scenario = stage16;
scenario.sequential_complete_reschedule_search = search;
scenario.formal_search_runtime_seconds = toc(runStart);
scenario.formal_search_config = config;
scenario.step = 16;
scenario.substep = '16.4';
scenario.is_search_executed_in_step_16 = true;
scenario.is_formal_search = true;
scenario.is_full_experiment = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && search.is_validated;

outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_search_outputs(outputDirectory, scenario, config);

fprintf(['Stage C sequential-fault complete-rescheduling ', ...
    'search completed.\n']);
fprintf('Output directory: %s\n', outputDirectory);
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

function save_search_outputs(outputDirectory, scenario, config)
result = scenario.sequential_complete_reschedule_search;
save(fullfile(outputDirectory, 'result.mat'), ...
    'scenario', 'config', '-v7');

front = result.pareto_front;
objectives = reshape([front.objectives], 2, []).';
paretoTable = table((1:size(objectives, 1)).', ...
    objectives(:, 1), objectives(:, 2), ...
    'VariableNames', {'solution_id', ...
    'final_unload_makespan', 'total_energy'});
writetable(paretoTable, fullfile(outputDirectory, ...
    'pareto_objectives.csv'));

history = result.history;
historyTable = table([history.generation].', ...
    [history.minimum_final_unload_makespan].', ...
    [history.minimum_total_energy].', ...
    [history.pareto_count].', ...
    'VariableNames', {'generation', ...
    'minimum_final_unload_makespan', ...
    'minimum_total_energy', 'pareto_count'});
writetable(historyTable, fullfile(outputDirectory, ...
    'search_history.csv'));

write_run_summary(fullfile(outputDirectory, 'run_summary.txt'), ...
    scenario, config, objectives);
end

function write_run_summary(filePath, scenario, config, objectives)
fileId = fopen(filePath, 'w');
if fileId < 0
    error('run_stage_c_sequential_complete_search:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

result = scenario.sequential_complete_reschedule_search;
commitments = scenario.sequential_frozen_problem.interrupted_commitments;
repairs = scenario.sequential_frozen_problem.repair_intervals;
fault = scenario.next_fault;
fprintf(fileId, ...
    'Stage C sequential-fault complete-rescheduling formal run\n');
fprintf(fileId, 'run_type=%s\n', config.run_type);
fprintf(fileId, 'population_size=%d\n', config.population_size);
fprintf(fileId, 'generations=%d\n', config.generations);
fprintf(fileId, 'crossover_probability=%.6g\n', ...
    config.crossover_probability);
fprintf(fileId, 'mutation_probability=%.6g\n', ...
    config.mutation_probability);
fprintf(fileId, 'tournament_size=%d\n', config.tournament_size);
fprintf(fileId, 'no_improvement_generations=%d\n', ...
    config.no_improvement_generations);
fprintf(fileId, 'max_runtime_seconds=%.6g\n', ...
    config.max_runtime_seconds);
fprintf(fileId, 'improvement_tolerance=%.12g\n', ...
    config.improvement_tolerance);
fprintf(fileId, 'seed=%d\n', config.seed);
fprintf(fileId, 'input_version_id=%d\n', ...
    scenario.sequential_impact_context.input_version_id);
fprintf(fileId, 'next_fault_event_id=%d\n', fault.event_id);
fprintf(fileId, 'next_fault_machine=%d\n', fault.machine_id);
fprintf(fileId, 'next_fault_start_time=%.12g\n', fault.start_time);
fprintf(fileId, 'next_fault_repair_end_time=%.12g\n', ...
    fault.repair_end_time);
fprintf(fileId, 'interrupted_operation_count=%d\n', ...
    numel(commitments));
fprintf(fileId, 'repair_interval_count=%d\n', numel(repairs));
for index = 1:numel(commitments)
    commitment = commitments(index);
    fprintf(fileId, 'interruption_%d_event_ids=%s\n', index, ...
        mat2str(commitment.event_ids));
    fprintf(fileId, 'interruption_%d_job=%d\n', ...
        index, commitment.job);
    fprintf(fileId, 'interruption_%d_operation=%d\n', ...
        index, commitment.operation);
    fprintf(fileId, 'interruption_%d_machine=%d\n', ...
        index, commitment.machine_id);
    fprintf(fileId, 'interruption_%d_progress_preserved=%d\n', ...
        index, commitment.progress_preserved);
end
for index = 1:numel(repairs)
    repair = repairs(index);
    fprintf(fileId, 'repair_%d_event_id=%d\n', ...
        index, repair.event_id);
    fprintf(fileId, 'repair_%d_machine=%d\n', ...
        index, repair.machine_id);
    fprintf(fileId, 'repair_%d_start_time=%.12g\n', ...
        index, repair.start_time);
    fprintf(fileId, 'repair_%d_end_time=%.12g\n', ...
        index, repair.end_time);
end
fprintf(fileId, 'multiple_split_operation_decoder=1\n');
fprintf(fileId, 'runtime_seconds=%.6f\n', ...
    scenario.formal_search_runtime_seconds);
fprintf(fileId, 'pareto_solution_count=%d\n', size(objectives, 1));
fprintf(fileId, 'completed_generations=%d\n', ...
    result.completed_generations);
fprintf(fileId, 'stop_reason=%s\n', result.stop_reason);
fprintf(fileId, 'minimum_final_unload_makespan=%.12g\n', ...
    min(objectives(:, 1)));
fprintf(fileId, 'minimum_total_energy=%.12g\n', ...
    min(objectives(:, 2)));
end
