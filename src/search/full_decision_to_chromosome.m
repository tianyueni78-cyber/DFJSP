function chrom = full_decision_to_chromosome(decision)
%FULL_DECISION_TO_CHROMOSOME Convert decision fields to OS/MS/AS/SS.

operationCount = numel(decision.operation_sequence);
speeds = zeros(1, 2 * operationCount);
speeds(1:2:end) = decision.free_speed_choice;
speeds(2:2:end) = decision.load_speed_choice;
chrom = [decision.operation_sequence, ...
    decision.machine_choice, decision.agv_assignment, speeds];
end
