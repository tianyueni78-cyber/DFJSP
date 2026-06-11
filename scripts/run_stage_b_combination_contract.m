function scenario = run_stage_b_combination_contract()
%RUN_STAGE_B_COMBINATION_CONTRACT Compare both strategies on a tiny search.
%   This reuses the 6-by-2 contract search and creates no output files.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

searchScenario = run_stage_b_restricted_search_contract();
searchScenario.complete_reschedule_search = ...
    searchScenario.restricted_search;
scenario = run_stage_b_combination_selection(searchScenario);
end
