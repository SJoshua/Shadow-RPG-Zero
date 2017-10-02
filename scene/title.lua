--------------------------------------------
-- title @ scene
-- Au: SJoshua
--------------------------------------------
local utils = require "base.utils"
local scene_manager = require "base.scene_manager"

local map = require "scene.map"
local exit = require "interface.exit"

local title = {}

local pos = {}
local focus = 1
local clock = 0
local cursor = {index = 1}

function title:enter()
	titleImage = image.title
	title = {
		love.graphics.newText(font.NotoSansCJK[60], "Shadow RPG Zero")
	}
	titleBtns = {
		love.graphics.newText(font.NotoSansCJK[30], "Start"),
		love.graphics.newText(font.NotoSansCJK[30], "Continue"),
		love.graphics.newText(font.NotoSansCJK[30], "Settings"),
		love.graphics.newText(font.NotoSansCJK[30], "Exit")
	}
	focus = 1
	clock = 0
end

function title:update()
	local x, y = love.mouse.getPosition()
	if clock < 30 then
		clock = clock + 1
	end
	focus = utils.select(pos, x, y) or focus
end

function title:draw()
	love.graphics.setColor(255, 255, 255, 255 / 30 * clock)
	love.graphics.draw(titleImage)
	utils.drawList(title, 0.35)
	pos = utils.drawList(titleBtns, 0.8, 0.15)
	if focus and utils.inRange(focus, 1, #pos) then
		love.graphics.line(pos[focus].x[1], pos[focus].y[2], pos[focus].x[2], pos[focus].y[2])
	end
end

local function process()
	if focus == 1 then
		return scene_manager:push(map)
	elseif focus == 2 then
		return scene_manager:push(map)
	elseif focus == 3 then
	elseif focus == 4 then
		return scene_manager:overlay(exit)
	end
end

function title:mousepressed(x, y, button, istouch)
	focus = utils.select(pos, x, y) or focus
	if utils.select(pos, x, y) and button == 1 then
		process()
	end
end

function title:keypressed(key)
	if key == "left" then
		focus = focus - 1
	elseif key == "right" then
		focus = focus + 1
	elseif key == "return" then
		return process()
	end
	focus = (focus - 1) % #pos + 1
end

return title
