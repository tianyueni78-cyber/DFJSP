clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));

scenario = run_stage_a_fault_event();
fault = scenario.fault;

requiredFields = {'event_id', 'stage', 'trigger_type', 'machine_id', ...
    'start_time', 'repair_duration', 'repair_end_time', 'trigger_job', ...
    'trigger_operation', 'trigger_operation_start', ...
    'trigger_operation_end', 'interrupted_operation', 'is_validated'};
for index = 1:numel(requiredFields)
    assert(isfield(fault, requiredFields{index}), ...
        'Missing fault field: %s', requiredFields{index});
end

assert(strcmp(fault.stage, 'A'), 'Fault stage must be A.');
assert(strcmp(fault.trigger_type, 'operation_completion'), ...
    'Fault trigger_type must be operation_completion.');
assert(fault.is_validated, 'Fault event must be validated.');
assert(isempty(fault.interrupted_operation), ...
    'Stage A fault must not interrupt an operation.');
assert(abs(fault.start_time - fault.trigger_operation_end) <= 1e-9, ...
    'Fault must start exactly when the trigger operation finishes.');
assert(abs(fault.repair_end_time - ...
    (fault.start_time + fault.repair_duration)) <= 1e-9, ...
    'Repair end time is inconsistent.');
assert(~scenario.is_rescheduled, ...
    'Stage A Step 2 must not perform rescheduling.');

triggerBlock = find_trigger_block( ...
    scenario.baseline.machineTable{fault.machine_id}, ...
    fault.trigger_job, fault.trigger_operation);
assert(abs(triggerBlock.end - fault.start_time) <= 1e-9, ...
    'Fault is not linked to the actual trigger operation block.');

expect_error(@() create_completion_fault_event( ...
    scenario.baseline, fault.trigger_job, fault.trigger_operation, 0), ...
    'create_completion_fault_event:InvalidInput');

invalidFault = fault;
invalidFault.start_time = ...
    (fault.trigger_operation_start + fault.trigger_operation_end) / 2;
invalidFault.repair_end_time = ...
    invalidFault.start_time + invalidFault.repair_duration;
invalidFault.is_validated = false;
expect_error(@() validate_completion_fault_event( ...
    invalidFault, scenario.baseline), ...
    'validate_completion_fault_event:FailureDuringProcessing');

fprintf('test_completion_fault_event passed\n');

function block = find_trigger_block(blocks, jobId, operationId)
matches = find([blocks.job] == jobId & [blocks.opera] == operationId);
assert(numel(matches) == 1, ...
    'The trigger operation must appear exactly once on the fault machine.');
block = blocks(matches);
end

function expect_error(action, expectedIdentifier)
try
    action();
catch errorInfo
    assert(strcmp(errorInfo.identifier, expectedIdentifier), ...
        'Expected %s but received %s.', ...
        expectedIdentifier, errorInfo.identifier);
    return
end
error('test_completion_fault_event:ExpectedErrorNotRaised', ...
    'Expected error was not raised: %s', expectedIdentifier);
end
