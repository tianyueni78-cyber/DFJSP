function scenario = run_stage_b_complete_search(baseline)
%RUN_STAGE_B_COMPLETE_SEARCH Run and save the Stage B formal search.
%   This entry creates a unique output directory and must only be called
%   after explicit approval to run MATLAB and generate outputs.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_b_complete_search_config(projectRoot);
if nargin < 1
    scenario = run_stage_b_frozen_problem();
else
    scenario = run_stage_b_frozen_problem(baseline);
end

options = search_options(config);
rng(config.seed);
runStart = tic;
scenario.complete_reschedule_search = ...
    search_stage_b_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, options);
scenario.formal_search_runtime_seconds = toc(runStart);
scenario.formal_search_config = config;
scenario.step = 11;
scenario.is_search_executed = true;
scenario.is_formal_search = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.complete_reschedule_search.is_validated;

outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_search_outputs(outputDirectory, scenario, config);

fprintf('Stage B formal complete-rescheduling search completed.\n');
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
    error('run_stage_b_complete_search:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

result = scenario.complete_reschedule_search;
commitment = scenario.frozen_problem.interrupted_commitment;
repair = scenario.frozen_problem.repair_interval;
fprintf(fileId, 'Stage B complete-rescheduling formal run\n');
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
fprintf(fileId, 'interrupted_job=%d\n', commitment.job);
fprintf(fileId, 'interrupted_operation=%d\n', commitment.operation);
fprintf(fileId, 'fault_machine=%d\n', repair.machine_id);
fprintf(fileId, 'fault_time=%.12g\n', repair.start_time);
fprintf(fileId, 'repair_end_time=%.12g\n', repair.end_time);
fprintf(fileId, 'split_operation_decoder=1\n');
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
