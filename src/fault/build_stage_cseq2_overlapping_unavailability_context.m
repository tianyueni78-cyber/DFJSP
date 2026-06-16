function context = build_stage_cseq2_overlapping_unavailability_context( ...
        scenario)
%BUILD_STAGE_CSEQ2_OVERLAPPING_UNAVAILABILITY_CONTEXT Build C-SEQ2 Step 2.
%   Historical repairs and the new repair are preserved together. Same-
%   machine overlaps are normalized by build_stage_c_machine_unavailability.

if nargin < 1 || ~isfield(scenario, 'next_fault') || ...
        ~isfield(scenario, 'next_fault_state') || ...
        ~strcmp(scenario.step, 'C-SEQ2.1') || ~scenario.is_validated
    error('build_stage_cseq2_overlapping_unavailability_context:InvalidInput', ...
        'A validated C-SEQ2 Step 1 scenario is required.');
end

previousFaults = scenario.faults;
nextFault = scenario.next_fault;
cumulativeFaults = [previousFaults, nextFault];
unavailability = build_stage_c_machine_unavailability( ...
    cumulativeFaults, scenario.baseline.problem.machineNum);
relationships = identify_overlap_relationships(previousFaults, nextFault);

context = struct();
context.stage = 'C-SEQ2';
context.step = '2';
context.previous_faults = previousFaults;
context.next_fault = nextFault;
context.cumulative_faults = cumulativeFaults;
context.active_previous_repairs = ...
    scenario.next_fault_state.active_previous_repairs;
context.active_previous_repair_count = ...
    scenario.next_fault_state.active_previous_repair_count;
context.cumulative_unavailability = unavailability;
context.overlap_relationships = relationships;
context.overlap_count = numel(relationships);
context.same_machine_overlap_count = ...
    sum([relationships.same_machine]);
context.different_machine_overlap_count = ...
    sum(~[relationships.same_machine]);
context.history_unchanged = true;
context.is_impact_propagated = false;
context.is_plan_modified = false;
context.is_rescheduled = false;
context.is_validated = validate_context(context, scenario);
end

function relationships = identify_overlap_relationships(previousFaults, nextFault)
template = relationship_template();
relationships = template([]);
for index = 1:numel(previousFaults)
    previous = previousFaults(index);
    overlapStart = max(previous.start_time, nextFault.start_time);
    overlapEnd = min(previous.repair_end_time, nextFault.repair_end_time);
    if overlapEnd <= overlapStart + 1e-9
        continue
    end
    relationship = template;
    relationship.previous_event_id = previous.event_id;
    relationship.next_event_id = nextFault.event_id;
    relationship.previous_machine_id = previous.machine_id;
    relationship.next_machine_id = nextFault.machine_id;
    relationship.same_machine = ...
        previous.machine_id == nextFault.machine_id;
    relationship.overlap_start = overlapStart;
    relationship.overlap_end = overlapEnd;
    relationship.overlap_duration = overlapEnd - overlapStart;
    relationship.is_active_at_next_fault = ...
        previous.repair_end_time > nextFault.start_time + 1e-9;
    relationships(end + 1) = relationship;
end
end

function result = validate_context(context, scenario)
nextFault = context.next_fault;
relationships = context.overlap_relationships;
result = context.cumulative_unavailability.is_validated && ...
    context.active_previous_repair_count > 0 && ...
    context.overlap_count > 0 && ...
    context.different_machine_overlap_count >= 0 && ...
    context.history_unchanged && ~context.is_impact_propagated && ...
    ~context.is_plan_modified && ~context.is_rescheduled && ...
    isequal([context.active_previous_repairs.event_id], ...
    [scenario.next_fault_state.active_previous_repairs.event_id]);
for index = 1:numel(relationships)
    relation = relationships(index);
    result = result && relation.next_event_id == nextFault.event_id && ...
        relation.overlap_duration > 0 && ...
        relation.is_active_at_next_fault;
end
coveredEventIds = [];
intervals = context.cumulative_unavailability.intervals;
for index = 1:numel(intervals)
    coveredEventIds = [coveredEventIds, intervals(index).source_event_ids];
end
result = result && isequal(sort(coveredEventIds), ...
    sort([context.cumulative_faults.event_id]));
if ~result
    error('build_stage_cseq2_overlapping_unavailability_context:InvalidContext', ...
        'C-SEQ2 overlapping unavailability context failed validation.');
end
end

function value = relationship_template()
value = struct('previous_event_id', [], 'next_event_id', [], ...
    'previous_machine_id', [], 'next_machine_id', [], ...
    'same_machine', false, 'overlap_start', [], 'overlap_end', [], ...
    'overlap_duration', [], 'is_active_at_next_fault', false);
end
