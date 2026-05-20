clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
config = small_nsga2_config(projectRoot);
addpath(config.paths.algorithmDir);

rng(config.random.seed);

problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

distance_matrix = machineData.distance_matrix;
machineEnergy = machineData.machineEnergy;
AGVEnergy = agvData.AGVEnergy;

AGVEG_MAX = config.energy.AGVEG_MAX;
eChargeSpeed = config.energy.eChargeSpeed;
distance_MAX = max([max(distance_matrix.machine_to_machine(:)), ...
    max(distance_matrix.load_to_machine), ...
    max(distance_matrix.machine_to_unload), ...
    distance_matrix.load_to_unload]);
AGVEG_MIN = distance_MAX / agvData.AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;

p_cross = config.algorithm.p_cross;
p_mutation = config.algorithm.p_mutation;
pop = config.algorithm.pop;
max_gen = config.algorithm.max_gen;
speedNum = length(agvData.AGVSpeed);

chrom = init(pop, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, speedNum);

NSGA2_Result = NSGA2(p_cross, p_mutation, pop, chrom, max_gen, ...
    problem.jobNum, ...
    problem.jobInfo, ...
    problem.operaNumVec, ...
    problem.machineNum, ...
    agvData.AGVNum, ...
    agvData.AGVSpeed, ...
    problem.candidateMachine, ...
    distance_matrix, ...
    machineEnergy, ...
    AGVEnergy, ...
    AGVEG_MAX, ...
    AGVEG_MIN, ...
    eChargeSpeed);

runDir = create_run_dir(config.paths.outputBaseDir);
save(fullfile(runDir, 'small_nsga2_result.mat'), ...
    'NSGA2_Result', 'chrom', 'problem', 'machineData', 'agvData', ...
    'AGVEG_MAX', 'AGVEG_MIN', 'eChargeSpeed', ...
    'p_cross', 'p_mutation', 'pop', 'max_gen', 'config');

obj_matrix = NSGA2_Result.obj_matrix;
summaryPath = fullfile(runDir, 'summary.txt');
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_small_nsga2:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'small NSGA-II result\n');
fprintf(fid, 'pop: %d\n', pop);
fprintf(fid, 'max_gen: %d\n', max_gen);
fprintf(fid, 'p_cross: %.6f\n', p_cross);
fprintf(fid, 'p_mutation: %.6f\n', p_mutation);
fprintf(fid, 'runTime: %.6f\n', NSGA2_Result.RunTime);
fprintf(fid, 'paretoSolutionCount: %d\n', size(obj_matrix, 1));
fprintf(fid, 'bestMakespan: %.6f\n', min(obj_matrix(:, 1)));
fprintf(fid, 'bestTotalEnergy: %.6f\n', min(obj_matrix(:, 2)));
fprintf(fid, 'outputDir: %s\n', runDir);

fprintf('small NSGA-II finished.\n');
fprintf('pop: %d, max_gen: %d\n', pop, max_gen);
fprintf('paretoSolutionCount: %d\n', size(obj_matrix, 1));
fprintf('bestMakespan: %.6f\n', min(obj_matrix(:, 1)));
fprintf('bestTotalEnergy: %.6f\n', min(obj_matrix(:, 2)));
fprintf('outputDir: %s\n', runDir);

function runDir = create_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    mkdir(baseDir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
runDir = fullfile(baseDir, stamp);
suffix = 1;
while exist(runDir, 'dir')
    runDir = fullfile(baseDir, sprintf('%s_%02d', stamp, suffix));
    suffix = suffix + 1;
end
mkdir(runDir);
end
