function scenario = run_stage_cs2_agv_impact_analysis(baseline)
%RUN_STAGE_CS2_AGV_IMPACT_ANALYSIS Build C-S2 Step 4.
%   AGV tasks invalidated by the restart-rule machine candidate are
%   identified without changing AGV routes, assignments, times, charging,
%   or energy records.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_cs2_machine_right_shift();
else
    scenario = run_stage_cs2_machine_right_shift(baseline);
end
baselineAGVTable = scenario.baseline.AGVTable;
candidateAGVTable = scenario.cs2_machine_right_shift.AGVTable;

scenario.cs2_agv_impact = analyze_stage_cs2_agv_impact( ...
    scenario.baseline, scenario.faults, ...
    scenario.cs2_machine_right_shift);
scenario.step = 'C-S2.4';
scenario.is_agv_impact_identified = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.source_agv_table_unchanged = ...
    isequaln(baselineAGVTable, scenario.baseline.AGVTable) && ...
    isequaln(candidateAGVTable, ...
    scenario.cs2_machine_right_shift.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.cs2_agv_impact.is_validated && ...
    scenario.source_agv_table_unchanged;
if ~scenario.is_validated
    error('run_stage_cs2_agv_impact_analysis:InvalidScenario', ...
        'C-S2 AGV impact analysis is inconsistent.');
end
end
