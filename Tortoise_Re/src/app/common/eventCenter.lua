
local eventCenter = require("cocos.framework.components.event").new()

eventCenter.SERVER_TIME = "SERVER_TIME" --服务器时间通知
eventCenter.ADD_ICE = "ADD_ICE"
eventCenter.PLAY_AGAIN = "PLAY_AGAIN"
eventCenter.CHANGE_PLAYER = "CHANGE_PLAYER"
eventCenter.GAME_START = "GAME_START"
eventCenter.GAME_END = "GAME_END"
eventCenter.NEW_LINE = "NEW_LINE"
eventCenter.MAP_INFO = "MAP_INFO"
eventCenter.GAME_STOP = "GAME_STOP"
eventCenter.GAME_RECOVER = "GAME_RECOVER"
eventCenter.GAME_PONG = "GAME_PONG"

eventCenter.SKEVNT_ERROR = "SKEVNT_ERROR"
eventCenter.SKEVNT_CONNECTED = "SKEVNT_CONNECTED"

eventCenter:bind({})


--[[
用法:
	在需要注册消息的地方
	eventCenter:on("SERVER_TIME" , function(e)
		self:onServerTime(e)
	end , "roomControl")

	发送消息时则调用
	eventCenter:dispatchEvent({ name = "SERVER_TIME",data = receiveData})
]]
return eventCenter