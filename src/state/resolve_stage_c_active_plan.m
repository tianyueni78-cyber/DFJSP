function version = resolve_stage_c_active_plan(history, queryTime)
%RESOLVE_STAGE_C_ACTIVE_PLAN Return the latest version active at queryTime.

if nargin < 2
    error('resolve_stage_c_active_plan:MissingInput', ...
        'history and queryTime are required.');
end
if ~isfield(history, 'versions') || isempty(history.versions) || ...
        ~isfield(history, 'is_validated') || ~history.is_validated
    error('resolve_stage_c_active_plan:InvalidHistory', ...
        'A validated nonempty plan history is required.');
end
if ~isscalar(queryTime) || ~isfinite(queryTime) || queryTime < 0
    error('resolve_stage_c_active_plan:InvalidTime', ...
        'queryTime must be a nonnegative finite scalar.');
end

eligible = find([history.versions.effective_time] <= queryTime + 1e-9);
if isempty(eligible)
    error('resolve_stage_c_active_plan:NoActiveVersion', ...
        'No plan version is active at queryTime.');
end
version = history.versions(eligible(end));
end
