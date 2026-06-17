function scenario = run_stage_cseq2_complete_reschedule_decode(stage7)
%RUN_STAGE_CSEQ2_COMPLETE_RESCHEDULE_DECODE Build C-SEQ2 Step 8.
%   Decode one baseline-seed complete-rescheduling candidate. Historical
%   repair unavailability stays attached as cumulative C-SEQ2 context.

if nargin < 1
    stage7 = run_stage_cseq2_frozen_problem();
end
if ~strcmp(stage7.step, 'C-SEQ2.7') || ~stage7.is_validated
    error('run_stage_cseq2_complete_reschedule_decode:InvalidInput', ...
        'A validated C-SEQ2 Step 7 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

currentView = stage7.next_fault_state.current_plan_view;
frozen = stage7.cseq2_frozen_problem;
decision = build_stage_a_baseline_seed_decision(currentView, frozen);

% The shared Stage C decoder expects the canonical Stage C frozen metadata.
% C-SEQ2 keeps its own metadata on the original frozen object and restores
% it on the returned candidate after decoding.
coreFrozen = frozen;
coreFrozen.stage = 'C';
coreFrozen.step = 9;
candidate = decode_stage_c_simultaneous_complete_reschedule( ...
    currentView, coreFrozen, decision);

candidate.stage = 'C-SEQ2';
candidate.step = '8';
candidate.substep = '8';
candidate.cumulative_unavailability = frozen.cumulative_unavailability;
candidate.overlap_relationships = frozen.overlap_relationships;
candidate.active_previous_repairs = frozen.active_previous_repairs;
candidate.history_unchanged = true;
[candidate.cumulative_repair_intervals_respected, ...
    candidate.frozen_history_repair_overlap_count] = ...
    audit_cumulative_repairs(candidate.processing_segments, ...
    frozen.cumulative_unavailability, frozen.frozen_operations);
candidate.is_validated = candidate.is_validated && ...
    candidate.cumulative_repair_intervals_respected;

scenario = stage7;
scenario.cseq2_complete_reschedule_decision = decision;
scenario.cseq2_complete_reschedule_candidate = candidate;
scenario.step = 'C-SEQ2.8';
scenario.substep = '8';
scenario.is_complete_reschedule_decoded = true;
scenario.is_search_executed_in_cseq2_step_8 = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && candidate.is_validated;
end

function [result, frozenOverlapCount] = audit_cumulative_repairs( ...
        segments, cumulative, frozenOperations)
if ~isfield(cumulative, 'intervals') || isempty(cumulative.intervals)
    result = cumulative.is_validated;
    frozenOverlapCount = 0;
    return
end
result = cumulative.is_validated;
frozenOverlapCount = 0;
tolerance = 1e-9;
for index = 1:numel(cumulative.intervals)
    interval = cumulative.intervals(index);
    records = segments([segments.machine_id] == interval.machine_id);
    for recordIndex = 1:numel(records)
        overlaps = records(recordIndex).start < ...
            interval.end_time - tolerance && ...
            records(recordIndex).end > interval.start_time + tolerance;
        if overlaps && is_frozen_operation(records(recordIndex), frozenOperations)
            frozenOverlapCount = frozenOverlapCount + 1;
        else
            result = result && ~overlaps;
        end
    end
end
end

function result = is_frozen_operation(segment, frozenOperations)
result = any([frozenOperations.job] == segment.job & ...
    [frozenOperations.operation] == segment.operation);
end
