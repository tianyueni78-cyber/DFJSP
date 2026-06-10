function selection = select_stage_a_combined_strategy( ...
        baseline, state, rightShift, completeSearch, config)
%SELECT_STAGE_A_COMBINED_STRATEGY Select the candidate with minimum Y.

if nargin < 5
    error('select_stage_a_combined_strategy:MissingInput', ...
        ['baseline, state, rightShift, completeSearch, ', ...
        'and config are required.']);
end
require_config(config);
if ~isfield(rightShift, 'is_fully_validated') || ...
        ~rightShift.is_fully_validated
    error('select_stage_a_combined_strategy:InvalidRightShift', ...
        'The AGV-linked right-shift candidate must be validated.');
end
if ~isfield(completeSearch, 'pareto_front') || ...
        isempty(completeSearch.pareto_front) || ...
        ~isfield(completeSearch, 'is_validated') || ...
        ~completeSearch.is_validated
    error('select_stage_a_combined_strategy:InvalidSearch', ...
        'A validated complete-rescheduling Pareto front is required.');
end

weights = struct();
weights.completion_time_weight = config.completion_time_weight;
weights.sequence_deviation_weight = ...
    config.sequence_deviation_weight;

rightEvaluation = evaluate_stage_a_rescheduling_plan( ...
    baseline, state, rightShift, 'partial_right_shift', weights);
completeEvaluations = evaluate_complete_front( ...
    baseline, state, completeSearch.pareto_front, weights);
evaluations = [rightEvaluation, completeEvaluations];
selectedIndex = select_minimum_score(evaluations, config.tie_tolerance);

selection = struct();
selection.weights = weights;
selection.evaluations = evaluations;
selection.selected_index = selectedIndex;
selection.selected_strategy = evaluations(selectedIndex).strategy;
selection.selected_candidate = evaluations(selectedIndex).candidate;
selection.selected_metrics = remove_candidate( ...
    evaluations(selectedIndex));
selection.right_shift_metrics = remove_candidate(rightEvaluation);
selection.complete_reschedule_metrics = ...
    remove_candidates(completeEvaluations);
selection.is_validated = validate_selection(selection);
end

function evaluations = evaluate_complete_front( ...
        baseline, state, front, weights)
template = evaluate_stage_a_rescheduling_plan( ...
    baseline, state, front(1).candidate, ...
    'complete_rescheduling', weights);
evaluations = repmat(template, 1, numel(front));
for index = 1:numel(front)
    evaluations(index) = evaluate_stage_a_rescheduling_plan( ...
        baseline, state, front(index).candidate, ...
        'complete_rescheduling', weights);
end
end

function selectedIndex = select_minimum_score(evaluations, tolerance)
selectedIndex = 1;
for index = 2:numel(evaluations)
    current = evaluations(index);
    selected = evaluations(selectedIndex);
    if current.Y < selected.Y - tolerance || ...
            (abs(current.Y - selected.Y) <= tolerance && ...
            current.tD < selected.tD - tolerance) || ...
            (abs(current.Y - selected.Y) <= tolerance && ...
            abs(current.tD - selected.tD) <= tolerance && ...
            current.SD < selected.SD)
        selectedIndex = index;
    end
end
end

function metrics = remove_candidate(evaluation)
metrics = rmfield(evaluation, 'candidate');
end

function metrics = remove_candidates(evaluations)
template = remove_candidate(evaluations(1));
metrics = repmat(template, 1, numel(evaluations));
for index = 1:numel(evaluations)
    metrics(index) = remove_candidate(evaluations(index));
end
end

function result = validate_selection(selection)
scores = [selection.evaluations.Y];
if selection.selected_metrics.Y > min(scores) + 1e-9
    error('select_stage_a_combined_strategy:SelectionMismatch', ...
        'Selected strategy does not have the minimum Y.');
end
if abs(sum([selection.weights.completion_time_weight, ...
        selection.weights.sequence_deviation_weight]) - 1) > 1e-9
    error('select_stage_a_combined_strategy:WeightMismatch', ...
        'Selection weights must sum to one.');
end
result = true;
end

function require_config(config)
required = {'completion_time_weight', ...
    'sequence_deviation_weight', 'tie_tolerance'};
for index = 1:numel(required)
    if ~isfield(config, required{index})
        error('select_stage_a_combined_strategy:MissingConfig', ...
            'config.%s is required.', required{index});
    end
end
if ~isscalar(config.tie_tolerance) || ...
        ~isfinite(config.tie_tolerance) || ...
        config.tie_tolerance < 0
    error('select_stage_a_combined_strategy:InvalidTolerance', ...
        'config.tie_tolerance must be finite and nonnegative.');
end
end
