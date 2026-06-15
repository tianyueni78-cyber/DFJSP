clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'fault'));

raw = repmat(raw_fault_template(), 1, 3);
raw(1) = make_fault(30, 3, 20, 4, 'restart_from_zero');
raw(2) = make_fault(10, 1, 10, 5, 'resume_remaining');
raw(3) = make_fault(20, 2, 10, 3, 'resume_remaining');

faults = normalize_stage_c_fault_events(raw, 6);

assert(isequal([faults.event_id], [10, 20, 30]));
assert(isequal([faults.source_order], [2, 3, 1]));
assert(isequal([faults.event_group], [1, 1, 2]));
assert(isequal([faults.machine_id], [1, 2, 3]));
assert(all(strcmp({faults.stage}, 'C')));
assert(all(strcmp({faults.trigger_type}, 'machine_failure')));
assert(all([faults.is_validated]));
assert(abs(faults(1).repair_end_time - 15) <= 1e-9);
assert(abs(faults(2).repair_end_time - 13) <= 1e-9);
assert(abs(faults(3).repair_end_time - 24) <= 1e-9);
assert(strcmp(faults(1).interruption_rule, 'resume_remaining'));
assert(strcmp(faults(3).interruption_rule, 'restart_from_zero'));

permuted = normalize_stage_c_fault_events(raw([3, 1, 2]), 6);
assert(isequal([permuted.event_id], [10, 20, 30]));
assert(isequal([permuted.event_group], [1, 1, 2]));

duplicate = raw;
duplicate(3).event_id = duplicate(2).event_id;
expect_error(@() normalize_stage_c_fault_events(duplicate, 6), ...
    'normalize_stage_c_fault_events:DuplicateEventId');

invalidMachine = raw;
invalidMachine(1).machine_id = 7;
expect_error(@() normalize_stage_c_fault_events(invalidMachine, 6), ...
    'normalize_stage_c_fault_events:InvalidMachine');

invalidRule = raw;
invalidRule(1).interruption_rule = 'unresolved';
expect_error(@() normalize_stage_c_fault_events(invalidRule, 6), ...
    'normalize_stage_c_fault_events:InvalidRule');

invalidRepairEnd = raw;
invalidRepairEnd(1).repair_end_time = 99;
expect_error(@() normalize_stage_c_fault_events(invalidRepairEnd, 6), ...
    'normalize_stage_c_fault_events:InvalidRepairEnd');

fprintf('test_stage_c_fault_events passed\n');

function value = raw_fault_template()
value = struct('event_id', [], 'machine_id', [], 'start_time', [], ...
    'repair_duration', [], 'repair_end_time', [], ...
    'interruption_rule', '');
end

function value = make_fault(eventId, machineId, startTime, ...
        repairDuration, interruptionRule)
value = raw_fault_template();
value.event_id = eventId;
value.machine_id = machineId;
value.start_time = startTime;
value.repair_duration = repairDuration;
value.interruption_rule = interruptionRule;
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
error('test_stage_c_fault_events:ExpectedErrorNotRaised', ...
    'Expected error was not raised: %s', expectedIdentifier);
end
