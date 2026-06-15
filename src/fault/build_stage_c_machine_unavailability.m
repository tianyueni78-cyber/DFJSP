function result = build_stage_c_machine_unavailability( ...
        faults, machineCount)
%BUILD_STAGE_C_MACHINE_UNAVAILABILITY Merge repair intervals by machine.
%   Overlapping or touching intervals on the same machine are merged.
%   Source event identities remain attached to each merged interval.

if nargin < 2
    error('build_stage_c_machine_unavailability:MissingInput', ...
        'faults and machineCount are required.');
end
validate_machine_count(machineCount);
validate_faults(faults, machineCount);

byMachine = cell(1, machineCount);
allIntervals = repmat(interval_template(), 1, 0);
for machineId = 1:machineCount
    machineFaults = faults([faults.machine_id] == machineId);
    intervals = merge_machine_intervals(machineFaults, machineId);
    byMachine{machineId} = intervals;
    allIntervals = [allIntervals, intervals];
end

result = struct();
result.stage = 'C';
result.machine_count = machineCount;
result.fault_count = numel(faults);
result.interval_count = numel(allIntervals);
result.by_machine = byMachine;
result.intervals = allIntervals;
result.interval_type = '[start, end)';
result.is_validated = validate_result(result, faults);
end

function intervals = merge_machine_intervals(machineFaults, machineId)
intervals = repmat(interval_template(), 1, 0);
if isempty(machineFaults)
    return
end

startTimes = [machineFaults.start_time].';
sourceOrders = [machineFaults.source_order].';
[~, order] = sortrows([startTimes, sourceOrders], [1, 2]);
machineFaults = machineFaults(order);

current = interval_from_fault(machineFaults(1), machineId);
tolerance = 1e-9;
for index = 2:numel(machineFaults)
    fault = machineFaults(index);
    if fault.start_time <= current.end_time + tolerance
        current.end_time = max(current.end_time, fault.repair_end_time);
        current.source_event_ids = [current.source_event_ids, ...
            fault.event_id];
        current.source_event_groups = unique( ...
            [current.source_event_groups, fault.event_group], 'stable');
        current.source_orders = [current.source_orders, ...
            fault.source_order];
    else
        current.repair_duration = current.end_time - current.start_time;
        intervals(end + 1) = current;
        current = interval_from_fault(fault, machineId);
    end
end
current.repair_duration = current.end_time - current.start_time;
intervals(end + 1) = current;
end

function value = interval_from_fault(fault, machineId)
value = interval_template();
value.machine_id = machineId;
value.start_time = fault.start_time;
value.end_time = fault.repair_end_time;
value.repair_duration = fault.repair_duration;
value.source_event_ids = fault.event_id;
value.source_event_groups = fault.event_group;
value.source_orders = fault.source_order;
value.interval_type = '[start, end)';
end

function value = interval_template()
value = struct('machine_id', [], 'start_time', [], 'end_time', [], ...
    'repair_duration', [], 'source_event_ids', [], ...
    'source_event_groups', [], 'source_orders', [], ...
    'interval_type', '');
end

function validate_faults(faults, machineCount)
required = {'event_id', 'stage', 'trigger_type', 'machine_id', ...
    'start_time', 'repair_duration', 'repair_end_time', ...
    'interruption_rule', 'event_group', 'source_order', ...
    'is_validated'};
if ~isstruct(faults) || isempty(faults) || ~isvector(faults)
    error('build_stage_c_machine_unavailability:InvalidFaultArray', ...
        'faults must be a nonempty normalized struct vector.');
end
for index = 1:numel(faults)
    fault = faults(index);
    require_fields(fault, required);
    if ~fault.is_validated || ~strcmp(fault.stage, 'C') || ...
            ~strcmp(fault.trigger_type, 'machine_failure')
        error('build_stage_c_machine_unavailability:InvalidFault', ...
            'Every fault must be a validated Stage C machine failure.');
    end
    if fault.machine_id < 1 || fault.machine_id > machineCount || ...
            fault.machine_id ~= floor(fault.machine_id)
        error('build_stage_c_machine_unavailability:InvalidMachine', ...
            'fault.machine_id is outside machineCount.');
    end
    if ~isfinite(fault.start_time) || ...
            ~isfinite(fault.repair_end_time) || ...
            fault.start_time < 0 || ...
            fault.repair_end_time <= fault.start_time || ...
            abs(fault.repair_end_time - fault.start_time - ...
            fault.repair_duration) > 1e-9
        error('build_stage_c_machine_unavailability:InvalidInterval', ...
            'Each repair interval must be finite and have positive duration.');
    end
end
end

function result = validate_result(value, faults)
tolerance = 1e-9;
result = true;
coveredEventIds = [];
for machineId = 1:value.machine_count
    intervals = value.by_machine{machineId};
    for index = 1:numel(intervals)
        interval = intervals(index);
        if interval.machine_id ~= machineId || ...
                interval.end_time <= interval.start_time || ...
                abs(interval.repair_duration - ...
                (interval.end_time - interval.start_time)) > tolerance
            result = false;
            return
        end
        if index > 1 && intervals(index - 1).end_time >= ...
                interval.start_time - tolerance
            result = false;
            return
        end
        coveredEventIds = [coveredEventIds, interval.source_event_ids];
    end
end
result = result && ...
    isequal(sort(coveredEventIds), sort([faults.event_id]));
end

function validate_machine_count(value)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value < 1 || value ~= floor(value)
    error('build_stage_c_machine_unavailability:InvalidMachineCount', ...
        'machineCount must be a positive integer.');
end
end

function require_fields(value, fields)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_c_machine_unavailability:MissingField', ...
            'faults.%s is required.', fields{index});
    end
end
end
