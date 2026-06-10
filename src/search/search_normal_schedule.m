function result = search_normal_schedule(sourceBaseline, options)
%SEARCH_NORMAL_SCHEDULE Optimize the original full scheduling problem.

options = normalize_options(options);
validate_inputs(sourceBaseline, options);
searchStart = tic;

searchProblem = build_normal_search_problem(sourceBaseline.problem);
seedDecision = chromosome_to_full_decision( ...
    sourceBaseline.chrom, sourceBaseline.problem);
population = initialize_stage_a_reschedule_population( ...
    sourceBaseline, searchProblem, options.population_size, seedDecision);
evaluated = evaluate_population(population, sourceBaseline);
evaluated = rank_population(evaluated);

history = repmat(history_template(), 1, options.generations + 1);
history(1) = summarize_generation(0, evaluated);
paretoArchive = pareto_objectives(evaluated);
stagnantGenerations = 0;
completedGenerations = 0;
stopReason = 'maximum_generations';

for generation = 1:options.generations
    parents = tournament_select( ...
        evaluated, options.population_size, options.tournament_size);
    offspringDecisions = vary_stage_a_reschedule_population( ...
        [parents.decision], sourceBaseline, searchProblem, ...
        options.crossover_probability, options.mutation_probability);
    offspring = evaluate_population(offspringDecisions, sourceBaseline);
    evaluated = rank_population([evaluated, offspring]);
    evaluated = select_elite(evaluated, options.population_size);
    evaluated = rank_population(evaluated);
    history(generation + 1) = summarize_generation(generation, evaluated);

    currentPareto = pareto_objectives(evaluated);
    if has_pareto_improvement( ...
            paretoArchive, currentPareto, options.improvement_tolerance)
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
    if stagnantGenerations >= options.no_improvement_generations
        stopReason = 'no_pareto_improvement';
        break
    end
end

front = evaluated([evaluated.rank] == 1);
front = deduplicate_front(front);
history = history(1:completedGenerations + 1);
selectedIndex = select_baseline(front);

result = struct();
result.strategy = 'normal_schedule_nsga2';
result.options = options;
result.population = evaluated;
result.pareto_front = front;
result.selected_index = selectedIndex;
result.selected_baseline = front(selectedIndex).baseline;
result.selection_rule = 'minimum_makespan_then_minimum_energy';
result.objective_names = {'makespan', 'total_energy'};
result.history = history;
result.completed_generations = completedGenerations;
result.stop_reason = stopReason;
result.runtime_seconds = toc(searchStart);
result.stagnant_generations = stagnantGenerations;
result.pareto_front_is_deduplicated = true;
result.is_search_executed = true;
result.is_validated = validate_result(result, options);
end

function evaluated = evaluate_population(decisions, sourceBaseline)
template = evaluation_template();
evaluated = repmat(template, 1, numel(decisions));
for index = 1:numel(decisions)
    chrom = full_decision_to_chromosome(decisions(index));
    baseline = build_normal_schedule( ...
        chrom, sourceBaseline.problem, sourceBaseline.machineData, ...
        sourceBaseline.agvData, sourceBaseline.energyConfig);
    baseline.problem = sourceBaseline.problem;
    baseline.machineData = sourceBaseline.machineData;
    baseline.agvData = sourceBaseline.agvData;
    baseline.energyConfig = sourceBaseline.energyConfig;
    baseline.seed = sourceBaseline.seed;

    evaluated(index).decision = decisions(index);
    evaluated(index).baseline = baseline;
    evaluated(index).objectives = ...
        [baseline.makespan, baseline.totalEnergy];
    evaluated(index).rank = [];
    evaluated(index).crowding_distance = [];
    evaluated(index).is_validated = ...
        baseline.isFaultFreeBaseline && ...
        all(isfinite(evaluated(index).objectives));
end
end

function ranked = rank_population(population)
count = numel(population);
objectives = reshape([population.objectives], 2, count).';
dominationCount = zeros(1, count);
dominates = cell(1, count);
fronts = {[]};

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
effectiveSize = min(tournamentSize, numel(population));
for outputIndex = 1:count
    competitors = randperm(numel(population), effectiveSize);
    winner = competitors(1);
    for index = competitors(2:end)
        if population(index).rank < population(winner).rank || ...
                (population(index).rank == population(winner).rank && ...
                population(index).crowding_distance > ...
                population(winner).crowding_distance)
            winner = index;
        end
    end
    parents(outputIndex) = population(winner);
