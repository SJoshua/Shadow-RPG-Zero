--------------------------------------------
-- Shadow RPG Zero
-- Au: SJoshua
--------------------------------------------
local tick = require "base.tick"
local utils = require "base.utils"
local scene_manager = require "base.scene_manager"
local resource_manager = require "base.resource_manager"

local title = require "scene.title"

--------------------------------------------
-- load @ love
--------------------------------------------
function love.load()
	tick.framerate = 60
	resource_manager:init()
	scene_manager:push(title)
end
