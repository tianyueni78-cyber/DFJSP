function run_all_contract_tests()
clc

repoRoot = fileparts(fileparts(mfilename('fullpath')));

contractTestCases = {
    'A', 'stage A config contract', fullfile(repoRoot, 'tests', 'test_small_nsga2_config.m')
    'A', 'stage A NSGA-II smoke', fullfile(repoRoot, 'tests', 'test_small_nsga2.m')
    'B', 'stage B small search loop', fullfile(repoRoot, 'tests', 'test_search_small_loop.m')
    'B-R', 'stage B-R decoding compare raw sorting', fullfile(repoRoot, 'tests', 'test_decoding_independent_compare_sorting.m')
    'B-R', 'stage B-R evaluation compare raw', fullfile(repoRoot, 'tests', 'test_evaluation_independent_compare_raw.m')
    'C', 'stage C independent search compare raw', fullfile(repoRoot, 'tests', 'test_search_independent_compare_raw.m')
    'C-S2', 'stage C-S2 independent config contract', fullfile(repoRoot, 'tests', 'test_independent_experiment_configs.m')
    'C-S2', 'stage C-S2 formal preflight', fullfile(repoRoot, 'tests', 'test_independent_formal_preflight.m')
    'C-SEQ2', 'stage C-SEQ2 multiseed summary dryrun', fullfile(repoRoot, 'tests', 'test_independent_multiseed_summary_dryrun.m')
};

testCount = size(contractTestCases, 1);
originalDir = pwd;
cleanup = onCleanup(@() cd(originalDir));

for i = 1:testCount
    stageLabel = contractTestCases{i, 1};
    testName = contractTestCases{i, 2};
    testPath = contractTestCases{i, 3};

    assert(isfile(testPath), 'Missing test file: %s', testPath);

    cd(repoRoot);
    fprintf('\n[%d/%d] %s (%s)\n%s\n', i, testCount, testName, stageLabel, testPath);
    evalin('base', sprintf('run(''%s'')', escape_matlab_path(testPath)));
end

fprintf('\nAll contract tests passed.\n');
end

function escapedPath = escape_matlab_path(testPath)
escapedPath = strrep(testPath, '''', '''''');
end
