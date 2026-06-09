function population = initialize_stage_a_reschedule_population( ...
        baseline, frozen, populationSize, seedDecision)
%INITIALIZE_STAGE_A_RESCHEDULE_POPULATION Initialize unfrozen decisions.
%   The first individual preserves the source-data seed. Remaining
%   individuals are sampled only from original candidate ranges.

if nargin < 4
    error('initialize_stage_a_reschedule_population:MissingInput', ...
        ['baseline, frozen, populationSize, and seedDecision ', ...
        'are required.']);
end
validate_inputs(baseline, frozen, populationSize, seedDecision);

template = decision_template();
population = repmat(template, 1, populationSize);
population(1) = normalize_decision(seedDecision, ...
    'baseline_chromosome_unstarted_suffix');

jobMultiset = build_job_multiset(frozen.reschedulable_operations);
operationCount = numel(frozen.reschedulable_operations);
speedCount = numel(baseline.agvData.AGVSpeed);

for individual = 2:populationSize
    decision = template;
    decision.source = 'restricted_random_initialization';
    if operationCount == 0
        decision.operation_sequence = [];
    else
        decision.operation_sequence = ...
            jobMultiset(randperm(operationCount));
    end
    decision.machine_choice = zeros(1, operationCount);
    for index = 1:operationCount
        upper = numel( ...
            frozen.reschedulable_operations(index).candidate_machines);
        decision.machine_choice(index) = randi(upper);
    end
    decision.agv_assignment = randi( ...
        baseline.agvData.AGVNum, 1, operationCount);
    decision.free_speed_choice = randi( ...
        speedCount, 1, operationCount);
    decision.load_speed_choice = randi( ...
        speedCount, 1, operationCount);
    population(individual) = decision;
end
end

function jobs = build_job_multiset(operations)
jobs = zeros(1, numel(operations));
for index = 1:numel(operations)
    jobs(index) = operations(index).job;
end
end

function decision = normalize_decision(source, sourceName)
decision = decision_template();
decision.source = sourceName;
decision.operation_sequence = source.operation_sequence(:).';
decision.machine_choice = source.machine_choice(:).';
decision.agv_assignment = source.agv_assignment(:).';
decision.free_speed_choice = source.free_speed_choice(:).';
decision.load_speed_choice = source.load_speed_choice(:).';
end

function value = decision_template()
value = struct('source', '', 'operation_sequence', [], ...
    'machine_choice', [], 'agv_assignment', [], ...
    'free_speed_choice', [], 'load_speed_choice', []);
end

function validate_inputs(baseline, frozen, populationSize, seedDecision)
if ~isfield(baseline, 'agvData') || ...
        ~isfield(baseline.agvData, 'AGVNum') || ...
        ~isfield(baseline.agvData, 'AGVSpeed') || ...
        ~isfield(frozen, 'reschedulable_operations') || ...
        ~isfield(frozen, 'is_validated') || ~frozen.is_validated
    error('initialize_stage_a_reschedule_population:InvalidInput', ...
        'Validated baseline and frozen problem are required.');
end
if ~isscalar(populationSize) || populationSize < 1 || ...
        populationSize ~= floor(populationSize)
    error('initialize_stage_a_reschedule_population:PopulationSize', ...
        'populationSize must be a positive integer.');
end

required = {'operation_sequence', 'machine_choice', ...
    'agv_assignment', 'free_speed_choice', 'load_speed_choice'};
operationCount = numel(frozen.reschedulable_operations);
for index = 1:numel(required)
    if ~isfield(seedDecision, required{index}) || ...
            numel(seedDecision.(required{index})) ~= operationCount
        error('initialize_stage_a_reschedule_population:SeedDecision', ...
            'Seed decision field %s has an invalid length.', ...
            required{index});
    end
end
end
