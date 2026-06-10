function scenario = run_stage_b_resume_rule(baseline)
%RUN_STAGE_B_RESUME_RULE Build the Stage B Step 2 recovery plan.
%   Only the interrupted operation is resolved. Successor propagation and
%   complete rescheduling remain outside this step.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_b_processing_fault_state();
else
    scenario = run_stage_b_processing_fault_state(baseline);
end

scenario.resolved_interruption_rule = ...
    'resume_on_original_machine';
scenario.state.interrupted_operation.interruption_rule = ...
    scenario.resolved_interruption_rule;
scenario.state.interruption_rule_resolved = true;
scenario.resume_plan = build_stage_b_resume_operation_plan( ...
    scenario.fault, scenario.state);
scenario.step = 2;
scenario.interruption_rule_resolved = true;
scenario.is_rescheduled = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.resume_plan.is_validated;
end
