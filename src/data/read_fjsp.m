function problem = read_fjsp(instancePath)
%READ_FJSP Read an FJSP instance without creating data.mat.

if nargin < 1
    error('read_fjsp:MissingInput', 'instancePath is required.');
end

[fileID, message] = fopen(instancePath, 'r');
if isequal(fileID, -1)
    error('read_fjsp:OpenFailed', '%s', message);
end
cleanupObj = onCleanup(@() fclose(fileID));

firstLine = strip(fgetl(fileID));
firstLineValues = split(firstLine);
jobNum = str2double(firstLineValues{1});
machineNum = str2double(firstLineValues{2});

operaNumVec = zeros(1, jobNum);
jobInfo = cell(1, jobNum);
for job = 1:jobNum
    lineValues = split(strip(fgetl(fileID)));
    operaNum = str2double(lineValues{1});
    operaNumVec(job) = operaNum;
    valueIndex = 2;

    for operation = 1:operaNum
        candidateCount = str2double(lineValues{valueIndex});
        processingTimes = inf(1, machineNum);
        for candidate = 1:candidateCount
            valueIndex = valueIndex + 1;
            machine = str2double(lineValues{valueIndex});
            valueIndex = valueIndex + 1;
            processingTimes(machine) = str2double(lineValues{valueIndex});
        end
        jobInfo{job} = [jobInfo{job}; processingTimes];
        valueIndex = valueIndex + 1;
    end
end

candidateMachine = cell(jobNum, max(operaNumVec));
for job = 1:jobNum
    for operation = 1:operaNumVec(job)
        candidateMachine{job, operation} = ...
            find(jobInfo{job}(operation, :) < Inf);
    end
end

problem = struct();
problem.jobNum = jobNum;
problem.machineNum = machineNum;
problem.operaNumVec = operaNumVec;
problem.jobInfo = jobInfo;
problem.candidateMachine = candidateMachine;
end
