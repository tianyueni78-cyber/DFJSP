function scenario = run_stage_cs2_combination_contract()
%RUN_STAGE_CS2_COMBINATION_CONTRACT Run a no-output C-S2 Step 11 contract.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

searchScenario = run_stage_cs2_restricted_search_contract();
searchScenario.complete_reschedule_search = ...
    searchScenario.restricted_search;
scenario = run_stage_cs2_combination_selection(searchScenario);
end
