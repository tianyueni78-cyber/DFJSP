function scenario = run_stage_a_confirmation_search()
%RUN_STAGE_A_CONFIRMATION_SEARCH Run and save the approved 10-by-20 search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_a_confirmation_search_config(projectRoot);
scenario = run_stage_a_frozen_problem();

options = struct();
options.population_size = config.population_size;
options.generations = config.generations;
options.crossover_probability = config.crossover_probability;
options.mutation_probability = config.mutation_probability;
options.tournament_size = config.tournament_size;

rng(config.seed);
runStart = tic;
scenario.complete_reschedule_search = ...
    search_stage_a_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, options);
scenario.confirmation_runtime_seconds = toc(runStart);
scenario.confirmation_config = config;
scenario.is_search_executed = true;
scenario.is_confirmation_run = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;

outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_confirmation_outputs(outputDirectory, scenario, config);

fprintf('Stage A confirmation search completed.\n');
fprintf('Output directory: %s\n', outputDirectory);
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

function save_confirmation_outputs(outputDirectory, scenario, config)
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
    error('run_stage_a_confirmation_search:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

fprintf(fileId, 'Stage A complete-rescheduling confirmation run\n');
fprintf(fileId, 'population_size=%d\n', config.population_size);
fprintf(fileId, 'generations=%d\n', config.generations);
fprintf(fileId, 'crossover_probability=%.6g\n', ...
    config.crossover_probability);
fprintf(fileId, 'mutation_probability=%.6g\n', ...
    config.mutation_probability);
fprintf(fileId, 'tournament_size=%d\n', config.tournament_size);
fprintf(fileId, 'seed=%d\n', config.seed);
fprintf(fileId, 'runtime_seconds=%.6f\n', ...
    scenario.confirmation_runtime_seconds);
fprintf(fileId, 'pareto_solution_count=%d\n', size(objectives, 1));
fprintf(fileId, 'minimum_final_unload_makespan=%.12g\n', ...
    min(objectives(:, 1)));
fprintf(fileId, 'minimum_total_energy=%.12g\n', ...
    min(objectives(:, 2)));
end
