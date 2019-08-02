local M = class("DataMgr")

function M:ctor()
	self.otherPlayerID = 0         --别的玩家的id

	self.actorID = 0          --我自己的id
	
	self.actorInfo = {}

	self.actorHandCardCount=0  --玩家开始的手牌长度

	self.otherPlayerInfo = {}
    
    self.allPlayerInfo={}

	self.gameOver = false

	self.mapInfo = nil

	self.state = 0
	self.winid = 0

	self.playerHandCards={}

	self.beDrawPlayerID=0
	self.beDrawCardValue=0

	self.drawPlayerPosIndex=0
	--AI 出牌的数据
	self.AIPlayCardMsg={}

	self.TortoiseSceneClass=nil
	--动画同步
	self.isSyncTween=false
	--是否选择了牌 用于同步其他玩家的选牌动画
	self.isChooseCard=false
	--是否开始抽牌
	self.isStartDrawCard=false

	self.gameOverMsg=nil

	self.isAIDrawCard=false
	self.DrawCardAI_ID=0 --当前抽牌的AI ID
	self.isPlayCard=false --是否进入出牌阶段
	self.isAIDrawCardComplete=false --AI是否已经抽牌完成

	self.isReloginGame=false --已经游戏重连

	self.mainPlayerID=0

	self.gameProtocolState=0
	
	self.connectSuccess=false --收到服务器的第一次心跳

	self.haveDrawCard=false;

	self.pokerSuit={"♤","♡","♧","♢"}
    self.pokerNum={'6','7','8','9','10','J','Q','K'}

    self.actorChooseCardNum=0 --当前选择牌的牌值

    self.actorChooseCard=nil

    self.actorTrustState=false --自身客户端是否托管抽牌

    self.recycleState=false

    self.actorDrawCardState=false --客户端托管抽牌

    self.trustCardNum=0

    self.lastCard=nil

    self.zombieAnimation=false --zombie Animation is play

    self.aiEmojiState=false

    self.playCardData=nil --出牌信息

    self.normalPlayCard=false --客户端正常托管出牌状态

    self.exitState=false --玩家是否主动退出

    self.drawCardMsg=nil

    self.netTag=false

end
--[[
	是否收到服务器新提
]]
function M:setConnectSuccess(isSuccess)
	self.connectSuccess=isSuccess
end

function M:getConnectSuccess()
	return self.connectSuccess
end

function M:setPlayerInfo(index,info)
	self.allPlayerInfo[index]={}
	self.allPlayerInfo[index] = info
	--dump(info,'---------info :')
end

function M:getPlayerInfo(index)
	return self.allPlayerInfo[index]
end

function M:getAllPlayerInfo()
   return self.allPlayerInfo
end

function M:setState( st )
	self.state = st
end

function M:getState( ... )
	return self.state
end

function M:setWinnerId( wid )
	self.winid = wid
end

function M:getWinnerId( ... )
	return self.winid
end
--[[
	设置游戏结束
]]
function M:setGameOver( go )
	self.gameOver = go
end

function M:getGameOver( ... )
	return self.gameOver
end

function M:setActorInfo( info )
	self.actorInfo = info
end

function M:getActorInfo( ... )
	return self.actorInfo
end

--[[
	记录自身客户端的ID
]]
function M:setActorID( id )
	self.actorID = id
end
--
function M:getActorID( ... )
	return self.actorID
end

--[[
	设置各个玩家的手牌
]]
function M:setPlayerHandCards(index,cards)
  --self.playerHandCards[index]={}
  self.playerHandCards[index]=cards
end

function M:getPlayerHandCards(index)
   return self.playerHandCards[index]
end

--[[
记录客户端选牌的牌值
]]
function M:setActorChooseCardNum(cardNum)
	self.actorChooseCardNum=cardNum
end
--[[

]]
function M:getActorChooseCardNum()
	return self.actorChooseCardNum
end
--[[
	记录当前客户端抽的牌对象
]]
function M:setActorChooseCard(card)
	self.actorChooseCard=card
end

function M:getActorChooseCard()
	return self.actorChooseCard
end

function M:getBeDrawCardValue()
	return self.beDrawCardValue
end
--[[
	记录AI出牌信息
]]
function M:setAIPlayCardMsg(msg)
	--dump(msg," MSG :")
	self.AIPlayCardMsg=msg
end

function M:getAIPlayCardMsg()
	return self.AIPlayCardMsg
end

function M:setActorCardsCount(count)
	self.actorHandCardCount=count
end
function M:getActorCardsCount()
	return self.actorHandCardCount
end

function M:setTortoiseClass(class)
	self.TortoiseSceneClass=class
end

function M:getTortoiseClass(class)
	return self.TortoiseSceneClass
end

function M:setIsSyncTween(isSync)
	self.isSyncTween=isSync
end

function M:getIsSyncTween()
	return self.isSyncTween
end
--[[
	是否进入选牌阶段
]]
function M:setIsChooseCard(isChoose)
	self.isChooseCard=isChoose
end

function M:getIsChooseCard()
	return self.isChooseCard
end

--[[
	记录游戏结束信息
]]
function M:setGameOverMsg(msg)
	self.gameOverMsg=msg
end

function M:getGameOverMsg()
	return self.gameOverMsg
