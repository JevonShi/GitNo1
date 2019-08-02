

ControlMgr=class("ControlMgr")

local c=ControlMgr

function c:ctor()
  self.playerCount=4
  self.windowSize = cc.Director:getInstance():getWinSize()
  self.visibleSize=cc.Director:getInstance():getVisibleSize() --实际得分辨率
  --dump(self.visibleSize,'-----------------self.visibleSize :')
	 cc.Director:getInstance():getVisibleOrigin() --实际原点
	
 	
 	self.centralPoint_X=375--1,3 玩家 X轴中心点

 	self.adaptionNum={}
  self.adaptionNum.x=self.visibleSize.width/self.windowSize.width
 	self.adaptionNum.y=self.visibleSize.height/self.windowSize.height
 	self.otherPlayerCardInterVal=40*self.adaptionNum.x --其他玩家的牌间距

 	self.cardInterVal=60*self.adaptionNum.x --自身玩家牌间距
  self.popupDis=90*self.adaptionNum.x --弹起距离
  self.popupActionTime=0.26 --弹起的动效时间
  self.expandSize=35*self.adaptionNum.y --自身客户端抽牌时被抽牌玩家的牌间距
  --手牌弹起数组
  self.popupDisArr={
    cc.p(0,0),
    cc.p(self.popupDis,0),
    cc.p(0,-self.popupDis),
    cc.p(-self.popupDis,0)
  }

  self.pokerListView={}

end


--[[
  
]]
function c:SetPokerListView(dataList,visibleOrigin)
  self.pokerListView=dataList
  self.visibleOrigin =visibleOrigin
  self.centralPoint_Y=902-self.visibleOrigin.y --2,4 玩家 Y轴中心点
  self.moveDownPos=1090-self.visibleOrigin.y
  
  self.leftMovePos=50+self.visibleOrigin.x --玩家左移动作
  self.leftActionTime=0.2 --左移动作时间
  self.cardShirinkValue=15 --左移动作后手牌的收缩数值
end

