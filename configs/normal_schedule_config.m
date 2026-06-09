function config = normal_schedule_config(projectRoot)
%NORMAL_SCHEDULE_CONFIG Define the Stage A normal baseline inputs.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();
config.seed = 42;
config.instancePath = fullfile(projectRoot, 'raw_code', 'fjsp', ...
    'Brandimarte_Data', 'Mk02.fjs');
config.machineDataPath = ...
    fullfile(projectRoot, 'raw_code', '机器数据.xlsx');
config.agvDataPath = ...
    fullfile(projectRoot, 'raw_code', 'AGV数据.xlsx');
config.AGVEG_MAX = 100;
config.eChargeSpeed = 20;
end
