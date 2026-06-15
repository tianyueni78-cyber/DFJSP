function analysis = analyze_stage_br_weight_sensitivity( ...
        baseline, state, rightShift, completeSearch, weights)
%ANALYZE_STAGE_BR_WEIGHT_SENSITIVITY Re-evaluate fixed Stage B-R candidates.

if nargin < 5
    error('analyze_stage_br_weight_sensitivity:MissingInput', ...
        'baseline, state, candidates, search, and weights are required.');
end
if isempty(weights) || any(~isfinite(weights)) || ...
        any(weights < 0) || any(weights > 1)
    error('analyze_stage_br_weight_sensitivity:Weights', ...
        'Completion-time weights must be finite values in [0, 1].');
end
rows = repmat(row_template(), 1, numel(weights));
for index = 1:numel(weights)
    config = struct();
    config.completion_time_weight = weights(index);
    config.sequence_deviation_weight = 1 - weights(index);
    config.tie_tolerance = 1e-9;
    selection = select_stage_br_combined_strategy( ...
        baseline, state, rightShift, completeSearch, config);

    rows(index).completion_time_weight = weights(index);
    rows(index).sequence_deviation_weight = 1 - weights(index);
    rows(index).selected_strategy = selection.selected_strategy;
    rows(index).selected_candidate_index = selection.selected_index;
    rows(index).selected_final_unload_makespan = ...
        selection.selected_metrics.candidate_makespan;
    rows(index).selected_tD = selection.selected_metrics.tD;
    rows(index).selected_SD = selection.selected_metrics.SD;
    rows(index).selected_Y = selection.selected_metrics.Y;
end

analysis = struct();
analysis.rows = rows;
analysis.weight_count = numel(rows);
analysis.strategy_switch_count = count_switches(rows);
analysis.is_search_reused = true;
analysis.is_validated = validate_analysis(rows);
end

function count = count_switches(rows)
count = 0;
for index = 2:numel(rows)
    count = count + ~strcmp(rows(index).selected_strategy, ...
        rows(index - 1).selected_strategy);
end
end

function result = validate_analysis(rows)
result = ~isempty(rows) && all(isfinite([rows.selected_Y])) && ...
    all([rows.selected_SD] >= 0);
if ~result
    error('analyze_stage_br_weight_sensitivity:InvalidResult', ...
        'Weight sensitivity result failed validation.');
end
end

function value = row_template()
value = struct('completion_time_weight', [], ...
    'sequence_deviation_weight', [], 'selected_strategy', '', ...
    'selected_candidate_index', [], ...
    'selected_final_unload_makespan', [], ...
    'selected_tD', [], 'selected_SD', [], 'selected_Y', []);
end
