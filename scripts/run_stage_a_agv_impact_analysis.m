function scenario = run_stage_a_agv_impact_analysis()
%RUN_STAGE_A_AGV_IMPACT_ANALYSIS Identify AGV tasks needing adjustment.
%   This entry performs analysis only and does not modify AGV tasks.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_a_machine_right_shift();
scenario.agv_impact = analyze_stage_a_agv_impact( ...
    scenario.baseline, scenario.right_shift);
scenario.is_agv_impact_identified = true;
scenario.is_agv_rescheduled = false;
scenario.is_rescheduled = false;
end
