function screening = screen_stage_cseq2_overlapping_next_fault_event( ...
        currentView, previousFaults, repairDuration)
%SCREEN_STAGE_CSEQ2_OVERLAPPING_NEXT_FAULT_EVENT Select a later fault
%whose start time falls inside an unfinished previous repair interval.

if nargin < 3
    error('screen_stage_cseq2_overlapping_next_fault_event:MissingInput', ...
        'currentView, previousFaults, and repairDuration are required.');
end
require_fields(currentView, {'machineTable', 'isCurrentPlanView', ...
    'source_version_id'}, 'currentView');
if ~currentView.isCurrentPlanView || isempty(previousFaults) || ...
        ~isscalar(repairDuration) || ~isfinite(repairDuration) || ...
        repairDuration <= 0
    error('screen_stage_cseq2_overlapping_next_fault_event:InvalidInput', ...
        'Validated current view, previous faults and repair duration are required.');
end

previousStart = min([previousFaults.start_time]);
previousRepairEnd = max([previousFaults.repair_end_time]);
operations = collect_operations(currentView.machineTable);
eligible = operations([operations.end] > previousStart + 1e-9 & ...
    [operations.start] < previousRepairEnd - 1e-9);
template = candidate_template();
candidates = template([]);
for index = 1:numel(eligible)
    operation = eligible(index);
    left = max(operation.start, previousStart + 1e-6);
    right = min(operation.end, previousRepairEnd - 1e-6);
    if right <= left + 1e-9
        continue
    end
    candidate = template;
    candidate.fault_time = (left + right) / 2;
    candidate.machine_id = operation.machine_id;
    candidate.interrupted_operation = operation;
    candidate.repair_duration = repairDuration;
    candidate.repair_end_time = candidate.fault_time + repairDuration;
    candidate.previous_repair_start = previousStart;
    candidate.previous_repair_end = previousRepairEnd;
    candidate.overlap_duration = previousRepairEnd - candidate.fault_time;
    candidate.source_version_id = currentView.source_version_id;
    candidate.source = 'current_active_plan_overlapping_previous_repair';
    candidates(end + 1) = candidate;
end
if isempty(candidates)
    error('screen_stage_cseq2_overlapping_next_fault_event:NoCandidate', ...
        'Current plan has no operation inside an active previous repair interval.');
end

ranking = [[candidates.overlap_duration].' * -1, ...
    [candidates.fault_time].', [candidates.machine_id].', ...
    arrayfun(@(value) value.interrupted_operation.job, candidates).', ...
    arrayfun(@(value) value.interrupted_operation.operation, candidates).'];
[~, order] = sortrows(ranking, [1, 2, 3, 4, 5]);
candidates = candidates(order);

screening = struct();
screening.stage = 'C-SEQ2';
screening.step = '1';
screening.source_version_id = currentView.source_version_id;
screening.previous_repair_start = previousStart;
screening.previous_repair_end = previousRepairEnd;
screening.repair_duration = repairDuration;
screening.candidates = candidates;
screening.candidate_count = numel(candidates);
screening.selected_candidate = candidates(1);
screening.additional_problem_data_generated = false;
screening.requires_active_previous_repair = true;
screening.is_validated = validate_screening(screening);
end

function operations = collect_operations(machineTable)
template = operation_template();
operations = template([]);
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if block.job <= 0 || block.opera <= 0 || ~isfinite(block.end)
            continue
        end
        value = template;
        value.machine_id = machineId;
        value.table_index = tableIndex;
        value.job = block.job;
        value.operation = block.opera;
        value.start = block.start;
        value.end = block.end;
        operations(end + 1) = value;
    end
end
end

function result = validate_screening(screening)
selected = screening.selected_candidate;
result = screening.candidate_count > 0 && ...
    selected.fault_time > screening.previous_repair_start + 1e-9 && ...
    selected.fault_time < screening.previous_repair_end - 1e-9 && ...
    selected.overlap_duration > 0 && ...
    selected.source_version_id == screening.source_version_id && ...
    ~screening.additional_problem_data_generated;
if ~result
    error('screen_stage_cseq2_overlapping_next_fault_event:InvalidResult', ...
        'C-SEQ2 overlapping next-fault screening failed validation.');
end
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', []);
end

function value = candidate_template()
value = struct('fault_time', [], 'machine_id', [], ...
    'interrupted_operation', operation_template(), ...
    'repair_duration', [], 'repair_end_time', [], ...
    'previous_repair_start', [], 'previous_repair_end', [], ...
    'overlap_duration', [], 'source_version_id', [], 'source', '');
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('screen_stage_cseq2_overlapping_next_fault_event:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
