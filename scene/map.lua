--------------------------------------------
-- map 
-- Au: SJoshua
--------------------------------------------
local scene_manager = require "base.scene_manager"
local utils = require "base.utils"
local exit = require "interface.exit"

local map = {}

-- Map ID
local currentMap = "000-debug"

-- define
local speed = 2 -- blocks per second
local frequency = 6 -- frames per second
local step = speed / 60
local resetLimit = 10

local movement = {
	down = {1, 0, step},
	left = {2, -step, 0},
	right = {3, step, 0},
	up = {4, 0, -step}
}

local function updateSpeed(spd)
	speed = spd
	step = speed / 60
	movement = {
		down = {1, 0, step},
		left = {2, -step, 0},
		right = {3, step, 0},
		up = {4, 0, -step}
	}
end

-- every object to draw
local object = {
	-- zero is character
	[0] = {
		id = 0,
		position = {
			x = 15,
			y = 10
		},
		faceto = movement.down[1],
		status = 2,
		block = true
	},
	[1] = {
		id = 1,
		position = {
			x = 10,
			y = 5
		},
		faceto = movement.down[1],
		status = 2,
		move = function (x, y)
			return x, y
		end,
		talk = function ()
			print("hello.")
		end,
		block = true
	}
}

-- storage
local info = {}
local tileset = {}
local layer = {}
local character = {
	source = {}
}

local clock = 0
local lastFrame = 0
local standTick = 0

