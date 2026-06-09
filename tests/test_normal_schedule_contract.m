clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

baseline = run_normal_schedule_baseline();

requiredFields = {'chrom', 'objectives', 'makespan', 'machineEnergy', ...
    'agvEnergy', 'totalEnergy', 'machineTable', 'AGVTable', ...
    'agvEGRecord', 'agvChargeNum', 'problem', 'machineData', ...
    'agvData', 'energyConfig', 'seed', 'isFaultFreeBaseline'};
for index = 1:numel(requiredFields)
    assert(isfield(baseline, requiredFields{index}), ...
        'Missing baseline field: %s', requiredFields{index});
end

assert(baseline.isFaultFreeBaseline, ...
    'The Stage A baseline must be marked as fault-free.');
assert(isfinite(baseline.makespan) && baseline.makespan > 0, ...
    'Baseline makespan must be positive and finite.');
assert(isfinite(baseline.totalEnergy) && baseline.totalEnergy > 0, ...
    'Baseline total energy must be positive and finite.');
assert(numel(baseline.machineTable) == baseline.problem.machineNum, ...
    'machineTable size does not match problem.machineNum.');
assert(numel(baseline.AGVTable) == baseline.agvData.AGVNum, ...
    'AGVTable size does not match agvData.AGVNum.');

fprintf('test_normal_schedule_contract passed\n');
