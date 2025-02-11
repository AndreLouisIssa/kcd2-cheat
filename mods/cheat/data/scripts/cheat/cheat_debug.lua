---@diagnostic disable: deprecated
-- ============================================================================
-- debug functions
-- ============================================================================
function Cheat:dump_all()
    for key, value in pairs(_G) do
        Cheat:logWarn("\n==============================================================================")
        if value then
            if type(value) == "table" then
                Cheat:logWarn("%s (%s)", tostring(key), type(value))
                Cheat:logWarn("==== META METHODS:")
                Cheat:print_methods(getmetatable(value))
                Cheat:logWarn("==== METHODS:")
                Cheat:print_methods(value)
            else
                Cheat:logWarn("%s (%s) = [%s]", tostring(key), type(value), tostring(value))
            end
        end
    end
end

function Cheat:print_db_table(tableName, filter, debug)
    if not Database.LoadTable(tableName) then
        Cheat:logError("Unable to load table [%s].", tostring(tableName))
        return
    end

    local tableInfo = Database.GetTableInfo(tableName)
    if not tableInfo then
        Cheat:logError("Table [%s] not found.", tostring(tableName))
        return
    end

    if tableInfo.LineCount == 0 then
        Cheat:logInfo("Table [%s] is empty.", tostring(tableName))
        return
    end

    local rows = tableInfo.LineCount - 1

    for i = 0, rows do
        local tableline = Database.GetTableLine(tableName, i)
        if tableline then
            local displayLine = ""
            for key, value in pairs(tableline) do
                if debug then
                    Cheat:logDebug("Pair key=[%s] value=[%s].", tostring(key), tostring(value))
                end

                if not Cheat:isBlank(filter) then
                    if string.find(string.upper(key), string.upper(filter)) or string.find(string.upper(tostring(value)), string.upper(filter)) then
                        displayLine = displayLine .. " " .. key .. "=" .. tostring(value)
                    end
                else
                    displayLine = displayLine .. " " .. key .. "=" .. tostring(value)
                end
            end

            if not Cheat:isBlank(displayLine) then
                Cheat:logInfo(displayLine)
            end
        else
            Cheat:logError("Read nil table line (this is a bug).")
        end
    end
end

function Cheat:print_methods(object, filter)
    if not object then
        Cheat:logDebug("Object is nil")
        return
    end

    for key, _ in pairs(object) do
        if Cheat:isBlank(filter) or string.find(Cheat:toUpper(key), Cheat:toUpper(filter), 1, true) then
            Cheat:logInfo(key)
        end
    end
end

function Cheat:print_all_tables(object, tableName, showMethods)
    if not object then
        object = _G
    end

    if not Cheat:isBlank(tableName) then
        tableName = Cheat:toUpper(tableName)
    else
        tableName = nil
    end

    if showMethods ~= true and showMethods ~= false then
        showMethods = false
    end

    for key, value in pairs(object) do
        if not tableName or (tableName and tableName ~= Cheat:toUpper(key)) then
            local getKeyType = loadstring("return type(" .. key .. ")")
            if getKeyType and getKeyType() == "table" then
                Cheat:logWarn("TABLE: " .. key)
                if showMethods then
                    local getTable = loadstring("return " .. key)
                    if getTable then
                        Cheat:print_methods(getTable())
                    end
                end
            end
        end
    end
end

function Cheat:print_all_functions(object)
    if not object then
        object = _G
    end

    for key, value in pairs(object) do
        local getKeyType = loadstring("return type(" .. key .. ")")
        if getKeyType and getKeyType() == "function" then
            Cheat:logWarn("BEGIN FUNC:" .. key)
            local func = loadstring("print_function_args(" .. key .. ")")
            if func then
                func()
            end
        end
    end
end

function Cheat:tprint(tbl, indent)
    if not indent then
        indent = 0
    end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            Cheat:logDebug(formatting)
            Cheat:tprint(v, indent + 1)
        else
            Cheat:logDebug(formatting .. tostring(v))
        end
    end
end

function Cheat:setup_hook()
    debug.sethook(function (event, line)
        Cheat:logWarn("event=" .. event .. " line=" .. tostring(line))
        Cheat:tprint(debug.getinfo(2, "flLnSu"))
        if event == "call" then
            local i = 1
            while true do
                local name, value = debug.getlocal(2, i)
                if name or value then
                    Cheat:logDebug("    local name=" .. name .. " value=" .. tostring(value))
                    i = i + 1
                else
                    break
                end
            end
        end
    end, "crl")
    Cheat:logDebug("hook set")
