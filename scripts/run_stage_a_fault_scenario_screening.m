function result = run_stage_a_fault_scenario_screening()
%RUN_STAGE_A_FAULT_SCENARIO_SCREENING Screen original baseline triggers.
%   The current configured repair duration is reused. The configuration
%   file is not modified by this analysis.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'impact'));
addpath(fullfile(projectRoot, 'src', 'state'));

baseline = run_normal_schedule_baseline();
config = stage_a_fault_config();
screening = screen_stage_a_fault_scenarios( ...
    baseline, config.repair_duration);

result = struct();
result.baseline = baseline;
result.current_fault_config = config;
result.screening = screening;
result.config_modified = false;

print_screening_summary(screening);
end

function print_screening_summary(screening)
fprintf('Stage A fault scenario screening\n');
fprintf('repair duration: %.6g\n', screening.repair_duration);
fprintf('candidate count: %d\n', screening.candidate_count);
fprintf(['rank  trigger  machine  fault_time  next_op  idle_gap  ', ...
    'affected  max_delay\n']);
for index = 1:numel(screening.candidates)
    candidate = screening.candidates(index);
    fprintf('%4d  J%d-O%d%7d%12.6g  J%d-O%d%10.6g%10d%11.6g\n', ...
        index, candidate.trigger_job, candidate.trigger_operation, ...
        candidate.machine_id, candidate.fault_time, ...
        candidate.next_job, candidate.next_operation, ...
        candidate.machine_idle_gap, ...
        candidate.affected_operations_total, ...
        candidate.maximum_projected_delay);
end
end
