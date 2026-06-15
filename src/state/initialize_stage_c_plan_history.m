function history = initialize_stage_c_plan_history(baseline)
%INITIALIZE_STAGE_C_PLAN_HISTORY Create immutable baseline version V0.

if nargin < 1
    error('initialize_stage_c_plan_history:MissingInput', ...
        'baseline is required.');
end
require_fields(baseline, {'machineTable', 'AGVTable', ...
    'makespan', 'isFaultFreeBaseline'}, 'baseline');
if ~baseline.isFaultFreeBaseline
    error('initialize_stage_c_plan_history:InvalidBaseline', ...
        'A validated fault-free baseline is required.');
end

version = version_template();
version.version_id = 0;
version.predecessor_version_id = -1;
version.effective_time = 0;
version.source_event_group = 0;
version.source_event_ids = [];
version.strategy = 'fault_free_baseline';
version.plan = baseline;
version.is_baseline = true;
version.is_validated = true;

history = struct();
history.stage = 'C';
history.step = 12;
history.versions = version;
eventTemplate = event_record_template();
history.event_records = eventTemplate([]);
history.current_version_id = 0;
history.current_plan = baseline;
history.version_count = 1;
history.event_group_count = 0;
history.history_is_immutable = true;
history.is_validated = true;
end

function value = version_template()
value = struct('version_id', [], 'predecessor_version_id', [], ...
    'effective_time', [], 'source_event_group', [], ...
    'source_event_ids', [], 'strategy', '', 'plan', [], ...
    'is_baseline', false, 'is_validated', false);
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
        error('initialize_stage_c_plan_history:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
