function scenario = run_stage_cseq2_unavailability_context(stage1)
%RUN_STAGE_CSEQ2_UNAVAILABILITY_CONTEXT Build C-SEQ2 Step 2.
%   Historical and new repair intervals are normalized without impact
%   propagation or schedule modification.

if nargin < 1
    stage1 = run_stage_cseq2_overlapping_fault_state();
end
if ~strcmp(stage1.step, 'C-SEQ2.1') || ~stage1.is_validated
    error('run_stage_cseq2_unavailability_context:InvalidInput', ...
        'A validated C-SEQ2 Step 1 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'fault'));

context = build_stage_cseq2_overlapping_unavailability_context(stage1);
scenario = stage1;
scenario.cseq2_unavailability_context = context;
scenario.step = 'C-SEQ2.2';
scenario.substep = '2';
scenario.is_cumulative_unavailability_built = true;
scenario.is_impact_propagated = false;
scenario.is_plan_modified_in_cseq2_step_2 = false;
scenario.is_search_executed_in_cseq2_step_2 = false;
scenario.is_validated = scenario.is_validated && context.is_validated;
end
