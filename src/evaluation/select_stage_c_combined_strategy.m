function selection = select_stage_c_combined_strategy( ...
        baseline, state, rightShift, completeSearch, config)
%SELECT_STAGE_C_COMBINED_STRATEGY Select the candidate with minimum Y.

if nargin < 5
    error('select_stage_c_combined_strategy:MissingInput', ...
        'baseline, state, rightShift, search, and config are required.');
end
if ~rightShift.is_fully_validated || ~rightShift.is_energy_evaluated
    error('select_stage_c_combined_strategy:InvalidRightShift', ...
        'Validated and energy-evaluated right shift is required.');
end
if ~completeSearch.is_validated || isempty(completeSearch.pareto_front)
    error('select_stage_c_combined_strategy:InvalidSearch', ...
        'Validated complete-rescheduling front is required.');
end

weights = struct( ...
    'completion_time_weight', config.completion_time_weight, ...
    'sequence_deviation_weight', config.sequence_deviation_weight);
rightEvaluation = evaluate_stage_c_rescheduling_plan( ...
    baseline, state, rightShift, 'partial_right_shift', weights);
front = completeSearch.pareto_front;
completeEvaluations = repmat(rightEvaluation, 1, numel(front));
for index = 1:numel(front)
    completeEvaluations(index) = evaluate_stage_c_rescheduling_plan( ...
        baseline, state, front(index).candidate, ...
        'complete_rescheduling', weights);
end
evaluations = [rightEvaluation, completeEvaluations];
selectedIndex = select_minimum(evaluations, config.tie_tolerance);

selection = struct();
selection.weights = weights;
selection.evaluations = evaluations;
selection.selected_index = selectedIndex;
selection.selected_strategy = evaluations(selectedIndex).strategy;
selection.selected_candidate = evaluations(selectedIndex).candidate;
selection.selected_metrics = remove_candidate(evaluations(selectedIndex));
selection.right_shift_metrics = remove_candidate(rightEvaluation);
selection.complete_reschedule_metrics = ...
    remove_candidates(completeEvaluations);
selection.is_validated = ...
    evaluations(selectedIndex).Y <= min([evaluations.Y]) + 1e-9;
end

function selected = select_minimum(evaluations, tolerance)
selected = 1;
for index = 2:numel(evaluations)
    current = evaluations(index);
    best = evaluations(selected);
    if current.Y < best.Y - tolerance || ...
            (abs(current.Y - best.Y) <= tolerance && ...
            current.tD < best.tD - tolerance) || ...
            (abs(current.Y - best.Y) <= tolerance && ...
            abs(current.tD - best.tD) <= tolerance && ...
            current.SD < best.SD)
        selected = index;
    end
end
end

function value = remove_candidate(evaluation)
value = rmfield(evaluation, 'candidate');
end

function values = remove_candidates(evaluations)
template = remove_candidate(evaluations(1));
values = repmat(template, 1, numel(evaluations));
for index = 1:numel(evaluations)
    values(index) = remove_candidate(evaluations(index));
end
end
