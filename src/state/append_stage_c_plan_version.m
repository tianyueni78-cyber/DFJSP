function history = append_stage_c_plan_version( ...
        history, selectedPlan, faults, strategy)
%APPEND_STAGE_C_PLAN_VERSION Append one event-group result without overwrite.

if nargin < 4
    error('append_stage_c_plan_version:MissingInput', ...
        'history, selectedPlan, faults, and strategy are required.');
end
validate_inputs(history, selectedPlan, faults, strategy);

eventTime = faults(1).start_time;
active = resolve_stage_c_active_plan(history, eventTime);
if active.version_id ~= history.current_version_id
    error('append_stage_c_plan_version:NonCurrentInput', ...
        'A new event must read the plan active at its event time.');
end

newVersion = history.versions(1);
newVersion.version_id = history.current_version_id + 1;
newVersion.predecessor_version_id = history.current_version_id;
newVersion.effective_time = eventTime;
newVersion.source_event_group = faults(1).event_group;
newVersion.source_event_ids = [faults.event_id];
newVersion.strategy = strategy;
newVersion.plan = selectedPlan;
newVersion.is_baseline = false;
newVersion.is_validated = true;

record = event_record_template();
record.event_group = faults(1).event_group;
record.event_ids = [faults.event_id];
record.event_time = eventTime;
record.input_version_id = history.current_version_id;
record.output_version_id = newVersion.version_id;
record.selected_strategy = strategy;
record.is_validated = true;

history.versions(end + 1) = newVersion;
history.event_records(end + 1) = record;
history.current_version_id = newVersion.version_id;
history.current_plan = selectedPlan;
history.version_count = numel(history.versions);
history.event_group_count = numel(history.event_records);
history.is_validated = validate_history(history);
end

function validate_inputs(history, selectedPlan, faults, strategy)
requiredHistory = {'versions', 'event_records', 'current_version_id', ...
    'history_is_immutable', 'is_validated'};
require_fields(history, requiredHistory, 'history');
require_fields(selectedPlan, {'machineTable', 'AGVTable'}, 'selectedPlan');
if ~history.is_validated || ~history.history_is_immutable || ...
        isempty(faults) || ~isstruct(faults)
    error('append_stage_c_plan_version:InvalidInput', ...
        'Validated history, selected plan, and faults are required.');
end
for index = 1:numel(faults)
    require_fields(faults(index), {'event_id', 'event_group', ...
        'start_time', 'is_validated'}, 'faults');
end
if ~all([faults.is_validated]) || ...
        numel(unique([faults.event_group])) ~= 1 || ...
        max(abs([faults.start_time] - faults(1).start_time)) > 1e-9
    error('append_stage_c_plan_version:InvalidEventGroup', ...
        'faults must form one validated event group.');
end
if any(ismember([faults.event_id], ...
        [history.event_records.event_ids]))
    error('append_stage_c_plan_version:DuplicateEvent', ...
        'A fault event cannot create more than one plan version.');
end
if ~(ischar(strategy) && isrow(strategy) && ~isempty(strategy))
    error('append_stage_c_plan_version:InvalidStrategy', ...
        'strategy must be a nonempty character vector.');
end
end

function result = validate_history(history)
versions = history.versions;
ids = [versions.version_id];
if ~isequal(ids, 0:numel(versions) - 1)
    error('append_stage_c_plan_version:VersionSequence', ...
        'Plan version identifiers must be consecutive.');
end
for index = 2:numel(versions)
    if versions(index).predecessor_version_id ~= ...
            versions(index - 1).version_id || ...
            versions(index).effective_time < ...
            versions(index - 1).effective_time
        error('append_stage_c_plan_version:VersionChain', ...
            'Plan versions must form a chronological chain.');
    end
end
result = history.current_version_id == versions(end).version_id && ...
    history.version_count == numel(versions) && ...
    history.event_group_count == numel(history.event_records);
end

function value = event_record_template()
value = struct('event_group', [], 'event_ids', [], ...
    'event_time', [], 'input_version_id', [], ...
    'output_version_id', [], 'selected_strategy', '', ...
    'is_validated', false);
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('append_stage_c_plan_version:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
