function config = stage_br_combination_config()
%STAGE_BR_COMBINATION_CONFIG Define the paper-based Stage B-R Y weights.

config = struct();
config.completion_time_weight = 0.9;
config.sequence_deviation_weight = 0.1;
config.tie_tolerance = 1e-9;
end

