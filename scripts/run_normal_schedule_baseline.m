function baseline = run_normal_schedule_baseline()
%RUN_NORMAL_SCHEDULE_BASELINE Build one fault-free baseline schedule.
%   The function returns data in memory. It does not save outputs, create
%   figures, or add machine-failure behavior.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = normal_schedule_config(projectRoot);
rng(config.seed);

problem = read_fjsp(config.instancePath);
machineData = read_machine_data(config.machineDataPath, problem.machineNum);
agvData = read_agv_data(config.agvDataPath);

energyConfig = struct();
energyConfig.AGVEG_MAX = config.AGVEG_MAX;
energyConfig.eChargeSpeed = config.eChargeSpeed;
energyConfig.AGVEG_MIN = calculate_minimum_agv_energy( ...
    machineData.distance_matrix, agvData);

chromosomeSet = init(1, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, ...
    numel(agvData.AGVSpeed));
chrom = chromosomeSet(1, :);

baseline = build_normal_schedule( ...
    chrom, problem, machineData, agvData, energyConfig);
baseline.problem = problem;
baseline.machineData = machineData;
baseline.agvData = agvData;
baseline.energyConfig = energyConfig;
baseline.seed = config.seed;
end

function minimumEnergy = calculate_minimum_agv_energy( ...
    distanceMatrix, agvData)
maximumDistance = max([ ...
    max(distanceMatrix.machine_to_machine(:)), ...
    max(distanceMatrix.load_to_machine), ...
    max(distanceMatrix.machine_to_unload), ...
    distanceMatrix.load_to_unload]);

fastestSpeed = agvData.AGVSpeed(end);
maximumRate = agvData.AGVEnergy.free(end) + ...
    agvData.AGVEnergy.load(end);
minimumEnergy = maximumDistance / fastestSpeed * maximumRate + 1e-6;
end
