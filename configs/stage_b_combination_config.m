function config = stage_b_combination_config()
%STAGE_B_COMBINATION_CONFIG Define the paper-based Stage B Y weights.

config = struct();
config.completion_time_weight = 0.9;
config.sequence_deviation_weight = 0.1;
config.tie_tolerance = 1e-9;
end
