function decision = chromosome_to_full_decision(chrom, problem)
%CHROMOSOME_TO_FULL_DECISION Convert original OS/MS/AS/SS encoding.

operationCount = sum(problem.operaNumVec);
decision = struct();
decision.source = 'original_source_chromosome';
decision.operation_sequence = chrom(1:operationCount);
decision.machine_choice = ...
    chrom(operationCount + 1:2 * operationCount);
decision.agv_assignment = ...
    chrom(2 * operationCount + 1:3 * operationCount);
speeds = chrom(3 * operationCount + 1:5 * operationCount);
decision.free_speed_choice = speeds(1:2:end);
decision.load_speed_choice = speeds(2:2:end);
end
