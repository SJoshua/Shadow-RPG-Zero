--------------------------------------------
-- Resource Manager
-- Au: SJoshua
--------------------------------------------
local M = {}

function M:init()
	font = {
		NotoSansCJK = {
			[30] = love.graphics.newFont("resource/fonts/NotoSansCJKtc-Regular.otf", 30),
			[40] = love.graphics.newFont("resource/fonts/NotoSansCJKtc-Regular.otf", 40),
			[60] = love.graphics.newFont("resource/fonts/NotoSansCJKtc-Regular.otf", 60)
		}
	}
end

return M
