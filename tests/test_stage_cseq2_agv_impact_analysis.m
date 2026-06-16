clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cseq2_agv_impact_analysis();
analysis = scenario.cseq2_agv_impact;
baselineAGVTable = scenario.next_fault_state.current_plan_view.AGVTable;

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-SEQ2.5'));
assert(strcmp(scenario.substep, '5'));
assert(scenario.is_agv_impact_identified);
assert(~scenario.is_agv_updated);
assert(~scenario.is_agv_rescheduled);
assert(~scenario.is_search_executed_in_cseq2_step_5);
assert(analysis.is_validated);
assert(strcmp(analysis.stage, 'C-SEQ2'));
assert(strcmp(analysis.step, '5'));
assert(~analysis.is_agv_updated);
assert(analysis.source_agv_table_unchanged);
assert(analysis.history_unchanged);
assert(~analysis.is_plan_modified);
assert(~analysis.is_rescheduled);
assert(analysis.cumulative_unavailability.is_validated);
assert(isequaln(baselineAGVTable, ...
    scenario.cseq2_machine_right_shift.AGVTable));

expectedChanged = ...
    scenario.cseq2_impact_context.counts.merged_affected + ...
    numel(scenario.next_fault_state.state.fault_in_progress_operations);
assert(analysis.counts.changed_operations == expectedChanged);
assert(analysis.counts.affected_transports_total + ...
    analysis.counts.unaffected_transports == ...
    count_job_transports(baselineAGVTable));
assert(analysis.requires_agv_adjustment == ...
    (analysis.counts.affected_transports_total > 0));
assert(numel(analysis.interrupted_operations) == 1);
assert(numel(analysis.overlap_relationships) == ...
    scenario.cseq2_impact_context.counts.overlap_relationships);

affectedKeys = transport_keys(analysis.affected_transports);
assert(size(unique(affectedKeys, 'rows'), 1) == ...
    size(affectedKeys, 1));
for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    assert(transport.direct_constraint_violation || ...
        transport.agv_sequence_review);
    assert(~isempty(transport.reasons));
    assert(transport.source_count == ...
        numel(transport.source_event_ids));
    assert(ismember(scenario.next_fault.event_id, ...
        transport.source_event_ids));
end

fprintf('test_stage_cseq2_agv_impact_analysis passed\n');

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
