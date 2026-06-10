function scenario = run_normal_baseline_search()
%RUN_NORMAL_BASELINE_SEARCH Optimize and save a source-data baseline.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = normal_baseline_search_config(projectRoot);
sourceBaseline = run_normal_schedule_baseline();
options = search_options(config);

rng(config.seed);
result = search_normal_schedule(sourceBaseline, options);

scenario = struct();
scenario.source_baseline = sourceBaseline;
scenario.normal_search = result;
scenario.optimized_baseline = result.selected_baseline;
scenario.config = config;
scenario.is_source_data_only = true;
scenario.is_fault_free = true;

outputDirectory = create_unique_output_directory(config.output_root);
scenario.output_directory = outputDirectory;
save_outputs(outputDirectory, scenario, config);

fprintf('Normal baseline search completed.\n');
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

function save_outputs(outputDirectory, scenario, config)
result = scenario.normal_search;
save(fullfile(outputDirectory, 'result.mat'), ...
    'scenario', 'config', '-v7');

objectives = reshape([result.pareto_front.objectives], 2, []).';
paretoTable = table((1:size(objectives, 1)).', ...
    objectives(:, 1), objectives(:, 2), ...
    'VariableNames', {'solution_id', 'makespan', 'total_energy'});
writetable(paretoTable, fullfile(outputDirectory, ...
    'pareto_objectives.csv'));

history = result.history;
historyTable = table([history.generation].', ...
    [history.minimum_makespan].', ...
    [history.minimum_total_energy].', ...
    [history.pareto_count].', ...
    'VariableNames', {'generation', 'minimum_makespan', ...
    'minimum_total_energy', 'pareto_count'});
writetable(historyTable, fullfile(outputDirectory, ...
    'search_history.csv'));

write_summary(fullfile(outputDirectory, 'run_summary.txt'), ...
    scenario, objectives);
end

function write_summary(filePath, scenario, objectives)
config = scenario.config;
result = scenario.normal_search;
selected = scenario.optimized_baseline;
fileId = fopen(filePath, 'w');
if fileId < 0
    error('run_normal_baseline_search:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));

fprintf(fileId, 'Source-data normal baseline search\n');
fprintf(fileId, 'source_data_only=1\n');
fprintf(fileId, 'population_size=%d\n', config.population_size);
fprintf(fileId, 'generations=%d\n', config.generations);
fprintf(fileId, 'no_improvement_generations=%d\n', ...
    config.no_improvement_generations);
fprintf(fileId, 'max_runtime_seconds=%.6g\n', ...
    config.max_runtime_seconds);
fprintf(fileId, 'seed=%d\n', config.seed);
fprintf(fileId, 'completed_generations=%d\n', ...
    result.completed_generations);
fprintf(fileId, 'stop_reason=%s\n', result.stop_reason);
fprintf(fileId, 'runtime_seconds=%.6f\n', result.runtime_seconds);
fprintf(fileId, 'pareto_solution_count=%d\n', size(objectives, 1));
fprintf(fileId, 'selected_makespan=%.12g\n', selected.makespan);
fprintf(fileId, 'selected_total_energy=%.12g\n', ...
    selected.totalEnergy);
fprintf(fileId, 'selection_rule=%s\n', result.selection_rule);
end
