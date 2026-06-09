clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_a_state_snapshot();
machineTableBefore = scenario.baseline.machineTable;
impact = identify_stage_a_affected_operations( ...
    scenario.baseline, scenario.fault, scenario.state);

assert(impact.is_validated, 'Impact analysis must be validated.');
assert(~impact.baseline_modified && ~impact.is_rescheduled, ...
    'Stage A Step 4 must not modify or reschedule the baseline.');
assert(isequaln(machineTableBefore, scenario.baseline.machineTable), ...
    'The baseline machine table was modified.');
assert(impact.unavailable_interval.machine_id == ...
    scenario.fault.machine_id, ...
    'Unavailable interval has the wrong machine.');
assert(abs(impact.unavailable_interval.start_time - ...
    scenario.fault.start_time) <= 1e-9);
assert(abs(impact.unavailable_interval.end_time - ...
    scenario.fault.repair_end_time) <= 1e-9);

partitionCount = impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted;
assert(partitionCount == ...
    numel(scenario.state.unstarted_operations), ...
    'Impact sets must partition all unstarted operations.');

for index = 1:numel(impact.directly_affected_operations)
    operation = impact.directly_affected_operations(index);
    assert(operation.machine_id == scenario.fault.machine_id);
    assert(operation.original_start < scenario.fault.repair_end_time);
    assert(scenario.fault.start_time < operation.original_end);
end

for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    assert(operation.projected_delay > 0, ...
        'Affected operations must have positive projected delay.');
    assert(operation.projected_start >= operation.original_start);
    assert(operation.projected_end >= operation.original_end);
    assert(operation.direct_repair_conflict || ...
        operation.job_precedence_conflict || ...
        operation.machine_sequence_conflict, ...
        'Affected operation has no recorded cause.');
end

for index = 1:numel(impact.unaffected_unstarted_operations)
    operation = impact.unaffected_unstarted_operations(index);
    assert(~contains_operation(impact.affected_operations, ...
        operation.job, operation.operation), ...
        'An operation appears in both impact partitions.');
end

fprintf('test_stage_a_impact_analysis passed\n');

function result = contains_operation(tasks, jobId, operationId)
result = false;
for index = 1:numel(tasks)
    if tasks(index).job == jobId && ...
            tasks(index).operation == operationId
        result = true;
        return
    end
end
end
