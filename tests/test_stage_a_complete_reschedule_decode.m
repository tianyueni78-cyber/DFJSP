clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_a_complete_reschedule_decode();
candidate = scenario.complete_reschedule_candidate;
frozen = scenario.frozen_problem;

assert(candidate.is_validated);
assert(candidate.is_complete_reschedule_decoded);
assert(~candidate.is_search_executed);
assert(~scenario.is_search_executed);
assert(strcmp(candidate.strategy, 'complete_rescheduling'));
assert(strcmp(scenario.complete_reschedule_seed.source, ...
    'baseline_chromosome_unstarted_suffix'));

assert(numel(candidate.operation_records) == ...
    sum(scenario.baseline.problem.operaNumVec));
assert_frozen_preserved(candidate.operation_records, ...
    frozen.frozen_operations);
assert_rescheduled_sources(candidate.operation_records, ...
    frozen.reschedulable_operations);
assert_machine_constraints(candidate.operation_records);
assert_job_constraints(candidate.operation_records, ...
    scenario.baseline.problem.operaNumVec);
assert_transport_constraints(candidate);
assert(all(candidate.job_complete_unload > 0));
assert(candidate.makespan == max(candidate.job_complete_unload));
assert(candidate.machine_energy >= 0);
assert(candidate.agv_energy >= 0);
assert(candidate.total_energy == ...
    candidate.machine_energy + candidate.agv_energy);
assert(all(isfinite(candidate.final_agv_energy)));
assert(all(candidate.agv_charge_count >= 0));

fprintf('test_stage_a_complete_reschedule_decode passed\n');

function assert_frozen_preserved(records, frozen)
for index = 1:numel(frozen)
    match = find([records.job] == frozen(index).job & ...
        [records.operation] == frozen(index).operation);
    assert(numel(match) == 1);
    assert(records(match).machine_id == frozen(index).machine_id);
    assert(abs(records(match).start - frozen(index).start) <= 1e-9);
    assert(abs(records(match).end - frozen(index).end) <= 1e-9);
end
end

function assert_rescheduled_sources(records, sources)
for index = 1:numel(sources)
    match = find([records.job] == sources(index).job & ...
        [records.operation] == sources(index).operation);
    assert(numel(match) == 1);
    assert(strcmp(records(match).status, 'rescheduled'));
    assert(any(records(match).machine_id == ...
        sources(index).candidate_machines));
    machinePosition = find(sources(index).candidate_machines == ...
        records(match).machine_id);
    assert(abs(records(match).duration - ...
        sources(index).processing_times(machinePosition)) <= 1e-9);
end
end

function assert_machine_constraints(records)
for machineId = unique([records.machine_id])
    machineRecords = records([records.machine_id] == machineId);
    [~, order] = sort([machineRecords.start]);
    machineRecords = machineRecords(order);
    for index = 1:numel(machineRecords) - 1
        assert(machineRecords(index).end <= ...
            machineRecords(index + 1).start + 1e-9);
    end
end
end

function assert_job_constraints(records, operaNumVec)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = find_operation(records, jobId, operationId);
        successor = find_operation(records, jobId, operationId + 1);
        assert(current.end <= successor.start + 1e-9);
    end
end
end

function assert_transport_constraints(candidate)
transports = candidate.transport_records;
for agvId = unique([transports.agv_id])
    agvRecords = transports([transports.agv_id] == agvId);
    [~, order] = sort([agvRecords.start]);
    agvRecords = agvRecords(order);
    for index = 1:numel(agvRecords) - 1
        assert(agvRecords(index).end <= ...
            agvRecords(index + 1).start + 1e-9);
    end
end
for index = 1:numel(transports)
    if transports(index).load_status ~= -2
        continue
    end
    if transports(index).operation == -1
        jobOperations = candidate.operation_records( ...
            [candidate.operation_records.job] == transports(index).job);
        lastOperationId = max([jobOperations.operation]);
        operation = find_operation(candidate.operation_records, ...
            transports(index).job, lastOperationId);
        assert(transports(index).start + 1e-9 >= operation.end);
        continue
    end
    operation = find_operation(candidate.operation_records, ...
        transports(index).job, transports(index).operation);
    assert(transports(index).end <= operation.start + 1e-9);
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
