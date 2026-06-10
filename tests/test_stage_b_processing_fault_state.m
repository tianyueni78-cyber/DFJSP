clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));

scenario = run_stage_b_processing_fault_state();
fault = scenario.fault;
state = scenario.state;
interrupted = state.interrupted_operation;

assert(scenario.is_validated);
assert(strcmp(scenario.baseline_source, ...
    'contract_normal_baseline'));
assert(strcmp(fault.stage, 'B'));
assert(strcmp(fault.trigger_type, 'operation_processing'));
assert(strcmp(fault.interruption_rule, 'unresolved'));
assert(strcmp(fault.interruption_rule, ...
    scenario.config.interruption_rule));
assert(~scenario.interruption_rule_resolved);
assert(~scenario.is_rescheduled);
assert(fault.start_time > interrupted.start);
assert(fault.start_time < interrupted.end);
assert(interrupted.machine_id == fault.machine_id);
assert(interrupted.job == fault.trigger_job);
assert(interrupted.operation == fault.trigger_operation);
assert(interrupted.elapsed_processing_time > 0);
assert(interrupted.remaining_processing_time > 0);
assert(abs(interrupted.elapsed_processing_time + ...
    interrupted.remaining_processing_time - ...
    interrupted.original_duration) <= 1e-9);
assert(abs(interrupted.progress_ratio - ...
    scenario.config.interruption_fraction) <= 1e-9);
assert(state.counts.interrupted_operations == 1);
assert(state.counts.completed_operations + ...
    state.counts.in_progress_operations + ...
    state.counts.unstarted_operations == ...
    sum(scenario.baseline.problem.operaNumVec));

expect_error(@() create_processing_fault_event( ...
    scenario.baseline, fault.trigger_job, fault.trigger_operation, ...
    0, fault.repair_duration), ...
    'create_processing_fault_event:InvalidInput');
expect_error(@() create_processing_fault_event( ...
    scenario.baseline, fault.trigger_job, fault.trigger_operation, ...
    1, fault.repair_duration), ...
    'create_processing_fault_event:InvalidInput');

fprintf('test_stage_b_processing_fault_state passed\n');

function expect_error(action, expectedIdentifier)
try
    action();
catch errorInfo
    assert(strcmp(errorInfo.identifier, expectedIdentifier), ...
        'Expected %s but received %s.', ...
        expectedIdentifier, errorInfo.identifier);
    return
end
error('test_stage_b_processing_fault_state:ExpectedErrorNotRaised', ...
    'Expected error was not raised: %s', expectedIdentifier);
end
