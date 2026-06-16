function evaluation = evaluate_stage_c_rescheduling_plan( ...
        baseline, state, candidate, strategy, weights)
%EVALUATE_STAGE_C_RESCHEDULING_PLAN Calculate tD, SD, and Y.
%   tD uses final-unload makespan. SD counts machine changes only among
%   operations that were unstarted at the simultaneous-fault time.

if nargin < 5
    error('evaluate_stage_c_rescheduling_plan:MissingInput', ...
        'baseline, state, candidate, strategy, and weights are required.');
end
require_fields(baseline, {'isFaultFreeBaseline'}, 'baseline');
require_fields(state, {'unstarted_operations', 'is_validated'}, 'state');
require_fields(candidate, {'operation_records'}, 'candidate');
validate_inputs(baseline, state, weights);

baselineMakespan = baseline_makespan(baseline);
candidateMakespan = final_unload_makespan(candidate);
sequenceDeviation = machine_assignment_deviation( ...
    state.unstarted_operations, candidate.operation_records);
completionTimeDeviation = candidateMakespan - baselineMakespan;

evaluation = struct();
evaluation.strategy = strategy;
evaluation.candidate = candidate;
evaluation.baseline_makespan = baselineMakespan;
evaluation.candidate_makespan = candidateMakespan;
evaluation.tD = completionTimeDeviation;
evaluation.SD = sequenceDeviation;
evaluation.Y = weights.completion_time_weight * ...
    completionTimeDeviation + ...
    weights.sequence_deviation_weight * sequenceDeviation;
evaluation.completion_time_weight = weights.completion_time_weight;
evaluation.sequence_deviation_weight = ...
    weights.sequence_deviation_weight;
evaluation.reschedulable_operation_count = ...
    numel(state.unstarted_operations);
evaluation.is_validated = true;
end

function makespan = final_unload_makespan(candidate)
if isfield(candidate, 'makespan') && ...
        isscalar(candidate.makespan) && isfinite(candidate.makespan)
    makespan = candidate.makespan;
    return
end
require_fields(candidate, {'agv_activity_records'}, 'candidate');
activities = candidate.agv_activity_records;
isFinalUnload = [activities.job] > 0 & ...
    [activities.operation] == -1 & ...
    [activities.load_status] == -2;
unloads = activities(isFinalUnload);
if isempty(unloads) || any(~isfinite([unloads.end]))
    error('evaluate_stage_c_rescheduling_plan:FinalUnloadMissing', ...
        'Candidate must contain finite final-unload activities.');
end
makespan = max([unloads.end]);
end

function value = baseline_makespan(baseline)
if isfield(baseline, 'isCurrentPlanView') && ...
        isequal(baseline.isCurrentPlanView, true) && ...
        isfield(baseline, 'current_plan_makespan') && ...
        isscalar(baseline.current_plan_makespan) && ...
        isfinite(baseline.current_plan_makespan)
    value = baseline.current_plan_makespan;
elseif isfield(baseline, 'makespan') && ...
        isscalar(baseline.makespan) && isfinite(baseline.makespan)
    value = baseline.makespan;
elseif isfield(baseline, 'current_plan_makespan') && ...
        isscalar(baseline.current_plan_makespan) && ...
        isfinite(baseline.current_plan_makespan)
    value = baseline.current_plan_makespan;
else
    error('evaluate_stage_c_rescheduling_plan:BaselineMakespan', ...
        'Baseline makespan must be finite.');
end
end

function deviation = machine_assignment_deviation( ...
        baselineOperations, candidateOperations)
deviation = 0;
for index = 1:numel(baselineOperations)
    source = baselineOperations(index);
    match = find([candidateOperations.job] == source.job & ...
        [candidateOperations.operation] == source.operation);
    if numel(match) ~= 1
        error('evaluate_stage_c_rescheduling_plan:OperationNotUnique', ...
            'J%d-O%d must appear exactly once.', ...
            source.job, source.operation);
    end
    deviation = deviation + ...
        (candidateOperations(match).machine_id ~= source.machine_id);
end
end

function validate_inputs(baseline, state, weights)
require_fields(weights, {'completion_time_weight', ...
    'sequence_deviation_weight'}, 'weights');
isFaultFree = isequal(baseline.isFaultFreeBaseline, true);
isCurrentView = isfield(baseline, 'isCurrentPlanView') && ...
    isequal(baseline.isCurrentPlanView, true);
if (~isFaultFree && ~isCurrentView) || ~state.is_validated
    error('evaluate_stage_c_rescheduling_plan:InvalidInput', ...
        'Validated Stage C baseline and state are required.');
end
values = [weights.completion_time_weight, ...
    weights.sequence_deviation_weight];
if any(~isfinite(values)) || any(values < 0) || ...
        abs(sum(values) - 1) > 1e-9
    error('evaluate_stage_c_rescheduling_plan:InvalidWeights', ...
        'Weights must be nonnegative and sum to one.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('evaluate_stage_c_rescheduling_plan:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
