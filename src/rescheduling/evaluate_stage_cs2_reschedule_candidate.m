function evaluation = evaluate_stage_cs2_reschedule_candidate( ...
        baseline, frozen, decision)
%evaluate_stage_cs2_reschedule_candidate Decode and score one decision.
%   Objectives are final-unload makespan and corrected total energy. All
%   interrupted operations use the C-S2 multiple restart decoder.

candidate = decode_stage_cs2_complete_reschedule( ...
    baseline, frozen, decision);
rescheduled = candidate.operation_records( ...
    strcmp({candidate.operation_records.status}, 'rescheduled'));

machineChanges = 0;
for index = 1:numel(rescheduled)
    machineChanges = machineChanges + ...
        (rescheduled(index).machine_id ~= ...
        rescheduled(index).baseline_machine_id);
end

evaluation = struct();
evaluation.decision = decision;
evaluation.candidate = candidate;
evaluation.objectives = [candidate.makespan, candidate.total_energy];
evaluation.objective_names = { ...
    'final_unload_makespan', 'total_energy'};
evaluation.machine_operation_makespan = candidate.machine_makespan;
evaluation.machine_assignment_changes = machineChanges;
evaluation.final_unload_makespan = candidate.makespan;
evaluation.machine_energy = candidate.machine_energy;
evaluation.agv_energy = candidate.agv_energy;
evaluation.total_energy = candidate.total_energy;
evaluation.interrupted_operation_count = ...
    numel(candidate.interrupted_commitments);
evaluation.repair_interval_count = numel(candidate.repair_intervals);
evaluation.restart_from_zero = true;
evaluation.progress_preserved = false;
evaluation.lost_processing_time = sum([candidate.interrupted_commitments.lost_processing_time]);
evaluation.total_machine_processing_time = sum([candidate.interrupted_commitments.total_machine_processing_time]);
evaluation.rank = [];
evaluation.crowding_distance = [];
evaluation.is_energy_evaluated = true;
evaluation.is_final_unload_evaluated = true;
evaluation.is_multiple_restart_operation_evaluated = ...
    candidate.is_stage_cs2_multiple_restart_operation_decoded;
evaluation.are_all_repair_intervals_evaluated = ...
    candidate.validation.all_repair_intervals_respected;
evaluation.is_validated = candidate.is_validated;
end
