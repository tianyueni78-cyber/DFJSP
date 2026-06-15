function scenario = run_stage_c_simultaneous_impact_analysis(baseline)
%RUN_STAGE_C_SIMULTANEOUS_IMPACT_ANALYSIS Build Stage C Step 5 impact.
%   Projected times are calculated only. Machine and AGV tables remain
%   unchanged.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_c_simultaneous_fault_scenario();
else
    scenario = run_stage_c_simultaneous_fault_scenario(baseline);
end
machineTableBefore = scenario.baseline.machineTable;
agvTableBefore = scenario.baseline.AGVTable;
scenario.impact = identify_stage_c_simultaneous_affected_operations( ...
    scenario.baseline, scenario.state, scenario.faults);
scenario.step = 5;
scenario.impact_propagated = true;
scenario.successor_propagation_executed = true;
scenario.is_rescheduled = false;
scenario.source_machine_table_unchanged = ...
    isequaln(machineTableBefore, scenario.baseline.machineTable);
scenario.source_agv_table_unchanged = ...
    isequaln(agvTableBefore, scenario.baseline.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.impact.is_validated && ...
    scenario.source_machine_table_unchanged && ...
    scenario.source_agv_table_unchanged;
end
