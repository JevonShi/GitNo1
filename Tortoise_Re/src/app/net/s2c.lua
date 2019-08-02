local s2c = {}
--[[
	这个数据结构有些差强人意
]]
local s2cEventKey={
	"GAME_PONG",
	"",
	"",
	"GET_PLAYER",
	"PLAYER_EMOJI",
	"",
	"",
	"PLAYER_OUT",
	"GAME_END",
	"",
	"PLAYER_RELOGIN",
	"GET_PLAYERHANDCARD",
	"PLAY_HANDCARD",
	"PLAYER_CLICK_HANDCARD",
	"REFRESH_POKER",
	"AI_CHOOSE_HANDCARD",
	"PLAYER_LOSE",
	"PLAYER_SYNC_TOON",
	"NEXT_PLAYER_ROUND",
	"GAEM_WASH_POKER",
	"PLAYER_GAME_OVER",
	"GET_CARD_NUM",
}

--[[
  服务器下行协议解析
]]
function s2c:parse(cmd,body)
	print('------------cc.DataMgr:getNoNetTag() :',cc.DataMgr:getNoNetTag())
	if cc.DataMgr:getNoNetTag() then
		if cmd==1 or cmd==17 or cmd==11 then
			eventCenter:dispatchEvent({	name = s2cEventKey[cmd],msg=body})
		end
		return
	end
	print('---------------------收到服务器协议-----------CMD: ',cmd)
	eventCenter:dispatchEvent({	name = s2cEventKey[cmd],msg=body})
end


return s2c