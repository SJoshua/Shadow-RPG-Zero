--------------------------------------------
-- Scene Manager
-- Au: SJoshua
--------------------------------------------

--------------------------------------------
-- scene @ Scene Manager
--------------------------------------------
local scene = {}
local cover = {}

local function __NULL__()
	-- NULL
end

local M = setmetatable({}, {__index = function(self, func)
	if func == "draw" then -- how about update?
		return function(...)
			(self.current()[func] or __NULL__)(...)
			for i = 1, #cover do
				(cover[i][func] or __NULL__)(...)
			end
		end
	else
		return function(...)
			(self.top()[func] or __NULL__)(...)
		end
	end
end})

--------------------------------------------
-- push @ Scene Manager
--------------------------------------------
-- state: table
--------------------------------------------
function M:push(state)
	assert(type(state) == "table", "Not a table.")
	scene[#scene + 1] = state
	state.enter()
end

--------------------------------------------
-- pop @ Scene Manager
--------------------------------------------
function M:pop()
	assert((#scene + #cover) > 1, "Not able to pop.")
	if cover[#cover] then
		cover[#cover] = nil
	else
		scene[#scene] = nil
	end
end

--------------------------------------------
-- switch @ Scene Manager
--------------------------------------------
-- state: table
--------------------------------------------
function M:switch(state)
	assert(type(state) == "table", "Not a table.")
	scene[#scene] = state
	state.enter()
end

--------------------------------------------
-- overlay @ Scene Manager
--------------------------------------------
-- state: table
--------------------------------------------
function M:overlay(state)
	assert(type(state) == "table", "Not a table.")
	cover[#cover + 1] = state
	state.enter()
end

--------------------------------------------
-- current @ Scene Manager
--------------------------------------------
-- ret: table
--------------------------------------------
function M:current()
	return scene[#scene]
end

--------------------------------------------
-- top @ Scene Manager
--------------------------------------------
-- ret: table
--------------------------------------------
function M:top()
	return cover[#cover] or scene[#scene]
end

setmetatable(love, {__index = M})

return M 