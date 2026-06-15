function config = stage_c_combination_config()
%STAGE_C_COMBINATION_CONFIG Define paper-based Stage C Y weights.

config = struct();
config.completion_time_weight = 0.9;
config.sequence_deviation_weight = 0.1;
config.tie_tolerance = 1e-9;
end
