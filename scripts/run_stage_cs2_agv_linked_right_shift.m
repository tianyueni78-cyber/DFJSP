function scenario = run_stage_cs2_agv_linked_right_shift(baseline)
%RUN_STAGE_CS2_AGV_LINKED_RIGHT_SHIFT Build C-S2 Step 5.
%   A restart-rule machine-only candidate and its AGV impact analysis are
%   coupled into a machine-plus-AGV feasible partial right-shift candidate.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_cs2_agv_impact_analysis();
else
    scenario = run_stage_cs2_agv_impact_analysis(baseline);
end
scenario.cs2_linked_right_shift = build_stage_cs2_agv_linked_right_shift( ...
    scenario.baseline, scenario.faults, ...
    scenario.cs2_machine_right_shift, scenario.cs2_agv_impact);
scenario.step = 'C-S2.5';
scenario.is_agv_rescheduled = true;
scenario.is_agv_updated = ...
    scenario.cs2_linked_right_shift.is_agv_updated;
scenario.is_fully_validated = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.cs2_linked_right_shift.is_fully_validated;
if ~scenario.is_validated
    error('run_stage_cs2_agv_linked_right_shift:InvalidScenario', ...
        'C-S2 AGV-linked right-shift candidate is inconsistent.');
end
end
