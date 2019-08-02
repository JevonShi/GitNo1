

PlayerMgr = class("PlayerMgr")


local c=PlayerMgr

function c:ctor()
  self:Init()

end

function c:Init()
  --ID
  self.id=0
  --座位索引
  self.posIndex=0
  --手牌
  self.cards={}

  self.handCardNum={}

  self.startHandCardLen=0
  --牌桌位置
  self.cardBoardPos=nil
  --是否是AI
  self.isAI=false
  --是否是出牌阶段
  self.isPlay=nil
  --性别
  self.sex=1

  self.playerName=nil
  
  self.handCardNode=nil
  --抽到的牌
  self.drawCard=nil

  self.isWin=false

  self.TortoiseSceneClass=cc.DataMgr:getTortoiseClass()

  self.handCardValueList={}

  self.isZombie=false

  self.cardOriPos=nil

  self.headPortraitUrl=nil --头像图片Url

  self.clickArea=nil
end
--[[
  设置玩家名字
]]
function c:SetPlayerName(name)
  self.playerName=name
end

function c:GetPlayerName()
  print('----------------self.playerName :',self.playerName)
  return self.playerName
end

function c:SetPlayerID(id)
   self.id=id
end

function c:GetPlayerID()
   return self.id
end

function c:SetSex(sex)
  self.sex=sex
end

function c:GetSex()
  return self.sex
end

function c:SetHandCardNode(node)
  self.handCardNode=node
