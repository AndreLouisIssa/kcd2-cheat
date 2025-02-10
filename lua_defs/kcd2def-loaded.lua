---@meta kcd2def-loaded

--- definition file containing LuaCATS annotations for the lua state added by loading/playing a save in-game (likely highly unstable)


---@class kcd2def*instance-Player:kcd2def*Player
do local player = { -- TODO: break this up into the class
	['Properties'] = {
		['LipSync'] = {
		};
		['guidSharedSoulId'] = '4666cffb-dea1-6263-72d7-b39f4db2d666';
	};
	['__this'] = '000001137A59FC00';
	['actor'] = {
		['__this'] = '0000000000007777';
	};
	['class'] = 'Player';
	['human'] = {
		['__this'] = '0000000000007777';
	};
	['id'] = '0000000000007777';
	['inventory'] = {
		['__this'] = '00000114F467A570';
	};
	['player'] = {
		['__this'] = '0000000000007777';
	};
	['soul'] = {
		['__ThisWUID'] = '05000000000012C3';
	};
	['this'] = {
		['context'] = {
			['animation'] = '';
		};
		['currentSUBB'] = '';
		['id'] = '05000000000012C3';
		['name'] = 'Dude';
	};
}; end

---@type kcd2def*instance-Player
player = ...