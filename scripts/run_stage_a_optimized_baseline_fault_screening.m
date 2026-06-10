function result = run_stage_a_optimized_baseline_fault_screening( ...
        normalScenario)
%RUN_STAGE_A_OPTIMIZED_BASELINE_FAULT_SCREENING Validate and select a fault.

if nargin < 1
    error('run_stage_a_optimized_baseline_fault_screening:MissingInput', ...
        'normalScenario from Stage A Step 10 is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'impact'));
addpath(fullfile(projectRoot, 'src', 'screening'));
addpath(fullfile(projectRoot, 'src', 'state'));

baseline = validate_normal_scenario(normalScenario);
config = stage_a_fault_config();

configuredFault = create_completion_fault_event( ...
    baseline, config.trigger_job, config.trigger_operation, ...
    config.repair_duration);
configuredState = extract_stage_a_state(baseline, configuredFault);
configuredImpact = identify_stage_a_affected_operations( ...
    baseline, configuredFault, configuredState);
configuredIsEffective = ...
    configuredImpact.counts.directly_affected > 0;

screening = screen_stage_a_fault_scenarios( ...
    baseline, config.repair_duration, 'optimized_normal_baseline');
if screening.candidate_count == 0
    error(['run_stage_a_optimized_baseline_fault_screening:', ...
        'NoEffectiveScenario'], ...
        'No effective completion-time fault exists for tr=%.6g.', ...
        config.repair_duration);
end

if configuredIsEffective
    selectedIndex = find_candidate(screening.candidates, ...
        config.trigger_job, config.trigger_operation);
    selectionReason = 'configured_trigger_remains_effective';
else
    selectedIndex = 1;
    selectionReason = 'configured_trigger_ineffective_use_rank_1';
end
selected = screening.candidates(selectedIndex);

selectedFault = create_completion_fault_event( ...
    baseline, selected.trigger_job, selected.trigger_operation, ...
    config.repair_duration);
selectedState = extract_stage_a_state(baseline, selectedFault);
selectedImpact = identify_stage_a_affected_operations( ...
    baseline, selectedFault, selectedState);

result = struct();
result.stage = 'A';
result.step = 11;
result.baseline = baseline;
result.baseline_source = 'stage_a_step_10_optimized_normal_baseline';
result.original_fault_config = config;
result.configured_fault = configuredFault;
result.configured_impact = configuredImpact;
result.configured_trigger_is_effective = configuredIsEffective;
result.screening = screening;
result.selected_candidate_rank = selectedIndex;
result.selected_candidate = selected;
result.selected_fault = selectedFault;
result.selected_state = selectedState;
result.selected_impact = selectedImpact;
result.selection_reason = selectionReason;
result.config_modified = false;
result.additional_problem_data_generated = false;
result.is_validated = validate_result(result);

print_summary(result);
end

function baseline = validate_normal_scenario(normalScenario)
required = {'optimized_baseline', 'normal_search', ...
    'is_source_data_only', 'is_fault_free'};
for index = 1:numel(required)
    if ~isfield(normalScenario, required{index})
        error('run_stage_a_optimized_baseline_fault_screening:InputField', ...
            'normalScenario.%s is required.', required{index});
    end
end
if ~normalScenario.is_source_data_only || ...
        ~normalScenario.is_fault_free || ...
        ~normalScenario.normal_search.is_validated
    error('run_stage_a_optimized_baseline_fault_screening:InvalidInput', ...
        'A validated source-data Step 10 scenario is required.');
end
baseline = normalScenario.optimized_baseline;
if ~baseline.isFaultFreeBaseline
    error('run_stage_a_optimized_baseline_fault_screening:Baseline', ...
        'The optimized baseline must be fault-free.');
end
end

function index = find_candidate(candidates, jobId, operationId)
matches = find([candidates.trigger_job] == jobId & ...
    [candidates.trigger_operation] == operationId);
if numel(matches) ~= 1
    error('run_stage_a_optimized_baseline_fault_screening:Candidate', ...
        'The effective configured trigger must appear exactly once.');
end
index = matches;
end

function result = validate_result(value)
selected = value.selected_candidate;
fault = value.selected_fault;
impact = value.selected_impact;
result = value.screening.is_validated && ...
    fault.is_validated && impact.is_validated && ...
    impact.counts.directly_affected > 0 && ...
    selected.trigger_job == fault.trigger_job && ...
    selected.trigger_operation == fault.trigger_operation && ...
    selected.machine_id == fault.machine_id && ...
    abs(selected.fault_time - fault.start_time) <= 1e-9 && ...
    ~value.config_modified && ...
    ~value.additional_problem_data_generated;
if ~result
    error('run_stage_a_optimized_baseline_fault_screening:InvalidResult', ...
        'The Step 11 result failed validation.');
end
end

function print_summary(result)
configured = result.configured_fault;
selected = result.selected_candidate;
fprintf('Stage A Step 11 optimized-baseline fault screening\n');
fprintf('optimized baseline makespan: %.6g\n', ...
    result.baseline.makespan);
fprintf('configured trigger: J%d-O%d, M%d, tf=%.6g, tr=%.6g\n', ...
    configured.trigger_job, configured.trigger_operation, ...
    configured.machine_id, configured.start_time, ...
    configured.repair_duration);
fprintf('configured trigger effective: %d\n', ...
    result.configured_trigger_is_effective);
fprintf('effective candidate count: %d\n', ...
    result.screening.candidate_count);
fprintf(['selected rank: %d, trigger: J%d-O%d, M%d, tf=%.6g, ', ...
    'affected=%d, max_delay=%.6g\n'], ...
    result.selected_candidate_rank, selected.trigger_job, ...
    selected.trigger_operation, selected.machine_id, ...
    selected.fault_time, selected.affected_operations_total, ...
    selected.maximum_projected_delay);
fprintf('selection reason: %s\n', result.selection_reason);
end
