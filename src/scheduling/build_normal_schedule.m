function baseline = build_normal_schedule( ...
    chrom, problem, machineData, agvData, energyConfig)
%BUILD_NORMAL_SCHEDULE Decode and evaluate one normal FJSP-AGV plan.
%   This function does not add machine-failure logic, save files, plot
%   figures, or modify the MATLAB path.

if nargin < 5
    error('build_normal_schedule:MissingInput', ...
        ['chrom, problem, machineData, agvData, and ', ...
        'energyConfig are required.']);
end

require_fields(problem, {'jobNum', 'jobInfo', 'operaNumVec', ...
    'machineNum', 'candidateMachine'}, 'problem');
require_fields(machineData, {'distance_matrix', 'machineEnergy'}, ...
    'machineData');
require_fields(agvData, {'AGVNum', 'AGVSpeed', 'AGVEnergy'}, 'agvData');
require_fields(energyConfig, ...
    {'AGVEG_MAX', 'AGVEG_MIN', 'eChargeSpeed'}, 'energyConfig');
validate_chromosome(chrom, problem);

[objectives, machineTable, AGVTable, makespan, machineEnergy, ...
    agvEnergy, agvEGRecord, agvChargeNum] = fitness( ...
    chrom, problem.jobNum, problem.jobInfo, problem.operaNumVec, ...
    problem.machineNum, agvData.AGVNum, agvData.AGVSpeed, ...
    problem.candidateMachine, machineData.distance_matrix, ...
    machineData.machineEnergy, agvData.AGVEnergy, ...
    energyConfig.AGVEG_MAX, energyConfig.AGVEG_MIN, ...
    energyConfig.eChargeSpeed);

baseline = struct();
baseline.chrom = chrom;
baseline.objectives = objectives{1};
baseline.makespan = makespan;
baseline.machineEnergy = machineEnergy;
baseline.agvEnergy = agvEnergy;
baseline.totalEnergy = machineEnergy + agvEnergy;
baseline.machineTable = machineTable;
baseline.AGVTable = AGVTable;
baseline.agvEGRecord = agvEGRecord;
baseline.agvChargeNum = agvChargeNum;
baseline.isFaultFreeBaseline = true;
end

function validate_chromosome(chrom, problem)
if ~isnumeric(chrom) || isempty(chrom) || ~isrow(chrom)
    error('build_normal_schedule:InvalidChromosome', ...
        'chrom must be a non-empty numeric row vector.');
end

expectedLength = 5 * sum(problem.operaNumVec);
if numel(chrom) ~= expectedLength
    error('build_normal_schedule:InvalidChromosome', ...
        'chrom length must equal 5 * sum(problem.operaNumVec).');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_normal_schedule:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
