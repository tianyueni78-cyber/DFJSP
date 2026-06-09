function result = search_stage_a_complete_reschedule( ...
        baseline, frozen, options)
%SEARCH_STAGE_A_COMPLETE_RESCHEDULE Run restricted NSGA-II generations.
%   This search operates only on unstarted-operation decisions. It uses
%   final-unload makespan and total machine-plus-AGV energy.

if nargin < 3
    error('search_stage_a_complete_reschedule:MissingInput', ...
        'baseline, frozen, and options are required.');
end
options = normalize_options(options);
validate_options(options);
searchStart = tic;

seedDecision = build_stage_a_baseline_seed_decision(baseline, frozen);
population = initialize_stage_a_reschedule_population( ...
    baseline, frozen, options.population_size, seedDecision);
evaluated = evaluate_population(population, baseline, frozen);
evaluated = rank_population(evaluated);

history = history_template();
history = repmat(history, 1, options.generations + 1);
history(1) = summarize_generation(0, evaluated);
paretoArchive = pareto_objectives(evaluated);
stagnantGenerations = 0;
completedGenerations = 0;
stopReason = 'maximum_generations';

for generation = 1:options.generations
    parents = tournament_select(evaluated, options.population_size, ...
        options.tournament_size);
    offspringDecisions = vary_stage_a_reschedule_population( ...
        [parents.decision], baseline, frozen, ...
        options.crossover_probability, ...
        options.mutation_probability);
    offspring = evaluate_population( ...
        offspringDecisions, baseline, frozen);
    combined = rank_population([evaluated, offspring]);
    evaluated = select_elite(combined, options.population_size);
    evaluated = rank_population(evaluated);
    history(generation + 1) = ...
        summarize_generation(generation, evaluated);

    currentPareto = pareto_objectives(evaluated);
    if has_pareto_improvement( ...
            paretoArchive, currentPareto, ...
            options.improvement_tolerance)
        paretoArchive = merge_pareto_objectives( ...
            paretoArchive, currentPareto, ...
            options.improvement_tolerance);
        stagnantGenerations = 0;
    else
        stagnantGenerations = stagnantGenerations + 1;
    end
    completedGenerations = generation;

    if toc(searchStart) >= options.max_runtime_seconds
        stopReason = 'time_limit';
        break
    end
    if stagnantGenerations >= ...
            options.no_improvement_generations
        stopReason = 'no_pareto_improvement';
        break
    end
end

front = evaluated([evaluated.rank] == 1);
front = deduplicate_front(front);
history = history(1:completedGenerations + 1);
result = struct();
result.stage = 'A';
result.strategy = 'restricted_complete_rescheduling_nsga2';
result.options = options;
result.population = evaluated;
result.pareto_front = front;
result.objective_names = { ...
    'final_unload_makespan', 'total_energy'};
result.history = history;
result.completed_generations = completedGenerations;
result.stop_reason = stopReason;
result.runtime_seconds = toc(searchStart);
result.stagnant_generations = stagnantGenerations;
result.pareto_front_is_deduplicated = true;
result.is_energy_evaluated = true;
result.is_final_unload_evaluated = true;
result.is_search_executed = true;
result.is_full_experiment = false;
result.is_validated = validate_result(result, options);
end

function evaluated = evaluate_population(decisions, baseline, frozen)
template = evaluation_template();
evaluated = repmat(template, 1, numel(decisions));
for index = 1:numel(decisions)
    value = evaluate_stage_a_reschedule_candidate( ...
        baseline, frozen, decisions(index));
    fields = fieldnames(value);
    for fieldIndex = 1:numel(fields)
        evaluated(index).(fields{fieldIndex}) = ...
            value.(fields{fieldIndex});
    end
end
end

function ranked = rank_population(population)
count = numel(population);
objectives = reshape([population.objectives], 2, count).';
dominationCount = zeros(1, count);
dominates = cell(1, count);
fronts = cell(1, 0);
fronts{1} = [];

for first = 1:count
    for second = 1:count
        if first == second
            continue
        end
        if dominates_vector(objectives(first, :), objectives(second, :))
            dominates{first}(end + 1) = second;
        elseif dominates_vector(objectives(second, :), ...
                objectives(first, :))
            dominationCount(first) = dominationCount(first) + 1;
        end
    end
    if dominationCount(first) == 0
        population(first).rank = 1;
        fronts{1}(end + 1) = first;
    end
