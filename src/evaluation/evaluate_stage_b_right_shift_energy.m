function candidate = evaluate_stage_b_right_shift_energy( ...
        baseline, rightShift)
%EVALUATE_STAGE_B_RIGHT_SHIFT_ENERGY Add comparable energy metrics.
%   Physical processing segments exclude the repair gap from work energy.
%   AGV energy is preserved because routes and durations are unchanged.

if nargin < 2
    error('evaluate_stage_b_right_shift_energy:MissingInput', ...
        'baseline and rightShift are required.');
end
require_fields(baseline, {'problem', 'machineData', 'agvEnergy', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(rightShift, {'processing_segments', 'validation', ...
    'is_fully_validated'}, 'rightShift');
validate_inputs(baseline, rightShift);

machineEnergy = calculate_machine_energy( ...
    rightShift.processing_segments, baseline);
agvEnergy = baseline.agvEnergy;
if ~isscalar(agvEnergy) || ~isfinite(agvEnergy) || agvEnergy < 0
    error('evaluate_stage_b_right_shift_energy:InvalidAgvEnergy', ...
        'baseline.agvEnergy must be finite and nonnegative.');
end

candidate = rightShift;
candidate.machine_energy = machineEnergy;
candidate.agv_energy = agvEnergy;
candidate.total_energy = machineEnergy + agvEnergy;
candidate.energy_evaluation = struct( ...
    'machine_energy_method', ...
    'recalculated_from_stage_b_processing_segments', ...
    'repair_gap_excluded_from_work', true, ...
    'agv_energy_method', ...
    'preserved_from_baseline_routes_and_durations');
candidate.is_energy_evaluated = true;
end

function value = calculate_machine_energy(segments, baseline)
machineCount = baseline.problem.machineNum;
work = zeros(machineCount, 1);
idle = zeros(machineCount, 1);
for machineId = 1:machineCount
    records = segments([segments.machine_id] == machineId);
    if isempty(records)
        continue
    end
    work(machineId) = sum([records.processing_time]);
    idle(machineId) = max([records.end]) - work(machineId);
    if idle(machineId) < -1e-9
        error('evaluate_stage_b_right_shift_energy:NegativeIdle', ...
            'Machine %d has invalid negative idle time.', machineId);
    end
    idle(machineId) = max(0, idle(machineId));
end
rates = baseline.machineData.machineEnergy;
if numel(rates.work) < machineCount || numel(rates.free) < machineCount
    error('evaluate_stage_b_right_shift_energy:MachineRates', ...
        'Machine energy rates do not cover all machines.');
end
value = rates.work(1:machineCount)' * work + ...
    rates.free(1:machineCount)' * idle;
end

function validate_inputs(baseline, rightShift)
if ~baseline.isFaultFreeBaseline || ~rightShift.is_fully_validated
    error('evaluate_stage_b_right_shift_energy:InvalidInput', ...
        'A validated baseline and Stage B right shift are required.');
end
requiredFlags = {'processing_durations_preserved', ...
    'interrupted_segments_preserved', 'agv_assignments_preserved', ...
    'agv_routes_preserved', 'agv_durations_preserved'};
for index = 1:numel(requiredFlags)
    field = requiredFlags{index};
    if ~isfield(rightShift.validation, field) || ...
            ~isequal(rightShift.validation.(field), true)
        error('evaluate_stage_b_right_shift_energy:PreservationRule', ...
            'rightShift.validation.%s must be true.', field);
    end
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('evaluate_stage_b_right_shift_energy:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
