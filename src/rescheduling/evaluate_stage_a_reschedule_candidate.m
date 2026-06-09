function evaluation = evaluate_stage_a_reschedule_candidate( ...
        baseline, frozen, decision)
%EVALUATE_STAGE_A_RESCHEDULE_CANDIDATE Decode and score one decision.
%   Objectives are limited to values currently computed completely:
%   machine-operation makespan and machine-assignment changes.

candidate = decode_stage_a_complete_reschedule( ...
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
evaluation.objectives = [candidate.machine_makespan, machineChanges];
evaluation.objective_names = { ...
    'machine_operation_makespan', ...
    'machine_assignment_changes'};
evaluation.machine_operation_makespan = ...
    candidate.machine_makespan;
evaluation.machine_assignment_changes = machineChanges;
evaluation.rank = [];
evaluation.crowding_distance = [];
evaluation.is_energy_evaluated = false;
evaluation.is_final_unload_evaluated = false;
evaluation.is_validated = candidate.is_validated;
end
