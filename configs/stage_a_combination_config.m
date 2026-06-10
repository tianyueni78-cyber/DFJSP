function config = stage_a_combination_config()
%STAGE_A_COMBINATION_CONFIG Define the first paper-based Y weights.

config = struct();
config.completion_time_weight = 0.9;
config.sequence_deviation_weight = 0.1;
config.tie_tolerance = 1e-9;
end