end

frontIndex = 1;
while frontIndex <= numel(fronts) && ~isempty(fronts{frontIndex})
    nextFront = [];
    for source = fronts{frontIndex}
        for target = dominates{source}
            dominationCount(target) = dominationCount(target) - 1;
            if dominationCount(target) == 0
                population(target).rank = frontIndex + 1;
                nextFront(end + 1) = target;
            end
        end
    end
    if ~isempty(nextFront)
        fronts{frontIndex + 1} = unique(nextFront, 'stable');
    end
    frontIndex = frontIndex + 1;
end

for index = 1:count
    population(index).crowding_distance = 0;
end
for index = 1:numel(fronts)
    if ~isempty(fronts{index})
        population = assign_crowding( ...
            population, fronts{index}, objectives);
    end
end
ranked = population;
end

function result = dominates_vector(first, second)
result = all(first <= second) && any(first < second);
end

function population = assign_crowding(population, indices, objectives)
frontSize = numel(indices);
if frontSize <= 2
    for index = indices
        population(index).crowding_distance = Inf;
    end
    return
end

distance = zeros(1, frontSize);
for objective = 1:size(objectives, 2)
    values = objectives(indices, objective);
    [sortedValues, order] = sort(values);
    distance(order(1)) = Inf;
    distance(order(end)) = Inf;
    span = sortedValues(end) - sortedValues(1);
    if span <= 0
        continue
    end
    for position = 2:frontSize - 1
        if ~isinf(distance(order(position)))
            distance(order(position)) = distance(order(position)) + ...
                (sortedValues(position + 1) - ...
                sortedValues(position - 1)) / span;
        end
    end
end
for position = 1:frontSize
    population(indices(position)).crowding_distance = ...
        distance(position);
end
end

function parents = tournament_select(population, count, tournamentSize)
parents = repmat(population(1), 1, count);
populationSize = numel(population);
effectiveSize = min(tournamentSize, populationSize);
for outputIndex = 1:count
    competitors = randperm(populationSize, effectiveSize);
    winner = competitors(1);
    for index = competitors(2:end)
        if is_better(population(index), population(winner))
            winner = index;
        end
    end
    parents(outputIndex) = population(winner);
end
end

function result = is_better(first, second)
result = first.rank < second.rank || ...
    (first.rank == second.rank && ...
    first.crowding_distance > second.crowding_distance);
end

function selected = select_elite(population, populationSize)
ranks = [population.rank].';
crowding = [population.crowding_distance].';
indices = (1:numel(population)).';
ordering = [ranks, -crowding, indices];
[~, order] = sortrows(ordering, [1, 2, 3]);
selected = population(order(1:populationSize));
end

function summary = summarize_generation(generation, population)
objectives = reshape([population.objectives], 2, []).';
summary = history_template();
summary.generation = generation;
summary.minimum_final_unload_makespan = min(objectives(:, 1));
summary.minimum_total_energy = min(objectives(:, 2));
summary.pareto_count = size(pareto_objectives(population), 1);
end

function result = validate_result(searchResult, options)
if numel(searchResult.population) ~= options.population_size
    error('search_stage_a_complete_reschedule:PopulationSize', ...
        'Final population size is incorrect.');
end
if isempty(searchResult.pareto_front) || ...
        any(~[searchResult.population.is_validated])
    error('search_stage_a_complete_reschedule:InvalidResult', ...
        'Search result contains invalid candidates or no Pareto front.');
end
if numel(searchResult.history) ~= ...
        searchResult.completed_generations + 1
    error('search_stage_a_complete_reschedule:HistoryLength', ...
        'Search history length is incorrect.');
end
if searchResult.completed_generations > options.generations
    error('search_stage_a_complete_reschedule:GenerationLimit', ...
        'Completed generations exceed the configured maximum.');
end
frontObjectives = reshape( ...
    [searchResult.pareto_front.objectives], 2, []).';
if size(unique(frontObjectives, 'rows'), 1) ~= ...
        size(frontObjectives, 1)
    error('search_stage_a_complete_reschedule:DuplicatePareto', ...
        'Pareto front contains duplicate objective vectors.');
end
result = true;
end

