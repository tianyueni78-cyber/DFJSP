function scenario = run_stage_b_processing_fault_state(baseline)
%RUN_STAGE_B_PROCESSING_FAULT_STATE Build the Stage B Step 1 state.
%   This entry creates an in-process fault from the existing normal
%   baseline and calculates elapsed and remaining processing time only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'state'));

if nargin < 1
    baseline = run_normal_schedule_baseline();
    baselineSource = 'contract_normal_baseline';
else
    baselineSource = 'provided_normal_baseline';
end
if ~isstruct(baseline) || ...
        ~isfield(baseline, 'isFaultFreeBaseline') || ...
        ~baseline.isFaultFreeBaseline
    error('run_stage_b_processing_fault_state:InvalidBaseline', ...
        'A fault-free normal baseline is required.');
end
config = stage_b_processing_fault_config();
fault = create_processing_fault_event( ...
    baseline, config.trigger_job, config.trigger_operation, ...
    config.interruption_fraction, config.repair_duration);
state = extract_stage_b_interrupted_state(baseline, fault);

scenario = struct();
scenario.stage = 'B';
scenario.step = 1;
scenario.baseline = baseline;
scenario.baseline_source = baselineSource;
scenario.config = config;
scenario.fault = fault;
scenario.state = state;
scenario.interruption_rule_resolved = false;
scenario.is_rescheduled = false;
scenario.is_validated = fault.is_validated && state.is_validated;
end
