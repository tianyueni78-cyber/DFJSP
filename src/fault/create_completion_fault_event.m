function fault = create_completion_fault_event( ...
    baseline, jobId, operationId, repairDuration)
%CREATE_COMPLETION_FAULT_EVENT Create one Stage A machine-failure event.
%   The failure occurs exactly when the selected operation finishes in the
%   fault-free baseline. No in-process operation is interrupted.

if nargin < 4
    error('create_completion_fault_event:MissingInput', ...
        'baseline, jobId, operationId, and repairDuration are required.');
end

require_baseline_fields(baseline);
validate_positive_integer(jobId, 'jobId');
validate_positive_integer(operationId, 'operationId');
validate_positive_scalar(repairDuration, 'repairDuration');

[machineId, operationBlock] = find_operation_block( ...
    baseline.machineTable, jobId, operationId);

fault = struct();
fault.event_id = 1;
fault.stage = 'A';
fault.trigger_type = 'operation_completion';
fault.machine_id = machineId;
fault.start_time = operationBlock.end;
fault.repair_duration = repairDuration;
fault.repair_end_time = fault.start_time + repairDuration;
fault.trigger_job = jobId;
fault.trigger_operation = operationId;
fault.trigger_operation_start = operationBlock.start;
fault.trigger_operation_end = operationBlock.end;
fault.interrupted_operation = [];
fault.is_validated = false;

fault = validate_completion_fault_event(fault, baseline);
end

function [machineId, operationBlock] = find_operation_block( ...
    machineTable, jobId, operationId)
matches = [];
for machine = 1:numel(machineTable)
    blocks = machineTable{machine};
    for blockIndex = 1:numel(blocks)
        block = blocks(blockIndex);
        if block.job == jobId && block.opera == operationId && ...
                isfinite(block.end)
            matches = [matches; machine, blockIndex];
        end
    end
end

if isempty(matches)
    error('create_completion_fault_event:OperationNotFound', ...
        'Operation J%d-O%d was not found in baseline.machineTable.', ...
        jobId, operationId);
end
if size(matches, 1) ~= 1
    error('create_completion_fault_event:OperationNotUnique', ...
        'Operation J%d-O%d appears more than once in baseline.machineTable.', ...
        jobId, operationId);
end

machineId = matches(1, 1);
operationBlock = machineTable{machineId}(matches(1, 2));
end

function require_baseline_fields(baseline)
required = {'machineTable', 'problem', 'isFaultFreeBaseline'};
for index = 1:numel(required)
    if ~isfield(baseline, required{index})
        error('create_completion_fault_event:MissingField', ...
            'baseline.%s is required.', required{index});
    end
end
if ~baseline.isFaultFreeBaseline
    error('create_completion_fault_event:InvalidBaseline', ...
        'The event must be created from a fault-free baseline.');
end
end

function validate_positive_integer(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value < 1 || value ~= floor(value)
    error('create_completion_fault_event:InvalidInput', ...
        '%s must be a positive integer.', name);
end
end

function validate_positive_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    error('create_completion_fault_event:InvalidInput', ...
        '%s must be a positive finite scalar.', name);
end
end
