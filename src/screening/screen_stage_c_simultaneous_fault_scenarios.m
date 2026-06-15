function screening = screen_stage_c_simultaneous_fault_scenarios( ...
        baseline, config)
%SCREEN_STAGE_C_SIMULTANEOUS_FAULT_SCENARIOS Find effective machine pairs.
%   A candidate time lies strictly inside active operations on both
%   machines. Repair-overlap counts are used only for scenario ranking.

if nargin < 2
    error('screen_stage_c_simultaneous_fault_scenarios:MissingInput', ...
        'baseline and config are required.');
end
validate_inputs(baseline, config);

operations = collect_operations(baseline.machineTable);
boundaries = unique([[operations.start], [operations.end]]);
template = candidate_template();
candidates = template([]);
examinedWindows = 0;

for boundaryIndex = 1:numel(boundaries) - 1
    left = boundaries(boundaryIndex);
    right = boundaries(boundaryIndex + 1);
    if right <= left
        continue
    end
    faultTime = (left + right) / 2;
    active = operations([operations.start] < faultTime & ...
        faultTime < [operations.end]);
    activeMachines = unique([active.machine_id]);
    if numel(activeMachines) < config.fault_count
        continue
    end
    examinedWindows = examinedWindows + 1;
    machineSets = nchoosek(activeMachines, config.fault_count);
    for setIndex = 1:size(machineSets, 1)
        machineIds = machineSets(setIndex, :);
        interrupted = active(ismember([active.machine_id], machineIds));
        interrupted = one_operation_per_machine(interrupted, machineIds);
        repairEnd = faultTime + config.repair_duration;
        overlapCount = count_repair_overlap( ...
            operations, machineIds, faultTime, repairEnd);

        candidate = template;
        candidate.fault_time = faultTime;
        candidate.repair_duration = config.repair_duration;
        candidate.repair_end_time = repairEnd;
        candidate.machine_ids = machineIds;
        candidate.interrupted_operations = interrupted;
        candidate.directly_affected_operations = numel(interrupted);
        candidate.repair_overlap_operations = overlapCount;
        candidate.active_window_start = left;
        candidate.active_window_end = right;
        candidate.active_window_duration = right - left;
        candidate.interruption_rule = config.interruption_rule;
        candidate.source = 'original_baseline_machine_table';
        candidates(end + 1) = candidate;
    end
end

candidates = rank_candidates(candidates);
screening = struct();
screening.stage = 'C';
screening.step = 4;
screening.source = 'original_normal_baseline';
screening.fault_count = config.fault_count;
screening.repair_duration = config.repair_duration;
screening.interruption_rule = config.interruption_rule;
screening.examined_active_windows = examinedWindows;
screening.candidates = candidates;
screening.candidate_count = numel(candidates);
screening.ranking_rule = config.selection_rule;
screening.additional_problem_data_generated = false;
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

function interrupted = one_operation_per_machine(active, machineIds)
template = operation_template();
interrupted = template([]);
for index = 1:numel(machineIds)
    matches = active([active.machine_id] == machineIds(index));
    if numel(matches) ~= 1
        error(['screen_stage_c_simultaneous_fault_scenarios:', ...
            'MachineOverlap'], ...
            'Each selected machine must have exactly one active operation.');
    end
    interrupted(end + 1) = matches;
end
end

function count = count_repair_overlap( ...
        operations, machineIds, startTime, endTime)
selected = operations(ismember([operations.machine_id], machineIds));
overlaps = [selected.start] < endTime & startTime < [selected.end];
count = sum(overlaps);
end

function candidates = rank_candidates(candidates)
if numel(candidates) < 2
    return
end
firstMachine = arrayfun(@(value) value.machine_ids(1), candidates).';
secondMachine = arrayfun(@(value) value.machine_ids(2), candidates).';
ranking = [-[candidates.repair_overlap_operations].', ...
    -[candidates.active_window_duration].', ...
    [candidates.fault_time].', firstMachine, secondMachine];
[~, order] = sortrows(ranking, 1:5);
candidates = candidates(order);
end

function result = validate_screening(screening)
result = screening.candidate_count > 0;
for index = 1:numel(screening.candidates)
    candidate = screening.candidates(index);
    result = result && ...
        numel(candidate.machine_ids) == screening.fault_count && ...
        numel(unique(candidate.machine_ids)) == screening.fault_count && ...
        candidate.directly_affected_operations == ...
        screening.fault_count && ...
        candidate.repair_overlap_operations >= ...
        candidate.directly_affected_operations && ...
        candidate.active_window_start < candidate.fault_time && ...
        candidate.fault_time < candidate.active_window_end && ...
        all([candidate.interrupted_operations.start] < ...
        candidate.fault_time) && ...
        all(candidate.fault_time < ...
        [candidate.interrupted_operations.end]);
end
if ~result
    error(['screen_stage_c_simultaneous_fault_scenarios:', ...
        'InvalidScreening'], ...
        'No validated simultaneous-fault scenario was found.');
end
end

function validate_inputs(baseline, config)
requiredBaseline = {'machineTable', 'problem', 'isFaultFreeBaseline'};
require_fields(baseline, requiredBaseline, 'baseline');
requiredConfig = {'fault_count', 'repair_duration', ...
    'interruption_rule', 'selection_rule'};
require_fields(config, requiredConfig, 'config');
if ~baseline.isFaultFreeBaseline
    error(['screen_stage_c_simultaneous_fault_scenarios:', ...
        'InvalidBaseline'], ...
        'A fault-free baseline is required.');
end
if config.fault_count ~= 2
    error(['screen_stage_c_simultaneous_fault_scenarios:', ...
        'InvalidFaultCount'], ...
        'Stage C Step 4 currently selects exactly two machines.');
end
if ~isfinite(config.repair_duration) || config.repair_duration <= 0
    error(['screen_stage_c_simultaneous_fault_scenarios:', ...
        'InvalidRepairDuration'], ...
        'repair_duration must be positive and finite.');
end
if ~strcmp(config.interruption_rule, 'resume_remaining')
    error(['screen_stage_c_simultaneous_fault_scenarios:', ...
        'InvalidRule'], ...
        'The first simultaneous-fault scenario uses resume_remaining.');
end
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', []);
end

function value = candidate_template()
operation = operation_template();
value = struct();
value.fault_time = [];
value.repair_duration = [];
value.repair_end_time = [];
value.machine_ids = [];
value.interrupted_operations = operation([]);
value.directly_affected_operations = [];
value.repair_overlap_operations = [];
value.active_window_start = [];
value.active_window_end = [];
value.active_window_duration = [];
value.interruption_rule = '';
value.source = '';
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error(['screen_stage_c_simultaneous_fault_scenarios:', ...
            'MissingField'], '%s.%s is required.', ...
            valueName, fields{index});
    end
end
end
