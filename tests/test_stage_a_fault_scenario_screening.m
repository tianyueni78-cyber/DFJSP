clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'screening'));

result = run_stage_a_fault_scenario_screening();
screening = result.screening;

assert(screening.is_validated, ...
    'Fault scenario screening must be validated.');
assert(strcmp(screening.source, 'original_baseline'));
assert(~screening.config_modified && ~result.config_modified, ...
    'Scenario screening must not modify the fault configuration.');
assert(~screening.additional_data_generated, ...
    'Scenario screening must not generate additional schedule data.');
assert(abs(screening.repair_duration - ...
    result.current_fault_config.repair_duration) <= 1e-9, ...
    'Screening must reuse the configured repair duration.');
assert(screening.candidate_count == numel(screening.candidates));
assert(screening.examined_trigger_count >= screening.candidate_count);

for index = 1:numel(screening.candidates)
    candidate = screening.candidates(index);
    assert(candidate.evaluated_repair_duration > ...
        candidate.machine_idle_gap);
    assert(candidate.minimum_effective_repair_threshold == ...
        candidate.machine_idle_gap);
    assert(candidate.directly_affected_operations >= 1);
    assert(candidate.affected_operations_total >= ...
        candidate.directly_affected_operations);
    assert(candidate.maximum_projected_delay > 0);
    assert_candidate_matches_baseline( ...
        candidate, result.baseline.machineTable);
end

for index = 1:numel(screening.candidates) - 1
    current = screening.candidates(index);
    next = screening.candidates(index + 1);
    if current.affected_operations_total == ...
            next.affected_operations_total
        assert(current.machine_idle_gap <= next.machine_idle_gap);
    else
        assert(current.affected_operations_total > ...
            next.affected_operations_total);
    end
end

fprintf('test_stage_a_fault_scenario_screening passed\n');

function assert_candidate_matches_baseline(candidate, machineTable)
blocks = machineTable{candidate.machine_id};
triggerMatch = find([blocks.job] == candidate.trigger_job & ...
    [blocks.opera] == candidate.trigger_operation);
nextMatch = find([blocks.job] == candidate.next_job & ...
    [blocks.opera] == candidate.next_operation);
assert(numel(triggerMatch) == 1);
assert(numel(nextMatch) == 1);
assert(abs(blocks(triggerMatch).end - candidate.fault_time) <= 1e-9);
assert(abs(blocks(nextMatch).start - ...
    candidate.next_start_time) <= 1e-9);
assert(abs(candidate.machine_idle_gap - ...
    (blocks(nextMatch).start - blocks(triggerMatch).end)) <= 1e-9);
end
