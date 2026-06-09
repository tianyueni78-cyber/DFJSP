function agvData = read_agv_data(excelPath)
%READ_AGV_DATA Read AGV count, speed, and energy data without writes.

if nargin < 1
    error('read_agv_data:MissingInput', 'excelPath is required.');
end
if ~isfile(excelPath)
    error('read_agv_data:FileNotFound', ...
        'AGV data file not found: %s', excelPath);
end

agvCount = xlsread(excelPath, 'AGV数量');
agvSpeed = xlsread(excelPath, 'AGV速度');
energyValues = xlsread(excelPath, 'AGV能耗');

if isempty(agvCount) || isempty(agvSpeed) || size(energyValues, 1) < 2
    error('read_agv_data:InvalidData', ...
        'AGV workbook does not contain the expected values.');
end

agvEnergy = struct();
agvEnergy.free = energyValues(1, :);
agvEnergy.load = energyValues(2, :);

agvData = struct();
agvData.AGVNum = agvCount(1);
agvData.AGVSpeed = agvSpeed(:).';
agvData.AGVEnergy = agvEnergy;
end
