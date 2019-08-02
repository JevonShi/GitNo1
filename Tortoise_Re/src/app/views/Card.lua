--require("app.net.NetMgr")

CardObject=class('CardObject')

local c=CardObject
--[[
  构造函数
]]
function c:ctor(index,value,posIndex,ownerID)
 
  self:Init(index,value,posIndex,ownerID)
end

--[[
  初始化
  index --当前牌所在牌组的索引
  value --牌值
  posIndex --牌组的位置索引
]]
function c:Init(index,value,seatIndex,ownerID)
  self.item=nil
  --牌组的位置索引
  self.seatIndex=seatIndex  
  --牌在牌组中的索引
  self.posIndex=index
  self.clickCount=0
  self.suit=nil
  self.value=value
  --目的地位置
  self.destinationPosX=nil
  self.destinationPosY=nil
  self.ownerID=ownerID

  self.TortoiseSceneClass=cc.DataMgr:getTortoiseClass()

  self.choose=nil

  self.upValue=60 --牌弹起距离
end

function c:SetObj(item)
  self.item=item
  self.item:addTouchEventListener(function(sender,eventType)
      if eventType==0 then 
       self:ClickEvent()
      end
  end)
end

function c:GetObj()
 return self.item
end


function c:GetSuit()
  return self.suit
end

function c:SetValue(cardNum)
  self.value=cardNum
end

function c:GetValue()
  --print('self.value :',self.value)
  return self.value
end
--[[
 设置牌所在牌桌上的位置
]]
function c:SetSeatIndex(index)
  self.seatIndex=index
end

function c:GetSeatIndex()
  return self.seatIndex
end

function c:SetTexture(spriteName)
  local texture='Pit_'..spriteName..'.png'
  self.item:loadTextureNormal(texture,ccui.TextureResType.plistType)
end

function c:SetDestination(posX,posY)
  self.destinationPosX=posX
  self.destinationPosY=posY
  --print('-------------SeatIndex :',self.seatIndex)
  --print('desPosX :',self.destinationPosX..' desPosY :',self.destinationPosY)
end
--[[
  设置牌在手牌上的位置
]]
function c:SetPosIndex(index)
  self.posIndex=index
end

function c:GetPosIndex()
  return self.posIndex
end
--[[
  设置光圈对象
]]
function c:SetChoose(choose)
  self.choose=choose
end

function c:GetChoose()
  return self.choose
end

--[[
  显示选择光圈
]]
function c:IsChoose(isChoose)
  --print('---------光圈显示还是隐藏 :',isChoose)
  self.choose:setVisible(isChoose)
end

