function result = run_stage_c_final_audit_multiseed()
%RUN_STAGE_C_FINAL_AUDIT_MULTISEED Run Stage C Step 17.2 formal audit.
%   This is the final multi-random-seed entry for the implemented Stage C
%   scenarios: C-S1 simultaneous faults and C-SEQ1 sequential faults.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

config = stage_c_final_audit_multiseed_config(projectRoot);
options = search_options(config);
outputDirectory = create_unique_output_directory(config.output_root);

runs = run_all_scenarios(config, options);
summary = summarize_all_runs(runs);

result = struct();
result.stage = 'C';
result.step = 17;
result.substep = '17.2';
result.audit_scope = config.audit_scope;
result.config = config;
result.runs = runs;
result.summary = summary;
result.output_directory = outputDirectory;
result.multiseed_search_executed = true;
result.is_full_experiment = true;
result.is_validated = all([runs.is_validated]);

save_outputs(outputDirectory, result, config);

fprintf('Stage C final audit multiseed experiment completed.\n');
fprintf('Output directory: %s\n', outputDirectory);
end

function runs = run_all_scenarios(config, options)
runs = [];
for scenarioIndex = 1:numel(config.scenarios)
    scenarioConfig = config.scenarios(scenarioIndex);
    baseScenario = build_base_scenario(scenarioConfig.id);
    for seedIndex = 1:numel(config.random_seeds)
        seed = config.random_seeds(seedIndex);
        run = run_one_seed(scenarioConfig, baseScenario, options, seed);
        runs = append_run(runs, run);
    end
end
end

function baseScenario = build_base_scenario(scenarioId)
switch scenarioId
    case 'C-S1'
        baseScenario = run_stage_c_simultaneous_frozen_problem();
    case 'C-SEQ1'
        baseScenario = run_stage_c_sequential_frozen_problem();
    otherwise
        error('run_stage_c_final_audit_multiseed:UnsupportedScenario', ...
            'Scenario %s is not implemented for Stage C Step 17.2.', ...
            scenarioId);
end
end

function run = run_one_seed(scenarioConfig, baseScenario, options, seed)
rng(seed);
timer = tic;
switch scenarioConfig.id
    case 'C-S1'
        search = search_stage_c_simultaneous_complete_reschedule( ...
            baseScenario.baseline, baseScenario.frozen_problem, options);
        searchScenario = baseScenario;
        searchScenario.complete_reschedule_search = search;
        combined = run_stage_c_combination_selection(searchScenario);
        searchField = 'complete_reschedule_search';
    case 'C-SEQ1'
        currentView = baseScenario.next_fault_state.current_plan_view;
        search = search_stage_c_simultaneous_complete_reschedule( ...
            currentView, baseScenario.sequential_frozen_problem, options);
        searchScenario = baseScenario;
        searchScenario.sequential_complete_reschedule_search = search;
        combined = run_stage_c_sequential_combination_selection( ...
            searchScenario);
        searchField = 'sequential_complete_reschedule_search';
    otherwise
        error('run_stage_c_final_audit_multiseed:UnsupportedScenario', ...
            'Scenario %s is not implemented for Stage C Step 17.2.', ...
            scenarioConfig.id);
end
runtimeSeconds = toc(timer);
run = summarize_run(scenarioConfig, seed, combined, searchField, ...
    runtimeSeconds);
end

function run = summarize_run(scenarioConfig, seed, combined, ...
        searchField, runtimeSeconds)
search = combined.(searchField);
selected = combined.combined_selection.selected_metrics;
run = struct();
run.scenario_id = scenarioConfig.id;
run.fault_relation = scenarioConfig.fault_relation;
run.interruption_rule = scenarioConfig.interruption_rule;
run.seed = seed;
run.stop_reason = search.stop_reason;
run.completed_generations = search.completed_generations;
run.runtime_seconds = runtimeSeconds;
run.search_runtime_seconds = search.runtime_seconds;
run.pareto_count = numel(search.pareto_front);
run.selected_strategy = combined.combined_selection.selected_strategy;
run.selected_final_unload_makespan = selected.candidate_makespan;
run.selected_tD = selected.tD;
run.selected_SD = selected.SD;
run.selected_Y = selected.Y;
run.all_constraint_audits_validated = ...
    combined.all_constraint_audits_validated;
run.all_energy_audits_complete = combined.all_energy_audits_complete;
run.is_validated = combined.is_validated && ...
    run.all_constraint_audits_validated && ...
    run.all_energy_audits_complete;
