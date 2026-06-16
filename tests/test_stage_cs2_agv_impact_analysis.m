clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_cs2_agv_impact_analysis();
analysis = scenario.cs2_agv_impact;
baselineAGVTable = scenario.baseline.AGVTable;

assert(scenario.is_validated);
assert(strcmp(scenario.extension, 'C-S2'));
assert(strcmp(scenario.step, 'C-S2.4'));
assert(scenario.is_agv_impact_identified);
assert(~scenario.is_agv_updated);
assert(~scenario.is_fully_validated);
assert(analysis.is_validated);
assert(strcmp(analysis.stage, 'C-S2'));
assert(analysis.step == 4);
assert(strcmp(analysis.interruption_rule, 'restart_from_zero'));
assert(analysis.restart_from_zero);
assert(~analysis.progress_preserved);
assert(~analysis.is_agv_updated);
assert(analysis.source_agv_table_unchanged);
assert(strcmp(analysis.analysis_core, ...
    'analyze_stage_c_simultaneous_agv_impact'));
assert(isequaln(baselineAGVTable, scenario.baseline.AGVTable));
assert(isequaln(baselineAGVTable, ...
    scenario.cs2_machine_right_shift.AGVTable));

expectedChanged = scenario.cs2_impact.counts.affected_total + ...
    numel(scenario.cs2_restart_commitments);
assert(analysis.counts.changed_operations == expectedChanged);
assert(abs(analysis.lost_processing_time - ...
    scenario.cs2_machine_right_shift.lost_processing_time) <= 1e-9);
assert(numel(analysis.interrupted_operations) == ...
    numel(scenario.cs2_restart_commitments));
assert(analysis.counts.affected_transports_total + ...
    analysis.counts.unaffected_transports == ...
    count_job_transports(baselineAGVTable));
assert(analysis.requires_agv_adjustment == ...
    (analysis.counts.affected_transports_total > 0));

lostSegments = analysis.processing_segments( ...
    strcmp({analysis.processing_segments.segment_type}, ...
    'lost_processing_before_fault'));
restartSegments = analysis.processing_segments( ...
    strcmp({analysis.processing_segments.segment_type}, ...
    'restart_after_repair'));
assert(numel(lostSegments) == numel(scenario.cs2_restart_commitments));
assert(numel(restartSegments) == numel(scenario.cs2_restart_commitments));
assert(~any([lostSegments.contributes_to_completion]));
assert(all([restartSegments.contributes_to_completion]));

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

reversed = analyze_stage_cs2_agv_impact( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.cs2_machine_right_shift);
assert(isequaln(analysis.affected_transports, ...
    reversed.affected_transports));
assert(isequaln(analysis.unaffected_transports, ...
    reversed.unaffected_transports));

fprintf('test_stage_cs2_agv_impact_analysis passed\n');

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
