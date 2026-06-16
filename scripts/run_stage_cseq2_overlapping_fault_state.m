function scenario = run_stage_cseq2_overlapping_fault_state(stage12)
%RUN_STAGE_CSEQ2_OVERLAPPING_FAULT_STATE Build C-SEQ2 Step 1.
%   Select a next fault whose start time overlaps an unfinished previous
%   repair interval. No impact propagation or rescheduling is performed.

if nargin < 1
    stage12 = run_stage_c_plan_version_history();
end
if stage12.step ~= 12 || ~stage12.is_validated
    error('run_stage_cseq2_overlapping_fault_state:InvalidInput', ...
        'A validated Stage C Step 12 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'screening'));
addpath(fullfile(projectRoot, 'src', 'state'));

activeVersion = stage12.plan_version_history.versions(end);
currentView = build_stage_c_current_plan_view( ...
    stage12.baseline, activeVersion);
config = stage_c_simultaneous_fault_config();
screening = screen_stage_cseq2_overlapping_next_fault_event( ...
    currentView, stage12.faults, config.repair_duration);
selected = screening.selected_candidate;

raw = struct();
raw.event_id = max([stage12.faults.event_id]) + 1;
raw.machine_id = selected.machine_id;
raw.start_time = selected.fault_time;
raw.repair_duration = selected.repair_duration;
raw.interruption_rule = config.interruption_rule;
nextFault = normalize_stage_c_fault_events( ...
    raw, stage12.baseline.problem.machineNum);
nextFault.event_group = max([stage12.faults.event_group]) + 1;

sequential = extract_stage_c_sequential_fault_state( ...
    stage12.baseline, stage12.plan_version_history, ...
    stage12.faults, nextFault);

scenario = stage12;
scenario.cseq2_overlapping_fault_screening = screening;
scenario.next_fault = nextFault;
scenario.next_fault_state = sequential;
scenario.step = 'C-SEQ2.1';
scenario.substep = '1';
scenario.is_next_fault_processed = true;
scenario.is_overlapping_repair_scenario = true;
scenario.is_impact_propagated = false;
scenario.is_plan_modified_in_cseq2_step_1 = false;
scenario.is_search_executed_in_cseq2_step_1 = false;
scenario.is_validated = scenario.is_validated && ...
    screening.is_validated && sequential.is_validated && ...
    validate_scenario(stage12, nextFault, sequential);
end

function result = validate_scenario(stage12, nextFault, sequential)
previousRepairEnd = max([stage12.faults.repair_end_time]);
previousRepairStart = min([stage12.faults.start_time]);
result = nextFault.start_time > previousRepairStart + 1e-9 && ...
    nextFault.start_time < previousRepairEnd - 1e-9 && ...
    sequential.active_previous_repair_count > 0 && ...
    sequential.history_unchanged && ~sequential.is_plan_modified && ...
    sequential.state.counts.fault_in_progress_operations == 1;
if ~result
    error('run_stage_cseq2_overlapping_fault_state:InvalidScenario', ...
        'C-SEQ2 overlapping repair scenario failed validation.');
end
end
