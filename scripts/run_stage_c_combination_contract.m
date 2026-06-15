function scenario = run_stage_c_combination_contract()
%RUN_STAGE_C_COMBINATION_CONTRACT Run a no-output Stage C Step 11 contract.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

searchScenario = run_stage_c_simultaneous_restricted_search_contract();
searchScenario.complete_reschedule_search = ...
    searchScenario.restricted_search;
scenario = run_stage_c_combination_selection(searchScenario);
end
