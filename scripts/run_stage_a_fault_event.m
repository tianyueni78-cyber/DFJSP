function scenario = run_stage_a_fault_event()
%RUN_STAGE_A_FAULT_EVENT Build the Stage A baseline and one fault event.
%   This entry only defines and validates the event. It does not extract
%   system state or perform rescheduling.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));

baseline = run_normal_schedule_baseline();
config = stage_a_fault_config();
fault = create_completion_fault_event( ...
    baseline, config.trigger_job, config.trigger_operation, ...
    config.repair_duration);

scenario = struct();
scenario.baseline = baseline;
scenario.fault = fault;
scenario.config = config;
scenario.stage = 'A';
scenario.is_rescheduled = false;
end
