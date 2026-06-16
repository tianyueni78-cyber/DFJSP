function scenario = run_stage_cs2_impact_analysis(baseline)
%RUN_STAGE_CS2_IMPACT_ANALYSIS Build C-S2 Step 2 impact.
%   The restart commitments from C-S2 Step 1 are propagated through job
%   and machine successors. No machine or AGV table is modified.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_cs2_restart_commitments();
else
    scenario = run_stage_cs2_restart_commitments(baseline);
end
machineTableBefore = scenario.baseline.machineTable;
agvTableBefore = scenario.baseline.AGVTable;

scenario.cs2_impact = identify_stage_cs2_restart_affected_operations( ...
    scenario.baseline, scenario.state, ...
    scenario.cs2_restart_commitments);
scenario.step = 'C-S2.2';
scenario.impact_propagated = true;
scenario.successor_propagation_executed = true;
scenario.is_rescheduled = false;
scenario.source_machine_table_unchanged = ...
    isequaln(machineTableBefore, scenario.baseline.machineTable);
scenario.source_agv_table_unchanged = ...
    isequaln(agvTableBefore, scenario.baseline.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.cs2_impact.is_validated && ...
    scenario.source_machine_table_unchanged && ...
    scenario.source_agv_table_unchanged;
if ~scenario.is_validated
    error('run_stage_cs2_impact_analysis:InvalidScenario', ...
        'C-S2 impact propagation is inconsistent.');
end
end
