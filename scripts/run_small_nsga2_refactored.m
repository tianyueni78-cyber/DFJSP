clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'search'));

config = small_nsga2_config(projectRoot);
config.paths.outputBaseDir = fullfile(projectRoot, 'outputs', ...
    'small_nsga2_refactored');

rng(config.random.seed);

problem = read_fjsp(config.paths.fjsp);
machineData = read_machine_data(config.paths.machineExcel, problem.machineNum);
agvData = read_agv_data(config.paths.agvExcel);

options = struct();
options.useRefactoredVariation = true;

[NSGA2_Result, chrom, runInfo] = run_nsga2_with_encoding( ...
    config, problem, machineData, agvData, options);

runDir = create_run_dir(config.paths.outputBaseDir);
save(fullfile(runDir, 'small_nsga2_refactored_result.mat'), ...
    'NSGA2_Result', 'chrom', 'problem', 'machineData', 'agvData', ...
    'runInfo', 'config');

obj_matrix = NSGA2_Result.obj_matrix;
summaryPath = fullfile(runDir, 'summary.txt');
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_small_nsga2_refactored:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'small NSGA-II refactored encoding result\n');
fprintf(fid, 'pop: %d\n', runInfo.pop);
fprintf(fid, 'max_gen: %d\n', runInfo.max_gen);
fprintf(fid, 'p_cross: %.6f\n', runInfo.p_cross);
fprintf(fid, 'p_mutation: %.6f\n', runInfo.p_mutation);
fprintf(fid, 'useRefactoredVariation: %d\n', runInfo.useRefactoredVariation);
fprintf(fid, 'runTime: %.6f\n', NSGA2_Result.RunTime);
fprintf(fid, 'paretoSolutionCount: %d\n', size(obj_matrix, 1));
fprintf(fid, 'bestMakespan: %.6f\n', min(obj_matrix(:, 1)));
fprintf(fid, 'bestTotalEnergy: %.6f\n', min(obj_matrix(:, 2)));
fprintf(fid, 'outputDir: %s\n', runDir);

fprintf('small NSGA-II refactored encoding finished.\n');
fprintf('pop: %d, max_gen: %d\n', runInfo.pop, runInfo.max_gen);
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
