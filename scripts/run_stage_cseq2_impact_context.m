function scenario = run_stage_cseq2_impact_context(stage2)
%RUN_STAGE_CSEQ2_IMPACT_CONTEXT Build C-SEQ2 Step 3.
%   New-fault impact is propagated while historical repair intervals remain
%   part of the cumulative unavailability context.

if nargin < 1
    stage2 = run_stage_cseq2_unavailability_context();
end
if ~strcmp(stage2.step, 'C-SEQ2.2') || ~stage2.is_validated
    error('run_stage_cseq2_impact_context:InvalidInput', ...
        'A validated C-SEQ2 Step 2 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'impact'));

context = build_stage_cseq2_impact_context(stage2);
scenario = stage2;
scenario.cseq2_impact_context = context;
scenario.step = 'C-SEQ2.3';
scenario.substep = '3';
scenario.is_impact_propagated = true;
scenario.is_cumulative_unavailability_built = true;
scenario.is_plan_modified_in_cseq2_step_3 = false;
scenario.is_rescheduled_in_cseq2_step_3 = false;
scenario.is_validated = scenario.is_validated && context.is_validated;
end
