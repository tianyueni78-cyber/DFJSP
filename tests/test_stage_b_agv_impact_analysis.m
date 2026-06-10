clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_agv_impact_analysis();
analysis = scenario.agv_impact;
baselineAGVTable = scenario.baseline.AGVTable;

assert(scenario.is_validated);
assert(scenario.step == 5);
assert(scenario.is_agv_impact_identified);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(analysis.is_validated);
assert(analysis.stage == 'B');
assert(analysis.step == 5);
assert(~analysis.is_agv_updated);
assert(analysis.source_agv_table_unchanged);
assert(isequaln(baselineAGVTable, scenario.baseline.AGVTable));
assert(isequaln(baselineAGVTable, ...
    scenario.machine_right_shift.AGVTable));

expectedChanged = scenario.impact.counts.affected_total + 1;
assert(analysis.counts.changed_operations == expectedChanged);
assert(any([analysis.changed_operations.is_interrupted]));
assert(analysis.interrupted_operation.job == ...
    scenario.resume_plan.job);
assert(analysis.interrupted_operation.operation == ...
    scenario.resume_plan.operation);
assert(abs(analysis.interrupted_operation.revised_completion_time - ...
    scenario.resume_plan.revised_completion_time) <= 1e-9);

transportCount = analysis.counts.affected_transports_total + ...
    analysis.counts.unaffected_transports;
assert(transportCount == count_job_transports(baselineAGVTable));
assert(analysis.requires_agv_adjustment == ...
    (analysis.counts.affected_transports_total > 0));

for index = 1:numel(analysis.directly_affected_transports)
    transport = analysis.directly_affected_transports(index);
    assert(transport.load_status == -2);
    assert(transport.direct_constraint_violation);
    assert(~isempty(transport.reason));
end

for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    assert(transport.direct_constraint_violation || ...
        transport.agv_sequence_review);
    assert(~isempty(transport.reason));
end

fprintf('test_stage_b_agv_impact_analysis passed\n');

function count = count_job_transports(AGVTable)
count = 0;
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for index = 1:numel(blocks)
        block = blocks(index);
        if block.job > 0 && block.charge == 0 && ...
                any(block.load_status == [-1, -2]) && ...
                isfinite(block.end)
            count = count + 1;
        end
    end
end
end