end

function M:setDrawCardAIID(id)
	self.DrawCardAI_ID=id
end

function M:getDrawCardAIID()
	return self.DrawCardAI_ID
end
--[[
	是否进入AI抽牌阶段
]]
function M:setIsAIDrawCard(isDraw)
	self.isAIDrawCard=isDraw
end

function M:getIsAIDrawCard()
	return self.isAIDrawCard
end
--[[
	是否进入出牌阶段
]]
function M:setIsAIPlayCard(isPlay)
	self.isPlayCard=isPlay
end

function M:getIsAIPlayCard()
	return self.isPlayCard
end
--[[
	设置是否已经断线重连
]]
function M:setIsReloginGame(isRelogin)
	self.isReloginGame=isRelogin
end

function M:getIsReloginGame()
	return self.isReloginGame
end


function M:setGameClientPlayerIDList(playerList)
	self.clientPlayerIDList={}
	self.clientPlayerIDList=playerList
end

function M:getGameClientPlayerIDList()

	return self.clientPlayerIDList
end
--[[
	设置主机玩家ID
]]
function M:setMainPlayerID(playerID)
	self.mainPlayerID=playerID
	print('--------------设置主机玩家  主机玩家的ID :',self.mainPlayerID)
end
--获取主机玩家ID
function M:getMainPlayerID()
	print('---------------------获取主机玩家的ID :',self.mainPlayerID)
	return self.mainPlayerID
end
--[[
	根据玩家ID获取客户端玩家在客户端玩家列表中的索引
]]
function M:getClientPlayerIndexByPlayerID(playerID)
	for i=1,#self.clientPlayerIDList do
		if self.clientPlayerIDList[i]==playerID then
			print('---------------客户端玩家索引 :',i)
			return i
		end
	end
end

--[[
	根据ID获取玩家信息
]]
function M:getPlayerInfoByID(playerID)
	for i=1,#self.allPlayerInfo do
		if self.allPlayerInfo[i].PlayerId==playerID then
			return self.allPlayerInfo[i]
		end
	end

end

--[[
	根据ID获取玩家列表中的索引
]]
function M:getPlayerIndexByID(playerID)
	--print('---------allPlayerInfo Len :',#self.allPlayerInfo)
	--dump(self.allPlayerInfo,'------------self.allPlayerInfo :')
	local len=#self.allPlayerInfo
	for i=1,len do
		local PlayerId=tonumber(self.allPlayerInfo[i].PlayerId)
		if PlayerId==playerID  then
			return i
		end
	end
	print('----------playerID :',playerID)
	--dump(self.allPlayerInfo,'-------------self.allPlayerInfo :')
end

--[[
	设置游戏协议状态
]]
function M:setGameProtocolState(protocol)
	self.gameProtocolState=protocol
end

function M:getGameProtocolState()
	return self.gameProtocolState
end

--[[
	获取扑克的花色
]]
function M:getPokerSuit(index)
	return self.pokerSuit[index]
end
--[[
	获取扑克的牌值
]]
function M:getPokerNum(index)
	return self.pokerNum[index]
end
--[[
	设置是否已经抽牌
]]
function M:setHaveDrawCard(isHave)
	self.haveDrawCard=isHave
end
--[[
	获取抽牌状态
]]
function M:getHaveDrawCard()
	return self.haveDrawCard
end


function M:setActorTrustState(isTrust)
	self.actorTrustState=isTrust
	print('---------------------self.actorTrustState :',self.actorTrustState)
end

function M:getActorTrustState()
	return self.actorTrustState
end

function M:setTrustCardNum(CardNum)
	self.trustCardNum=CardNum
end

function M:getTrustCardNum()
	return self.trustCardNum
end

function M:setRecycleState(isRecycle)
	self.recycleState=isRecycle
end

function M:getRecycleState()
	return self.recycleState
end

function M:setActorDrawCardState(isState)
	self.actorDrawCardState=isState
end

function M:getActorDrawCardState()
	return self.actorDrawCardState
end

function M:setLastCard(card)
	self.lastCard=card
end

function M:getLastCard()
	return self.lastCard
end

function M:setZombieAnimation(isPlay)
	self.zombieAnimation=isPlay
end

function M:getZombieAnimation()
	return self.zombieAnimation
end

function M:setAIEmojiState(state)
	self.aiEmojiState=state
end

function M:getAIEmojiState()
	return self.aiEmojiState
end

function M:setPlayCardMsg(msg)
	self.playCardData=msg
end

function M:getPlayCardMsg()
	return self.playCardData
end

function M:setNormalPlayCardState(state)
	self.normalPlayCard=state
	print('-------Set self.normalPlayCard :',self.normalPlayCard)
end

function M:getNormalPlayCardState()
	print('-------Get self.normalPlayCard :',self.normalPlayCard)
	return self.normalPlayCard

end

function M:setExitState(state)
	self.exitState=state
end

function M:getExitState()
	return self.exitState
end

function M:setDrawCardMsg(msg)
	self.drawCardMsg=msg
end

function M:getDrawCardMsg()
	return self.drawCardMsg
end

function M:setNoNetTag(tag)
	self.netTag=tag
end

function M:getNoNetTag()
	return self.netTag
end

cc.DataMgr = M.new()

return M