function map:enter()
	-- load map
	local res = love.filesystem.read(string.format("resource/map/%s.tmx", currentMap))
	
	-- step 0: load info
	local mapTags = res:match("<map([^\n]+)>")
	assert(mapTags, "Invaild map data.")
	info = {
		width = mapTags:match([[width="(%d+)"]]),
		height = mapTags:match([[height="(%d+)"]]),
		tileWidth = mapTags:match([[tilewidth="(%d+)"]]),
		tileHeight = mapTags:match([[tileheight="(%d+)"]])
	}
	assert(info.width and info.height and info.tileWidth and info.tileHeight, "Invaild map tags.")
	for k, v in pairs(info) do
		info[k] = tonumber(v)
	end
	-- step 1: load tilesets
	local tilesetPt = [[<tileset(.-)/>]]
	while res:find(tilesetPt) do
		local s = res:match(tilesetPt)
		res = res:gsub(tilesetPt, "", 1)
		local source = s:match([[source=".-([^/]+%.tsx)"]])
		local first = s:match([[firstgid="(%d+)"]])
		local alpha = s:match([[opacity="([%d%.]+)"]])
		assert(source and first, "Invaild tileset tag.")
		
		source = love.filesystem.read(string.format("resource/tiles/%s", source))
		
		local s = source:match("<tileset([^\n]-)>")
		local tilecount = s:match([[tilecount="(%d+)"]])
		local columns = s:match([[columns="(%d+)"]])
		local source = source:match([[<image.-source="(.-)".->]])
		assert(tilecount and columns, "Invaild tileset file.")
		tilecount = tonumber(tilecount)
		columns = tonumber(columns)
		tileset[#tileset + 1] = {
			source = love.graphics.newImage(string.format("resource/tiles/%s", source)),
			quad = {},
			first = tonumber(first),
			alpha = tonumber(alpha or 1)
		}
		for i = 1, tilecount do
			local sx = (i - 1) % columns * info.tileWidth
			local sy = math.floor((i - 1) / columns) * info.tileHeight
			tileset[#tileset].quad[i] = love.graphics.newQuad(sx, sy, info.tileWidth, info.tileHeight,
			tileset[#tileset].source:getDimensions())
		end
	end
	-- step 2: load layers
	local layerPt = "<layer[^\n]->.-<data.->(.-)</data>.-</layer>"
	while res:find(layerPt) do
		local layerData = res:match(layerPt)
		res = res:gsub(layerPt, "", 1)
		assert(layerData, "Layer data not found.")
		local status, csv = pcall(loadstring(string.format("return {%s}", layerData)))
		assert(status, "Failed to load layer data.")
		table.insert(layer, {})
		for line = 0, info.height - 1 do
			layer[#layer][line] = {}
			for col = 0, info.width - 1 do
				local id = csv[line * info.width + col + 1]
				if id == 0 then
					layer[#layer][line][col] = nil
				else
					local tile = #tileset
					for i = 1, #tileset do
						if tileset[i].first > id then
							tile = i - 1
							break
						end
					end
					layer[#layer][line][col] = {
						tile = tile,
						id = id - tileset[tile].first + 1
					}
				end
			end
		end
	end
	
	-- load characters
	local index = love.filesystem.load("resource/characters/index.des")()
	assert(index, "Character index not found.")
	
	for i = 1, #index do
		local t = love.filesystem.load(string.format("resource/characters/%s", index[i]))()
		assert(t, string.format("Character description <%s> not found.", index[i]))
		table.insert(character.source, {
			width = t.width,
			height = t.height,
			columns = t.columns,
			source = love.graphics.newImage(string.format("resource/characters/%s", t.source))
		})
		for k, v in pairs(t) do
			if type(k) == "number" then
				character[k] = {
					source = #character.source
				}
				for i = 1, 4 do
					character[k][i] = {}
					for c = 1, t.columns do
						local sx = (v.col + c - 2) * t.width
						local sy = (v.line + i - 2) * t.height
						character[k][i][c] = love.graphics.newQuad(sx, sy, t.width, t.height,
						character.source[#character.source].source:getDimensions())
					end
					if t.columns == 3 then
						character[k][i][4] = character[k][i][2]
					end
				end
			end
		end
	end
	-- init
	clock = 0
end

function map:update()
	if clock < 30 then
		clock = clock + 1
	end
	local moving = false
	for k, v in pairs(movement) do
		if love.keyboard.isDown(k) then
			object[0].faceto = v[1]
			
			local nx = utils.limit(object[0].position.x + v[2], 0, info.width - 1)
			local ny = utils.limit(object[0].position.y + v[3], 0, info.height - 1)
			
			if layer[2] then
				local fnx, fny = math.floor(nx), math.floor(ny + 0.25)
				if layer[2][fny] and layer[2][fny][fnx] then
					nx = object[0].position.x
					ny = object[0].position.y
				end
			end
			
			for i = 1, #object do
				if object[i].block then
					if utils.maxDistance({x = nx, y = ny}, object[i].position) < 0.5 then
						nx = object[0].position.x
						ny = object[0].position.y
						break
					end
				end
			end
			
			object[0].position = {
				x = nx,
				y = ny
			}
			
			if love.timer.getTime() - lastFrame > 1 / frequency then	
				object[0].status = object[0].status + 1
				if object[0].status > #character[0][1] then
					object[0].status = 1
				end
				lastFrame = love.timer.getTime()
			end
			
			standTick = 0
			moving = true
			break
		end
	end
	if not moving then
		standTick = standTick + 1
		if standTick > resetLimit then
			object[0].status = 2
		end
	end
end

function map:draw()
	love.graphics.setColor(255, 255, 255, 255 / 30 * clock)
	local width, height = love.graphics.getDimensions()
	width = width / info.tileWidth
	height = height / info.tileHeight
	local halfWidth, halfHeight = width / 2, height / 2
	local pos = {
		x = info.width <= width and (info.width - 1) / 2 or 
			utils.limit(object[0].position.x, halfWidth, info.width - halfWidth),
		y = info.height <= height and (info.height - 1) / 2 or 
			utils.limit(object[0].position.y, halfHeight, info.height - halfHeight)
	}
	
	local colLeft, colRight = pos.x - halfWidth, pos.x + halfWidth
	local lineLeft, lineRight = pos.y - halfHeight, pos.y + halfHeight
	for i = 1, #layer do
		for line = lineLeft, lineRight + 1 do
			for col = colLeft, colRight + 1 do
				if layer[i][math.floor(line)] and layer[i][math.floor(line)][math.floor(col)] then
					local cur = layer[i][math.floor(line)][math.floor(col)]
					love.graphics.draw(tileset[cur.tile].source, tileset[cur.tile].quad[cur.id],
						(col - colLeft - utils.tail(colLeft)) * info.tileWidth,
						(line - lineLeft - utils.tail(lineLeft)) * info.tileHeight)
				end
			end
		end
		if i == 2 then
			local order = {}
			for k = 0, #object do
				table.insert(order, k)
			end
			table.sort(order, function(a, b) 
				return object[a].position.y < object[b].position.y
			end)
			for p = 1, #order do
				local k = order[p]
				local v = object[k]
				love.graphics.draw(character.source[character[k].source].source,
					character[k][v.faceto][v.status],
					(v.position.x - colLeft - 0.5) * info.tileWidth,
					(v.position.y - lineLeft + 0.25) * info.tileHeight - character.source[character[k].source].height)
			end
		end
	end
end

function map:mousepressed(x, y, button, istouch)
	
end

function map:keypressed(key)
	if key == "escape" then
		scene_manager:overlay(exit)
	elseif key == "return" then
		for k, v in pairs(movement) do
			if v[1] == object[0].faceto then
				for i = 1, #object do
					local nx = object[0].position.x + v[2]
					local ny = object[0].position.y + v[3]
					if utils.maxDistance({x = nx, y = ny}, object[i].position) < 0.5 then
						if object[i].talk then
							object[i].talk()
						end
						break
					end
				end
			end
		end
	elseif key == "lshift" then
		updateSpeed(speed * 2)
	end
end

function map:keyreleased(key)
	if key == "lshift" then
		updateSpeed(speed / 2)
	end
end

return map 
