function searchProblem = build_normal_search_problem(problem)
%BUILD_NORMAL_SEARCH_PROBLEM Build full-operation decision ranges.
%   All ranges are derived from the original problem instance.

operationCount = sum(problem.operaNumVec);
operations = repmat(operation_template(), 1, operationCount);
index = 0;
for jobId = 1:problem.jobNum
    for operationId = 1:problem.operaNumVec(jobId)
        index = index + 1;
        operations(index).job = jobId;
        operations(index).operation = operationId;
        operations(index).candidate_machines = ...
            problem.candidateMachine{jobId, operationId};
    end
end

searchProblem = struct();
searchProblem.reschedulable_operations = operations;
searchProblem.is_validated = ...
    numel(operations) == operationCount && ...
    all(arrayfun(@(item) ...
    ~isempty(item.candidate_machines), operations));
end

function value = operation_template()
value = struct('job', [], 'operation', [], ...
    'candidate_machines', []);
end
