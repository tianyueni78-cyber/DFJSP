clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'fault'));

raw = repmat(raw_fault_template(), 1, 6);
raw(1) = make_fault(1, 1, 10, 5);
raw(2) = make_fault(2, 1, 14, 4);
raw(3) = make_fault(3, 1, 18, 2);
raw(4) = make_fault(4, 1, 25, 3);
raw(5) = make_fault(5, 2, 14, 2);
raw(6) = make_fault(6, 3, 30, 1);

faults = normalize_stage_c_fault_events(raw, 4);
result = build_stage_c_machine_unavailability(faults, 4);

assert(result.is_validated);
assert(strcmp(result.stage, 'C'));
assert(result.machine_count == 4);
assert(result.fault_count == 6);
assert(result.interval_count == 4);
assert(strcmp(result.interval_type, '[start, end)'));
assert(numel(result.by_machine) == 4);
assert(numel(result.by_machine{1}) == 2);
assert(numel(result.by_machine{2}) == 1);
assert(numel(result.by_machine{3}) == 1);
assert(isempty(result.by_machine{4}));

machine1 = result.by_machine{1};
assert(abs(machine1(1).start_time - 10) <= 1e-9);
assert(abs(machine1(1).end_time - 20) <= 1e-9);
assert(abs(machine1(1).repair_duration - 10) <= 1e-9);
assert(isequal(machine1(1).source_event_ids, [1, 2, 3]));
assert(isequal(machine1(1).source_event_groups, [1, 2, 3]));
assert(abs(machine1(2).start_time - 25) <= 1e-9);
assert(abs(machine1(2).end_time - 28) <= 1e-9);
assert(isequal(machine1(2).source_event_ids, 4));

machine2 = result.by_machine{2};
assert(abs(machine2.start_time - 14) <= 1e-9);
assert(abs(machine2.end_time - 16) <= 1e-9);
assert(isequal(machine2.source_event_ids, 5));

covered = [];
for index = 1:numel(result.intervals)
    covered = [covered, result.intervals(index).source_event_ids];
end
assert(isequal(sort(covered), 1:6));

invalid = faults;
invalid(1).is_validated = false;
expect_error(@() build_stage_c_machine_unavailability(invalid, 4), ...
    'build_stage_c_machine_unavailability:InvalidFault');
expect_error(@() build_stage_c_machine_unavailability(faults, 2), ...
    'build_stage_c_machine_unavailability:InvalidMachine');

fprintf('test_stage_c_machine_unavailability passed\n');

function value = raw_fault_template()
value = struct('event_id', [], 'machine_id', [], 'start_time', [], ...
    'repair_duration', [], 'repair_end_time', [], ...
    'interruption_rule', '');
end

function value = make_fault(eventId, machineId, startTime, repairDuration)
value = raw_fault_template();
value.event_id = eventId;
value.machine_id = machineId;
value.start_time = startTime;
value.repair_duration = repairDuration;
value.interruption_rule = 'resume_remaining';
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
error('test_stage_c_machine_unavailability:ExpectedErrorNotRaised', ...
    'Expected error was not raised: %s', expectedIdentifier);
end