end

function Cheat:print_function_args(f)
    Cheat:logDebug("begin - print_function_args")

    local calltracer = function (event, line)
        Cheat:logWarn("event=" .. event .. " line=" .. tostring(line))
        Cheat:tprint(debug.getinfo(2, "flLnSu"))
        if event == "call" then
            local i = 1
            while true do
                local name, value = debug.getlocal(2, i)
                if name or value then
                    Cheat:logDebug("    local name=" .. name .. " value=" .. tostring(value))
                    i = i + 1
                else
                    break
                end
            end
        end
    end
    Cheat:logDebug("tracer function created")
    debug.sethook(calltracer, "crl")
    Cheat:logDebug("debug hook set")

    f()

    debug.sethook()
    Cheat:logDebug("end - print_function_args")
end

do
    -- since this uses debug.sethook, none of it is thread safe anyway

    local nop = function() end
    local sethook = debug.sethook
    local hook_set = false
    local function_lookup
    local aggregate

    local function generate_function_lookup()
        -- assume most relevant functions are global or directly in global tables
        function_lookup = {}
        for k,v in pairs(_G) do
            if k ~= '_G' then
                local t = type(v)
                if t == 'function' then
                    function_lookup[v] = k
                elseif t == 'table' then
                    for j,u in pairs(v) do
                        t = type(u)
                        if t == 'function' then
                            function_lookup[u] = k .. '.' .. j
                        end
                    end
                end
            end
        end
    end

    local function lookup_function(info)
        local key = function_lookup[info.func]
        if key ~= nil then
            return '_G.' .. key
        end
        -- in case the name is some arbitrary local
        -- we don't want to confuse it with a global
        return info.name
    end

    local function get_type(object)
        local t = type(object)
        if t ~= 'table' or t ~= 'userdata' then
            return t
        end
        --assume documentation namespace
        local meta = getmetatable(object)
        if meta == nil then
            return t
        end
        local namespace = 'kcd2def*'
        t = meta.type
        if _G[t] == meta then
            return namespace .. t
        end
        return namespace .. 'unknown-' .. t
    end

    local function join_type_set(data,name,datum)
        if name == '(*temporary)' then
            name = '...'
        end
        if data.types == nil then
            data.types = {}
        end
        local types = data.types[name]
        if types == nil then
            types = {}
            data.types[name] = types
        end
        types[get_type(datum)] = true
    end

    function Cheat:begin_aggregate_function_args(join,group)
        if hook_set then
            Cheat:logError('aggregate_function_args active, cannot begin')
            return
        end
        
        Cheat:logDebug("begin - aggregate_function_args")

        if join == nil then
            join = join_type_set
        end

        if group == nil then
            if function_lookup == nil then
                generate_function_lookup()
            end
            group = lookup_function
        end

        aggregate = {}

        local calltracer = function()
            --Cheat:logWarn('call')
            local info = debug.getinfo(2, "flLnSu")
            --Cheat:tprint(info)
            local key = group(info)
            local data = aggregate[key]
            if data == nil then
                data = {}
                aggregate[key] = data
                for k,v in pairs(info) do
                    data[k] = v
                end
            end
            local i = 1
            while true do
                local name, value = debug.getlocal(2, i)
                if name ~= nil then
                    join(data,name,value)
                    i = i + 1
                else
                    break
                end
            end
        end

        Cheat:logDebug("tracer function created")
        hook_set = true
        debug.sethook = nop
        sethook(calltracer, "c")
    end

    function Cheat:end_aggregate_function_args()
        if not hook_set then
            Cheat:logError('aggregate_function_args not active, cannot end')
            return
        end

        sethook()
        debug.sethook = sethook
        hook_set = false
        Cheat:logDebug("end - aggregate_function_args")

        return aggregate
    end

    function Cheat:test_aggregate_function_args()

        local s, m = pcall(function()

        Cheat:begin_aggregate_function_args()
        
        print(1)
        print(coroutine.running())
        print(next(_G))

        local a = Cheat:end_aggregate_function_args()

        Cheat:tprint(a)

        end)

        if not s then
            Cheat:logError(m)
        end

    end
end

-- ============================================================================
-- end
-- ============================================================================
Cheat:logDebug("cheat_debug.lua loaded")
