function scenario = run_stage_c_simultaneous_machine_right_shift(baseline)
%RUN_STAGE_C_SIMULTANEOUS_MACHINE_RIGHT_SHIFT Build Stage C Step 6.
%   Machine times are updated; AGV tasks are intentionally unchanged.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_c_simultaneous_impact_analysis();
else
    scenario = run_stage_c_simultaneous_impact_analysis(baseline);
end
baselineMachineTable = scenario.baseline.machineTable;
baselineAGVTable = scenario.baseline.AGVTable;
scenario.machine_right_shift = ...
    build_stage_c_simultaneous_machine_right_shift( ...
    scenario.baseline, scenario.faults, scenario.state, ...
    scenario.impact);
scenario.step = 6;
scenario.is_machine_right_shift_built = true;
scenario.is_rescheduled = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.source_machine_table_unchanged = ...
    isequaln(baselineMachineTable, scenario.baseline.machineTable);
scenario.source_agv_table_unchanged = ...
    isequaln(baselineAGVTable, scenario.baseline.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.machine_right_shift.is_machine_validated && ...
    scenario.source_machine_table_unchanged && ...
    scenario.source_agv_table_unchanged;
end
