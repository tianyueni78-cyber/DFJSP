clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

stage13Contract = run_stage_a_step_13_contract();
stage13Contract.is_formal_run = true;
result = run_stage_a_step_14_analysis(stage13Contract);
config = stage_a_step_14_config(projectRoot);

assert(result.is_validated);
assert(result.step == 14);
assert(isequal(size(config.seeds), [1, 5]));
assert(numel(unique(config.seeds)) == 5);
assert(any(config.seeds == 42));
assert(~result.multiseed_search_executed);
assert(result.weight_sensitivity.is_search_reused);
assert(result.weight_sensitivity.weight_count == 11);
assert(result.right_shift_audit.is_validated);
assert(result.right_shift_audit.energy_audit_complete);
assert(result.right_shift_energy_candidate.is_energy_evaluated);
assert(result.right_shift_energy_candidate.agv_energy == ...
    stage13Contract.baseline.agvEnergy);
assert(abs(result.right_shift_energy_candidate.machine_energy - ...
    expected_machine_energy(result.right_shift_energy_candidate, ...
    stage13Contract.baseline)) <= 1e-9);
assert(abs(result.right_shift_energy_candidate.total_energy - ...
    result.right_shift_energy_candidate.machine_energy - ...
    result.right_shift_energy_candidate.agv_energy) <= 1e-9);
assert(all([result.complete_reschedule_audits.is_validated]));
assert(result.all_constraint_audits_validated);
assert(result.all_energy_audits_complete);
assert(all([result.complete_reschedule_audits.energy_audit_complete]));

fprintf('test_stage_a_step_14_contract passed\n');

clear stage13Contract result

function value = expected_machine_energy(candidate, baseline)
machineCount = baseline.problem.machineNum;
work = zeros(machineCount, 1);
idle = zeros(machineCount, 1);
for machineId = 1:machineCount
    records = candidate.operation_records( ...
        [candidate.operation_records.machine_id] == machineId);
    if isempty(records)
        continue
    end
    work(machineId) = sum([records.duration]);
    idle(machineId) = max([records.end]) - work(machineId);
end
workRates = baseline.machineData.machineEnergy.work(1:machineCount);
idleRates = baseline.machineData.machineEnergy.free(1:machineCount);
value = workRates(:)' * work + idleRates(:)' * idle;
end
