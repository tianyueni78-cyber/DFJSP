function result = run_stage_a_step_14_analysis(stage13)
%RUN_STAGE_A_STEP_14_ANALYSIS Audit candidates and analyze fixed weights.

if nargin < 1 || ~isfield(stage13, 'combined_selection') || ...
        ~stage13.is_formal_run || ~stage13.is_validated
    error('run_stage_a_step_14_analysis:InvalidInput', ...
        'A validated formal Stage 13 result is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

config = stage_a_step_14_config(projectRoot);
weightAnalysis = analyze_stage_a_weight_sensitivity( ...
    stage13.baseline, stage13.state, stage13.linked_right_shift, ...
    stage13.complete_reschedule_search, ...
    config.completion_time_weights);

rightAudit = audit_stage_a_rescheduling_candidate( ...
    stage13.linked_right_shift, stage13.fault, ...
    'partial_right_shift');
front = stage13.complete_reschedule_search.pareto_front;
completeAudits = repmat(rightAudit, 1, numel(front));
for index = 1:numel(front)
    completeAudits(index) = audit_stage_a_rescheduling_candidate( ...
        front(index).candidate, stage13.fault, ...
        'complete_rescheduling');
end

result = struct();
result.stage = 'A';
result.step = 14;
result.config = config;
result.weight_sensitivity = weightAnalysis;
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
