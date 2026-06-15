function audit = audit_stage_br_rescheduling_candidate( ...
        candidate, fault, restartPlan, strategy)
%AUDIT_STAGE_BR_RESCHEDULING_CANDIDATE Audit restart processing and energy.

if nargin < 4
    error('audit_stage_br_rescheduling_candidate:MissingInput', ...
        'candidate, fault, restartPlan, and strategy are required.');
end
require_fields(candidate, {'validation', 'processing_segments'}, ...
    'candidate');
validationFields = fieldnames(candidate.validation);
validationValues = false(1, numel(validationFields));
for index = 1:numel(validationFields)
    value = candidate.validation.(validationFields{index});
    validationValues(index) = islogical(value) && isscalar(value) && value;
end
repairRespected = audit_repair_interval( ...
    candidate.processing_segments, fault);
restartCommitmentRespected = audit_restart_commitment( ...
    candidate.processing_segments, restartPlan);
[finalUnloadComplete, finalUnloadMakespan] = ...
    audit_final_unload(candidate);
energy = audit_energy(candidate);

audit = struct();
audit.strategy = strategy;
audit.validation_fields = validationFields;
audit.validation_field_count = numel(validationFields);
audit.validation_flags_all_true = all(validationValues);
audit.repair_interval_respected = repairRespected;
audit.restart_commitment_respected = restartCommitmentRespected;
audit.restart_from_zero = restartPlan.restart_from_zero;
audit.progress_preserved = restartPlan.progress_preserved;
audit.lost_processing_time = restartPlan.lost_processing_time;
audit.final_unload_complete = finalUnloadComplete;
audit.final_unload_makespan = finalUnloadMakespan;
audit.energy_available = energy.available;
audit.machine_energy = energy.machine;
audit.agv_energy = energy.agv;
audit.total_energy = energy.total;
audit.energy_audit_complete = energy.available && energy.valid;
audit.is_validated = audit.validation_flags_all_true && ...
    repairRespected && restartCommitmentRespected && ...
    finalUnloadComplete && (~energy.available || energy.valid);
end

function result = audit_repair_interval(segments, fault)
records = segments([segments.machine_id] == fault.machine_id);
result = true;
for index = 1:numel(records)
    overlaps = records(index).start < fault.repair_end_time - 1e-9 && ...
        fault.start_time < records(index).end - 1e-9;
    if overlaps
        result = false;
        return
    end
end
end

function result = audit_restart_commitment(segments, plan)
selected = segments([segments.job] == plan.job & ...
    [segments.operation] == plan.operation);
if numel(selected) ~= 2
    result = false;
    return
end
[~, order] = sort([selected.segment_order]);
selected = selected(order);
result = plan.restart_from_zero && ~plan.progress_preserved && ...
    abs(selected(1).start - ...
    plan.lost_processing_segment.start) <= 1e-9 && ...
    abs(selected(1).end - ...
    plan.lost_processing_segment.end) <= 1e-9 && ...
    abs(selected(1).processing_time - ...
    plan.lost_processing_time) <= 1e-9 && ...
    abs(selected(2).start - plan.restart_segment.start) <= 1e-9 && ...
    abs(selected(2).end - plan.restart_segment.end) <= 1e-9 && ...
    abs(selected(2).processing_time - ...
    plan.original_duration) <= 1e-9 && ...
    abs(sum([selected.processing_time]) - ...
    plan.total_machine_processing_time) <= 1e-9;
end

function [result, makespan] = audit_final_unload(candidate)
if isfield(candidate, 'job_complete_unload') && ...
        ~isempty(candidate.job_complete_unload)
    values = candidate.job_complete_unload;
    result = all(isfinite(values)) && all(values > 0);
    makespan = max(values);
    return
end
if ~isfield(candidate, 'agv_activity_records')
    result = false;
    makespan = NaN;
    return
end
activities = candidate.agv_activity_records;
isUnload = [activities.job] > 0 & ...
    [activities.operation] == -1 & ...
    [activities.load_status] == -2;
values = [activities(isUnload).end];
result = ~isempty(values) && all(isfinite(values));
if result
    makespan = max(values);
else
    makespan = NaN;
end
end

function energy = audit_energy(candidate)
energy = struct('available', false, 'valid', true, ...
    'machine', NaN, 'agv', NaN, 'total', NaN);
required = {'machine_energy', 'agv_energy', 'total_energy'};
if ~all(isfield(candidate, required))
    return
end
energy.available = true;
energy.machine = candidate.machine_energy;
energy.agv = candidate.agv_energy;
energy.total = candidate.total_energy;
energy.valid = all(isfinite([energy.machine, energy.agv, ...
    energy.total])) && energy.machine >= 0 && energy.agv >= 0 && ...
    abs(energy.total - energy.machine - energy.agv) <= 1e-9;
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('audit_stage_br_rescheduling_candidate:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