--[[
	计算牌的位置
	seatIndex --位置索引
	medianPoint --中间点
  count --牌组的第几张
]]
function c:CalculateCardPosition(seatIndex,medianPoint,listLen,count)
  --print('------------seatIndex :',seatIndex..'--------------------------medianPoint :',medianPoint..'----------------------------- count :',count)
	local cardPos={}
  cardPos.x=self.pokerListView[seatIndex].x
  cardPos.y=self.pokerListView[seatIndex].y
	if seatIndex==1 then
      if listLen%2==0 then
        if count<medianPoint then
          cardPos.x=self.centralPoint_X-self.cardInterVal*0.5-(medianPoint-count)*self.cardInterVal
        elseif count==medianPoint then
          cardPos.x=self.centralPoint_X-self.cardInterVal*0.5
        elseif count==medianPoint+1 then
          cardPos.x=self.centralPoint_X+self.cardInterVal*0.5
        elseif count>(medianPoint+1) then
          cardPos.x=self.centralPoint_X+self.cardInterVal*0.5+(count-(medianPoint+1))*self.cardInterVal
        end
      else
        if count<medianPoint then
          cardPos.x=self.centralPoint_X-(medianPoint-count)*self.cardInterVal
        elseif count==medianPoint then
          cardPos.x=self.centralPoint_X
        elseif count>medianPoint then
          cardPos.x=self.centralPoint_X+(count-medianPoint)*self.cardInterVal
        end
      end
  elseif seatIndex==2 then
      if listLen%2==0 then
        if count<medianPoint then
          cardPos.y=self.centralPoint_Y+self.otherPlayerCardInterVal*0.5+(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.y=self.centralPoint_Y+self.otherPlayerCardInterVal*0.5
        elseif count==medianPoint+1 then
          cardPos.y=self.centralPoint_Y-self.otherPlayerCardInterVal*0.5
        elseif count>(medianPoint+1) then
          cardPos.y=self.centralPoint_Y-self.otherPlayerCardInterVal*0.5-(count-(medianPoint+1))*self.otherPlayerCardInterVal
        end
      else
        if count<medianPoint then
          cardPos.y=self.centralPoint_Y+(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.y=self.centralPoint_Y
        elseif count>medianPoint then
          cardPos.y=self.centralPoint_Y-(count-medianPoint)*self.otherPlayerCardInterVal
        end
      end
  elseif seatIndex==3 then
      if listLen%2==0 then
        if count<medianPoint then
          cardPos.x=self.centralPoint_X+self.otherPlayerCardInterVal*0.5+(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.x=self.centralPoint_X+self.otherPlayerCardInterVal*0.5
        elseif count==medianPoint+1 then
          cardPos.x=self.centralPoint_X-self.otherPlayerCardInterVal*0.5
        elseif count>(medianPoint+1) then
          cardPos.x=self.centralPoint_X-self.otherPlayerCardInterVal*0.5-(count-(medianPoint+1))*self.otherPlayerCardInterVal
        end
      else
        if count<medianPoint then
          cardPos.x=self.centralPoint_X+(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.x=self.centralPoint_X
        elseif count>medianPoint then
          cardPos.x=self.centralPoint_X-(count-medianPoint)*self.otherPlayerCardInterVal
        end
      end
  else
      if listLen%2==0 then
        if count<medianPoint then
          cardPos.y=self.centralPoint_Y-self.otherPlayerCardInterVal*0.5-(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.y=self.centralPoint_Y-self.otherPlayerCardInterVal*0.5
        elseif count==medianPoint+1 then
          cardPos.y=self.centralPoint_Y+self.otherPlayerCardInterVal*0.5
        elseif count>(medianPoint+1) then
          cardPos.y=self.centralPoint_Y+self.otherPlayerCardInterVal*0.5+(count-(medianPoint+1))*self.otherPlayerCardInterVal
        end
      else
        if count<medianPoint then
          cardPos.y=self.centralPoint_Y-(medianPoint-count)*self.otherPlayerCardInterVal
        elseif count==medianPoint then
          cardPos.y=self.centralPoint_Y
        elseif count>medianPoint then
          cardPos.y=self.centralPoint_Y+(count-medianPoint)*self.otherPlayerCardInterVal
        end
      end
  end
  --dump(cardPos,'------------CardPos :')
  return cardPos
end


--[[
  被抽牌的手牌动效
]]
function c:BeDrawHandsAction(seatIndex,medianPoint,cardObjList)
  local listLen=#cardObjList
  local dispersePos=nil
  local disperseAction=nil
  local cardObj=nil
  local num=#cardObjList%2==0 --是否双数手牌
  --手牌先散开,向两边散开,中间手牌不动
  for i=1,listLen do
    cardObj=cardObjList[i]:GetObj()
    if i~=medianPoint then
      if i<medianPoint then
        if seatIndex==2 then
          dispersePos=cc.p(0,self.expandSize*(medianPoint-i))
        elseif seatIndex==3 then
          dispersePos=cc.p(self.expandSize*(medianPoint-i),0)
        elseif seatIndex==4 then
          dispersePos=cc.p(0,-self.expandSize*(medianPoint-i))
        end
      elseif i>medianPoint then
        if seatIndex==2 then
          dispersePos=cc.p(0,-self.expandSize*(i-medianPoint))
        elseif seatIndex==3 then
          dispersePos=cc.p(-self.expandSize*(i-medianPoint),0)
        elseif seatIndex==4 then
          dispersePos=cc.p(0,self.expandSize*(i-medianPoint))
        end
      end
    dump(dispersePos,'----------dispersePos :')
    disperseAction=cc.MoveBy:create(0.4,dispersePos)
    if i==listLen then
      disperseAction=cc.Sequence:create(cc.MoveBy:create(0.4,dispersePos),cc.CallFunc:create(function()
        self:HandsPopup(seatIndex,cardObjList,listLen)
      end))
    end
    cardObj:runAction(disperseAction)
    end
  end
end

--[[
  所有手牌全部弹起
]]
function c:HandsPopup(seatIndex,cardObjList,listLen)
  local popupPos=self.popupDisArr[seatIndex]
  for i=1,listLen do
    local cardObj=cardObjList[i]:GetObj()
    local popupAction=cc.MoveBy:create(self.popupActionTime,popupPos)
    if i~=listLen then
      cardObj:runAction(popupAction)
    elseif i~=listLen and seatIndex==4  then
      cardObj:runAction(cc.Sequence:create(popupAction,cc.CallFunc:create(function() 
        self:BeDrawHandsMoveDown(cardObjList.listLen)
      end)))
    end
  end
end
--[[
  一张牌弹起,当手牌只剩下一张牌的时候调用
]]
function c:CardPopup(seatIndex,cardObj)
  local popupPos=self.popupDisArr[seatIndex]
  local popupAction=cc.MoveBy:create(self.popupActionTime,popupPos)
  cardObj:runAction(popupAction)
end
--[[
  被抽手牌的下移
]]
function c:BeDrawHandsMoveDown(cardObjList,listLen)
  local moveDownPos=nil 
  local downIndex=listLen
  for i=1,listLen do
    local cardObj=cardObjList[downIndex]:GetObj()
    moveDownPos=cc.p(cardObj:getPositionX(),self.moveDownPos-(i-1)*(self.expandSize+self.otherPlayerCardInterVal))
    cardObj:runAction(cc.MoveTo:create(0.3,moveDownPos))
    downIndex=downIndex-1
  end 
end
--[[
  被抽手牌恢复原来位置动作
]]
function c:BeDrawHandsRecoverAction(otherIndex,cardObjList)
  local listLen=#cardObjList
  if listLen>0 then
        --返回的位置
    local returnPosY=self.pokerListView[otherIndex].y
    local returnPosX=self.pokerListView[otherIndex].x
    local recoverPos=nil
    local otherCardMedian=math.ceil(listLen*0.5)

    local intervalNum=(self.otherPlayerCardInterVal+self.expandSize)
        
    local evenNum_1 =intervalNum*0.5
        
    local evenNum_2 =intervalNum*1.5

    for n=1,listLen do
      local otherCardObj=cardObjList[n]:GetObj()
      if otherIndex==2 then
            returnPosY=otherCardObj:getPositionY()
      elseif otherIndex==3 then
            returnPosX=otherCardObj:getPositionX()
      elseif otherIndex==4 then
        if listLen%2==0 then
          if n<otherCardMedian then
            returnPosY=self.centralPoint_Y-(otherCardMedian-n)*evenNum_1
          elseif n==otherCardMedian then
            returnPosY=self.centralPoint_Y-evenNum_1
          elseif n==otherCardMedian+1 then
            returnPosY=self.centralPoint_Y+evenNum_1
          else
            returnPosY=self.centralPoint_Y+(n-(otherCardMedian+1))*evenNum_2
          end
        else
          if n<otherCardMedian then
            returnPosY=self.centralPoint_Y-(otherCardMedian-n)*intervalNum
          elseif n==otherCardMedian then
            returnPosY=self.centralPoint_Y
          else
            returnPosY=self.centralPoint_Y+(n-otherCardMedian)*intervalNum
          end
        end
      end
      recoverPos=cc.p(returnPosX,returnPosY)
          
      if otherIndex==3 then
        otherCardObj:setGlobalZOrder(0)
      end
          
      if n~=listLen then
        otherCardObj:runAction(cc.MoveTo:create(0.2,recoverPos))
      else
        local function TogetherFunc()
          self:HandCardGathering(otherIndex,cardObjList)
        end
        local togetherSequence=cc.Sequence:create(cc.MoveTo:create(0.2,recoverPos),cc.CallFunc:create(TogetherFunc))
        otherCardObj:runAction(togetherSequence)
      end
    end
  end
end
--[[
  抽牌玩家左移动作(只有自身客户端抽位置为4的玩家才会触发)
]]
function c:DrawPlayerLeftMoveAction(cardObjList,callBack)
  local listLen=#cardObjList
  for i=1,listLen do
    local cardObj=cardObjList[i]:GetObj()
    local value=self.leftMovePos+self.cardInterVal*(i-1)
    if i~=listLen then
      cardObj:runAction(cc.MoveTo:create(self.leftMoveTime,cc.p(value,cardObj:getPositionY())))
    else
      local shrinkSequen=cc.Sequence:create(cc.MoveTo:create(self.leftMoveTime,cc.p(value,cardObj:getPositionY())),cc.CallFunc:create(function()
            self:HandsShirink(cardObjList,listLen,callBack)
        end))
      item:runAction(shrinkSequen)
    end
  end
end
--[[
  手牌聚集
]]
function c:HandsShirink(cardObjList,listLen,callBack)
  local medianIndex=math.ceil(listLen*0.5)
  local shirinkPos=nil
  local shirinkTime=0.3
  local shirinkX=0
  for i=1,listLen do
    local shirinkItem=cardObjList[i]:GetObj()
    if i~=medianIndex then --手牌两边向中间聚集
      if i<medianIndex then
        shirinkX=shirinkItem:getPositionX()+(medianIndex-i)*self.cardShirinkValue
        shirinkPos=cc.p(shirinkX,shirinkItem:getPositionY())
      elseif i>medianIndex then
        shirinkX=shirinkItem:getPositionX()-(i-medianIndex)*self.cardShirinkValue
        shirinkPos=cc.p(shirinkX,shirinkItem:getPositionY())
      end
      if i==listLen and callBack~=nil then
        local shirinkEndSequen=cc.Sequence:create(cc.MoveTo:create(shirinkTime,shirinkPos),cc.CallFunc:create(callBack))
        shirinkItem:runAction(shirinkEndSequen)
      else
        shirinkItem:runAction(cc.MoveTo:create(shirinkTime,shirinkPos))
      end
    end
  end

end

function c:HandCardGathering(seatIndex,cardObjList,callBack)
  local listLen=#cardObjList
  local togetherPos=nil
  local cardMedian=math.ceil(listLen*0.5)
  local gatheringTime=0.2
  --print('-------seatIndex :',seatIndex)
  --print('---------------listLen :',listLen)
  --print('---------------callBack :',callBack)
  for i=1,listLen do
    local togetherItem=cardObjList[i]:GetObj()
    togetherPos=self:CalculateCardPosition(seatIndex,cardMedian,listLen,i)
    local togetherAction=cc.MoveTo:create(gatheringTime,cc.p(togetherPos.x,togetherPos.y))
    if i==listLen and callBack~=nil then
      togetherAction=cc.Sequence:create(cc.MoveTo:create(gatheringTime,cc.p(togetherPos.x,togetherPos.y)),cc.CallFunc:create(callBack))
    end
    togetherItem:runAction(togetherAction)
  end
  --直接游戏结束,不知道游戏结束的时候为什么callBack参数会为空
  if cc.DataMgr:getGameOver() then
    if callBack==nil then
      local tortoiseScene=cc.DataMgr:getTortoiseClass()
      tortoiseScene:GameOver(cc.DataMgr:getGameOverMsg())
    end
  end
end

cc.ControlMgr=c.new()

return c