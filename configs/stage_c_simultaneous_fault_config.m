function config = stage_c_simultaneous_fault_config()
%STAGE_C_SIMULTANEOUS_FAULT_CONFIG Define Stage C first scenario rules.
%   Production data remain unchanged. Only fault experiment parameters are
%   defined here.

config = struct();
config.fault_count = 2;
config.repair_duration = 5;
config.interruption_rule = 'resume_remaining';
config.selection_rule = [ ...
    'repair-overlap operations desc, overlap duration desc, ', ...
    'fault time asc, machine ids asc'];
end
