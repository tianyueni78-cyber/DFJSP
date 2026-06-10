clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_impact_analysis();
impact = scenario.impact;
machineTableBefore = scenario.baseline.machineTable;

assert(scenario.is_validated);
assert(scenario.step == 3);
assert(scenario.is_impact_identified);
assert(scenario.successor_propagation_executed);
assert(~scenario.is_rescheduled);
assert(impact.is_validated);
assert(~impact.baseline_modified);
assert(~impact.is_rescheduled);
assert(isequaln(machineTableBefore, scenario.baseline.machineTable));
assert(impact.root_operation.machine_id == ...
    scenario.resume_plan.machine_id);
assert(impact.root_operation.job == scenario.resume_plan.job);
assert(impact.root_operation.operation == ...
    scenario.resume_plan.operation);
assert(abs(impact.root_operation.revised_end - ...
    scenario.resume_plan.revised_completion_time) <= 1e-9);
assert(abs(impact.root_operation.completion_delay - ...
    scenario.fault.repair_duration) <= 1e-9);
if impact.root_job_successor.exists
    assert(impact.root_job_successor.job == ...
        scenario.resume_plan.job);
    assert(impact.root_job_successor.operation == ...
        scenario.resume_plan.operation + 1);
end
if impact.root_machine_successor.exists
    assert(impact.root_machine_successor.machine_id == ...
        scenario.resume_plan.machine_id);
end
assert(impact.counts.affected_total > 0);
assert(impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted == ...
    numel(scenario.state.unstarted_operations));

for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    assert(operation.projected_delay > 0);
    assert(operation.projected_start >= operation.original_start);
    assert(operation.projected_end >= operation.original_end);
    assert(operation.root_job_successor || ...
        operation.root_machine_successor || ...
        operation.job_precedence_conflict || ...
        operation.machine_sequence_conflict);
end

fprintf('test_stage_b_impact_analysis passed\n');
