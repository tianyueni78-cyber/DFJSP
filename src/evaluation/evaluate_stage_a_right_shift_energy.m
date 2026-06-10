function candidate = evaluate_stage_a_right_shift_energy( ...
        baseline, rightShift)
%EVALUATE_STAGE_A_RIGHT_SHIFT_ENERGY Add comparable energy metrics.
%   Machine energy is recalculated from the shifted operation records.
%   AGV energy is preserved from the baseline because the validated
%   partial-right-shift candidate preserves every AGV route and duration.

if nargin < 2
    error('evaluate_stage_a_right_shift_energy:MissingInput', ...
        'baseline and rightShift are required.');
end
require_fields(baseline, {'problem', 'machineData', 'agvEnergy', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(rightShift, {'operation_records', 'validation', ...
    'is_fully_validated'}, 'rightShift');
require_fields(baseline.problem, {'machineNum'}, 'baseline.problem');
require_fields(baseline.machineData, {'machineEnergy'}, ...
    'baseline.machineData');

validate_inputs(baseline, rightShift);
machineEnergy = calculate_machine_energy( ...
    rightShift.operation_records, baseline);
agvEnergy = baseline.agvEnergy;

if ~isscalar(agvEnergy) || ~isfinite(agvEnergy) || agvEnergy < 0
    error('evaluate_stage_a_right_shift_energy:InvalidAgvEnergy', ...
        'baseline.agvEnergy must be a finite nonnegative scalar.');
end

candidate = rightShift;
candidate.machine_energy = machineEnergy;
candidate.agv_energy = agvEnergy;
candidate.total_energy = machineEnergy + agvEnergy;
candidate.energy_evaluation = struct( ...
    'machine_energy_method', 'recalculated_from_shifted_operations', ...
    'agv_energy_method', 'preserved_from_baseline_routes_and_durations', ...
    'agv_routes_preserved', true, ...
    'agv_durations_preserved', true);
candidate.is_energy_evaluated = true;
end

function value = calculate_machine_energy(operations, baseline)
machineCount = baseline.problem.machineNum;
work = zeros(machineCount, 1);
idle = zeros(machineCount, 1);
for machineId = 1:machineCount
    records = operations([operations.machine_id] == machineId);
    if isempty(records)
        continue
    end
    work(machineId) = sum([records.duration]);
    idle(machineId) = max([records.end]) - work(machineId);
    if idle(machineId) < -1e-9
        error('evaluate_stage_a_right_shift_energy:NegativeIdle', ...
            'Machine %d has invalid negative idle time.', machineId);
    end
    idle(machineId) = max(0, idle(machineId));
end
rates = baseline.machineData.machineEnergy;
require_fields(rates, {'work', 'free'}, ...
    'baseline.machineData.machineEnergy');
if numel(rates.work) < machineCount || numel(rates.free) < machineCount
    error('evaluate_stage_a_right_shift_energy:MachineRates', ...
        'Machine energy rates do not cover all machines.');
end
workRates = rates.work(1:machineCount);
idleRates = rates.free(1:machineCount);
value = workRates(:)' * work + idleRates(:)' * idle;
if ~isscalar(value) || ~isfinite(value) || value < 0
    error('evaluate_stage_a_right_shift_energy:InvalidMachineEnergy', ...
        'Calculated machine energy must be finite and nonnegative.');
end
end

function validate_inputs(baseline, rightShift)
if ~baseline.isFaultFreeBaseline || ~rightShift.is_fully_validated
    error('evaluate_stage_a_right_shift_energy:InvalidInput', ...
        'A validated baseline and right-shift candidate are required.');
end
requiredFlags = {'machine_assignments_preserved', ...
    'operation_durations_preserved', 'agv_assignments_preserved', ...
    'agv_routes_preserved', 'agv_durations_preserved'};
for index = 1:numel(requiredFlags)
    field = requiredFlags{index};
    if ~isfield(rightShift.validation, field) || ...
            ~isequal(rightShift.validation.(field), true)
        error('evaluate_stage_a_right_shift_energy:PreservationRule', ...
            'rightShift.validation.%s must be true.', field);
    end
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('evaluate_stage_a_right_shift_energy:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