end

function runs = append_run(runs, run)
if isempty(runs)
    runs = run;
else
    runs(end + 1) = run;
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

function summary = summarize_all_runs(runs)
scenarioIds = unique({runs.scenario_id}, 'stable');
summary = repmat(struct(), 1, numel(scenarioIds));
for index = 1:numel(scenarioIds)
    scenarioId = scenarioIds{index};
    selected = strcmp({runs.scenario_id}, scenarioId);
    scenarioRuns = runs(selected);
    yValues = [scenarioRuns.selected_Y];
    makespans = [scenarioRuns.selected_final_unload_makespan];
    summary(index).scenario_id = scenarioId;
    summary(index).run_count = numel(scenarioRuns);
    summary(index).best_Y = min(yValues);
    summary(index).mean_Y = mean(yValues);
    summary(index).worst_Y = max(yValues);
    summary(index).best_makespan = min(makespans);
    summary(index).mean_makespan = mean(makespans);
    summary(index).all_runs_validated = all([scenarioRuns.is_validated]);
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
writetable(runs_table(result.runs), fullfile(outputDirectory, ...
    'multiseed_summary.csv'));
writetable(summary_table(result.summary), fullfile(outputDirectory, ...
    'scenario_summary.csv'));
write_run_summary(fullfile(outputDirectory, 'run_summary.txt'), result);
end

function tableValue = runs_table(runs)
tableValue = table( ...
    {runs.scenario_id}.', ...
    [runs.seed].', ...
    {runs.stop_reason}.', ...
    [runs.completed_generations].', ...
    [runs.runtime_seconds].', ...
    [runs.pareto_count].', ...
    {runs.selected_strategy}.', ...
    [runs.selected_final_unload_makespan].', ...
    [runs.selected_tD].', ...
    [runs.selected_SD].', ...
    [runs.selected_Y].', ...
    [runs.all_constraint_audits_validated].', ...
    [runs.all_energy_audits_complete].', ...
    [runs.is_validated].', ...
    'VariableNames', {'scenario_id', 'seed', 'stop_reason', ...
    'generations', 'runtime_seconds', 'pareto_count', ...
    'strategy', 'makespan', 'tD', 'SD', 'Y', ...
    'constraints_validated', 'energy_complete', 'is_validated'});
end

function tableValue = summary_table(summary)
tableValue = table( ...
    {summary.scenario_id}.', ...
    [summary.run_count].', ...
    [summary.best_Y].', ...
    [summary.mean_Y].', ...
    [summary.worst_Y].', ...
    [summary.best_makespan].', ...
    [summary.mean_makespan].', ...
    [summary.all_runs_validated].', ...
    'VariableNames', {'scenario_id', 'run_count', 'best_Y', ...
    'mean_Y', 'worst_Y', 'best_makespan', 'mean_makespan', ...
    'all_runs_validated'});
end

function write_run_summary(filePath, result)
fileId = fopen(filePath, 'w');
if fileId < 0
    error('run_stage_c_final_audit_multiseed:SummaryFile', ...
        'Unable to create run summary.');
end
cleanupFile = onCleanup(@() fclose(fileId));
fprintf(fileId, 'Stage C Step 17.2 final audit multiseed run\n');
fprintf(fileId, 'scenario_count=%d\n', numel(result.summary));
fprintf(fileId, 'run_count=%d\n', numel(result.runs));
fprintf(fileId, 'seeds=%s\n', mat2str(result.config.random_seeds));
fprintf(fileId, 'population_size=%d\n', result.config.population_size);
fprintf(fileId, 'generations=%d\n', result.config.generations);
fprintf(fileId, 'no_improvement_generations=%d\n', ...
    result.config.no_improvement_generations);
fprintf(fileId, 'max_runtime_seconds=%.6g\n', ...
    result.config.max_runtime_seconds);
fprintf(fileId, 'all_runs_validated=%d\n', result.is_validated);
for index = 1:numel(result.summary)
    item = result.summary(index);
    fprintf(fileId, '%s_run_count=%d\n', item.scenario_id, ...
        item.run_count);
    fprintf(fileId, '%s_best_Y=%.12g\n', item.scenario_id, ...
        item.best_Y);
    fprintf(fileId, '%s_mean_Y=%.12g\n', item.scenario_id, ...
        item.mean_Y);
    fprintf(fileId, '%s_all_runs_validated=%d\n', item.scenario_id, ...
        item.all_runs_validated);
end
end
