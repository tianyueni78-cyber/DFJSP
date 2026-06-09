clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_a_machine_right_shift();
baselineAGVTable = scenario.baseline.AGVTable;
analysis = analyze_stage_a_agv_impact( ...
    scenario.baseline, scenario.right_shift);

assert(analysis.is_validated, 'AGV impact analysis must be validated.');
assert(~analysis.is_agv_updated, ...
    'Stage A AGV impact analysis must not update AGV tasks.');
assert(analysis.source_agv_table_unchanged, ...
    'The source AGV table must remain unchanged.');
assert(isequaln(baselineAGVTable, scenario.baseline.AGVTable));
assert(isequaln(baselineAGVTable, scenario.right_shift.AGVTable));

transportCount = analysis.counts.affected_transports_total + ...
    analysis.counts.unaffected_transports;
assert(transportCount == count_job_transports(baselineAGVTable), ...
    'AGV transport partition is incomplete.');

if analysis.counts.changed_operations == 0
    assert(~analysis.requires_agv_adjustment, ...
        'Zero machine changes must require zero AGV adjustments.');
    assert(analysis.counts.affected_transports_total == 0);
end

for index = 1:numel(analysis.directly_affected_transports)
    transport = analysis.directly_affected_transports(index);
    assert(transport.load_status == -2, ...
        'Direct AGV violations must be loaded transports.');
    assert(~isempty(transport.reason), ...
        'Direct AGV violation must record a reason.');
end

for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    assert(transport.direct_constraint_violation || ...
        transport.agv_sequence_review, ...
        'Affected transport must have an impact source.');
end

fprintf('test_stage_a_agv_impact_analysis passed\n');

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