function options = normalize_options(options)
defaults = struct();
defaults.no_improvement_generations = Inf;
defaults.max_runtime_seconds = Inf;
defaults.improvement_tolerance = 1e-9;
fields = fieldnames(defaults);
for index = 1:numel(fields)
    if ~isfield(options, fields{index})
        options.(fields{index}) = defaults.(fields{index});
    end
end
end

function validate_options(options)
required = {'population_size', 'generations', ...
    'crossover_probability', 'mutation_probability', ...
    'tournament_size'};
for index = 1:numel(required)
    if ~isfield(options, required{index})
        error('search_stage_a_complete_reschedule:MissingOption', ...
            'options.%s is required.', required{index});
    end
end
validate_positive_integer(options.population_size, 'population_size');
validate_nonnegative_integer(options.generations, 'generations');
validate_positive_integer(options.tournament_size, 'tournament_size');
validate_probability(options.crossover_probability, ...
    'crossover_probability');
validate_probability(options.mutation_probability, ...
    'mutation_probability');
validate_positive_limit(options.no_improvement_generations, ...
    'no_improvement_generations');
validate_positive_limit(options.max_runtime_seconds, ...
    'max_runtime_seconds');
if ~isscalar(options.improvement_tolerance) || ...
        ~isfinite(options.improvement_tolerance) || ...
        options.improvement_tolerance < 0
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        'improvement_tolerance must be finite and nonnegative.');
end
end

function validate_positive_limit(value, name)
if ~isscalar(value) || value <= 0 || ...
        (~isfinite(value) && value ~= Inf)
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        '%s must be positive or Inf.', name);
end
if strcmp(name, 'no_improvement_generations') && ...
        isfinite(value) && value ~= floor(value)
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        '%s must be an integer or Inf.', name);
end
end

function validate_positive_integer(value, name)
if ~isscalar(value) || value < 1 || value ~= floor(value)
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        '%s must be a positive integer.', name);
end
end

function validate_nonnegative_integer(value, name)
if ~isscalar(value) || value < 0 || value ~= floor(value)
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        '%s must be a nonnegative integer.', name);
end
end

function validate_probability(value, name)
if ~isscalar(value) || value < 0 || value > 1
    error('search_stage_a_complete_reschedule:InvalidOption', ...
        '%s must be between zero and one.', name);
end
end

function value = evaluation_template()
value = struct('decision', [], 'candidate', [], ...
    'objectives', [], 'objective_names', {{}}, ...
    'machine_operation_makespan', [], ...
    'machine_assignment_changes', [], ...
    'final_unload_makespan', [], 'machine_energy', [], ...
    'agv_energy', [], 'total_energy', [], 'rank', [], ...
    'crowding_distance', [], 'is_energy_evaluated', false, ...
    'is_final_unload_evaluated', false, 'is_validated', false);
end

function value = history_template()
value = struct('generation', [], ...
    'minimum_final_unload_makespan', [], ...
    'minimum_total_energy', [], 'pareto_count', []);
end

function objectives = pareto_objectives(population)
front = population([population.rank] == 1);
front = deduplicate_front(front);
objectives = reshape([front.objectives], 2, []).';
end

function front = deduplicate_front(front)
if isempty(front)
    return
end
objectives = reshape([front.objectives], 2, []).';
[~, uniqueIndices] = unique(objectives, 'rows', 'stable');
front = front(uniqueIndices);
end

function improved = has_pareto_improvement( ...
        archive, current, tolerance)
improved = false;
for currentIndex = 1:size(current, 1)
    weaklyDominated = false;
    for archiveIndex = 1:size(archive, 1)
        if all(archive(archiveIndex, :) <= ...
                current(currentIndex, :) + tolerance)
            weaklyDominated = true;
            break
        end
    end
    if ~weaklyDominated
        improved = true;
        return
    end
end
end

function archive = merge_pareto_objectives( ...
        archive, current, tolerance)
candidates = [archive; current];
keep = true(size(candidates, 1), 1);
for first = 1:size(candidates, 1)
    if ~keep(first)
        continue
    end
    for second = 1:size(candidates, 1)
        if first == second
            continue
        end
        if all(candidates(second, :) <= ...
                candidates(first, :) + tolerance) && ...
                any(candidates(second, :) < ...
                candidates(first, :) - tolerance)
            keep(first) = false;
            break
        end
    end
end
archive = unique(candidates(keep, :), 'rows', 'stable');
end
