function scenario = run_stage_c_simultaneous_fault_scenario(baseline)
%RUN_STAGE_C_SIMULTANEOUS_FAULT_SCENARIO Build Stage C Step 4 scenario.
%   The scenario is selected from the supplied source-data baseline. No
%   impact propagation or schedule modification is performed.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'screening'));
addpath(fullfile(projectRoot, 'src', 'state'));

if nargin < 1
    baseline = run_normal_schedule_baseline();
    baselineSource = 'original_normal_baseline';
else
    baselineSource = 'provided_source_data_baseline';
end
config = stage_c_simultaneous_fault_config();
screening = screen_stage_c_simultaneous_fault_scenarios( ...
    baseline, config);
selected = screening.candidates(1);

rawFaults = repmat(raw_fault_template(), 1, config.fault_count);
for index = 1:config.fault_count
    rawFaults(index).event_id = index;
    rawFaults(index).machine_id = selected.machine_ids(index);
    rawFaults(index).start_time = selected.fault_time;
    rawFaults(index).repair_duration = config.repair_duration;
    rawFaults(index).interruption_rule = config.interruption_rule;
end
faults = normalize_stage_c_fault_events( ...
    rawFaults, baseline.problem.machineNum);
unavailability = build_stage_c_machine_unavailability( ...
    faults, baseline.problem.machineNum);
state = extract_stage_c_event_group_state(baseline, faults, 1);

scenario = struct();
scenario.stage = 'C';
scenario.step = 4;
scenario.baseline = baseline;
scenario.baseline_source = baselineSource;
scenario.config = config;
scenario.screening = screening;
scenario.selected_candidate_rank = 1;
scenario.selected_candidate = selected;
scenario.faults = faults;
scenario.unavailability = unavailability;
scenario.state = state;
scenario.additional_problem_data_generated = false;
scenario.impact_propagated = false;
scenario.is_rescheduled = false;
scenario.is_validated = validate_scenario(scenario);
end

function result = validate_scenario(value)
result = value.screening.is_validated && ...
    all([value.faults.is_validated]) && ...
    value.unavailability.is_validated && ...
    value.state.is_validated && ...
    numel(value.faults) == value.config.fault_count && ...
    numel(unique([value.faults.machine_id])) == ...
    value.config.fault_count && ...
    numel(unique([value.faults.start_time])) == 1 && ...
    value.state.counts.fault_in_progress_operations == ...
    value.config.fault_count && ...
    ~value.additional_problem_data_generated && ...
    ~value.impact_propagated && ~value.is_rescheduled;
if ~result
    error('run_stage_c_simultaneous_fault_scenario:InvalidScenario', ...
        'The selected simultaneous-fault scenario is inconsistent.');
end
end

function value = raw_fault_template()
value = struct('event_id', [], 'machine_id', [], 'start_time', [], ...
    'repair_duration', [], 'repair_end_time', [], ...
    'interruption_rule', '');
end
