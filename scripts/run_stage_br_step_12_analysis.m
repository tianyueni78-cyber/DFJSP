function result = run_stage_br_step_12_analysis(stage11)
%RUN_STAGE_BR_STEP_12_ANALYSIS Audit candidates and scan fixed weights.

if nargin < 1 || ~isfield(stage11, 'combined_selection') || ...
        stage11.step ~= 11 || ~stage11.is_validated
    error('run_stage_br_step_12_analysis:InvalidInput', ...
        'A validated Stage B-R Step 11 result is required.');
end
projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

config = stage_br_step_12_config(projectRoot);
rightShift = evaluate_stage_br_right_shift_energy( ...
    stage11.baseline, stage11.linked_right_shift);
weightAnalysis = analyze_stage_br_weight_sensitivity( ...
    stage11.baseline, stage11.state, rightShift, ...
    stage11.complete_reschedule_search, ...
    config.completion_time_weights);

rightAudit = audit_stage_br_rescheduling_candidate( ...
    rightShift, stage11.fault, stage11.restart_plan, ...
    'partial_right_shift');
front = stage11.complete_reschedule_search.pareto_front;
completeAudits = repmat(rightAudit, 1, numel(front));
for index = 1:numel(front)
    completeAudits(index) = audit_stage_br_rescheduling_candidate( ...
        front(index).candidate, stage11.fault, ...
        stage11.restart_plan, 'complete_rescheduling');
end

result = struct();
result.stage = 'B-R';
result.step = 12;
result.config = config;
result.weight_sensitivity = weightAnalysis;
result.right_shift_energy_candidate = rightShift;
result.right_shift_audit = rightAudit;
result.complete_reschedule_audits = completeAudits;
result.all_constraint_audits_validated = rightAudit.is_validated && ...
    all([completeAudits.is_validated]);
result.all_energy_audits_complete = ...
    rightAudit.energy_audit_complete && ...
    all([completeAudits.energy_audit_complete]);
result.multiseed_search_executed = false;
result.is_validated = weightAnalysis.is_validated && ...
    result.all_constraint_audits_validated;
end
