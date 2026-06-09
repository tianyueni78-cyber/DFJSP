function config = stage_a_fault_config()
%STAGE_A_FAULT_CONFIG Define the first completion-time fault scenario.

config = struct();
config.trigger_job = 1;
config.trigger_operation = 1;
config.repair_duration = 5;
end
