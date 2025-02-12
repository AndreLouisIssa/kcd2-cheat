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

    local Cheat = Cheat
    local print_queue = {}
    local function to_print(x,...)
        print_queue[#print_queue] = x
    end
    local function print(...)
        return Cheat:logWarn(tostring(...))
    end
    local function tprint(...)
        return Cheat:tprint(...)
    end
    local function error(...)
        return Cheat:logError(...)
    end
    local function nop() end

    local _G = _G
    local pairs = pairs
    local sethook = debug.sethook
    local getinfo = debug.getinfo
    local getlocal = debug.getlocal
    local type = type
    local pcall = pcall
    local select = select
    local unpack = table.unpack or unpack
    local getmetatable = debug.getmetatable
    local pack = function (...)
        return { n = select('#', ...), ... }
    end

    local hook_set = false
    local within_hook = false
    local within_call = false
    local aggregate
    local function_lookup

    local function resethook()
        -- TODO: restore stored gethook?
        return sethook()
    end

    local function clear_print_queue()
        for i = 1, #print_queue, 1 do
            print(print_queue[i])
            print_queue[i] = nil
        end
    end

    local function cleanup_function_lookup()
        for f,p in pairs(function_lookup) do
            p.parent[p.key] = f
        end
        function_lookup = nil
    end

    local function get_type(object)
        local t = type(object)
        if t ~= 'table' or t ~= 'userdata' then
            return t
        end
        --assume documentation namespace
        local meta = getmetatable(object)
        if meta == nil or meta.type == nil then
            return t
        end
        local namespace = 'kcd2def*'
        t = meta.type
        if _G[t] == meta then
            return namespace .. t
        end
        return namespace .. 'unknown-' .. t
    end

    local function join_type_set(data,name,value)
        local types = data[name]
        if types == nil then
            types = {}
            data[name] = types
        end
        local t = get_type(value)
        --to_print(name .. ': ' .. t)
        types[t] = true
    end

    local function get_function_data(path)
        local data = aggregate[path]
        if data == nil then
            data = {}
            aggregate[path] = data
        end
    end

    local function calltracer(event)
        if not hook_set then return end
        if not within_call then return end
        if event == 'tail return' then return end
        
        within_hook = true
        
        local info = getinfo(2,"f")
        local p = function_lookup[info.func]
        
        if p ~= nil then
            local path = p.path
            to_print(event)
            to_print(path)
            local data = get_function_data(path)

            local i = 1
            if event == 'call' then
                while true do
                    local name, value = getlocal(2, i)
                    if name ~= nil then
                        if name == '(*temporary)' then
                            name = 'vararg'
                        else
                            name = 'param_' .. tostring(i) .. '_' .. name
                        end
                        join_type_set(data,name,value)
                        i = i + 1
                    else
                        break
                    end
                end
            else
                while true do
                    local name, value = getlocal(2, i)
                    if name ~= nil then
                        if name ~= '(*temporary)' then
                            name = 'local_' .. tostring(i) .. '_' .. name
                            join_type_set(data,name,value)
                        end
                        i = i + 1
                    else
                        break
                    end
                end
            end

        end
        
        within_hook = false
    end

    local function sethook_calltracer()
        return sethook(calltracer,"cr")
    end

    local function call_aggregate_function_types(func,...)
        if within_hook or not hook_set then
            return func(...)
        end
        local p = function_lookup[func]
        if p == nil then
            return func(...)
        end

        local path = p.path
        --local args = pack(...)

        local data = get_function_data(path)
        --if data ~= nil then
        --    for i = 1, args.n, 1 do
        --        join_type_set(data, 'arg_' .. tostring(i), args[i])
        --    end
        --end

        local outer_layer = not within_call

        if outer_layer then
            --sethook_calltracer()
            within_call = true
        end

        local rets = pack(func(...))

        if outer_layer then
            within_call = false
        end

        --resethook()

        --data = get_function_data(path)
        --if data ~= nil then
        --    for i = 1, rets.n, 1 do
        --        join_type_set(data, 'return_' .. tostring(i), rets[i])
        --    end
        --end

        to_print('return')
        to_print(p.path)
        return unpack(rets)
    end

    local function wrap_function(f)
        return function(...) return call_aggregate_function_types(f,...) end
    end

    local function generate_function_lookup()
        if function_lookup ~= nil then
            cleanup_function_lookup()
        end
        -- assume most relevant functions are global or directly in global tables
        function_lookup = {}
        for k,v in pairs(_G) do
            if k ~= '_G' and v ~= select and v ~= pcall and v ~= Cheat then
                local t = type(v)
                if t == 'function' then
                    function_lookup[v] = {path = k, parent = _G, key = k}
                    _G[k] = wrap_function(v)
                elseif t == 'table' then
                    for j,u in pairs(v) do
                        if u ~= sethook then
                            t = type(u)
                            if t == 'function' then
                                function_lookup[u] = {path = k .. '.' .. j, parent = v, key = j}
                                v[j] = wrap_function(u)
                            end
                        end
                    end
                end
            end
        end
    end

    local function begin_aggregate_function_types()
        if hook_set then
            error('aggregate_function_types active, cannot begin')
            return
        end
        
        print("begin - aggregate_function_types")

        generate_function_lookup()
        aggregate = {}
        hook_set = true
    end

    local function end_aggregate_function_types()
        if not hook_set then
            error('aggregate_function_types not active, cannot end')
            return
        end

        hook_set = false
        clear_print_queue()
        cleanup_function_lookup()
        tprint(aggregate)

        print("end - aggregate_function_types")
        
        return aggregate
    end

    local function test_aggregate_function_types(f, ...)
        print('test begin')

        begin_aggregate_function_types()

        local s,m = pcall(f or nop, ...)
        local result = end_aggregate_function_types()

        if not s then
            error(m)
        end

        print('test end')
        return result
    end

    function Cheat:begin_aggregate_function_types()
        return begin_aggregate_function_types()
    end

    function Cheat:end_aggregate_function_types()
        return end_aggregate_function_types()
    end

    function Cheat:call_aggregate_function_types(...)
        return call_aggregate_function_types(...)
    end

    function Cheat:test_aggregate_function_types(...)
        return test_aggregate_function_types(...)
    end
end

-- ============================================================================
-- end
-- ============================================================================
Cheat:logDebug("cheat_debug.lua loaded")
