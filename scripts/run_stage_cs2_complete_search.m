function scenario = run_stage_cs2_complete_search(baseline)
%RUN_STAGE_CS2_COMPLETE_SEARCH Run and save the C-S2 formal search.
%   This entry creates a unique output directory and must only be called
%   after explicit approval to run MATLAB and generate outputs.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_cs2_complete_search_config(projectRoot);
if nargin < 1
    scenario = run_stage_cs2_frozen_problem();
else
    scenario = run_stage_cs2_frozen_problem(baseline);
end

% Block 1: run the approved C-S2 single-seed formal search.
options = search_options(config);
rng(config.seed);
runStart = tic;
scenario.complete_reschedule_search = ...
    search_stage_cs2_complete_reschedule( ...
    scenario.baseline, scenario.cs2_frozen_problem, options);
scenario.formal_search_runtime_seconds = toc(runStart);
scenario.formal_search_config = config;
scenario.step = 'C-S2.10';
scenario.substep = '10';
scenario.is_search_executed = true;
scenario.is_formal_search = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.complete_reschedule_search.is_validated;

% Block 2: save result.mat, Pareto objectives, search history and summary.
outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_search_outputs(outputDirectory, scenario, config);

fprintf(['Stage C-S2 simultaneous restart complete-rescheduling ', ...
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
result = scenario.complete_reschedule_search;
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
    error('run_stage_cs2_complete_search:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

result = scenario.complete_reschedule_search;
commitments = scenario.cs2_frozen_problem.interrupted_commitments;
repairs = scenario.cs2_frozen_problem.repair_intervals;
fprintf(fileId, ...
    'Stage C-S2 simultaneous restart formal run\n');
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
    fprintf(fileId, 'interruption_%d_restart_from_zero=%d\n', ...
        index, commitment.restart_from_zero);
    fprintf(fileId, 'interruption_%d_progress_preserved=%d\n', ...
        index, commitment.progress_preserved);
    fprintf(fileId, 'interruption_%d_lost_processing_time=%.12g\n', ...
        index, commitment.lost_processing_time);
    fprintf(fileId, 'interruption_%d_restart_processing_time=%.12g\n', ...
        index, commitment.original_duration);
    fprintf(fileId, ...
        'interruption_%d_total_machine_processing_time=%.12g\n', ...
        index, commitment.total_machine_processing_time);
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
fprintf(fileId, 'multiple_restart_operation_decoder=1\n');
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
