function audit = audit_stage_a_rescheduling_candidate( ...
        candidate, fault, strategy)
%AUDIT_STAGE_A_RESCHEDULING_CANDIDATE Summarize validated constraints.

if nargin < 3
    error('audit_stage_a_rescheduling_candidate:MissingInput', ...
        'candidate, fault, and strategy are required.');
end
if ~isfield(candidate, 'validation') || ~isstruct(candidate.validation)
    error('audit_stage_a_rescheduling_candidate:Validation', ...
        'candidate.validation is required.');
end

validationFields = fieldnames(candidate.validation);
validationValues = false(1, numel(validationFields));
for index = 1:numel(validationFields)
    value = candidate.validation.(validationFields{index});
    validationValues(index) = islogical(value) && isscalar(value) && value;
end

repairRespected = audit_repair_interval( ...
    candidate.operation_records, fault);
[finalUnloadComplete, finalUnloadMakespan] = ...
    audit_final_unload(candidate);
energy = audit_energy(candidate);

audit = struct();
audit.strategy = strategy;
audit.validation_fields = validationFields;
audit.validation_field_count = numel(validationFields);
audit.validation_flags_all_true = all(validationValues);
audit.repair_interval_respected = repairRespected;
audit.final_unload_complete = finalUnloadComplete;
audit.final_unload_makespan = finalUnloadMakespan;
audit.energy_available = energy.available;
audit.machine_energy = energy.machine;
audit.agv_energy = energy.agv;
audit.total_energy = energy.total;
audit.energy_audit_complete = energy.available && energy.valid;
audit.is_validated = audit.validation_flags_all_true && ...
    repairRespected && finalUnloadComplete && ...
    (~energy.available || energy.valid);
end

function result = audit_repair_interval(operations, fault)
result = true;
records = operations([operations.machine_id] == fault.machine_id);
for index = 1:numel(records)
    overlaps = records(index).start < fault.repair_end_time - 1e-9 && ...
        fault.start_time < records(index).end - 1e-9;
    if overlaps
        result = false;
        return
    end
end
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
