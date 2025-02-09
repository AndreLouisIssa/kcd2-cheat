---@meta kcd2def

--- definition file containing LuaCATS annotations for the lua state (except builtins) after all typical packages of Kingdom Come Deliverance II have loaded
--- if a parameter is annotated starting with 'unk_', the purpose or type of that parameter is merely being guessed

---@alias kcd2def*unknown_function fun(...): ...

---@module "kcd2def-builtin"
---@module "kcd2def-magic"
---@module "kcd2def-enums"


--- Common Structures (no metatable, but common fields)


---@class kdc2def*Actor.PhysicalStats
---@field public mass number

---@class kcd2def*Database.TableInfo
---@field public LineCount integer

---@class kcd2def*Database.TableLine: table

---@class kcd2def*Vector
---@field public x number
---@field public y number
---@field public z number


--- Actual Classes (structure of something with a metatable or is a global metatable)


---@class kcd2def*Actor
---@field public AwakePhysics fun(self: kcd2def*Actor, unk_1: 1|number): nil
---@field public AddImpulse fun(self: kcd2def*Actor, unk_1: -1|number, unk_position: kcd2def*Vector, unk_up: kcd2def*Vector, unk_acceleration: number): nil
---@field public GetPhysicalStats fun(self:kcd2def*Actor): kdc2def*Actor.PhysicalStats
---@field public GetWorldDir fun(self: kcd2def*Actor): kcd2def*Vector
---@field public GetWorldPos fun(self: kcd2def*Actor): kcd2def*Vector


--- Type Coercions (must use ---@type at consumer)


---@class kcd2def*Database.TableLine-quest:kcd2def*Database.TableLine
---@field public quest_id ...
---@field public quest_name string

---@class kcd2def*Database.TableLine-quest_objective:kcd2def*Database.TableLine
---@field public quest_id ...
---@field public objective_id ...
---@field public objective_name string


--- Singleton Types (mainly for the fields of nested global tables)


---@class kcd2def*Actor-player:kcd2def*Actor

---@class kcd2def*Database
---@field public GetTableInfo fun(tableName: string): kcd2def*Database.TableInfo
---@field public GetTableLine fun(tableName: string, lineIndex: integer): kcd2def*Database.TableLine?


--- Global Annotations



---@type kcd2def*Database
Database = ...

---@type kcd2def*unknown_function
_IAction = ...
---@type kcd2def*unknown_function
_IActionMap = ...
---@type kcd2def*unknown_function
_IClass = ...
---@type kcd2def*unknown_function
_IDisabledBarkMetarole = ...
---@type kcd2def*unknown_function
_IEnabled = ...
---@type kcd2def*unknown_function
_IFunc = ...
---@type kcd2def*unknown_function
_IHint = ...
---@type kcd2def*unknown_function
_IInteraction = ...
---@type kcd2def*unknown_function
_IReason = ...
---@type kcd2def*unknown_function
_IType = ...
---@type kcd2def*unknown_function
_IUiOrder = ...
---@type kcd2def*unknown_function
_IUiVisible = ...

_dataMetaTable = {
    ---@type kcd2def*unknown_function
	__index = ...;
    ---@type kcd2def*unknown_function
	__newindex = ...;
}

---@type kcd2def*unknown_function
expr = ...

---@type kcd2def*unknown_function
forwardTime = ...

---@type kcd2def*unknown_function
gcinfo = ...

---@type kcd2def*unknown_function
imod = ...

json = {
	_version = '0.1.1';
    ---@type kcd2def*unknown_function
	decode = ...;
    ---@type kcd2def*unknown_function
	encode = ...;
}

---@type kcd2def*Actor-player
player = ...

---@type kcd2def*unknown_function
newproxy = ...

q = {
    ---@type kcd2def*unknown_function
	ci = ...;
    ---@type kcd2def*unknown_function
	dd = ...;
    ---@type kcd2def*unknown_function
	en = ...;
    ---@type kcd2def*unknown_function
	nen = ...;
    ---@type kcd2def*unknown_function
	sm = ...;
	utils = {
        ---@type kcd2def*unknown_function
		parseEntityParam = ...
	};
};

---@type kcd2def*unknown_function
rd = ...

---@type kcd2def*unknown_function
rp = ...