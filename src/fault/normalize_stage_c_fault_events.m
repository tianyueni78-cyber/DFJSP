function faults = normalize_stage_c_fault_events(rawFaults, machineCount)
%NORMALIZE_STAGE_C_FAULT_EVENTS Validate and normalize Stage C faults.
%   Events are sorted by start time while source_order preserves the input
%   identity. Events with the same start time share one event_group.

if nargin < 2
    error('normalize_stage_c_fault_events:MissingInput', ...
        'rawFaults and machineCount are required.');
end
validate_machine_count(machineCount);
if ~isstruct(rawFaults) || isempty(rawFaults) || ~isvector(rawFaults)
    error('normalize_stage_c_fault_events:InvalidFaultArray', ...
        'rawFaults must be a nonempty struct vector.');
end

template = fault_template();
faults = repmat(template, 1, numel(rawFaults));
eventIds = zeros(1, numel(rawFaults));
for index = 1:numel(rawFaults)
    raw = rawFaults(index);
    require_fields(raw, {'event_id', 'machine_id', 'start_time', ...
        'repair_duration', 'interruption_rule'});
    eventIds(index) = validate_positive_integer( ...
        raw.event_id, 'event_id');
    faults(index).event_id = eventIds(index);
    faults(index).stage = 'C';
    faults(index).trigger_type = 'machine_failure';
    faults(index).machine_id = validate_machine_id( ...
        raw.machine_id, machineCount);
    faults(index).start_time = validate_nonnegative_scalar( ...
        raw.start_time, 'start_time');
    faults(index).repair_duration = validate_positive_scalar( ...
        raw.repair_duration, 'repair_duration');
    faults(index).repair_end_time = faults(index).start_time + ...
        faults(index).repair_duration;
    validate_optional_repair_end(raw, faults(index).repair_end_time);
    faults(index).interruption_rule = normalize_rule( ...
        raw.interruption_rule);
    faults(index).source_order = index;
end

if numel(unique(eventIds)) ~= numel(eventIds)
    error('normalize_stage_c_fault_events:DuplicateEventId', ...
        'Each fault event_id must be unique.');
end

startTimes = [faults.start_time].';
sourceOrders = [faults.source_order].';
[~, order] = sortrows([startTimes, sourceOrders], [1, 2]);
faults = faults(order);
faults = assign_event_groups(faults);
for index = 1:numel(faults)
    faults(index).is_validated = true;
end
end

function faults = assign_event_groups(faults)
tolerance = 1e-9;
groupId = 1;
groupStart = faults(1).start_time;
faults(1).event_group = groupId;
for index = 2:numel(faults)
    if abs(faults(index).start_time - groupStart) > tolerance
        groupId = groupId + 1;
        groupStart = faults(index).start_time;
    end
    faults(index).event_group = groupId;
end
end

function value = fault_template()
value = struct('event_id', [], 'stage', '', 'trigger_type', '', ...
    'machine_id', [], 'start_time', [], 'repair_duration', [], ...
    'repair_end_time', [], 'interruption_rule', '', ...
    'event_group', [], 'source_order', [], 'is_validated', false);
end

function validate_machine_count(value)
validate_positive_integer(value, 'machineCount');
end

function value = validate_machine_id(value, machineCount)
value = validate_positive_integer(value, 'machine_id');
if value > machineCount
    error('normalize_stage_c_fault_events:InvalidMachine', ...
        'machine_id must not exceed machineCount.');
end
end

function value = validate_positive_integer(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value < 1 || value ~= floor(value)
    error('normalize_stage_c_fault_events:InvalidInteger', ...
        '%s must be a positive integer.', name);
end
end

function value = validate_nonnegative_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 0
    error('normalize_stage_c_fault_events:InvalidScalar', ...
        '%s must be a nonnegative finite scalar.', name);
end
end

function value = validate_positive_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    error('normalize_stage_c_fault_events:InvalidScalar', ...
        '%s must be a positive finite scalar.', name);
end
end

function validate_optional_repair_end(raw, expected)
if ~isfield(raw, 'repair_end_time') || isempty(raw.repair_end_time)
    return
end
value = raw.repair_end_time;
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        abs(value - expected) > 1e-9
    error('normalize_stage_c_fault_events:InvalidRepairEnd', ...
        'repair_end_time must equal start_time + repair_duration.');
end
end

function value = normalize_rule(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
if ~ischar(value) || size(value, 1) ~= 1
    error('normalize_stage_c_fault_events:InvalidRule', ...
        'interruption_rule must be a character vector or string scalar.');
end
allowed = {'resume_remaining', 'restart_from_zero'};
if ~any(strcmp(value, allowed))
    error('normalize_stage_c_fault_events:InvalidRule', ...
        'Unsupported interruption_rule: %s.', value);
end
end

function require_fields(value, fields)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('normalize_stage_c_fault_events:MissingField', ...
            'rawFaults.%s is required.', fields{index});
    end
end
end
