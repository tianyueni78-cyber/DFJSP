function evaluation = evaluate_stage_b_reschedule_candidate( ...
        baseline, frozen, decision)
%EVALUATE_STAGE_B_RESCHEDULE_CANDIDATE Decode and score one decision.
%   Objectives are final-unload makespan and corrected total energy. The
%   interrupted operation is evaluated through the Stage B split decoder.

candidate = decode_stage_b_complete_reschedule( ...
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
evaluation.rank = [];
evaluation.crowding_distance = [];
evaluation.is_energy_evaluated = true;
evaluation.is_final_unload_evaluated = true;
evaluation.is_split_operation_evaluated = ...
    candidate.is_stage_b_split_operation_decoded;
evaluation.is_validated = candidate.is_validated;
end
