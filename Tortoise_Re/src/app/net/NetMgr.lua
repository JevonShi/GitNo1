local protobuf = require("protobuf")
local socket = require("socket")
local M = class("WSMgr")
local s2c = require("app.net.s2c")

local  HeartCount = 0
local  HeartTime = 2                 -- 2秒一次心跳
local  TimesOut  = 10                 -- 最大心跳包次数
local  reconnState = 0

function M:ctor( ... )
	self.ws = nil
    self.heartBeatTimer = nil
    self._reconnectSchedule = nil
end

function M:init( ... )
    self.lastSendTime = self:getSysTime()
    self.lastRecieveTime = self:getSysTime()
    self.isPinging = false
    self.isMapInit = false
    self:stopTimer()
end

function M:stopTimer( ... )
   if self.heartBeatTimer ~= nil then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.heartBeatTimer)
        self.heartBeatTimer = nil
    end
end

function M:connect( url )
    self:init()
    self.url = url
	if self.ws ~= nil then
		self:close()
	end
   
	self.ws = cc.WebSocket:create(url)
     print('-----------------------URL :',url..'     --------------------------WS :',self.ws)
     --接收服务器下行协议
	if self.ws then
        self.ws:registerScriptHandler(handler(self, self.onOpen), cc.WEBSOCKET_OPEN )
        self.ws:registerScriptHandler(handler(self, self.onMessage), cc.WEBSOCKET_MESSAGE)
        self.ws:registerScriptHandler(handler(self, self.onClose), cc.WEBSOCKET_CLOSE)
        self.ws:registerScriptHandler(handler(self, self.onError), cc.WEBSOCKET_ERROR)
    end
    
end

function M:setTimeOutCount(n)
    TimesOut = math.ceil(n/HeartTime)+1
end
--[[
 开始发送心跳协议
]]
function M:startHearbeat()
    --print("call startHearbeat---->")
    
    eventCenter:on("GAME_PONG" , function(e)
        local recvMsg = protobuf.decode("pbghost.HeartbeatRsp",e.msg)
        --dump(recvMsg,'--------EEEEEE :')

        self.lastRecieveTime = self:getSysTime()*1000
        print('---------LastRecieveTime :',self.lastRecieveTime)
        print('---------recvMsg.timestamp :',recvMsg.timestamp)
        local delayMS = self.lastRecieveTime - recvMsg.timestamp
        --local time2=os.time()
        --local data2=os.date("%Y-%m-%d %H:%M:%S",time2)
        --print('---------data :',data2)
        print('-----delayMS :',delayMS)
        eventCenter:dispatchEvent({name = "SKEVNT_PING",msg = {notifyData = delayMS}})
        eventCenter:dispatchEvent({ name = "GAME_HEARTBEAT_EVENT"}) --心跳包事件

        --self:ping()
        --print("the delayMS is --->",delayMS)
    end , "WSMgr")
   
    --self.lastRecieveTime = self:getSysTime()
    if not self.isPinging then
        self.isPinging = true
        self:ping()  --发送心跳协议
        self.heartBeatTimer = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self,self.ping), 1, false)
    end
end

function M:ping( ... )
    --print("call ping---->")
    self.lastSendTime = self:getSysTime()*1000
    print('-------------------发送心跳协议----------')
    self:sendMsg(CLIENT_2_SERVER.HEARTBEAT,"pbghost.HeartbeatReq",{timestamp = self.lastSendTime})
    --local time1=os.time()
    --local data1=os.date("%Y-%m-%d %H:%M:%S")
    --print('---------data :',data1)
end

function M:setHeartCount( cnt )
    --print("call setHeartCount--->",cnt)
    HeartCount = cnt
end

function M:onOpen( data )
    HeartCount = 0
	--print('------------ws onOpen',data,HeartCount)
    print('--------------Open------------------')
    self:startHearbeat()
    --if not self.isMapInit then
        eventCenter:dispatchEvent({ name = "SKEVNT_CONNECTED"})
    --end
