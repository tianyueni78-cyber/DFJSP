function scenario = run_stage_a_state_snapshot()
%RUN_STAGE_A_STATE_SNAPSHOT Build and classify the Stage A fault state.
%   This entry extracts task state only. It does not alter the baseline or
%   perform right-shift or complete rescheduling.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'state'));

scenario = run_stage_a_fault_event();
scenario.state = extract_stage_a_state( ...
    scenario.baseline, scenario.fault);
scenario.is_state_extracted = true;
scenario.is_rescheduled = false;
end
