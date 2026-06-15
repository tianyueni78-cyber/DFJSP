clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_c_simultaneous_agv_impact_analysis();
analysis = scenario.agv_impact;
baselineAGVTable = scenario.baseline.AGVTable;

assert(scenario.is_validated);
assert(scenario.step == 7);
assert(scenario.is_agv_impact_identified);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(analysis.is_validated);
assert(strcmp(analysis.stage, 'C'));
assert(analysis.step == 7);
assert(~analysis.is_agv_updated);
assert(analysis.source_agv_table_unchanged);
assert(isequaln(baselineAGVTable, scenario.baseline.AGVTable));
assert(isequaln(baselineAGVTable, ...
    scenario.machine_right_shift.AGVTable));

expectedChanged = scenario.impact.counts.affected_total + ...
    numel(scenario.state.fault_in_progress_operations);
assert(analysis.counts.changed_operations == expectedChanged);
assert(numel(analysis.interrupted_operations) == ...
    numel(scenario.faults));
assert(analysis.counts.affected_transports_total + ...
    analysis.counts.unaffected_transports == ...
    count_job_transports(baselineAGVTable));
assert(analysis.requires_agv_adjustment == ...
    (analysis.counts.affected_transports_total > 0));

affectedKeys = transport_keys(analysis.affected_transports);
assert(size(unique(affectedKeys, 'rows'), 1) == ...
    size(affectedKeys, 1));
for index = 1:numel(analysis.directly_affected_transports)
    transport = analysis.directly_affected_transports(index);
    assert(transport.load_status == -2);
    assert(transport.direct_constraint_violation);
    assert(~isempty(transport.reasons));
end
for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    assert(transport.direct_constraint_violation || ...
        transport.agv_sequence_review);
    assert(~isempty(transport.reasons));
    assert(transport.source_count == ...
        numel(transport.source_event_ids));
    assert(all(ismember(transport.source_event_ids, ...
        [scenario.faults.event_id])));
end
assert(analysis.counts.multi_source_transports == ...
    sum([analysis.affected_transports.source_count] > 1));

reversed = analyze_stage_c_simultaneous_agv_impact( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.machine_right_shift);
assert(isequaln(analysis.affected_transports, ...
    reversed.affected_transports));
assert(isequaln(analysis.unaffected_transports, ...
    reversed.unaffected_transports));

fprintf('test_stage_c_simultaneous_agv_impact_analysis passed\n');

function keys = transport_keys(transports)
if isempty(transports)
    keys = zeros(0, 2);
else
    keys = [[transports.agv_id].', [transports.table_index].'];
end
end

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
