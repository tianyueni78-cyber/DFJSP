clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

contractScenario = struct();
contractScenario.optimized_baseline = run_normal_schedule_baseline();
contractScenario.normal_search = struct('is_validated', true);
contractScenario.is_source_data_only = true;
contractScenario.is_fault_free = true;

contractResult = run_stage_a_rebuilt_rescheduling_chain( ...
    contractScenario);

assert(contractResult.is_validated);
assert(contractResult.step == 12);
assert(contractResult.stage11.is_validated);
assert(contractResult.state.is_validated);
assert(contractResult.impact.is_validated);
assert(contractResult.impact.counts.directly_affected > 0);
assert(contractResult.right_shift.is_machine_validated);
assert(contractResult.agv_impact.is_validated);
assert(contractResult.linked_right_shift.is_fully_validated);
assert(contractResult.frozen_problem.is_validated);
assert(~contractResult.is_search_executed);
assert(isempty(contractResult.complete_reschedule_search));
assert(~contractResult.is_combination_evaluated);
assert(~contractResult.baseline_modified);

assert(abs(contractResult.fault.start_time - ...
    contractResult.state.snapshot_time) <= 1e-9);
assert(contractResult.fault.machine_id == ...
    contractResult.impact.unavailable_interval.machine_id);
assert(contractResult.frozen_problem.counts.frozen_operations + ...
    contractResult.frozen_problem.counts.reschedulable_operations == ...
    sum(contractResult.baseline.problem.operaNumVec));

fprintf('test_stage_a_rebuilt_rescheduling_chain passed\n');

clear contractScenario contractResult
