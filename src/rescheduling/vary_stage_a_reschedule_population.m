function offspring = vary_stage_a_reschedule_population( ...
        population, baseline, frozen, crossoverProbability, ...
        mutationProbability)
%VARY_STAGE_A_RESCHEDULE_POPULATION Apply restricted IPOX, MPX, mutation.

if nargin < 5
    error('vary_stage_a_reschedule_population:MissingInput', ...
        'Population, baseline, frozen, and probabilities are required.');
end
validate_inputs(population, baseline, frozen, ...
    crossoverProbability, mutationProbability);

populationSize = numel(population);
offspring = repmat(population(1), 1, populationSize);
for childIndex = 1:2:populationSize
    firstParent = randi(populationSize);
    secondParent = choose_second_parent(population, firstParent);
    firstChild = population(firstParent);
    secondChild = population(secondParent);

    if rand < crossoverProbability && populationSize > 1
        [firstChild.operation_sequence, ...
            secondChild.operation_sequence] = crossover_os( ...
            population(firstParent).operation_sequence, ...
            population(secondParent).operation_sequence);
        [firstChild, secondChild] = crossover_decision_parts( ...
            firstChild, secondChild, population(firstParent), ...
            population(secondParent));
    end

    firstChild = mutate_decision(firstChild, baseline, frozen, ...
        mutationProbability);
    firstChild.source = 'restricted_variation';
    offspring(childIndex) = firstChild;

    if childIndex + 1 <= populationSize
        secondChild = mutate_decision(secondChild, baseline, frozen, ...
            mutationProbability);
        secondChild.source = 'restricted_variation';
        offspring(childIndex + 1) = secondChild;
    end
end
end

function second = choose_second_parent(population, first)
populationSize = numel(population);
if populationSize == 1
    second = first;
    return
end
different = find(~arrayfun(@(item) ...
    decisions_equal(item, population(first)), population));
if isempty(different)
    candidates = setdiff(1:populationSize, first);
    second = candidates(randi(numel(candidates)));
else
    second = different(randi(numel(different)));
end
end

function result = decisions_equal(first, second)
result = isequal(first.operation_sequence, second.operation_sequence) && ...
    isequal(first.machine_choice, second.machine_choice) && ...
    isequal(first.agv_assignment, second.agv_assignment) && ...
    isequal(first.free_speed_choice, second.free_speed_choice) && ...
    isequal(first.load_speed_choice, second.load_speed_choice);
end

function [firstChild, secondChild] = crossover_os(first, second)
activeJobs = unique([first, second]);
if numel(activeJobs) <= 1
    firstChild = first;
    secondChild = second;
    return
end

selectedCount = randi(numel(activeJobs) - 1);
selectedJobs = activeJobs(randperm(numel(activeJobs), selectedCount));
firstSelected = ismember(first, selectedJobs);
secondSelected = ismember(second, selectedJobs);

firstChild = zeros(size(first));
secondChild = zeros(size(second));
firstChild(firstSelected) = first(firstSelected);
secondChild(secondSelected) = second(secondSelected);
firstChild(~firstSelected) = second(~secondSelected);
secondChild(~secondSelected) = first(~firstSelected);
end

function [firstChild, secondChild] = crossover_decision_parts( ...
        firstChild, secondChild, firstParent, secondParent)
fields = {'machine_choice', 'agv_assignment', ...
    'free_speed_choice', 'load_speed_choice'};
for fieldIndex = 1:numel(fields)
    field = fields{fieldIndex};
    mask = rand(size(firstParent.(field))) < 0.5;
    firstParentValues = firstParent.(field);
    secondParentValues = secondParent.(field);
    firstValues = secondParentValues;
    secondValues = firstParentValues;
    firstValues(mask) = firstParentValues(mask);
    secondValues(mask) = secondParentValues(mask);
    firstChild.(field) = firstValues;
    secondChild.(field) = secondValues;
end
end

function decision = mutate_decision( ...
        decision, baseline, frozen, mutationProbability)
if rand >= mutationProbability
    return
end

decision.operation_sequence = mutate_os( ...
    decision.operation_sequence);
operationCount = numel(frozen.reschedulable_operations);
if operationCount == 0
    return
end
mutableFieldCount = 4 * operationCount;
mutationCount = max(1, round(0.05 * mutableFieldCount));
positions = randperm(mutableFieldCount, ...
    min(mutationCount, mutableFieldCount));

for position = positions
    if position <= operationCount
        index = position;
        upper = numel( ...
            frozen.reschedulable_operations(index).candidate_machines);
        decision.machine_choice(index) = randi(upper);
    elseif position <= 2 * operationCount
        index = position - operationCount;
        decision.agv_assignment(index) = ...
            randi(baseline.agvData.AGVNum);
    elseif position <= 3 * operationCount
        index = position - 2 * operationCount;
        decision.free_speed_choice(index) = ...
            randi(numel(baseline.agvData.AGVSpeed));
    else
        index = position - 3 * operationCount;
        decision.load_speed_choice(index) = ...
            randi(numel(baseline.agvData.AGVSpeed));
    end
end
end

function sequence = mutate_os(sequence)
if numel(unique(sequence)) <= 1
    return
end
first = randi(numel(sequence));
candidates = find(sequence ~= sequence(first));
second = candidates(randi(numel(candidates)));
cache = sequence(first);
sequence(first) = sequence(second);
sequence(second) = cache;
end

function validate_inputs(population, baseline, frozen, ...
        crossoverProbability, mutationProbability)
if isempty(population) || ~isstruct(population)
    error('vary_stage_a_reschedule_population:Population', ...
        'Population must be a non-empty struct array.');
end
if ~isfield(baseline, 'agvData') || ...
        ~isfield(frozen, 'reschedulable_operations') || ...
        ~isfield(frozen, 'is_validated') || ~frozen.is_validated
    error('vary_stage_a_reschedule_population:InvalidInput', ...
        'Validated baseline and frozen problem are required.');
end
validate_probability(crossoverProbability, 'crossoverProbability');
validate_probability(mutationProbability, 'mutationProbability');
end

function validate_probability(value, name)
if ~isscalar(value) || value < 0 || value > 1
    error('vary_stage_a_reschedule_population:Probability', ...
        '%s must be between zero and one.', name);
end
end
