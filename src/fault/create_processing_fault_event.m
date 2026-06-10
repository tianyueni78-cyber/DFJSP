function fault = create_processing_fault_event( ...
        baseline, jobId, operationId, interruptionFraction, ...
        repairDuration)
%CREATE_PROCESSING_FAULT_EVENT Create one Stage B in-process fault.
%   The fault time lies strictly inside an existing baseline operation.
%   This step records processing progress but does not decide whether the
%   interrupted operation resumes, restarts, or migrates.

if nargin < 5
    error('create_processing_fault_event:MissingInput', ...
        ['baseline, jobId, operationId, interruptionFraction, ', ...
        'and repairDuration are required.']);
end
require_baseline(baseline);
validate_positive_integer(jobId, 'jobId');
validate_positive_integer(operationId, 'operationId');
if ~isscalar(interruptionFraction) || ...
        ~isfinite(interruptionFraction) || ...
        interruptionFraction <= 0 || interruptionFraction >= 1
    error('create_processing_fault_event:InvalidInput', ...
        'interruptionFraction must be strictly between zero and one.');
end
if ~isscalar(repairDuration) || ~isfinite(repairDuration) || ...
        repairDuration <= 0
    error('create_processing_fault_event:InvalidInput', ...
        'repairDuration must be a positive finite scalar.');
end

[machineId, block] = find_operation_block( ...
    baseline.machineTable, jobId, operationId);
originalDuration = block.end - block.start;
faultTime = block.start + interruptionFraction * originalDuration;
elapsed = faultTime - block.start;
remaining = block.end - faultTime;

interrupted = struct();
interrupted.machine_id = machineId;
interrupted.job = jobId;
interrupted.operation = operationId;
interrupted.original_start = block.start;
interrupted.original_end = block.end;
interrupted.original_duration = originalDuration;
interrupted.elapsed_processing_time = elapsed;
interrupted.remaining_processing_time = remaining;
interrupted.progress_ratio = elapsed / originalDuration;

fault = struct();
fault.event_id = 1;
fault.stage = 'B';
fault.trigger_type = 'operation_processing';
fault.machine_id = machineId;
fault.start_time = faultTime;
fault.repair_duration = repairDuration;
fault.repair_end_time = faultTime + repairDuration;
fault.trigger_job = jobId;
fault.trigger_operation = operationId;
fault.interruption_fraction = interruptionFraction;
fault.interruption_rule = 'unresolved';
fault.interrupted_operation = interrupted;
fault.is_validated = false;

fault = validate_processing_fault_event(fault, baseline);
end

function [machineId, block] = find_operation_block( ...
        machineTable, jobId, operationId)
matches = [];
for machine = 1:numel(machineTable)
    blocks = machineTable{machine};
    for index = 1:numel(blocks)
        if blocks(index).job == jobId && ...
                blocks(index).opera == operationId && ...
                isfinite(blocks(index).end)
            matches = [matches; machine, index];
        end
    end
end
if isempty(matches)
    error('create_processing_fault_event:OperationNotFound', ...
        'Operation J%d-O%d was not found.', jobId, operationId);
end
if size(matches, 1) ~= 1
    error('create_processing_fault_event:OperationNotUnique', ...
        'Operation J%d-O%d must appear exactly once.', ...
        jobId, operationId);
end
machineId = matches(1, 1);
block = machineTable{machineId}(matches(1, 2));
end

function require_baseline(baseline)
required = {'machineTable', 'problem', 'isFaultFreeBaseline'};
for index = 1:numel(required)
    if ~isfield(baseline, required{index})
        error('create_processing_fault_event:MissingField', ...
            'baseline.%s is required.', required{index});
    end
end
if ~baseline.isFaultFreeBaseline
    error('create_processing_fault_event:InvalidBaseline', ...
        'The event must be created from a fault-free baseline.');
end
end

function validate_positive_integer(value, name)
if ~isscalar(value) || ~isfinite(value) || value < 1 || ...
        value ~= floor(value)
    error('create_processing_fault_event:InvalidInput', ...
        '%s must be a positive integer.', name);
end
end
