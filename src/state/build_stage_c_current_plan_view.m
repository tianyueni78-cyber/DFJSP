function view = build_stage_c_current_plan_view(baseline, version)
%BUILD_STAGE_C_CURRENT_PLAN_VIEW Adapt one version for state extraction.
%   Logical operations are rebuilt once each from operation_records.

if nargin < 2
    error('build_stage_c_current_plan_view:MissingInput', ...
        'baseline and version are required.');
end
require_fields(baseline, {'problem', 'AGVTable', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(version, {'version_id', 'effective_time', ...
    'strategy', 'plan', 'is_validated'}, 'version');
require_fields(version.plan, {'machineTable'}, 'version.plan');
if ~version.is_validated
    error('build_stage_c_current_plan_view:InvalidVersion', ...
        'A validated plan version is required.');
end

plan = version.plan;
if isfield(plan, 'operation_records')
    machineTable = rebuild_logical_machine_table( ...
        plan.operation_records, baseline.problem.machineNum);
else
    machineTable = plan.machineTable;
end
if isfield(plan, 'AGVTable')
    agvTable = plan.AGVTable;
elseif isfield(plan, 'agv_activity_records')
    agvTable = rebuild_agv_table( ...
        plan.agv_activity_records, numel(baseline.AGVTable));
else
    error('build_stage_c_current_plan_view:MissingAgvPlan', ...
        'Version plan must contain AGVTable or agv_activity_records.');
end

view = baseline;
view.machineTable = machineTable;
view.AGVTable = agvTable;
view.isFaultFreeBaseline = false;
view.isCurrentPlanView = true;
view.source_version_id = version.version_id;
view.version_effective_time = version.effective_time;
view.version_strategy = version.strategy;
view.current_plan_makespan = plan_makespan(plan, machineTable);
view.is_validated = true;
end

function machineTable = rebuild_logical_machine_table(records, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    selected = records([records.machine_id] == machineId);
    [~, order] = sort([selected.start]);
    selected = selected(order);
    template = machine_block_template();
    blocks = template([]);
    cursor = 0;
    for index = 1:numel(selected)
        if selected(index).start > cursor
            blocks(end + 1) = idle_machine_block( ...
                cursor, selected(index).start);
        end
        block = template;
        block.start = selected(index).start;
        block.end = selected(index).end;
        block.job = selected(index).job;
        block.opera = selected(index).operation;
        blocks(end + 1) = block;
        cursor = selected(index).end;
    end
    blocks(end + 1) = idle_machine_block(cursor, Inf);
    machineTable{machineId} = blocks;
end
end

function AGVTable = rebuild_agv_table(activities, agvCount)
AGVTable = cell(1, agvCount);
for agvId = 1:agvCount
    selected = activities([activities.agv_id] == agvId);
    [~, order] = sort([selected.start]);
    selected = selected(order);
    template = agv_block_template();
    blocks = template([]);
    cursor = 0;
    location = -1;
    for index = 1:numel(selected)
        if selected(index).start > cursor
            blocks(end + 1) = idle_agv_block( ...
                cursor, selected(index).start, location);
        end
        block = template;
        block.start = selected(index).start;
        block.end = selected(index).end;
        block.job = selected(index).job;
        block.opera = selected(index).operation;
        block.load_status = selected(index).load_status;
        block.from_machine = selected(index).from_machine;
        block.to_machine = selected(index).to_machine;
        block.charge = selected(index).charge;
        blocks(end + 1) = block;
        cursor = selected(index).end;
        location = selected(index).to_machine;
    end
    blocks(end + 1) = idle_agv_block(cursor, Inf, location);
    AGVTable{agvId} = blocks;
end
end

function value = plan_makespan(plan, machineTable)
if isfield(plan, 'makespan') && isfinite(plan.makespan)
    value = plan.makespan;
    return
end
value = 0;
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    finiteEnds = [blocks(isfinite([blocks.end])).end];
    if ~isempty(finiteEnds)
        value = max(value, max(finiteEnds));
    end
end
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', []);
end

function value = idle_machine_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
end

function value = agv_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'load_status', [], 'from_machine', [], 'to_machine', [], ...
    'charge', []);
end

function value = idle_agv_block(startTime, endTime, location)
value = agv_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
value.load_status = 0;
value.from_machine = location;
value.to_machine = 0;
value.charge = 0;
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_c_current_plan_view:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