end
--[[
 玩家手牌
]]
function c:SetHandCard(playCard)
  if playCard==nil then
    self.cards={}
    self.handCardValueList=nil
    return
  end
  if not self.isWin then
    print(self.id..' # HandCardLen :',#playCard)
    self.cards=playCard
    self.handCardValueList={}
    for i=1,#self.cards do
      self.handCardValueList[i]=self.cards[i]:GetValue()
      self.cards[i]:SetPosIndex(i)
      self.cards[i]:GetObj():setLocalZOrder(i)
    end
    if self.cardOriPos==nil then
      self.cardOriPos={x=self.cards[1]:GetObj():getPositionX(),y=self.cards[1]:GetObj():getPositionY()}
    end
  end
end

function c:GetHandCard()
   return self.cards
end

function c:SetHandCardNum(cardNumArr)
  self.handCardNum=cardNumArr
  self.startHandCardLen=#cardNumArr
  --dump(self.handCardNum,'---------self.handCardNum :')
end
--返回服务器发送过来得手牌
function c:GetHandCardNum()
  return  self.handCardNum
end


function c:SetCardBoard(cardBoardPos)
  self.cardBoardPos=cardBoardPos
end
--[[
 转成AI操作
]]
function c:ActiveAI(isAI)
  self.isAI=isAI
  --print(self.id ..' ISAI :',self.isAI)
end

function c:GetIsAI()
  return self.isAI
end

--[[
  设置玩家座位索引
]]
function c:SetPosIndex(posIndex)
   self.posIndex=posIndex
end
function c:GetPosIndex()
  return self.posIndex
end

function c:SetPlayerWinState(isWin)
  self.isWin=isWin
end

function c:GetPlayerWinState()
  return self.isWin
end

function c:GetHandsValueList()
  local hands={}
  for i=1,#self.cards do
    table.insert(hands,#hands+1,self.cards[i]:GetValue())
  end
  return hands
end

function c:GetStartHandCardLen()
  return self.startHandCardLen
end
--[[
  设置玩家的是否是丧尸
]]
function c:SetZombieState(isZombie)
  self.isZombie=isZombie
end

function c:GertZombieState()
  return self.isZombie
end
--[[
  记录玩家头像URL
]]
function c:SetHeadPortraitUrl(url)
  self.headPortraitUrl=url
end

function c:GetHeadPortraitUrl()
  return self.headPortraitUrl
end

function c:SetClickArea(area)
  self.clickArea=area
end

function c:GetClickArea()
  return self.clickArea
end
--[[
  重置手牌索引
]]
function c:ResetHandCardIndex()
  --print('---------重置时手牌的长度 :',#self.cards)
  for i=1,#self.cards do
    self.cards[i]:SetPosIndex(i)
  end
end
--[[
出牌
 card --抽到的牌
]]
function c:PlayCard(msg)
  --dump(msg,"--------------------------------------PlayCard Msg :")
  print('---------------Card Len :',#self.cards)
  local playCardPosIndex=nil
  local playCardPos=nil
  local tempDrawCard=self.cards[msg.Index1+1]
  local tempDrawCardObj=self.cards[msg.Index1+1]:GetObj()
  local tempPlayCard=self.cards[msg.Index2+1]
  local gameMsg={} 
  local suitNum=0
  local suit={} --牌的花色
  local controlState=0
  local cardNumIndex={} --转换后的牌值数组
  local pokerNum={}
  suitNum=math.ceil(msg.OutCard1/8)
  print('---------suitNum :',suitNum)
  suit[1]=cc.DataMgr:getPokerSuit(suitNum)
  print('--------suit1 :',suit[1])
  cardNumIndex[1]=msg.OutCard1-(suitNum-1)*8
  pokerNum[1]=cc.DataMgr:getPokerNum(cardNumIndex[1])
  print('--------pokerNum[1] :',pokerNum[1])
  suitNum=math.ceil(msg.OutCard2/8)
  suit[2]=cc.DataMgr:getPokerSuit(suitNum)
  print('--------suit2 :',suit[2])
  cardNumIndex[2]=msg.OutCard2-(suitNum-1)*8
  pokerNum[2]=cc.DataMgr:getPokerNum(cardNumIndex[2])
  print('--------pokerNum[2] :',pokerNum[2])
  local gameMsgContent=' '..pokerNum[1]..suit[1]..pokerNum[2]..suit[2]
  print('--------------------gameMsgContent :',gameMsgContent)
  if self.posIndex==1 then
    --dump(cardNumIndex,'------cardNumIndex :')
    gameMsg[1]=gameMsgContent
    controlState=1
  else
    gameMsg[1]=self:GetPlayerName()
    gameMsg[2]=gameMsgContent
    controlState=3
  end
  self.TortoiseSceneClass:PlayerControllerMsg(gameMsg,controlState) --玩家操作信息显示
  if tempPlayCard ==nil then
    print('------------这张牌不存在出牌玩家的手牌中-------: ',msg.OutCard1)
    dump(self.cards,'------------玩家手牌 :')
  end
  --计时暂停
  if self.TortoiseSceneClass.timingCoroutine~=nil  then
    self.TortoiseSceneClass:PlayerTimerPause()
  end
  local duration=0.25
  local actionFunc1=nil
  local actionFunc2=nil
  local playCardSpacing=30
  --dump(self.cardBoardPos," self.cardBoardPos:")
  local playPos={x=self.cardBoardPos.x,y=self.cardBoardPos.y}
  --print("-----------playCardAction :",playCardAction,"  self.drawCard Obj:",self.drawCard:GetObj())
  
  --自身客户端玩家出牌
  if self.id==cc.DataMgr:getActorID() then
    
    actionFunc1=function()
      print('-----------------------出第一张牌----------------:',msg.OutCard1)
      --print(" DrawCard Pos Y: ",tempDrawCardObj:getPositionX()..' DrawCard Pos Y: ',tempDrawCardObj:getPositionY())
      playCardPos={x=tempDrawCardObj:getPositionX(),y=tempDrawCardObj:getPositionY()}
      local desPos={x=playPos.x-tempDrawCardObj:getPositionX()-playCardSpacing,y=playPos.y-tempDrawCardObj:getPositionY()}
      --dump(desPos,"-------------desPos :")
      --tempDrawCardObj:setGlobalZOrder(10)
      local playCardAction=cc.CallFunc:create(function()   
          tempDrawCardObj:runAction(cc.Sequence:create(cc.DelayTime:create(duration),cc.CallFunc:create(function() 
            self.TortoiseSceneClass:ShowPlayCard({x=playPos.x-playCardSpacing,y=playPos.y},msg.OutCard1) 
            end)))
         tempDrawCardObj:runAction(cc.Sequence:create(cc.MoveBy:create(duration,desPos),cc.CallFunc:create(function()
            tempDrawCardObj:setVisible(false)
          end)))
        end)
        
      tempDrawCardObj:runAction(playCardAction)
      tempDrawCardObj:setGlobalZOrder(25)
      self.TortoiseSceneClass.curPlayCardObj[1]=tempDrawCardObj
      AudioEngine.playEffect("gameMusic/PlayCard.mp3") --抽牌音效
    end
    actionFunc2=function()
      playCardPos={x=tempPlayCard:GetObj():getPositionX(),y=tempPlayCard:GetObj():getPositionY()}
      local desPos={x=playPos.x-tempPlayCard:GetObj():getPositionX()+playCardSpacing,y=playPos.y-tempPlayCard:GetObj():getPositionY()}
      print('-----------------------出第二张牌--------------:',msg.OutCard2)
      --dump(desPos,"-------------desPos :")
      tempPlayCard:GetObj():setGlobalZOrder(25)
      local playCardAction=cc.CallFunc:create(function() 
        tempPlayCard:GetObj():runAction(cc.Sequence:create(cc.DelayTime:create(duration),cc.CallFunc:create(function()  
          self.TortoiseSceneClass:ShowPlayCard({x=playPos.x+playCardSpacing,y=playPos.y},msg.OutCard2)
          end)))
        tempPlayCard:GetObj():runAction(cc.Sequence:create(cc.MoveBy:create(duration,desPos),cc.CallFunc:create(function()
          tempPlayCard:GetObj():setVisible(false)
        end)))
        end)
      tempPlayCard:GetObj():runAction(playCardAction)
      self.TortoiseSceneClass.curPlayCardObj[2]=tempDrawCardObj
      AudioEngine.playEffect("gameMusic/PlayCard.mp3") --抽牌音效
    end
  else
    print(' self.posIndex :',self.posIndex)
    actionFunc1=function()
      print('-----------------------同步其他出第一张牌------------:',msg.OutCard1)
      tempDrawCardObj:setColor({r=255,g=255,b=255,a=255})
      --print(" DrawCard Pos Y: ",tempDrawCardObj:getPositionX()..'  DrawCard Pos Y: ',tempDrawCardObj:getPositionY())
      playCardPos={x=tempDrawCardObj:getPositionX(),y=tempDrawCardObj:getPositionY()}
      local desPos={x=playPos.x-tempDrawCardObj:getPositionX()-playCardSpacing,y=playPos.y-tempDrawCardObj:getPositionY()}
      --dump(desPos,"-------------desPos :")
      local angle=-(self.posIndex-1)*90
      tempDrawCardObj:setGlobalZOrder(20)
      tempDrawCard:SetTexture(msg.OutCard1)
      local playCardAction=cc.Sequence:create(cc.MoveBy:create(duration,desPos),cc.CallFunc:create(function() 
        tempDrawCardObj:setVisible(false)
        self.TortoiseSceneClass:ShowPlayCard({x=playPos.x-playCardSpacing,y=playPos.y},msg.OutCard1)
  
      end))
      local rotaAction=cc.RotateBy:create(duration,angle)
      tempDrawCardObj:runAction(rotaAction)
      tempDrawCardObj:runAction(playCardAction)   
      --playCardPosIndexList[1]=self.drawCard:GetPosIndex()
      --self:RemoveHandCard(#self.cards)
      self.TortoiseSceneClass.curPlayCardObj[1]=tempDrawCardObj
      AudioEngine.playEffect("gameMusic/PlayCard.mp3") --抽牌音效
    end
    actionFunc2=function()
      print('-----------------------同步其他出第二张牌--------------:',msg.OutCard2)
      tempPlayCard:GetObj():setColor({r=255,g=255,b=255,a=255})
      local desPos={x=playPos.x-tempPlayCard:GetObj():getPositionX()+playCardSpacing,y=playPos.y-tempPlayCard:GetObj():getPositionY()}
      playCardPos={x=tempPlayCard:GetObj():getPositionX(),y=tempPlayCard:GetObj():getPositionY()}
      --dump(desPos,"-------------desPos :")
      local angle=-(self.posIndex-1)*90
      tempPlayCard:GetObj():setGlobalZOrder(25)
      --local spawn=cc.Spawn:create(cc.MoveBy:create(duration,desPos),cc.RotateTo:create(duration,0))
      tempPlayCard:SetTexture(msg.OutCard2)
      local playCardAction=cc.Sequence:create(cc.MoveBy:create(duration,desPos),cc.CallFunc:create(function()
        tempPlayCard:GetObj():setVisible(false)
        self.TortoiseSceneClass:ShowPlayCard({x=playPos.x+playCardSpacing,y=playPos.y},msg.OutCard2)
   
      end))
      local rotaAction=cc.RotateBy:create(duration,angle)
      tempPlayCard:GetObj():runAction(rotaAction)
      tempPlayCard:GetObj():runAction(playCardAction)
      
      self.TortoiseSceneClass.curPlayCardObj[2]=tempDrawCardObj
      AudioEngine.playEffect("gameMusic/PlayCard.mp3") --抽牌音效
    end
  end
  
  local sequenceAction=nil
  sequenceAction=cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(actionFunc1),cc.DelayTime:create(0.3),cc.CallFunc:create(actionFunc2),
    cc.DelayTime:create(0.3),cc.CallFunc:create(function() 
      self:RemoveHandCard(msg.Index2+1)
      self:RemoveHandCard(#self.cards)
      self:PlayCardCompleted(msg.PokerList,playCardPos) 
    end))
  self.handCardNode:runAction(sequenceAction)
  table.insert(self.TortoiseSceneClass.playCardArr,#self.TortoiseSceneClass.playCardArr+1,tempDrawCardObj)
  table.insert(self.TortoiseSceneClass.playCardArr,#self.TortoiseSceneClass.playCardArr+1,tempPlayCard:GetObj())
end
--[[
  出牌完成
  cardList  --牌列表
  cardPosIndexList --出牌的位置索引
  cardPoslist -出牌的位置
]]
function c:PlayCardCompleted(cardList,cardPos)
  if self.id==cc.DataMgr:getActorID() then
    cc.DataMgr:setPlayCardMsg(nil)
  end
  --cc.DataMgr:setNormalPlayCardState(false)
  --dump(cardPosIndex,"---------------cardPosIndexList :")
  --dump(cardPos,"--------------cardPoslist :")
  --dump(cardList,"--------------cardList :")
  print('--------------服务器牌组长度 :',#cardList)
  --cc.DataMgr:setIsAIPlayCard(false)
  print('--------------玩家出完后的手牌长度 Len :',#self.cards)

  if cc.DataMgr:getGameOver() then
    print('------------------游戏已经结束-------------')
    if #self.cards== 0 then
      self:PlayerTriumph()
    end
    --游戏已经进入结束阶段
    local function GameOverStage()
      print('---------------游戏已经进入结束阶段-------------')
      self.TortoiseSceneClass:GameOver(cc.DataMgr:getGameOverMsg())
    end
    self.TortoiseSceneClass:HandCardGathering(self.posIndex,GameOverStage)
    return
  end
  if #cardList>0 then
    self.TortoiseSceneClass:HandCardGathering(self.posIndex)
  end
  local gameState=self:RefreshHandCard(cardList)
  --出完牌后,对牌组中的牌重新进行索引赋值
  self:ResetHandCardIndex()
  if gameState==1 then
    local isNew,shuffleIndex=self.TortoiseSceneClass:NewGameRound(self.posIndex) 
    if isNew then
      return
    end
  elseif gameState==2 then
    if self.isAI or cc.DataMgr:getGameOver() then
      print('-------------出牌玩家是AI---------------')
     self.TortoiseSceneClass:HandCardGathering(self.posIndex,function() 
      --cc.DataMgr:setGameOver(false)
      self.TortoiseSceneClass:GameOver(cc.DataMgr:getGameOverMsg()) 
      end)
    end
    --游戏结束
    print('------------出牌完成后,得到的游戏状态数字为2-----------')
    return
  end
end
--[[
  刷新手牌
  核对客户端与服务器的手牌是否一致
  返回state  1 表示玩家已经出完手牌 
             2 表示游戏结束
]]
function c:RefreshHandCard(cardList)
  if #self.cards==0 then
    --玩家出完牌了
    print('-------------玩家完成出完牌的胜利-----------------')
    return self:PlayerTriumph()
  end
  if self.id==cc.DataMgr:getActorID() then
    local tempCardList={}
    for i=1,#cardList do
      tempCardList[i]=cardList[i]
    end
    local sameCount=0
    for i=1,#self.cards do
     for j=1,#cardList do
        if self.cards[i]:GetValue()==cardList[j] then
          sameCount=sameCount+1
        end
      end
    end
    --客户端与服务器不一致就同步服务器
    if #cardList~=sameCount then
      cc.NetMgr:close()
      cc.NetMgr:doConnect()
    end
  else
    local checkNum=#self.cards-#cardList
    local len=math.abs(checkNum)
    if checkNum~=0 then
      cc.NetMgr:close()
      cc.NetMgr:doConnect()
    end
    
  end
  return 0
end
--[[
  玩家获得胜利
  返回state  1 表示玩家已经出完手牌 
            2 表示游戏结束
]]
function c:PlayerTriumph()
  print(" 玩家获得胜利   玩家的位置 :",self.posIndex)
  if self.isWin then
    return
  end
  self.TortoiseSceneClass:PlayerRoundEnd(self.posIndex) --隐藏玩家计时器
  self.isWin=true
  self.cards={}
  self.handCardValueList={}
  local gameState=(self.TortoiseSceneClass:GameOverDetection() and 2)or 1
  print('---------------------gameState :',gameState)
  return gameState
end

--[[
 随机打乱手牌
 changeCount --
]]
function c:Shuffle(shuffleIndexList,destinationIndexList,changeCount,callBack)
--dump(self.cards," -----------------玩家洗手牌 :")
 local shuffleNum=0
 local delay=0.35
 --dump(self.cards,'-------玩家洗牌函数--------:')
 local function ShuffleFunc()
  --print('-----------开始洗牌')
    AudioEngine.playEffect("gameMusic/Shuffle.mp3") --洗牌音效
    --if self.TortoiseSceneClass.breakLineState then
      --for i=1,#self.cards do
      
        --self.cards[i]:GetObj():setLocalZOrder(i)
        --self.cards[i]:SetPosIndex(i)
      --end
      --return
    --end
    local duration=0.25
    local shufflePos1={}
    local shufflePos2={}
    print('----------------self.cards Len:',#self.cards)
    --dump(shuffleIndexList," shuffleIndexList :")
    --dump(destinationIndexList," destinationIndexList :")
    local len=changeCount+shuffleNum
    for i=(shuffleNum+1),len do
      local index1=shuffleIndexList[i]
      local index2=destinationIndexList[i]
      local cardObj1=self.cards[index1]:GetObj()
      local cardObj2=self.cards[index2]:GetObj()
    --print(" index 1:",index1.."  index 2:",index2..' ----cardObj1 :',cardObj1)
    --print('---------------cardObj2 :',cardObj2)
      if self.posIndex ==1 or self.posIndex ==3 then
        shufflePos1[i]={x=cardObj1:getPositionX(),y=self.cardOriPos.y}
        shufflePos2[i]={x=cardObj2:getPositionX(),y=self.cardOriPos.y}
      elseif self.posIndex ==2 or self.posIndex ==4 then
        shufflePos1[i]={x=self.cardOriPos.x,y=cardObj1:getPositionY()}
        shufflePos2[i]={x=self.cardOriPos.x,y=cardObj2:getPositionY()}
      end
      --print('--------------洗牌动画播放')
        --if not self.TortoiseSceneClass.breakLineState then
        --print('-----------------------self.TortoiseSceneClass.breakLineState :',self.TortoiseSceneClass.breakLineState)
        local moveAction1=cc.MoveTo:create(duration,cc.p(shufflePos2[i].x,shufflePos2[i].y))
        cardObj1:runAction(moveAction1)
        local moveAction2=cc.MoveTo:create(duration,cc.p(shufflePos1[i].x,shufflePos1[i].y))
        cardObj2:runAction(moveAction2)
        --print('--------------洗牌动画播放 ing.......')
        --[[
        local tempValue=self.cards[index1]:GetValue()
        self.cards[index1].item=cardObj2
        self.cards[index2].item=cardObj1
        self.cards[index1].value=self.cards[index2].value
        self.cards[index2].value=tempValue
        ]]
        local temp=self.cards[index1]
        self.cards[index1]=self.cards[index2]
        self.cards[index2]=temp
      --end

    end
    for i=1,#self.cards do
      --self.cards[i]:GetObj():setGlobalZOrder(i)
      self.cards[i]:GetObj():setLocalZOrder(i)
      self.cards[i]:SetPosIndex(i)
    end
    shuffleNum=shuffleNum+changeCount
  end
 local waitStartTime=0.6 --洗牌开始等待时间
 local  shuffleSequence=cc.Sequence:create(cc.CallFunc:create(ShuffleFunc),cc.DelayTime:create(delay),
    cc.CallFunc:create(ShuffleFunc),cc.DelayTime:create(delay),cc.CallFunc:create(function()
    for i=1,#self.cards do
      --self.cards[i]:GetObj():setLocalZOrder(i)
      self.cards[i]:SetPosIndex(i)
    end
    print("----------------洗牌完成------------")
    if self.posIndex==1 then
      local sendPokerList={}
      for i=1,#self.cards do
        table.insert(sendPokerList,i,self.cards[i]:GetValue())
      end
      cc.NetMgr:sendMsg(CLIENT_2_SERVER.GAEM_WASH_POKER,"pbghost.WashInfo",{PokerList=sendPokerList}) --发送客户端洗牌后的数组给服务器
    end
    cc.DataMgr:setIsSyncTween(false)
      --玩家回合结束
    self.TortoiseSceneClass:PlayerRoundEnd(self.posIndex)
    
    if callBack~=nil then
      callBack(thisAI)
    end
  end))
  self.handCardNode:runAction(shuffleSequence)
  return self.cards
  --print('-----------Shuffle Completed-------------')
end
--[[
  根据索引移除手牌
]]
function c:RemoveHandCard(cardIndex)
  print('---------cardIndex :',cardIndex..'  ---------------------self.cards Len 1:',#self.cards)
  --table.remove(self.TortoiseSceneClass.playerCardObjs[self.posIndex],cardIndex)
  --table.remove(self.handCardValueList,cardIndex)
  table.remove(self.cards,cardIndex)
  print('  ---------------------self.cards Len 2:',#self.cards)
end

function c:ActiveHandCardTouch(isActive)
   for i=1,#self.cards do
    self.cards[i]:GetObj():setTouchEnabled(isActive)
  end

end

function c:HandCardShadeState(isShow)
  for i=1,#self.cards do
    local card=self.cards[i]:GetObj()
    if isShow then
      card:setColor({r=127,g=127,b=127,a=255})
    else
      card:setColor({r=255,g=255,b=255,a=255})
    end
  end
end



return c