--[[
  点击事件
]]
function c:ClickEvent()
  --print('----------------Call ClickEvent -----------------')
  --local upValue=60
  local popupTime=0.13 --点击牌弹起时间
  local duration=0.3  --牌的移动时间
  if self.clickCount==0 then
    --print('-------  _G.SelectionCard~=nil :',_G.SelectionCard~=nil)
    if _G.SelectionCard~=nil then
     _G.SelectionCard:Down()
    end
    --print(" -----------ClickCard Size  :",self.item:getScale())

    if self.TortoiseSceneClass.PlayIndex==1 then
      self:IsChoose(true)
      self.TortoiseSceneClass.outTimeCount=0 
      self.TortoiseSceneClass.PlayerRoundTime=self.TortoiseSceneClass.OriRoundTime
      cc.DataMgr:setActorTrustState(false)
    end
    _G.SelectionCard=self
    AudioEngine.playEffect("gameMusic/ChooseCard.mp3") --选牌音效
    --cc.DataMgr:setIsChooseCard(false)
    local action=nil
    if self.seatIndex==1 then
      self.item:runAction(cc.MoveBy:create(popupTime,cc.p(0,self.upValue)))
    elseif self.seatIndex==2 then
      self.item:runAction(cc.MoveBy:create(popupTime,cc.p(self.upValue,0)))
    elseif self.seatIndex==3 then
      self.item:runAction(cc.MoveBy:create(popupTime,cc.p(0,-self.upValue)))
    else
   	  --print(' _G.SelectionCard :',_G.SelectionCard)
      self.item:runAction(cc.MoveBy:create(popupTime,cc.p(-self.upValue,0)))
      --print(" CardPosIndex :",self.posIndex)
    end
    --[[
    self.item:runAction(cc.Sequence:create(cc.DelayTime:create(popupTime),cc.CallFunc:create(function()  
        cc.DataMgr:setIsChooseCard(false)
      end)))
      ]]
    --抽牌的是自身客户端就发送同步点击协议,或者被点击的是AI手牌
    if self.TortoiseSceneClass.PlayIndex==1  then
      cc.DataMgr:setIsChooseCard(true)
      print('---------发送选牌同步协议')
      cc.NetMgr:sendMsg(CLIENT_2_SERVER.GAME_CLICK_POKER,"pbghost.ClickInfo",{PlayerId=self.ownerID,Index=self.posIndex})
    end
  else
    self.TortoiseSceneClass.curGameState=GAME_STATE.DRAW_CARD
    cc.DataMgr:setActorChooseCard(self)
    --cc.DataMgr:setHaveDrawCard(true)
    cc.DataMgr:setNormalPlayCardState(false)
    self:IsChoose(false)
    --self.item:setGlobalZOrder(10)
    self.TortoiseSceneClass.playerObj[self.seatIndex]:ActiveHandCardTouch(false)
    print(' PlayIndex :',self.TortoiseSceneClass.PlayIndex,' BeDrawIndex :',self.TortoiseSceneClass.BeDrawIndex )
    AudioEngine.playEffect("gameMusic/DrawCard.mp3") --抽牌音效
    --self.item:setTouchEnabled(false)
    if self.TortoiseSceneClass.PlayIndex==1 then
      _G.SelectionCard:IsChoose(false)
      cc.DataMgr:setDrawCardMsg({item=self.item})
      if not cc.DataMgr:getActorTrustState() then
        print('-----------缩小------')
        self.item:setScale(0.92)
      end
      if self.TortoiseSceneClass.actorFirstControl then
        self.TortoiseSceneClass:HidePlayerGuidePanel()
      end

      --print('---------------Scale: ',self.item:getScale())
    end
    self.TortoiseSceneClass.autoDrawCard=false
    --dump(scale,'----------------DrawCard Scale :')
    self.TortoiseSceneClass:SetCardDestination(self.TortoiseSceneClass.PlayIndex,self.TortoiseSceneClass.BeDrawIndex)
    local oriPos={x=self.item:getPositionX(),y=self.item:getPositionY()}
    local angle=0
    local rotateAction=nil
    local controlPoint1=nil
    local controlPoint2=nil
    if self.destinationPosX==nil then
      print('-----------Card SeatIndex :',self.seatIndex..'------------------PlayIndex :',self.TortoiseSceneClass.PlayIndex..'----------------self.TortoiseSceneClass.BeDrawIndex :',self.TortoiseSceneClass.BeDrawIndex)
    end
    if self.ownerID==cc.DataMgr:getActorID() then
      local temp=self.TortoiseSceneClass.playerObj[1]:GetHandCard()
      print('-----------------------------自身客户端被抽之前的剩余手牌数量 :',#temp)
    end
    local sequenceAction=nil
   if self.seatIndex==1 then
      self:SetTexture("beimian")
      --self:SetTexture(self.Value)
      if self.value==33 then
        self.TortoiseSceneClass:BecomeAMan()
      end
   end
    print('------------------抽牌----------------------')
    local playerObj=self.TortoiseSceneClass.playerObj[self.TortoiseSceneClass.PlayIndex]
    --抽牌玩家是自身客户端就进行抽牌同步
    if self.TortoiseSceneClass.PlayIndex==1 and not cc.DataMgr:getActorTrustState() then
      --print("  同步抽牌玩家ID :",playerObj:GetPlayerID())
      cc.NetMgr:sendMsg(CLIENT_2_SERVER.GAEM_CARD_TOON,"pbghost.ChooseInfo",{PlayerId=self.ownerID,Index=self.posIndex})
    end
    
    print('-------------self.destinationPosX :',self.destinationPosX..'   -------------self.destinationPosY :',self.destinationPosY)
    --dump(bezier," Bezier Config :")
    sequenceAction=cc.Sequence:create(cc.MoveTo:create(duration,cc.p(self.destinationPosX,self.destinationPosY)),cc.DelayTime:create(0.15),cc.CallFunc:create(
      function() 
        --self.item:setRotation(0)
        print('-------------被抽牌所在的位置 Index:',self.seatIndex)
        print('----------------------被抽牌所在的位置--------- X:',self.item:getPositionX() )
        print('----------------------被抽牌所在的位置--------- Y:',self.item:getPositionY() )
        print('--------抽牌者位置 :',self.TortoiseSceneClass.PlayIndex..'  ----------被抽牌者位置 :',self.TortoiseSceneClass.BeDrawIndex)
        --self.item:setLocalZOrder(30)
        self.TortoiseSceneClass:DrawCardCompleted(self.TortoiseSceneClass.PlayIndex,self.TortoiseSceneClass.BeDrawIndex,oriPos,self)
        --设置新的归属者ID
        self.ownerID=self.TortoiseSceneClass.playerObj[self.TortoiseSceneClass.PlayIndex]:GetPlayerID()
      end))
    self.item:runAction(sequenceAction)
    angle=(self.TortoiseSceneClass.PlayIndex-self.TortoiseSceneClass.BeDrawIndex)*90
    rotateAction=cc.RotateBy:create(duration,angle)
    self.item:runAction(rotateAction)
    self.item:setLocalZOrder(20)
  end

  self.clickCount=(self.clickCount+1)%2

end

--[[
  牌的弹出恢复
]]
function c:Down()
  if self.seatIndex==1 then
    self.item:runAction(cc.MoveBy:create(0.2,cc.p(0,-self.upValue)))
  elseif self.seatIndex==2 then
    self.item:runAction(cc.MoveBy:create(0.2,cc.p(-self.upValue,0)))
  elseif self.seatIndex==3 then
    self.item:runAction(cc.MoveBy:create(0.2,cc.p(0,self.upValue)))
  else
    self.item:runAction(cc.MoveBy:create(0.2,cc.p(self.upValue,0)))
  end
  self.clickCount=0
  _G.SelectionCard=nil
  self:IsChoose(false)
end
--[[
 开牌
]]
function c:OpenCard(isOver)
  AudioEngine.playEffect("gameMusic/OpenCard.mp3") --开牌音效
  if not isOver then
    print('-----------抽牌玩家ID--------:' ,self.TortoiseSceneClass.playerObj[self.TortoiseSceneClass.PlayIndex]:GetPlayerID())
    local angle=nil
    local spriteName=nil
    --if self.TortoiseSceneClass.playerObj[self.TortoiseSceneClass.PlayIndex]:GetPlayerID()==cc.DataMgr:getActorID() then
    if self.TortoiseSceneClass.PlayIndex==1 then
      --print('----------------玩家抽牌---------------------')
      angle=90
      self.value=cc.DataMgr:getActorChooseCardNum()
      spriteName='Pit_'..tostring(self.value)..'.png'
      local callBack=cc.CallFunc:create(function() 
        --print(' SpriteName :',spriteName)
        self.item:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
        
      end)
      local rota_01=cc.RotateTo:create(0.15,0,angle)
      local rota_02=cc.RotateTo:create(0.15,0,0)
      local sequence=cc.Sequence:create(rota_01,callBack,rota_02,cc.CallFunc:create(function()  
        if self.value==33 then
          self.TortoiseSceneClass:BecomeAZombie(1)
        end
        end))
      self.item:runAction(sequence)
    end
  else
    angle=90
    spriteName='Pit_33.png'
    self.item:setColor({r=255,g=255,b=255,a=255})
    local callBack=cc.CallFunc:create(function() 
        --print(' SpriteName :',spriteName)
      self.item:loadTextureNormal(spriteName,ccui.TextureResType.plistType)  
      end)
    local rota_01=nil
    local rota_02=nil
    if self.seatIndex==2 or self.seatIndex==4 then
      rota_01=cc.RotateBy:create(0.15,0,angle)
      rota_02=cc.RotateBy:create(0.15,0,-angle)
    elseif self.seatIndex==3 then
      rota_01=cc.RotateBy:create(0.15,0,angle)
      rota_02=cc.RotateBy:create(0.15,0,-angle)
    end
    local sequence=cc.Sequence:create(rota_01,callBack,rota_02)
    self.item:runAction(sequence)
  end
end


return c