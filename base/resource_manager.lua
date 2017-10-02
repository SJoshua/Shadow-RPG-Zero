--------------------------------------------
-- Resource Manager
-- Au: SJoshua
--------------------------------------------
local utils = require("base.utils")

local M = {}

local font_ext = {
	".otf",
	".ttf"
}

local image_ext = {
	".jpg",
	".png"
}

function M:init()
	font = setmetatable({}, {
		__index = function (table, key)
			for _, ext in pairs(font_ext) do
				local path = "resource/fonts/" .. key .. ext
				if utils.touch(path) then
					table[key] = setmetatable({
						path = path
					}, {
						__index = function (table, size)
							if type(size) == "number" then
								table[size] = love.graphics.newFont(table.path, size)
								return table[size]
							end
						end
					})
					return table[key]
				end
			end
		end
	})
	image = setmetatable({}, {
		__index = function (table, key)
			for _, ext in pairs(image_ext) do
				local path = "resource/images/" .. key .. ext
				if utils.touch(path) then
					table[key] = love.graphics.newImage(path)
					return table[key]
				end
			end
		end
	})
end

return M
