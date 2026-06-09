function config = stage_a_fault_config()
%STAGE_A_FAULT_CONFIG Define the selected source-data Stage A scenario.

config = struct();
config.trigger_job = 5;
config.trigger_operation = 1;
config.repair_duration = 5;
end
