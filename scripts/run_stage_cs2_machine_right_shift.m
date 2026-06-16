function scenario = run_stage_cs2_machine_right_shift(baseline)
%RUN_STAGE_CS2_MACHINE_RIGHT_SHIFT Build C-S2 Step 3.
%   The C-S2 restart commitments and propagated successor times are
%   written into a machine-only right-shift candidate. AGV tasks are still
%   copied unchanged.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_cs2_impact_analysis();
else
    scenario = run_stage_cs2_impact_analysis(baseline);
end
machineTableBefore = scenario.baseline.machineTable;
agvTableBefore = scenario.baseline.AGVTable;

scenario.cs2_machine_right_shift = build_stage_cs2_machine_right_shift( ...
    scenario.baseline, scenario.faults, scenario.state, ...
    scenario.cs2_restart_commitments, scenario.cs2_impact);
scenario.step = 'C-S2.3';
scenario.is_machine_right_shift_built = true;
scenario.is_rescheduled = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.source_machine_table_unchanged = ...
    isequaln(machineTableBefore, scenario.baseline.machineTable);
scenario.source_agv_table_unchanged = ...
    isequaln(agvTableBefore, scenario.baseline.AGVTable);
scenario.is_validated = scenario.is_validated && ...
    scenario.cs2_machine_right_shift.is_machine_validated && ...
    scenario.source_machine_table_unchanged && ...
    scenario.source_agv_table_unchanged;
if ~scenario.is_validated
    error('run_stage_cs2_machine_right_shift:InvalidScenario', ...
        'C-S2 machine right-shift candidate is inconsistent.');
end
end
