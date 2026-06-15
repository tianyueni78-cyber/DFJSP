function scenario = run_stage_br_restart_rule(baseline)
%RUN_STAGE_BR_RESTART_RULE Build the Stage B-R Step 1 restart plan.
%   This step changes only the interruption recovery rule. It does not
%   propagate successors, adjust AGVs, or run a search.

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

scenario.stage = 'B-R';
scenario.resolved_interruption_rule = ...
    'restart_on_original_machine';
scenario.state.interrupted_operation.interruption_rule = ...
    scenario.resolved_interruption_rule;
scenario.state.interruption_rule_resolved = true;
scenario.restart_plan = build_stage_br_restart_operation_plan( ...
    scenario.fault, scenario.state);
scenario.step = 1;
scenario.interruption_rule_resolved = true;
scenario.is_rescheduled = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.restart_plan.is_validated;
end
