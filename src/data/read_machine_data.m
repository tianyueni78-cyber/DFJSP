function machineData = read_machine_data(excelPath, machineNum)
%READ_MACHINE_DATA Read machine distance and energy data without writes.

if nargin < 2
    error('read_machine_data:MissingInput', ...
        'excelPath and machineNum are required.');
end
if ~isfile(excelPath)
    error('read_machine_data:FileNotFound', ...
        'Machine data file not found: %s', excelPath);
end

stationDistances = xlsread(excelPath, '装卸站到机器距离');
distanceMatrix = struct();
distanceMatrix.load_to_machine = stationDistances(1, 1:machineNum);
distanceMatrix.machine_to_unload = stationDistances(2, 1:machineNum);

machineDistances = xlsread(excelPath, '机器到机器距离');
distanceMatrix.machine_to_machine = ...
    machineDistances(1:machineNum, 1:machineNum);
distanceMatrix.load_to_unload = ...
    xlsread(excelPath, '装载站到卸载站距离');

machineEnergy = struct();
machineEnergy.work = xlsread(excelPath, '机器加工能耗');
machineEnergy.free = xlsread(excelPath, '机器空载能耗');

machineData = struct();
machineData.distance_matrix = distanceMatrix;
machineData.machineEnergy = machineEnergy;
end
