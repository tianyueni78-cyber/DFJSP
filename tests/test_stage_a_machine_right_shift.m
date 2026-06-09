clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_a_impact_analysis();
baselineMachineTable = scenario.baseline.machineTable;
baselineAGVTable = scenario.baseline.AGVTable;

candidate = build_stage_a_machine_right_shift( ...
    scenario.baseline, scenario.fault, scenario.state, scenario.impact);

assert(scenario.impact.counts.directly_affected > 0, ...
    'The configured fault must directly affect at least one operation.');
assert(scenario.impact.counts.affected_total > 0, ...
    'The configured fault must produce a non-empty impact set.');
assert(candidate.is_machine_validated, ...
    'Machine right-shift candidate must be validated.');
assert(~candidate.is_agv_updated && ~candidate.is_agv_validated, ...
    'Stage A Step 5 must not update or validate AGV scheduling.');
assert(~candidate.is_fully_validated, ...
    'Machine-only candidate cannot be marked fully validated.');
assert(isequaln(baselineMachineTable, scenario.baseline.machineTable), ...
    'The baseline machine table was modified.');
assert(isequaln(baselineAGVTable, scenario.baseline.AGVTable), ...
    'The baseline AGV table was modified.');
assert(isequaln(candidate.AGVTable, baselineAGVTable), ...
    'The candidate AGV table must remain the baseline copy.');

validationFields = {'durations_preserved', ...
    'machine_assignments_preserved', ...
    'unaffected_operations_preserved', 'affected_times_applied', ...
    'machine_non_overlap', 'machine_table_structure', ...
    'job_precedence', ...
    'repair_interval_respected'};
for index = 1:numel(validationFields)
    assert(candidate.validation.(validationFields{index}), ...
        'Failed validation: %s', validationFields{index});
end

for index = 1:numel(scenario.impact.affected_operations)
    affected = scenario.impact.affected_operations(index);
    operation = find_operation(candidate.operation_records, ...
        affected.job, affected.operation);
    assert(operation.machine_id == affected.machine_id);
    assert(abs(operation.start - affected.projected_start) <= 1e-9);
    assert(abs(operation.end - affected.projected_end) <= 1e-9);
    assert(operation.start > operation.original_start, ...
        'Affected operation must move to a later start time.');
end

for index = 1:numel(scenario.impact.unaffected_unstarted_operations)
    unaffected = scenario.impact.unaffected_unstarted_operations(index);
    operation = find_operation(candidate.operation_records, ...
        unaffected.job, unaffected.operation);
    assert(abs(operation.start - unaffected.original_start) <= 1e-9);
    assert(abs(operation.end - unaffected.original_end) <= 1e-9);
end

assert_machine_table_matches_records( ...
    candidate.machineTable, candidate.operation_records);

fprintf('test_stage_a_machine_right_shift passed\n');

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1, ...
    'Operation J%d-O%d must appear exactly once.', jobId, operationId);
operation = records(match);
end

function assert_machine_table_matches_records(machineTable, records)
tableOperationCount = 0;
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    assert(isinf(blocks(end).end), ...
        'Each machine table must end with an infinite idle block.');
    for index = 1:numel(blocks)
        if blocks(index).job <= 0
            continue
        end
        tableOperationCount = tableOperationCount + 1;
        operation = find_operation( ...
            records, blocks(index).job, blocks(index).opera);
        assert(operation.machine_id == machineId);
        assert(abs(operation.start - blocks(index).start) <= 1e-9);
        assert(abs(operation.end - blocks(index).end) <= 1e-9);
    end
end
assert(tableOperationCount == numel(records), ...
    'Machine table operation count does not match operation records.');
end
