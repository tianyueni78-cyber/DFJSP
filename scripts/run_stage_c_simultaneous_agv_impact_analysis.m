function scenario = run_stage_c_simultaneous_agv_impact_analysis(baseline)
%RUN_STAGE_C_SIMULTANEOUS_AGV_IMPACT_ANALYSIS Build Stage C Step 7.
%   Invalid and review-required transports are identified only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_c_simultaneous_machine_right_shift();
else
    scenario = run_stage_c_simultaneous_machine_right_shift(baseline);
end
baselineAGVTable = scenario.baseline.AGVTable;
candidateAGVTable = scenario.machine_right_shift.AGVTable;
scenario.agv_impact = analyze_stage_c_simultaneous_agv_impact( ...
    scenario.baseline, scenario.faults, ...
    scenario.machine_right_shift);
scenario.step = 7;
scenario.is_agv_impact_identified = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.source_agv_table_unchanged = ...
    isequaln(baselineAGVTable, scenario.baseline.AGVTable) && ...
    isequaln(candidateAGVTable, ...
    scenario.machine_right_shift.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.agv_impact.is_validated && ...
    scenario.source_agv_table_unchanged;
end
