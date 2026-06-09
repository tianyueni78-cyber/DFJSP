function decision = build_stage_a_baseline_seed_decision(baseline, frozen)
%BUILD_STAGE_A_BASELINE_SEED_DECISION Extract a source-data decoder seed.
%   The seed uses the original chromosome decisions only for operations
%   that were unstarted at the fault time. It creates no synthetic data.

if nargin < 2
    error('build_stage_a_baseline_seed_decision:MissingInput', ...
        'baseline and frozen are required.');
end
if ~isfield(baseline, 'chrom') || ~isfield(baseline, 'problem') || ...
        ~isfield(frozen, 'reschedulable_operations') || ...
        ~isfield(frozen, 'job_boundaries')
    error('build_stage_a_baseline_seed_decision:InvalidInput', ...
        'Baseline chromosome and frozen problem are required.');
end

operationTotal = sum(baseline.problem.operaNumVec);
OS = baseline.chrom(1:operationTotal);
MS = baseline.chrom(operationTotal + 1:2 * operationTotal);
AS = baseline.chrom(2 * operationTotal + 1:3 * operationTotal);
SS = baseline.chrom(3 * operationTotal + 1:5 * operationTotal);

remainingSequence = zeros(1, numel(frozen.reschedulable_operations));
seen = zeros(1, baseline.problem.jobNum);
outputIndex = 0;
for jobId = OS
    seen(jobId) = seen(jobId) + 1;
    if seen(jobId) <= frozen.job_boundaries(jobId).completed_prefix
        continue
    end
    outputIndex = outputIndex + 1;
    remainingSequence(outputIndex) = jobId;
end
if outputIndex ~= numel(remainingSequence)
    error('build_stage_a_baseline_seed_decision:SequenceCount', ...
        'Baseline chromosome does not match the frozen problem.');
end

count = numel(frozen.reschedulable_operations);
machineChoice = zeros(1, count);
agvAssignment = zeros(1, count);
freeSpeedChoice = zeros(1, count);
loadSpeedChoice = zeros(1, count);
for index = 1:count
    operation = frozen.reschedulable_operations(index);
    chromosomeIndex = sum(baseline.problem.operaNumVec( ...
        1:operation.job - 1)) + operation.operation;
    machineChoice(index) = MS(chromosomeIndex);
    agvAssignment(index) = AS(chromosomeIndex);
    freeSpeedChoice(index) = SS(2 * chromosomeIndex - 1);
    loadSpeedChoice(index) = SS(2 * chromosomeIndex);
end

decision = struct();
decision.source = 'baseline_chromosome_unstarted_suffix';
decision.operation_sequence = remainingSequence;
decision.machine_choice = machineChoice;
decision.agv_assignment = agvAssignment;
decision.free_speed_choice = freeSpeedChoice;
decision.load_speed_choice = loadSpeedChoice;
end
