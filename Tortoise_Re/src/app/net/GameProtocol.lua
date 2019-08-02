--require('app.scenes.TortoiseScene')

GameProtocol=class("GameProtocol")

local c=GameProtocol


math.randomseed(tostring(os.time()):reverse():sub(1, 7) .. math.random(1,10000))
PalyerId = math.random(30000,50000)
--[[
  字符串切割
]]
function stringSplit(str)
    local symindex={}
    local oid={}
    for k = 1,string.len(str) do
      if string.sub(str,k,k) == ',' then
        table.insert(symindex,k)
      end
    end
    local firstID=string.sub(str,1,symindex[1]-1)
    table.insert(oid,tonumber(firstID))
    for k=1,#symindex-1 do
      table.insert(oid,string.sub(str,symindex[k]+1,symindex[k+1]-1))
    end
    table.insert(oid,string.sub(str,symindex[#symindex]+1,string.len(str)))
    return oid
end

function c:ctor(...)
 self.eventListeners = {}
 self.isLoading=false --是否已经Loading
 self.isGameStart=false --游戏是否已经开始
 self.isSyncTween=false --是否在同步动作
 self.isStartDrawCard=false --是否开始抽牌
end

function c:connectServer( ... )

    local platformUrl =nil
    --local platformUrl = 'ws://192.168.18.30:12003/?postData={"roomId":"22334","player":{"uid":'..tostring(PalyerId)..',"name":"name","avatarUrl":"http://dsads.sad","sex":1,"ai":false},"other":{"uid":2132,"name":"name2","avatarUrl":"http://dsads.sad","sex":1,"ai":true},"other1":{"uid":2142,"name":"name3","avatarUrl":"http://dsads.sad","sex":1,"ai":true},"other2":{"uid":2152,"name":"name4","avatarUrl":"http://dsads.sad","sex":1,"ai":true}}'
    if device.platform == "windows" then
      PalyerId=99999999--8888888 99999999,223454364,3123124
      --192.168.18.34:12003
      --127.0.0.1:12003
      --platformUrl = 'ws://192.168.18.32:11019/?postData={"roomId":"22334","player":{"uid":'..tostring(PalyerId)..',"name":"name","avatarUrl":"http://dsads.sad","sex":1,"ai":false},"other":{"uid":2132,"name":"name2","avatarUrl":"http://dsads.sad","sex":1,"ai":false},"other1":{"uid":2142,"name":"name3","avatarUrl":"http://dsads.sad","sex":1,"ai":false},"other2":{"uid":2152,"name":"name4","avatarUrl":"http://dsads.sad","sex":1,"ai":false}}'
      platformUrl ='ws://192.168.18.108:12003/?timestamp=1558062317123&nonce=5fw3x4&sign=3a1d35e2b07cb09ec35fddf6c4480055&uid='..PalyerId..'&roomId=32436547658768678768&players=[[99999999],[223454364],[3123124],[8888888]]&ai=[223454364,3123124,8888888]&v=1'  --223454364,3123124,8888888
    else
      platformUrl = HYGameBridge:getInstance():getGameURL()
    end

    local orgUrl = platformUrl
    --cc.DataMgr:setActorID(PalyerId)
    local _,startpos = string.find(platformUrl,"uid=")
    --print('-------------startpos :',startpos)
    local isExist,endpos=string.find(platformUrl,"&roomId")
    --print('-------------endpos :',endpos)
    local jsonData = string.sub(platformUrl,startpos+1,endpos-7)

    print('-------------ActorID :',tonumber(jsonData))
    cc.DataMgr:setActorID(tonumber(jsonData))

    local _,otherStartPos= string.find(platformUrl,"players=")
    local isExist,otherEndPos=string.find(platformUrl,"&ai")
    local otherData = string.sub(platformUrl,otherStartPos+2,otherEndPos-3)
    otherData=string.gsub(otherData,"[%[%]]","")

    local allPlayerID=stringSplit(otherData)

    for n=1,#allPlayerID do
      cc.DataMgr:setPlayerInfo(n,{PlayerId=allPlayerID[n]})
      
    end

    cc.NetMgr:setTimeOutCount(10)
    cc.NetMgr:connect(orgUrl)

    self.TortoiseScene=cc.DataMgr:getTortoiseClass()
end

function c:addEvent( ... )

    eventCenter:on("GAME_END" , function(e)
        --self:showEnd(e.msg)
      local recvMsg = protobuf.decode("pbghost.GameWinInfo",e.msg)
      print('-----------收到游戏结束协议-----------')
      self.TortoiseScene:RecordGameOverMsg(recvMsg.Game)
    end , "TortoiseScene")

    eventCenter:on("SKEVNT_CONNECTED" , function(e)
        self:onConnected(e)
    end ,  "TortoiseScene")

    eventCenter:on("GET_PLAYER" , function(e)
        local recvMsg = protobuf.decode("pbghost.PlayerInfoRsp",e.msg)
        self:GetPlayer(recvMsg.players)
    end ,  "TortoiseScene")
    eventCenter:on("GAME_START" , function(e)
      if not self.isGameStart then
        self:runGameStart()
      end
    end ,"TortoiseScene")

    eventCenter:on("GET_PLAYERHANDCARD" , function(e)
      local recvMsg = protobuf.decode("pbghost.PokerMsg",e.msg)
      self:GetPlayerHandCard(recvMsg)
    end ,"TortoiseScene")
    
    eventCenter:on("PLAYER_CLICK_HANDCARD" , function(e)
      --if not cc.DataMgr:getIsChooseCard() then
        local recvMsg = protobuf.decode("pbghost.ClickInfo",e.msg)
        self:SyncClickCard(recvMsg)
      --end
    end ,"TortoiseScene")
    
    eventCenter:on("PLAYER_SYNC_TOON",function (e)
      if not cc.DataMgr:getIsSyncTween() then
        local recvMsg = protobuf.decode("pbghost.ChooseInfo",e.msg)
        self:SyncPlayerToon(recvMsg)
      end
    end,"TortoiseScene")
    eventCenter:on("AI_CHOOSE_HANDCARD",function (e)
      local recvMsg = protobuf.decode("pbghost.ChooseInfo",e.msg)
      self:AIDrawACard(recvMsg)
    end, "TortoiseScene")
    
    eventCenter:on("PLAY_HANDCARD",function (e)
      local recvMsg = protobuf.decode("pbghost.OutCard",e.msg)
      self:PlayHandCard(recvMsg)
    end, "TortoiseScene")

    eventCenter:on("NEXT_PLAYER_ROUND",function (e)
      local recvMsg = protobuf.decode("pbghost.RoundInfo",e.msg)
      self:StartDrawCard(recvMsg)
    end, "TortoiseScene")

    eventCenter:on("PLAYER_LOSE",function (e)
      local recvMsg = protobuf.decode("pbghost.LoseInfo",e.msg)
        --其他玩家掉线
      self:OtherPlayerLose(recvMsg)
    end, "TortoiseScene")


    eventCenter:on("PLAYER_RELOGIN",function(e)
      local recvMsg = protobuf.decode("pbghost.ReLoginInfo",e.msg)
      self:PlayerRelogin(recvMsg)
      --end
    end,"TortoiseScene")

    eventCenter:on("GAME_HEARTBEAT_EVENT",function(e)
     --print('-------------GAME_HEARTBEAT_EVENT ------')
      self.TortoiseScene.gameHeartbeatTime=0
    end,"TortoiseScene")

     eventCenter:on("PLAYER_EMOJI",function(e)
      local recvMsg = protobuf.decode("pbghost.EmojiInfo",e.msg)
      eventCenter:dispatchEvent({ name = "PLAYER_EXPRESSIONS_EVENT", notifyData = recvMsg })
    end,"TortoiseScene")

     eventCenter:on("GAEM_WASH_POKER",function(e)
      local recvMsg = protobuf.decode("pbghost.WashInfo",e.msg)
      self:GamePlayerShuffle(recvMsg)
    end,"TortoiseScene")

    eventCenter:on("GET_CARD_NUM",function(e)
      local recvMsg = protobuf.decode("pbghost.CardInfo",e.msg)
      dump(recvMsg,'-----------------------牌值协议recvMsg :')
      self.TortoiseScene:PlayerOpenCard(recvMsg.CardNum)
    end,"TortoiseScene")

    eventCenter:on("PLAYER_GAME_OVER",function(e)
      local recvMsg = protobuf.decode("pbghost.OverInfo",e.msg)
      dump(recvMsg,'-----recvMsg :')
      self.TortoiseScene:PlayerVitory(recvMsg)
    end,"TortoiseScene")

end

--[[
 游戏连接成功
]]
function c:onConnected( ... )
	print(' ---------Connect-----------')
end


--[[
 游戏开始
]]
function c:runGameStart( ... )
  --print('-------Game Start--------------')
  print('----发牌------')
  self.isGameStart=true

end
--[[
    获取玩家列表
]]
function c:GetPlayer(msg)
   --dump(msg,'-------recvMsg :')
    if not self.isLoading then
      print('-----------发送Loading协议-----------')
      self.isLoading=true
      cc.NetMgr:sendMsg(CLIENT_2_SERVER.LOADING,"pbghost.LoadingReq",{})
    end
end

--[[
  获取玩家手牌
]]
function c:GetPlayerHandCard(msg)
     local pokerMsg=msg.Poker
     local washMsg=msg.WashInfo
     local clientPlayerIDList={} --客户端ID列表
     dump(pokerMsg,'----------------玩家手牌Msg :')
     for k,v in pairs(pokerMsg) do
       cc.DataMgr:setPlayerInfo(k,{PlayerId=v.PlayerId,AI=v.AI})
       if cc.DataMgr:getActorID()==v.PlayerId then
        print('-----------记录自己客户端信息-----------')
          cc.DataMgr:setActorID(v.PlayerId)
          cc.DataMgr:setActorInfo({PlayerId=v.PlayerId})
       end
       --不是AI
       if not v.AI then
          local playerIndex=#clientPlayerIDList+1
          table.insert(clientPlayerIDList,playerIndex,v.PlayerId)
       end
    end
    cc.DataMgr:setGameClientPlayerIDList(clientPlayerIDList) --记录游戏所有客户端玩家的ID
    --dump(msg,'-------recvMsg :')
    local allPlayerInfo=cc.DataMgr:getAllPlayerInfo()
    --print('---------- allPlayerInfo :',#allPlayerInfo)
    --dump(allPlayerInfo,'---------- allPlayerInfo :')
    local playPlayerID=nil --出牌玩家ID
    --记录玩家信息
    for k,v in pairs(pokerMsg) do
     for key,info in pairs(allPlayerInfo) do
        local playerInfo=info
        if playerInfo.PlayerId==v.PlayerId then
          playerInfo.PlayerId= v.PlayerId  
          playerInfo.Sort=v.Sort
          playerInfo.PokerList=v.PokerList
          playerInfo.Seat=v.Seat+1
          --print('------------cc.DataMgr:getActorID() :',cc.DataMgr:getActorID())
          if cc.DataMgr:getActorID()==v.PlayerId then
            local actorInfo=cc.DataMgr:getActorInfo()
            actorInfo.PlayerId= v.PlayerId  
            actorInfo.Sort=v.Sort
            actorInfo.PokerList=v.PokerList
            actorInfo.Seat=v.Seat+1
            --dump(cc.DataMgr:getActorInfo(),'-------------------------actorInfo :')
          end
        end
     end
     if v.Sort>0 then
        playPlayerID=v.PlayerId
     end
    end
    --自己客户端在第一
    for i=1,#allPlayerInfo do
      if allPlayerInfo[i].PlayerId==cc.DataMgr:getActorID() then
          if i~=1 then
           local temp=allPlayerInfo[i]
           allPlayerInfo[i]=allPlayerInfo[1]
           allPlayerInfo[1]=temp
          end
          break
      end
    end
    local playerSeat=cc.DataMgr:getActorInfo().Seat
    local nextSeat=(playerSeat+1==5 and 1)or playerSeat+1
    print('------------NextSeat :',nextSeat)
    self.TortoiseScene:PlayerSeatSort(cc.DataMgr:getAllPlayerInfo(),2,nextSeat)
    local AIIDList={}
    local allPlayerIDList={} --所有玩家的ID列表
    --dump(allPlayerInfo,'---------------------allPlayerInfo :')
    local isExitAI=false
    --dump(TortoiseScene.playerObj,'--------------------TortoiseScene.playerObj :')
    for i=1,#allPlayerInfo do

     self.TortoiseScene:SetPlayerGameInfo(i,allPlayerInfo[i])
     if allPlayerInfo[i].AI then
      isExitAI=true
      table.insert(AIIDList,#AIIDList+1,allPlayerInfo[i].PlayerId)
     end
      table.insert(allPlayerIDList,#allPlayerIDList+1,allPlayerInfo[i].PlayerId)
      
    end
    self.TortoiseScene:SetGameVoice(allPlayerIDList) --设置语音
    self.TortoiseScene:SetEmojiInfo(allPlayerIDList) --设置表情
    self.TortoiseScene.alreadyLoadPlayerInfo=true
    print('-------------self.TortoiseScene.alreadyLoadPlayerInfo :',self.TortoiseScene.alreadyLoadPlayerInfo)
    --dump(AIIDList,'-------AIIDList :')
    self.TortoiseScene.emojiChatLayer:setIsAIAutoSend(isExitAI,AIIDList) --是否开启AI自动回复表情
   
   self.TortoiseScene:Deal(washMsg) --发牌
end
--[[
  玩家洗牌
]]
function c:GamePlayerShuffle(msg)
  --dump(msg,'------------------------------MSG :')
  local isSelf=msg.PlayerId==cc.DataMgr:getActorID()
  local shuffleIndex=cc.DataMgr:getPlayerIndexByID(msg.PlayerId)
  print('-------------shuffleIndex :',shuffleIndex)
  print('-----------------isSelf :',isSelf)
  self.TortoiseScene:PlayerShuffle(shuffleIndex,isSelf,msg)
  --local time=os.time()
  --local date=os.date("%Y-%m-%d %H:%M:%S",time)
  --print('-------------------ShuffleCard Data :',date)
end

--[[
 ͬ同步点击牌操作
]]
function c:SyncClickCard(msg)
  --自己客户端不会同步自己的点牌操作
  --如果牌已经在抽牌了也不同步,直接同步抽牌操作
  if cc.DataMgr:getHaveDrawCard() or self.TortoiseScene.PlayIndex==1  then
    return
  end
  print('--------ActorID :',cc.DataMgr:getActorID())
  --cc.DataMgr:setIsChooseCard(true)
  dump(msg," MSG :")
  local playerObjs=self.TortoiseScene.playerObj
    for i=1,#playerObjs do
      if playerObjs[i]:GetPlayerID()==msg.PlayerId then 
        local handCards=playerObjs[i]:GetHandCard()
        print('------------playerSeatIndex :',i)
        for j=1,#handCards do
          if handCards[j]:GetPosIndex()==msg.Index then
            handCards[j].clickCount=0
            handCards[j]:ClickEvent()
            return
          end
        end
      end
    end
  --end
end

--[[
 ͬ同步其他玩家的动画
]]
function c:SyncPlayerToon(msg)
    --dump(msg," SyncToon  MSG :")
    if self.TortoiseScene.PlayIndex==1  then
      return
    end
    cc.DataMgr:setIsSyncTween(true)
    self.TortoiseScene:SyncDrawACard(msg.Index) --同步抽牌
end

--[[
 开始抽牌
]]
function c:StartDrawCard(msg)
    
    --dump(msg,'---------------开始抽牌协议信息 :')
    self.TortoiseScene:PlayerRoundStart(msg,false)
    --显示回合计时器
    self.TortoiseScene:ShowRoundTimer(self.TortoiseScene.PlayIndex)
    
    
    
end

--[[
 出牌协议
]]
function c:PlayHandCard(msg)

  local playCardPlayer=nil
  local playerObjs=self.TortoiseScene.playerObj
  print('   出牌玩家位置索引:',self.TortoiseScene.PlayIndex..'  出牌玩家ID :',playerObjs[self.TortoiseScene.PlayIndex]:GetPlayerID().."   Msg ID :",msg.PlayerId)
  
    for i=1,#playerObjs do
      if playerObjs[i]:GetPlayerID()==msg.PlayerId then
          playCardPlayer=playerObjs[i]
          print('----出牌玩家位置  :',playCardPlayer:GetPosIndex())
          break
      end
    end
    print('---------------cc.DataMgr:getNormalPlayCardState() :',cc.DataMgr:getNormalPlayCardState())
    if cc.DataMgr:getNormalPlayCardState() then --普通的出牌状态
        playCardPlayer:PlayCard(msg)
    else
        print('------------缓存出牌信息')
        cc.DataMgr:setPlayCardMsg(msg)
    end
    --[[
    if msg.PlayerId ~=cc.DataMgr:getActorID() then
      playCardPlayer:PlayCard(msg,playCardPlayer:GetIsAI())
    else 
      print('---------------cc.DataMgr:getNormalPlayCardState() :',cc.DataMgr:getNormalPlayCardState())
      if cc.DataMgr:getNormalPlayCardState() then --普通的出牌状态
        playCardPlayer:PlayCard(msg,playCardPlayer:GetIsAI())
      else
        print('------------缓存出牌信息')
        cc.DataMgr:setPlayCardMsg(msg)
      end
    end
    ]]
end


--[[
 AI抽牌
]]
function c:AIDrawACard(msg)
    dump(msg,'-----------------AI 抽牌信息 :')
    --AI抽牌
    self.TortoiseScene:AIStartDrawACard(msg)
    
end


function c:AIPlayCard(msg)
  dump(msg,'----------------AI 出牌协议信息 :')
  --cc.DataMgr:setIsAIPlayCard(true)
  --cc.DataMgr:setIsAIDrawCard(false)
  local playCardPlayer=self.TortoiseScene.playerObj[self.TortoiseScene.PlayIndex]
  --local playerObjs=TortoiseScene.playerObj
  --dump(msg,"MSG :")
  print(' AI出牌玩家位置索引:',self.TortoiseScene.PlayIndex..'   出牌AI玩家 :',playCardPlayer:GetPlayerID().."   AI出牌玩家ID :",msg.PlayerId)
  playCardPlayer:PlayCard(msg) 

end

--[[
  玩家掉线
]]
function c:OtherPlayerLose(msg)
  --dump(msg,'--------------玩家掉线信息:')
  --return
  --print('--------------------不会进来的---------')
  
  if msg.PlayerId==cc.DataMgr:getActorID() then
      --自身客户端断线重连
    cc.NetMgr:close()
    cc.NetMgr:doConnect()
    --self.TortoiseScene:RecycleAllPlayerHandCard()
  end
  
end
--[[
  玩家断线重连
]]
function c:PlayerRelogin(msg)
  if msg.PlayerId==cc.DataMgr:getActorID() then
    --print('----------自身客户端玩家断线重连--------------')
    --dump(msg,"---------------------断线重连的信息 :")
    self.TortoiseScene:RecycleAllPlayerHandCard()
    self.TortoiseScene:GameRelogin(msg)
  end
end

