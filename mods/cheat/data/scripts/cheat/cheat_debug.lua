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
    -- aggregate function types
    -- since this uses debug.sethook, none of it is thread safe anyway

    local Cheat = Cheat
    local print_queue = {}
    local function to_print(x,...)
        -- allows for printing without causing a loop in the hook
        print_queue[#print_queue+1] = x
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
    local tostring = tostring
    local pcall = pcall
    local select = select
    local unpack = table.unpack or unpack
    local getmetatable = getmetatable
    local pack = function (...)
        return { n = select('#', ...), ... }
    end

    local tracemode = "c" -- c, r, l are valid elements
    local hook_set = false
    local within_hook = false
    local within_call = false
    local aggregate
    local function_lookup

    local tolookup = function(t)
        local lookup = {}
        for k,v in pairs(t) do
            lookup[v] = k
        end
        return lookup
    end
    local lookup_exclude = tolookup{_G, Cheat, sethook, select, pairs, pcall, type, getmetatable}

    local function resethook()
        -- TODO: restore stored gethook?
        return sethook()
    end

    local function clear_print_queue()
        local n = #print_queue
        for i = 1, n, 1 do
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
        if t ~= 'table' and t ~= 'userdata' then
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

    local function join_type_set(data,kind,value,name)
        local names, types
        local t = get_type(value)
        if kind == nil then
            -- skip this layer
            names = data
        else
            names = data[kind]
            if names == nil then
                names = {}
                data[kind] = names
            end
        end
        if name == nil then
            -- skip this layer
            types = names
        else
            types = names[name]
            if types == nil then
                types = {}
                names[name] = types
            end
        end
        types[t] = true
    end

    local function get_function_data(path)
        local data = aggregate[path]
        if data == nil then
            data = {}
            aggregate[path] = data
        end
        return data
    end

    local type_order = {'boolean', 'integer', 'number', 'string', 'function', 'thread', 'table', 'userdata'}

    local function calltracer(event)
        if not hook_set then return end
        if not within_call then return end
        if event == 'tail return' then return end
        
        within_hook = true
        
        local info = getinfo(2,"f")
        local p = function_lookup[info.func]
        
        if p ~= nil then
            local path = p.path
            --to_print(event .. ': ' .. path)
            local data = get_function_data(path)
            local i = 1
            local n = 0
            if event == 'call' then
                while true do
                    local name, value = getlocal(2, i)
                    if name ~= nil then
                        if name ~= '(*temporary)' then
                            local order = data.order
                            if order == nil then
                               order = {}
                               data.order = order
                            end
                            n = n + 1
                            order[n] = name
                            join_type_set(data,'param',value,name)
                        --else
                            --join_type_set(data,'vararg',value)
                        end
                        i = i + 1
                    else
                        break
                    end
                end
            --[[
            else -- return or line work here, line is more consistent but expensive
                -- in theory, this may allow for documenting the names of return values
                while true do
                    local name, value = getlocal(2, i)
                    if name ~= nil then
                        if name ~= '(*temporary)' then
                            join_type_set(data,name,value,'local',i)
                        end
                        i = i + 1
                    else
                        break
                    end
                end
            --]]
            end

        end
        
        within_hook = false
    end

    local function sethook_calltracer()
        return sethook(calltracer,tracemode)
    end

    local function call_aft(func,...)
        if within_hook or not hook_set then
            return func(...)
        end
        local p = function_lookup[func]
        if p == nil then
            return func(...)
        end

        local path = p.path

        --to_print('wcall: ' .. path)

        local args = pack(...)

        local data = get_function_data(path)
        if data ~= nil then
            for i = 1, args.n, 1 do
                join_type_set(data,'arg',args[i],i)
            end
        end

        local outer_layer = not within_call

        if outer_layer then
            sethook_calltracer()
            within_call = true
        end

        local rets = pack(func(...))

        if outer_layer then
            within_call = false
        end

        resethook()

        data = get_function_data(path)
        if data ~= nil then
            for i = 1, rets.n, 1 do
                join_type_set(data,'return',rets[i],i)
            end
        end

        ---to_print('wreturn: ' .. path)
        return unpack(rets)
    end

    local function wrap_function(f)
        return function(...) return call_aft(f,...) end
    end

    local function inner_generate_function_lookup(max_depth,depth,path,parent,key,value)
        if depth > max_depth then return end
        if depth > 0 and lookup_exclude[value] then return end
        if function_lookup[value] ~= nil then return end
        local t = type(value)
        if t == 'function' then
            function_lookup[value] = {path = path, parent = parent, key = key}
            parent[key] = wrap_function(value)
        elseif t == 'table' then
            for k,v in pairs(value) do
                if type(k) == 'string' then
                    local path = path
                    if path ~= nil then
                        path = path .. '.' .. k
                    else
                        path = k
                    end
                    inner_generate_function_lookup(max_depth,depth+1,path,value,k,v)
                end
            end
        end
    end

    local function generate_function_lookup(depth)
        -- associates function references with a global path
        -- uses DFS (depth-first search) currently, but BFS (breadth-first search) would be ideal
        if function_lookup ~= nil then
            cleanup_function_lookup()
        end
        function_lookup = {}
        inner_generate_function_lookup(depth,0,nil,nil,nil,_G)
    end

    local function join_types(types)
        -- mutates the data provided

        local opt = types['nil']
        types['nil'] = nil
        local expr = ''
        local sep = '|'
        for _,t in ipairs(type_order) do
            if types[t] then
                types[t] = nil
                expr = expr .. sep .. t
            end
        end
        local rest = {}
        local n = 0
        for k in pairs(types) do
            n = n + 1
            rest[n] = k
        end
        table.sort(rest)
        for _,t in ipairs(rest) do
            expr = expr .. sep .. t
        end
        if opt then
            expr = expr .. '?'
        end
        return expr:sub(2)
    end

    local function process_aft_result(result)
        -- mutates the data provided

        for _,res in pairs(result) do
            local vars = res['vararg']
            if vars ~= nil then
                res['vararg'] = join_types(vars)
            end
            local args = res['arg']
            if args ~= nil then
                for i,u in ipairs(args) do
                    args[i] = join_types(u)
                end
            end
            local rets = res['return']
            if rets ~= nil then
                for i,u in ipairs(rets) do
                    rets[i] = join_types(u)
                end
            end
            local pars = res['param']
            if pars ~= nil then
                for k,u in pairs(pars) do
                    pars[k] = join_types(u)
                end
            end
        end

        return result
    end

    local function dump_aft_result(result,logger)
        -- produces hopefully valid type annotations

        --tprint(results)

        local paths = {}
        do
            local n = 0
            for path in pairs(result) do
                n = n + 1
                paths[n] = path
            end
        end

        table.sort(paths)

        local prefix = ' fun('
        local infix = '): '
        logger = logger or function(s) Cheat:logDebug(s) end

        local lastpath = nil
        for _,path in ipairs(paths) do
            local res = result[path]
            local pars = res['param']
            if pars ~= nil then
                local pord = res['order']
                for i,n in ipairs(pord) do
                    pars[i] = n .. ': ' .. pars[n]
                end
                pars = table.concat(pars,', ')
            else
                local args = res['arg']
                if args == nil then
                    pars = ''
                else
                    pars = {}
                    local n = 0
                    for i,a in ipairs(args) do
                        n = n + 1
                        pars[n] = 'unk_' .. tostring(i) .. ': ' .. a
                    end
                    pars = table.concat(pars,', ')
                end
            end
            local rets = res['return']
            if rets == nil then
                rets = 'nil'
            else
                rets = table.concat(rets,', ')
            end
            
            local sig = prefix .. pars .. infix .. rets

            --- private or deprecated by default so they can be manually adjusted later
            local i = path:match'^.*()%.'
            local key = path:sub(i+1)
            path = path:sub(1,i-1)

            if #path > 0 then
                if path ~= lastpath then
                    logger('')
                    logger('---@class kcd2def*' .. path)
                end
                lastpath = path
                logger('---@field private ' .. key .. sig)
            else
                logger('')
                logger('---@deprecated')
                logger('---@type' .. sig)
                logger(key .. ' = ...')
            end
            
        end
    end

    local function enable_aft()
        if hook_set then
            error('aggregate_function_types active, cannot begin')
            return
        end
        
        print("begin - aggregate_function_types")

        -- max depth of 2 to avoid DFS tunneling into super/__index obscuring the root class
        generate_function_lookup(2)
        aggregate = {}
        hook_set = true
    end

    local function disable_aft()
        if not hook_set then
            error('aggregate_function_types not active, cannot end')
            return
        end

        hook_set = false
        clear_print_queue()
        cleanup_function_lookup()

        process_aft_result(aggregate)
        dump_aft_result(aggregate)

        print("end - aggregate_function_types")
        
        return aggregate
    end

    local function test_aft(f, ...)
        print('test begin')

        enable_aft()

        local s,m = pcall(f or nop, ...)
        local result = disable_aft()

        if not s then
            error(m)
        end

        print('test end')
        return result
    end

    function Cheat:enable_aft()
        return enable_aft()
    end

    function Cheat:disable_aft()
        return disable_aft()
    end

    function Cheat:call_aft(...)
        return call_aft(...)
    end

    function Cheat:test_aft(...)
        return test_aft(...)
    end
end

-- ============================================================================
-- end
-- ============================================================================
Cheat:logDebug("cheat_debug.lua loaded")
