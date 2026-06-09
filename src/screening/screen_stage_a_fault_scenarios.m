function screening = screen_stage_a_fault_scenarios( ...
        baseline, repairDuration)
%SCREEN_STAGE_A_FAULT_SCENARIOS Find source-data faults with real impact.
%   Every candidate uses an operation completion from the original
%   baseline and the supplied repair duration. No schedule data is created.

if nargin < 2
    error('screen_stage_a_fault_scenarios:MissingInput', ...
        'baseline and repairDuration are required.');
end
require_fields(baseline, {'machineTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
if ~baseline.isFaultFreeBaseline
    error('screen_stage_a_fault_scenarios:InvalidBaseline', ...
        'A fault-free baseline is required.');
end
if ~isnumeric(repairDuration) || ~isscalar(repairDuration) || ...
        ~isfinite(repairDuration) || repairDuration <= 0
    error('screen_stage_a_fault_scenarios:InvalidRepairDuration', ...
        'repairDuration must be a positive finite scalar.');
end

candidateTemplate = candidate_template();
candidates = candidateTemplate([]);
examinedTriggerCount = 0;

for machineId = 1:numel(baseline.machineTable)
    operations = collect_machine_operations( ...
        baseline.machineTable{machineId});
    for position = 1:numel(operations) - 1
        trigger = operations(position);
        nextOperation = operations(position + 1);
        gap = nextOperation.start - trigger.end;
        examinedTriggerCount = examinedTriggerCount + 1;

        if repairDuration <= gap
            continue
        end

        fault = create_completion_fault_event( ...
            baseline, trigger.job, trigger.operation, repairDuration);
        state = extract_stage_a_state(baseline, fault);
        impact = identify_stage_a_affected_operations( ...
            baseline, fault, state);

        if impact.counts.directly_affected == 0
            continue
        end

        candidate = candidateTemplate;
        candidate.trigger_job = trigger.job;
        candidate.trigger_operation = trigger.operation;
        candidate.machine_id = machineId;
        candidate.fault_time = trigger.end;
        candidate.next_job = nextOperation.job;
        candidate.next_operation = nextOperation.operation;
        candidate.next_start_time = nextOperation.start;
        candidate.machine_idle_gap = gap;
        candidate.minimum_effective_repair_threshold = gap;
        candidate.threshold_rule = 'repair_duration > machine_idle_gap';
        candidate.evaluated_repair_duration = repairDuration;
        candidate.directly_affected_operations = ...
            impact.counts.directly_affected;
        candidate.affected_operations_total = ...
            impact.counts.affected_total;
        candidate.maximum_projected_delay = ...
            maximum_projected_delay(impact.affected_operations);
        candidates(end + 1) = candidate;
    end
end

candidates = rank_candidates(candidates);

screening = struct();
screening.source = 'original_baseline';
screening.repair_duration = repairDuration;
screening.examined_trigger_count = examinedTriggerCount;
screening.candidates = candidates;
screening.candidate_count = numel(candidates);
screening.ranking_rule = ...
    'affected_operations desc, idle_gap asc, fault_time asc';
screening.config_modified = false;
screening.additional_data_generated = false;
screening.is_validated = validate_screening(screening);
end

function operations = collect_machine_operations(blocks)
template = operation_template();
operations = template([]);
for tableIndex = 1:numel(blocks)
    block = blocks(tableIndex);
    if block.job <= 0 || block.opera <= 0 || ~isfinite(block.end)
        continue
    end
    operation = template;
    operation.table_index = tableIndex;
    operation.job = block.job;
    operation.operation = block.opera;
    operation.start = block.start;
    operation.end = block.end;
    operations(end + 1) = operation;
end

if numel(operations) > 1
    ordering = [[operations.start].', [operations.table_index].'];
    [~, order] = sortrows(ordering, [1, 2]);
    operations = operations(order);
end
end

function value = maximum_projected_delay(affectedOperations)
if isempty(affectedOperations)
    value = 0;
else
    value = max([affectedOperations.projected_delay]);
end
end

function candidates = rank_candidates(candidates)
if numel(candidates) < 2
    return
end
ranking = [-[candidates.affected_operations_total].', ...
    [candidates.machine_idle_gap].', [candidates.fault_time].'];
[~, order] = sortrows(ranking, [1, 2, 3]);
candidates = candidates(order);
end

function result = validate_screening(screening)
for index = 1:numel(screening.candidates)
    candidate = screening.candidates(index);
    if candidate.evaluated_repair_duration <= ...
            candidate.machine_idle_gap || ...
            candidate.directly_affected_operations < 1 || ...
            candidate.affected_operations_total < ...
            candidate.directly_affected_operations
        error('screen_stage_a_fault_scenarios:InvalidCandidate', ...
            'Candidate %d does not satisfy screening rules.', index);
    end
end
result = true;
end

function value = operation_template()
value = struct('table_index', [], 'job', [], 'operation', [], ...
    'start', [], 'end', []);
end

function value = candidate_template()
value = struct('trigger_job', [], 'trigger_operation', [], ...
    'machine_id', [], 'fault_time', [], 'next_job', [], ...
    'next_operation', [], 'next_start_time', [], ...
    'machine_idle_gap', [], ...
    'minimum_effective_repair_threshold', [], ...
    'threshold_rule', '', 'evaluated_repair_duration', [], ...
    'directly_affected_operations', [], ...
    'affected_operations_total', [], ...
    'maximum_projected_delay', []);
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('screen_stage_a_fault_scenarios:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
