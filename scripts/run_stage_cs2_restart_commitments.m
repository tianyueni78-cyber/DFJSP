function scenario = run_stage_cs2_restart_commitments(baseline)
%RUN_STAGE_CS2_RESTART_COMMITMENTS Build C-S2 Step 1.
%   This entry reuses the Stage C simultaneous-fault scenario but changes
%   the interruption rule to restart_from_zero. It only builds fixed
%   interrupted-operation commitments; it does not propagate impacts or
%   modify any machine or AGV schedule.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'state'));

if nargin < 1
    scenario = run_stage_c_simultaneous_fault_scenario();
else
    scenario = run_stage_c_simultaneous_fault_scenario(baseline);
end

scenario.faults = convert_faults_to_restart_from_zero( ...
    scenario.faults, scenario.baseline.problem.machineNum);
scenario.unavailability = build_stage_c_machine_unavailability( ...
    scenario.faults, scenario.baseline.problem.machineNum);
scenario.state = extract_stage_c_event_group_state( ...
    scenario.baseline, scenario.faults, 1);
scenario.cs2_restart_commitments = ...
    build_stage_c_simultaneous_restart_commitments( ...
    scenario.faults, scenario.state);

scenario.extension = 'C-S2';
scenario.step = 'C-S2.1';
scenario.interruption_rule = 'restart_from_zero';
scenario.restart_commitments_built = true;
scenario.impact_propagated = false;
scenario.is_rescheduled = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.unavailability.is_validated && ...
    scenario.state.is_validated && ...
    all([scenario.cs2_restart_commitments.is_validated]) && ...
    all(~[scenario.cs2_restart_commitments.progress_preserved]) && ...
    all([scenario.cs2_restart_commitments.restart_from_zero]);
if ~scenario.is_validated
    error('run_stage_cs2_restart_commitments:InvalidScenario', ...
        'C-S2 restart commitments are inconsistent.');
end
end

function faults = convert_faults_to_restart_from_zero( ...
        originalFaults, machineCount)
rawFaults = repmat(raw_fault_template(), 1, numel(originalFaults));
for index = 1:numel(originalFaults)
    rawFaults(index).event_id = originalFaults(index).event_id;
    rawFaults(index).machine_id = originalFaults(index).machine_id;
    rawFaults(index).start_time = originalFaults(index).start_time;
    rawFaults(index).repair_duration = ...
        originalFaults(index).repair_duration;
    rawFaults(index).interruption_rule = 'restart_from_zero';
end
faults = normalize_stage_c_fault_events(rawFaults, machineCount);
end

function value = raw_fault_template()
value = struct('event_id', [], 'machine_id', [], 'start_time', [], ...
    'repair_duration', [], 'repair_end_time', [], ...
    'interruption_rule', '');
end