end

function M:setMapInit( binit )
    self.isMapInit = binit
end

function M:onMessage( data )
    --dump(data,"---------------------服务器 data :")
    local msg = protobuf.decode("pbghost.Packet",data)
    --dump(msg,"---------------------服务器 msg :")
    if msg.uri~=1 then
        --print('----------收到服务器信息----------------------')
    end
    print('-------------OnMessage  :',msg.uri)
    s2c:parse(msg.uri,msg.body)
end

function M:getState( ... )
    return self.ws:getReadyState()
end

function M:onClose( data )
	print('-----------------------------ws onClose')
    eventCenter:dispatchEvent({ name = "SKEVNT_CLOSE"})
    --cc.DataMgr:setIsReloginGame(false)
    --自身客户端断线

    --HYGameBridge:getInstance():gameFinish(4, {})
    self:doReconnect()
end

function M:onError( data )
	print('ws onError :',data)
    --dump(data,'------------------------data :')
    eventCenter:dispatchEvent({ name = "SKEVNT_ERROR"})
    --[[
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(function() 
        cc.DataMgr:setIsReloginGame(false)
        self:doReconnect()
    end,0.3,false)
    ]]
end

-- 重连
function M:doReconnect()
    if cc.DataMgr:getIsReloginGame() then --已经在断线重连状态
        return
    end
    self:close()
    
    if self._reconnectSchedule ~= nil then
        return
    end

    local scheduler = cc.Director:getInstance():getScheduler()
    self._reconnectSchedule = scheduler:scheduleScriptFunc(
        function()
            if self:isSocketOpen() or cc.DataMgr:getGameOver() then
                self:clearReconnect()
            else
                if cc.DataMgr:getIsReloginGame() then --已经在断线重连状态
                    return
                end
                cc.DataMgr:setIsReloginGame(true) --设置断线重连状态
                --cc.DataMgr:setNoNetTag(true)
                --self..gameHeartbeatTime
                --cc.DataMgr:getTortoiseClass().gameHeartbeatTime=0
                cc.DataMgr:getTortoiseClass().curGameState=GAME_STATE.LOSE
                cc.DataMgr:getTortoiseClass():PlayerTimerPause()
                self:doConnect()
            end
        end,
        2,
        false
    )
end

function M:doConnect()
    self:connect(self.url)
end

--[[
    socket是否为链接状态
]]
function M:isSocketOpen()
    if self.ws and self.ws:getReadyState() == cc.WEBSOCKET_STATE_OPEN then
        return true
    end
    return false
end

function M:clearReconnect()
    local scheduler = cc.Director:getInstance():getScheduler()
    if self._reconnectSchedule ~= nil then
        scheduler:unscheduleScriptEntry(self._reconnectSchedule)
        self._reconnectSchedule = nil
    end
end


function M:close()
    if self.ws then
        self.ws:close()
        self.ws = nil
    end

    self:stopTimer()
    self:clearReconnect()
    eventCenter:removeEventListenersByTag("WSMgr")
end

function M:getSysTime( ... )
    return socket.gettime()
end

function M:sendMsg( msgId,protoT,data )
    --print("-------------sendMsg--->",msgId)
    if msgId~=CLIENT_2_SERVER.HEARTBEAT then
       print("-------------sendMsg--->",msgId)
    end
    local buf = protobuf.encode(protoT, data)
    --dump('-----------------Buf :',buf)
    self:sendMsg_(msgId,buf)
end

function M:sendMsg_( msgId , data )

    if self.ws ~= nil then
        --print('-----------------------发送协议')
        local tp = { uri = msgId, body = data }
        local tpBuf = protobuf.encode("pbghost.Packet", tp)
        print(type(tpBuf), tpBuf)
	   self.ws:sendString(tpBuf)
    else
        print("calll---->")
    end
end

cc.NetMgr = M.new()

return M