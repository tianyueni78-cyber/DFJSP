function combined = run_stage_a_combination_selection(searchScenario)
%RUN_STAGE_A_COMBINATION_SELECTION Reuse an existing complete search.

if nargin < 1 || ...
        ~isfield(searchScenario, 'complete_reschedule_search')
    error('run_stage_a_combination_selection:MissingSearch', ...
        'A scenario containing complete_reschedule_search is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

rightScenario = run_stage_a_agv_linked_right_shift();
validate_same_baseline(searchScenario, rightScenario);

combined = rightScenario;
combined.complete_reschedule_search = ...
    searchScenario.complete_reschedule_search;
combined.combination_config = stage_a_combination_config();
combined.combined_selection = select_stage_a_combined_strategy( ...
    combined.baseline, combined.state, ...
    combined.linked_right_shift, ...
    combined.complete_reschedule_search, ...
    combined.combination_config);
combined.is_combination_evaluated = true;
end

function validate_same_baseline(searchScenario, rightScenario)
required = {'baseline', 'fault'};
for index = 1:numel(required)
    if ~isfield(searchScenario, required{index})
        error('run_stage_a_combination_selection:MissingField', ...
            'searchScenario.%s is required.', required{index});
    end
end

sameChromosome = isequal( ...
    searchScenario.baseline.chrom, rightScenario.baseline.chrom);
sameMakespan = abs(searchScenario.baseline.makespan - ...
    rightScenario.baseline.makespan) <= 1e-9;
sameFault = searchScenario.fault.machine_id == ...
    rightScenario.fault.machine_id && ...
    abs(searchScenario.fault.start_time - ...
    rightScenario.fault.start_time) <= 1e-9 && ...
    abs(searchScenario.fault.repair_end_time - ...
    rightScenario.fault.repair_end_time) <= 1e-9;
if ~sameChromosome || ~sameMakespan || ~sameFault
    error('run_stage_a_combination_selection:ScenarioMismatch', ...
        'Complete search and right shift must share one baseline and fault.');
end
end
