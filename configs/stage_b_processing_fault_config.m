function config = stage_b_processing_fault_config()
%STAGE_B_PROCESSING_FAULT_CONFIG Define the first Stage B test event.
%   The operation and processing time come from the existing baseline.
%   Only the interruption fraction and repair duration are experiment
%   parameters; no new production data are generated.

config = struct();
config.trigger_job = 5;
config.trigger_operation = 1;
config.interruption_fraction = 0.5;
config.repair_duration = 5;
config.interruption_rule = 'unresolved';
end
