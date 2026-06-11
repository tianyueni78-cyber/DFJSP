function result = run_stage_b_step_13_analysis(stage12)
%RUN_STAGE_B_STEP_13_ANALYSIS Audit candidates and scan fixed weights.

if nargin < 1 || ~isfield(stage12, 'combined_selection') || ...
        stage12.step ~= 12 || ~stage12.is_validated
    error('run_stage_b_step_13_analysis:InvalidInput', ...
        'A validated Stage B Step 12 result is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

config = stage_b_step_13_config(projectRoot);
rightShift = evaluate_stage_b_right_shift_energy( ...
    stage12.baseline, stage12.linked_right_shift);
weightAnalysis = analyze_stage_b_weight_sensitivity( ...
    stage12.baseline, stage12.state, rightShift, ...
    stage12.complete_reschedule_search, ...
    config.completion_time_weights);

rightAudit = audit_stage_b_rescheduling_candidate( ...
    rightShift, stage12.fault, stage12.resume_plan, ...
    'partial_right_shift');
front = stage12.complete_reschedule_search.pareto_front;
completeAudits = repmat(rightAudit, 1, numel(front));
for index = 1:numel(front)
    completeAudits(index) = audit_stage_b_rescheduling_candidate( ...
        front(index).candidate, stage12.fault, ...
        stage12.resume_plan, 'complete_rescheduling');
end

result = struct();
result.stage = 'B';
result.step = 13;
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
