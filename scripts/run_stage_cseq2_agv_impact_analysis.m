function scenario = run_stage_cseq2_agv_impact_analysis(stage4)
%RUN_STAGE_CSEQ2_AGV_IMPACT_ANALYSIS Build C-SEQ2 Step 5.
%   Identify affected AGV transports without changing AGV schedules.

if nargin < 1
    stage4 = run_stage_cseq2_machine_right_shift();
end
if ~strcmp(stage4.step, 'C-SEQ2.4') || ~stage4.is_validated
    error('run_stage_cseq2_agv_impact_analysis:InvalidInput', ...
        'A validated C-SEQ2 Step 4 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'impact'));

coreCandidate = stage4.cseq2_machine_right_shift;
coreCandidate.stage = 'C';
coreCandidate.step = 6;
analysis = analyze_stage_c_simultaneous_agv_impact( ...
    stage4.next_fault_state.current_plan_view, ...
    stage4.next_fault, coreCandidate);
analysis.stage = 'C-SEQ2';
analysis.step = '5';
analysis.cumulative_unavailability = ...
    stage4.cseq2_impact_context.cumulative_unavailability;
analysis.overlap_relationships = ...
    stage4.cseq2_impact_context.overlap_relationships;
analysis.history_unchanged = true;
analysis.is_plan_modified = false;
analysis.is_rescheduled = false;
analysis.is_validated = analysis.is_validated && ...
    validate_analysis(analysis, stage4);

scenario = stage4;
scenario.cseq2_agv_impact = analysis;
scenario.step = 'C-SEQ2.5';
scenario.substep = '5';
scenario.is_agv_impact_identified = true;
scenario.is_agv_updated = false;
scenario.is_agv_rescheduled = false;
scenario.is_search_executed_in_cseq2_step_5 = false;
scenario.is_validated = scenario.is_validated && analysis.is_validated;
end

function result = validate_analysis(analysis, stage4)
result = ~analysis.is_agv_updated && analysis.source_agv_table_unchanged && ...
    analysis.history_unchanged && ~analysis.is_plan_modified && ...
    ~analysis.is_rescheduled && ...
    analysis.cumulative_unavailability.is_validated && ...
    numel(analysis.overlap_relationships) == ...
    stage4.cseq2_impact_context.counts.overlap_relationships && ...
    analysis.counts.changed_operations == ...
    stage4.cseq2_impact_context.counts.merged_affected + ...
    numel(stage4.next_fault_state.state.fault_in_progress_operations);
if ~result
    error('run_stage_cseq2_agv_impact_analysis:InvalidAnalysis', ...
        'C-SEQ2 AGV impact analysis failed validation.');
end
end