end
end

function selected = select_elite(population, populationSize)
ordering = [[population.rank].', ...
    -[population.crowding_distance].', ...
    (1:numel(population)).'];
[~, order] = sortrows(ordering, [1, 2, 3]);
selected = population(order(1:populationSize));
end

function summary = summarize_generation(generation, population)
objectives = reshape([population.objectives], 2, []).';
summary = history_template();
summary.generation = generation;
summary.minimum_makespan = min(objectives(:, 1));
summary.minimum_total_energy = min(objectives(:, 2));
summary.pareto_count = size(pareto_objectives(population), 1);
end

function objectives = pareto_objectives(population)
front = deduplicate_front(population([population.rank] == 1));
objectives = reshape([front.objectives], 2, []).';
end

function front = deduplicate_front(front)
if isempty(front)
    return
end
objectives = reshape([front.objectives], 2, []).';
[~, indices] = unique(objectives, 'rows', 'stable');
front = front(indices);
end

function improved = has_pareto_improvement(archive, current, tolerance)
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

function archive = merge_pareto_objectives(archive, current, tolerance)
candidates = [archive; current];
keep = true(size(candidates, 1), 1);
for first = 1:size(candidates, 1)
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

function selectedIndex = select_baseline(front)
objectives = reshape([front.objectives], 2, []).';
[~, order] = sortrows(objectives, [1, 2]);
selectedIndex = order(1);
end

function options = normalize_options(options)
defaults = struct('no_improvement_generations', Inf, ...
    'max_runtime_seconds', Inf, 'improvement_tolerance', 1e-9);
fields = fieldnames(defaults);
for index = 1:numel(fields)
    if ~isfield(options, fields{index})
        options.(fields{index}) = defaults.(fields{index});
    end
end
end

function validate_inputs(sourceBaseline, options)
required = {'problem', 'machineData', 'agvData', ...
    'energyConfig', 'chrom', 'seed', 'isFaultFreeBaseline'};
for index = 1:numel(required)
    if ~isfield(sourceBaseline, required{index})
        error('search_normal_schedule:MissingField', ...
            'sourceBaseline.%s is required.', required{index});
    end
end
optionFields = {'population_size', 'generations', ...
    'crossover_probability', 'mutation_probability', ...
    'tournament_size', 'no_improvement_generations', ...
    'max_runtime_seconds', 'improvement_tolerance'};
for index = 1:numel(optionFields)
    if ~isfield(options, optionFields{index})
        error('search_normal_schedule:MissingOption', ...
            'options.%s is required.', optionFields{index});
    end
end
if ~sourceBaseline.isFaultFreeBaseline
    error('search_normal_schedule:InvalidBaseline', ...
        'A validated fault-free source baseline is required.');
end
if options.population_size < 2 || ...
        options.population_size ~= floor(options.population_size) || ...
        options.generations < 1 || ...
        options.generations ~= floor(options.generations) || ...
        options.tournament_size < 1 || ...
        options.tournament_size ~= floor(options.tournament_size)
    error('search_normal_schedule:InvalidSearchSize', ...
        'Population, generation, and tournament sizes are invalid.');
end
if options.crossover_probability < 0 || ...
        options.crossover_probability > 1 || ...
        options.mutation_probability < 0 || ...
        options.mutation_probability > 1
    error('search_normal_schedule:InvalidProbability', ...
        'Crossover and mutation probabilities must be in [0, 1].');
end
end

function result = validate_result(searchResult, options)
frontObjectives = reshape( ...
    [searchResult.pareto_front.objectives], 2, []).';
result = numel(searchResult.population) == options.population_size && ...
    ~isempty(searchResult.pareto_front) && ...
    all([searchResult.population.is_validated]) && ...
    size(unique(frontObjectives, 'rows'), 1) == ...
    size(frontObjectives, 1) && ...
    searchResult.completed_generations <= options.generations && ...
    searchResult.selected_baseline.isFaultFreeBaseline;
if ~result
    error('search_normal_schedule:InvalidResult', ...
        'Normal baseline search result failed validation.');
end
end

function value = evaluation_template()
value = struct('decision', [], 'baseline', [], ...
    'objectives', [], 'rank', [], ...
    'crowding_distance', [], 'is_validated', false);
end

function value = history_template()
value = struct('generation', [], 'minimum_makespan', [], ...
    'minimum_total_energy', [], 'pareto_count', []);
end
