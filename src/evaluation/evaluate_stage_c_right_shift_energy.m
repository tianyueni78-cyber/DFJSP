function candidate = evaluate_stage_c_right_shift_energy( ...
        baseline, rightShift)
%EVALUATE_STAGE_C_RIGHT_SHIFT_ENERGY Add comparable energy metrics.
%   Machine work uses physical processing segments, excluding repair gaps.
%   AGV energy is preserved because routes, speeds, and durations do not
%   change in the validated linked right-shift candidate.

if nargin < 2
    error('evaluate_stage_c_right_shift_energy:MissingInput', ...
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
    error('evaluate_stage_c_right_shift_energy:InvalidAgvEnergy', ...
        'baseline.agvEnergy must be finite and nonnegative.');
end

candidate = rightShift;
candidate.machine_energy = machineEnergy;
candidate.agv_energy = agvEnergy;
candidate.total_energy = machineEnergy + agvEnergy;
candidate.energy_evaluation = struct( ...
    'machine_energy_method', ...
    'recalculated_from_stage_c_processing_segments', ...
    'repair_gaps_excluded_from_work', true, ...
    'agv_energy_method', ...
    'preserved_from_baseline_routes_speeds_and_durations');
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
        error('evaluate_stage_c_right_shift_energy:NegativeIdle', ...
            'Machine %d has invalid negative idle time.', machineId);
    end
    idle(machineId) = max(0, idle(machineId));
end
rates = baseline.machineData.machineEnergy;
value = rates.work(1:machineCount)' * work + ...
    rates.free(1:machineCount)' * idle;
if ~isscalar(value) || ~isfinite(value) || value < 0
    error('evaluate_stage_c_right_shift_energy:InvalidMachineEnergy', ...
        'Calculated machine energy must be finite and nonnegative.');
end
end

function validate_inputs(baseline, rightShift)
if ~baseline.isFaultFreeBaseline || ~rightShift.is_fully_validated
    error('evaluate_stage_c_right_shift_energy:InvalidInput', ...
        'Validated Stage C inputs are required.');
end
requiredFlags = {'machine_assignments_preserved', ...
    'processing_durations_preserved', ...
    'all_resume_commitments_preserved', ...
    'agv_assignments_preserved', 'agv_routes_preserved', ...
    'agv_durations_preserved', ...
    'repair_intervals_after_agv_feedback'};
for index = 1:numel(requiredFlags)
    field = requiredFlags{index};
    if ~isfield(rightShift.validation, field) || ...
            ~isequal(rightShift.validation.(field), true)
        error('evaluate_stage_c_right_shift_energy:PreservationRule', ...
            'rightShift.validation.%s must be true.', field);
    end
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('evaluate_stage_c_right_shift_energy:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
