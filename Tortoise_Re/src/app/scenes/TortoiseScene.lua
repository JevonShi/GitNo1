
local json = require("json")
require("app.views.Card")
require("app.views.PlayerMgr")

require("app.views.PlatformFunction")

TortoiseScene=class("TortoiseScene", function(  )
    return display.newScene("TortoiseScene")
end )

AudioEngine.preloadMusic("gameMusic/bgm.mp3") --预加载BGM
 AudioEngine.preloadEffect("gameMusic/Zombie.mp3")
_G.SelectionCard=nil
local c=TortoiseScene

local LangEnum = {
    "ar_sa",
    "en_us",
    "es_es",
    "hi_in",
    "pt_br",
    "zh_cn"
}



function applicationWillEnterForeground()
  
  --self:RecycleAllPlayerHandCard()
  --cc.NetMgr:doReconnect()
  cc.DataMgr:setNoNetTag(true)
  cc.NetMgr:close()
  cc.NetMgr:clearReconnect()
  cc.NetMgr:doConnect()
  --if self.gameHeartbeatTimerSchedule then
    --cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.gameHeartbeatTimerSchedule)

  --end
  print('-----------------回到游戏前台--------------')
end

function applicationDidEnterBackground()
  print('-----------------退出游戏后台--------------')
end


function c:ctor()
	print('----------TortoiseScene')
  self:OnEnter()

end

function c:onExit() 
  print('----------------退出场景')
end

function c:cleanup() 
   print('----------------销毁场景')
end

function c:OnEnter()
  local windosScaleFactor = 0.6
  local designWidth   = 750 
  local designHeight    = 1500
  
  --cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(designWidth, designHeight, cc.ResolutionPolicy.NO_BORDER)
  if device.platform == "windows" then
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(designWidth, designHeight, cc.ResolutionPolicy.SHOW_ALL)
    cc.Director:getInstance():getOpenGLView():setFrameSize(designWidth, designHeight)
    cc.Director:getInstance():getOpenGLView():setFrameZoomFactor(windosScaleFactor)
  else
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(designWidth, designHeight, cc.ResolutionPolicy.NO_BORDER)
  end
  cc.DataMgr:setTortoiseClass(self)
  self.gameProtocol=GameProtocol.new()

  self:Init()
  self.gameProtocol:addEvent()
  self.gameProtocol:connectServer()
end


function c:Init() 

  --玩家人数
  self.playerCount=4
  --玩家手牌视图列表
  self.playerCard_ListView={}

  --self.playerCards={}
  --牌桌位置
  self.pokerTablePos=nil
  --牌数值数组
  self.playerCardNum={}
  --牌堆
  self.cardPile={}

  --玩家手牌
  self.playerCardObjs={}

  self.playCardArr={} --打出的牌数组
  self.shuffleDeck={} 
  self.destinationDeck={} 

  self.windowSize = cc.Director:getInstance():getWinSize()
  self.visibleOrigin = cc.Director:getInstance():getVisibleOrigin() --实际原点
  --dump(self.visibleOrigin ,'--------------self.visibleOrigin  :')
  self.visibleSize=cc.Director:getInstance():getVisibleSize() --实际得分辨率
  --dump(self.visibleSize,'---------------------self.visibleSize :')
  self.adaptionNum={}
  self.adaptionNum.x=self.visibleSize.width/self.windowSize.width
  self.adaptionNum.y=self.visibleSize.height/self.windowSize.height

  local tortoisePanel = cc.CSLoader:createNode("TortoiseScene.csb") --场景
  self:addChild(tortoisePanel)

  local poker=tortoisePanel:getChildByName('PokerPanel')
  for i=1,self.playerCount do
   self.cardPile[i]=poker:getChildByName('card_'..tostring(self.playerCount-(i-1)))
   local sprite=display.newSpriteFrame('#Pit_beimian.png')
   self.cardPile[i]:setSpriteFrame(sprite)
  end
  local bg=poker:getChildByName("BG_Normal")
  local bgSize=bg:getContentSize()
  --self.adaptoveCoefficent=self.visibleSize.width/750 --自适应系数
  
  bg:setScaleX(self.adaptionNum.x)
  bg:setScaleY(self.adaptionNum.x)
  --bg:setAnchorPoint(0.5,0.5)
  --bg:setPositionX(375-self.visibleOrigin.x)
  if self.adaptionNum.x~=1 and self.adaptionNum.y==1 then
    bg:setPositionY(bg:getPositionY()*self.adaptionNum.x)
  else
    bg:setPositionY(self.visibleOrigin.y+ bg:getPositionY())
  end

  self.playerPanelNode=tortoisePanel:getChildByName('PlayerPanel')
  local childrenCount=self.playerPanelNode:getChildrenCount()


  self.pokerTable=self.playerPanelNode:getChildByName('Node_1')
  self.pokerTablePos={x=self.pokerTable:getPositionX(),y=self.pokerTable:getPositionY()}

  --按钮UI
  self.btn_Ruturn=tortoisePanel:getChildByName("Btn_Return")
  self.btn_Ruturn:setPositionY(1445-self.visibleOrigin.y)
  local btn_RuturnPosX=self.visibleOrigin.x+self.btn_Ruturn:getPositionX()+5
  self.btn_Ruturn:setPositionX(btn_RuturnPosX)
  --self.btn_Ruturn:setPosition(50,1450)
  self.btn_Ruturn:setGlobalZOrder(50)
  self.btn_Ruturn:addClickEventListener(function()
      print('-----------------退出游戏按钮---------------')
      HYGameBridge:getInstance():requestGameExit()
      --self:onGameExit()
  end)

 self.btn_Help=tortoisePanel:getChildByName("Btn_Help")
 self.btn_Help:setPositionY(1445-self.visibleOrigin.y)
 --self.btn_Help:setScale(1)
 local btn_HelpPosX=self.btn_Help:getPositionX()-self.visibleOrigin.x-5
 self.btn_Help:setPositionX(btn_HelpPosX)
 self.btn_Help:setGlobalZOrder(50)
  --游戏说明界面-----------------------
 self.pageIndex=1
 self.curShowsPanel=nil --当前说明界面
 self.btn_HelpState=not self.btn_HelpState
 self.HelpPanelShade=tortoisePanel:getChildByName("HelpPanelShade")
 self.HelpPanelShade:setPositionX(375)
 self.HelpPanelShade:setPositionY(0)
 self.HelpPanelShade:setVisible(false)
 self.HelpPanelShade:setGlobalZOrder(70)
 self.HelpPanel=tortoisePanel:getChildByName("Panel_Help")
 self.HelpPanel:setGlobalZOrder(75)
 --self.HelpPanel:setPosition(cc.p(375,750))
 self.Btn_HelpLeft= self.HelpPanel:getChildByName("Btn_Left")
 self.Btn_HelpLeft:setGlobalZOrder(76)
 self.Btn_HelpLeft:addTouchEventListener(function(sender,type)
  if type==0 then
    print('---------------Turn 1')
   self:GameShowsPageTurn(1)
  end
 end)
 self.Btn_HelpRight= self.HelpPanel:getChildByName("Btn_Right")
 self.Btn_HelpRight:setGlobalZOrder(76)
 self.Btn_HelpRight:addTouchEventListener(function(sender,type)
  if type==0 then
   self:GameShowsPageTurn(0)
  end
 end)
 self.Btn_HelpReturn= self.HelpPanel:getChildByName("Btn_Return")
 self.Btn_HelpReturn:setGlobalZOrder(76)
 self.Btn_HelpReturn:setScale(1)
 self.Btn_HelpReturn:addClickEventListener(function()
    self.HelpPanel:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,0),cc.CallFunc:create(function() self.HelpPanelShade:setVisible(false) end)))
  end)
 self.Text_HelpContent=self.HelpPanel:getChildByName("Text_Content")
 self.HelpPanel:setPositionX(375)
 self.HelpPanel:setPositionY(750)
 self.HelpPanel:setScale(0)

 self:SetGameHelpPanel()  --设置帮助说明界面

 self.btn_Help:addClickEventListener(function()
      print('-----------------帮助按钮点击---------------')
      self.HelpPanelShade:setVisible(true)
      self.HelpPanel:runAction(cc.ScaleTo:create(0.2,1))
 end)
 -----------------------------------
  
  self.btn_Voice=tortoisePanel:getChildByName("Btn_Voice")
  --self.btn_Help:setName("Btn_Voice")
  self.btn_Voice:loadTextureNormal("button_voice_1.png",ccui.TextureResType.plistType)
  --self.btn_Voice:setScale(1)
  --self:addChild(self.btn_Voice,50)
  self.btn_Voice:setPositionY(1445-self.visibleOrigin.y)
  local btn_VoicePosX=self.btn_Voice:getPositionX()-self.visibleOrigin.x-5
  self.btn_Voice:setPositionX(btn_VoicePosX)
  --self.btn_Voice:setPosition(702,1450)
  self.btn_Voice:setGlobalZOrder(50)

  self.text_GameMsg=tortoisePanel:getChildByName("Text_GameMessage")
  self.text_GameMsg:setPositionY(self.text_GameMsg:getPositionY()+20)
  self.text_GameMsg:setString('')
  --self.text_GameMsg:setContentSize(40)
  self.text_GameMsg:setFontSize(30)
  self.text_GameMsg:setTextAreaSize(cc.size(680,90))

  self.headFrame_PlaySprite=display.newSpriteFrame("#PlayHead.png")
  --print('------------self.headFrame_PlaySprite :',self.headFrame_PlaySprite)
  self.headFrame_NormalSprite=display.newSpriteFrame("#Head.png")
  self.playerVoice_On=display.newSpriteFrame("#Icon_Music B.png")
  self.playerVoice_Off=display.newSpriteFrame("#Icon_Mute.png")

  --Zombie --------
  self.moon=poker:getChildByName("Moon")
  self.moon:setScaleX(self.adaptionNum.x)
  self.moon:setScaleY(self.adaptionNum.x)
  self.moon:setOpacity(255)
  self.tombstone=poker:getChildByName("Tombstone")
  self.tombstone:setScaleX(self.adaptionNum.x)
  self.tombstone:setScaleY(self.adaptionNum.x)
  self.tombstone:setPositionX(375)
  if self.adaptionNum.y==1 and self.adaptionNum.x~=1 then
    self.tombstone:setPositionY(self.tombstone:getPositionY()*self.adaptionNum.x)
  else
    self.tombstone:setPositionY(self.visibleOrigin.y+self.tombstone:getPositionY())
  end
  self.tombstone:setOpacity(0)
  self.zombieHand_Left=poker:getChildByName("Hand_Left")
  self.zombieHand_Left:setScaleX(self.adaptionNum.x)
  self.zombieHand_Left:setScaleY(self.adaptionNum.x)
  self.zombieHand_Right=poker:getChildByName("Hand_Right")
  self.zombieHand_Right:setScaleX(self.adaptionNum.x)
  self.zombieHand_Right:setScaleY(self.adaptionNum.x)
  self.zombieLogo=tortoisePanel:getChildByName("ZombieLogo")
  self.zombieLogo:setScaleX(self.adaptionNum.x)
  self.zombieLogo:setScaleY(self.adaptionNum.x)
  self.zombieLogo:setPositionX(375)
  self.zombieLogo:setScale(0)

  ----------------------------------------------------------------
  --头像界面
  --玩家显示的UI
  self.headPanel = cc.CSLoader:createNode("HeadPortrait.csb")
  self:addChild(self.headPanel)
  self.headPanel:setPosition(0,0)
  self.playerMesUI={}
  for i=1,self.playerCount do 
    self.playerMesUI[i]={}
    self.playerMesUI[i].headPanel=self.headPanel:getChildByName('HeadPanel_'..tostring(i))

    self.playerMesUI[i].head_Frame=self.playerMesUI[i].headPanel:getChildByName('Head')
    --self.playerMesUI[i].head_Frame:setVisible(true)
    self.playerMesUI[i].head_Sprite=self.playerMesUI[i].head_Frame:getChildByName('Sprite')
    self.playerMesUI[i].head_Sprite:setOpacity(0)
    self.playerMesUI[i].sex=self.playerMesUI[i].headPanel:getChildByName('Sex')
    self.playerMesUI[i].sex:setScale(0.8)
    --self.playerMesUI[i].sex:setPositionY(self.playerMesUI[i].sex:getPositionY()-2)
    self.playerMesUI[i].name=self.playerMesUI[i].headPanel:getChildByName('Text_Name')
    self.playerMesUI[i].name:setString("Player"..tostring(i))
    self.playerMesUI[i].voice=self.playerMesUI[i].headPanel:getChildByName('Voice')
    self.playerMesUI[i].voice:setSpriteFrame(self.playerVoice_Off)
    self.playerMesUI[i].voice:setScale(0.75)
    self.playerMesUI[i].voice:setPositionY(self.playerMesUI[i].voice:getPositionY()-2)
    self.playerMesUI[i].progressBarPanel=self.playerMesUI[i].headPanel:getChildByName('ProgressBarBG')
    self.playerMesUI[i].progressBarPanel:setVisible(false)
    --print('-----progressBarPanel :',self.playerMesUI[i].progressBarPanel)
    self.playerMesUI[i].progressBar=self.playerMesUI[i].headPanel:getChildByName('ProgressBar')
    self.playerMesUI[i].progressBar:setVisible(false)
    --print('---------self.playerMesUI[i].progressBar :',self.playerMesUI[i].progressBar)
    self.playerMesUI[i].clickArea=self.playerMesUI[i].headPanel:getChildByName('ClickArea')
    self.playerMesUI[i].clickArea:setOpacity(0)
    self.playerMesUI[i].name:setPositionY(self.playerMesUI[i].name:getPositionY()-6)
    local noEffect=cc.Sprite:create("StaticImage/HelpPanel_Close.png")
    noEffect:setOpacity(0)
    self.playerMesUI[i].headPanel:addChild(noEffect)
    noEffect:setAnchorPoint(cc.p(0.5,0.5))
    noEffect:setPosition(-45,60)
    self.playerMesUI[i].no=noEffect
    --CCSPlayAction(self.playerMesUI[i].no,i.."ST_s",0,true)
    
    local headPanelPos={}
   if i==1 then
      self.playerMesUI[i].yourTurn=self.playerMesUI[i].headPanel:getChildByName('Yourturn')
      headPanelPos.x=self.playerMesUI[i].headPanel:getPositionX()
      headPanelPos.y=290
      
    elseif i==2 then
      headPanelPos.x=self.playerMesUI[i].headPanel:getPositionX()+self.visibleOrigin.x+30
      headPanelPos.y=1224-self.visibleOrigin.y
    elseif i==3 then
      headPanelPos.x=self.playerMesUI[i].headPanel:getPositionX()
      headPanelPos.y=1370-self.visibleOrigin.y
    else
      headPanelPos.x=self.playerMesUI[i].headPanel:getPositionX()-self.visibleOrigin.x-30
      headPanelPos.y=1224-self.visibleOrigin.y
    end
   --dump(headPanelPos,'-----------------------headPanelPos :')
    --self.playerMesUI[i].progressBar:setPercent(100)
    self.playerMesUI[i].headPanel:setPositionX(headPanelPos.x)
    self.playerMesUI[i].headPanel:setPositionY(headPanelPos.y)
  end

-----------------------------------------------------------------------------------------------
  self.listViewPos={}

  for i=1,self.playerCount do
    self.playerCard_ListView[i]=self.playerPanelNode:getChildByName('ListView_Player_'..tostring(i))
    self.playerCard_ListView[i]:setTouchEnabled(false)
    self.playerCard_ListView[i]:setScrollBarEnabled(false)

    self.playerCardNum[i]=0
    self.listViewPos[i]={}
    if i==1 then
      self.listViewPos[i].x=self.playerCard_ListView[i]:getPositionX()+self.visibleOrigin.x
      self.listViewPos[i].y=self.playerCard_ListView[i]:getPositionY()
    elseif i==2 then
      self.listViewPos[i].x=self.playerCard_ListView[i]:getPositionX()+self.visibleOrigin.x
      self.listViewPos[i].y=self.playerCard_ListView[i]:getPositionY()---self.visibleOrigin.y
    elseif i==3 then
      self.listViewPos[i].x=self.playerCard_ListView[i]:getPositionX()+self.visibleOrigin.x
      self.listViewPos[i].y=self.playerCard_ListView[i]:getPositionY()-self.visibleOrigin.y
    else
      self.listViewPos[i].x=self.playerCard_ListView[i]:getPositionX()-self.visibleOrigin.x
      self.listViewPos[i].y=self.playerCard_ListView[i]:getPositionY()---self.visibleOrigin.y
    end
    --dump(listViewPos,'-----------------listViewPos :')
    self.playerCard_ListView[i]:setPositionX(self.listViewPos[i].x)
    self.playerCard_ListView[i]:setPositionY(self.listViewPos[i].y)

  end
  cc.ControlMgr:SetPokerListView(self.listViewPos,self.visibleOrigin)

    
  self.GAMESTATE={GAMEPRE=0,GAMESTART=1,GAMING=2,GAMEOVER=3}
  self.curGameState=GAME_STATE.START --当前游戏状态

  
  --玩家对象
  self.playerObj={}
  for i=1,self.playerCount do
   self.playerObj[i]=PlayerMgr.new()
   self.playerObj[i]:SetCardBoard(self.pokerTablePos)
   self.playerObj[i]:SetHandCardNode(self.playerPanelNode)
  end

  self.pokerPrefab=nil
   --牌对象列表
  for i=1,4 do
   self.playerCardObjs[i]={}
  end
  
  --被抽牌的索引
  self.BeDrawIndex=0
  --抽牌索引
  self.PlayIndex=0

  --剩余的玩家数量
 self.playerCount_OnGame=4
 --
 self.curPlayCardObj={}
 self.lastPlayCardObj={}


 self.tableCard=nil  --

 self.handCardIsLeftMove=false --手牌是否大左移操作
 self.autoDrawCard=false --是否自动出牌
 --超时次数
 self.outTimeCount=0

 self.PlayerRoundTime=8 --玩家回合时间
 self.OriRoundTime=self.PlayerRoundTime
 self.dealAcitonTime=0.25  --发牌飞行时间
 self.otherPlayerCardInterVal=40*self.adaptionNum.x --其他玩家的牌间距

 self.cardInterVal=60*self.adaptionNum.x --自身玩家牌间距
 self.expandSize=35*self.adaptionNum.y --自身客户端抽牌时被抽牌玩家的牌间距

 self.popupDis=90*self.adaptionNum.x --弹起距离
 self.cardShirinkValue=15 --手牌收缩数值

 self.centralPoint_Y=902-self.visibleOrigin.y --2,4 玩家
 --print('----- self.centralPoint_Y: ',self.centralPoint_Y)
 self.centralPoint_X=375--1,3 玩家
 --print('----- self.centralPoint_X: ',self.centralPoint_X)

 self.moveDownPos=1090-self.visibleOrigin.y  --下移手牌的顶点位置

 self.cardTogetherTime=0.3  --牌聚集的时间

 self.onDeal=false
 -----------------------------------------------

 --游戏结束界面-----------------------
 self.GameOverShade=tortoisePanel:getChildByName("GameOverShade")
 self.GameOverShade:setVisible(false)
 self.GameOverShade:setGlobalZOrder(85)
 self.GameOverPanel=tortoisePanel:getChildByName("Panel_GameOver")
 local gameOverPanel_Bg=self.GameOverPanel:getChildByName("BG")
 gameOverPanel_Bg:setLocalZOrder(5)
 self.failPlayerHead= self.GameOverPanel:getChildByName("Frame")
 self.failPlayerHead:setLocalZOrder(20)
 self.failPlayerHead_Head=self.GameOverPanel:getChildByName("Head")
 self.failPlayerHead_Head:setLocalZOrder(15)
 self.failPlayerHead_Head:setVisible(false)
 self.GameOverPanel:setScale(0)
 --self.GameOverPanel:setGlobalZOrder(90)

 -----------------排名界面
 
 self.rankListPanel=tortoisePanel:getChildByName("Panel_RankingList")
 --self.RankPanelShade=tortoisePanel:getChildByName("RankPanelShade")
 --self.RankPanelShade:setVisible(false)
 self.Title=self.rankListPanel:getChildByName("Title")
 --self.Title:setPositionY(644)
 --banner:setPositionY(620)
 self.Banner=self.rankListPanel:getChildByName("Banner")
 self.playerInfoArr={}
 for i=1,self.playerCount do
  self.playerInfoArr[i]={}
  self.playerInfoArr[i].panel=self.rankListPanel:getChildByName("Info_Player_"..i)

  self.playerInfoArr[i].bg=self.playerInfoArr[i].panel:getChildByName("back")

  self.playerInfoArr[i].head=self.playerInfoArr[i].panel:getChildByName("Head")
  self.playerInfoArr[i].head_Man=self.playerInfoArr[i].panel:getChildByName("Head_Man")
  self.playerInfoArr[i].image_Add=self.playerInfoArr[i].panel:getChildByName("Image_Add")
  local addPosX=self.playerInfoArr[i].image_Add:getPositionX()
  self.playerInfoArr[i].image_Add:setPositionX(addPosX-10)
  self.playerInfoArr[i].name=self.playerInfoArr[i].panel:getChildByName("Text_Name")
  self.playerInfoArr[i].name:setString('Player_'..i)

  --self.playerInfoArr[i].panel:setGlobalZOrder(92)
 end

 self.btnContinue=self.rankListPanel:getChildByName("Button_Continue")
 self.btnContinue:setGlobalZOrder(90)

 self.rankListPanel:setOpacity(0)

 self.rankListPanel:setVisible(false)
 -----------------------------------
 --设置玩家操作指示
 self:SetPlayerGuidePanel(tortoisePanel)

 --------------------------------------

 self:addEvent()

 self.gameHeartbeatTime=0   
 self:listenHeartbeatEvent()

 --平台功能
 --表情
 --自身客户端头像位置
  --print('--------self.playerMesUI[1].head_Frame:getPositionX() :',self.playerMesUI[1].head_Frame:getPositionX())
  --print('--------self.visibleOrigin.x :',self.visibleOrigin.x)
  local headPanelSize=self.playerMesUI[1].headPanel:getContentSize()
  self.myPlayerPos=self.playerMesUI[1].headPanel:convertToWorldSpace(cc.p(self.playerMesUI[1].head_Frame:getPositionX()+headPanelSize.width*2,self.playerMesUI[1].head_Frame:getPositionY()))
  local myPlayerPos2=self.playerMesUI[2].headPanel:convertToWorldSpace(cc.p(self.playerMesUI[2].head_Frame:getPositionX()+headPanelSize.width*0.5,self.playerMesUI[2].head_Frame:getPositionY()))
  self.otherPlayerPos={
      self.playerMesUI[2].headPanel:convertToWorldSpace(cc.p(self.playerMesUI[2].head_Frame:getPositionX()+headPanelSize.width*0.5,self.playerMesUI[2].head_Frame:getPositionY())),
      self.playerMesUI[3].headPanel:convertToWorldSpace(cc.p(self.playerMesUI[3].head_Frame:getPositionX()+headPanelSize.width*2,self.playerMesUI[3].head_Frame:getPositionY())),
      self.playerMesUI[4].headPanel:convertToWorldSpace(cc.p(self.playerMesUI[4].head_Frame:getPositionX()-headPanelSize.width*0.5,self.playerMesUI[4].head_Frame:getPositionY()))
    }


   --平台的语音功能
  self.platformFunc=PlatformFunction.new(self)
  self.spinePosList={self.playerMesUI[1].head_Frame,self.playerMesUI[2].head_Frame,self.playerMesUI[3].head_Frame,self.playerMesUI[4].head_Frame}

  --网络信号
  local WifiLayer = require("app.common.WifiLayer")
  local wifiX = self.btn_Help:getPositionX()-self.btn_Help:getContentSize().width/2-45
  local wifiY = self.btn_Help:getPositionY()-self.btn_Help:getContentSize().height/2+20
  self.wifiLayer=WifiLayer:create(wifiX,wifiY)
  self:addChild(self.wifiLayer,70)
  self.wifiLayer:setGlobalZOrder(70)

  self.actorFirstControl=false
  
  --[[每帧调用
  local function update()
    print('------------每帧调用的----------')
  end

  self:scheduleUpdateWithPriorityLua(update,0)
  ]]


  AudioEngine.playMusic("gameMusic/bgm.mp3",true)


  --cc.Director:getInstance():setDisplayStats(true) --显示帧率
  self.alreadyLoadPlayerInfo=false --已经加载过了,就不在加载

  self.actorDrawAction=false --是否已经播放抽牌动画

  self.breakLineState=false

  self.noEffectArray={false,false,false,false}

 

end
--[[
  监听平台的回调事件
]]
function c:addEvent()

  local listener = cc.EventListenerCustom:create(HYNotifyEvent.notifyUserInfo, handler(self, self.onGetUserInfo))
  local eventDispatcher = self:getEventDispatcher()
  eventDispatcher:addEventListenerWithFixedPriority(listener, 1)

  listener = cc.EventListenerCustom:create(HYNotifyEvent.notifyGameExit, handler(self, self.onGameExit))
  eventDispatcher = self:getEventDispatcher()
  eventDispatcher:addEventListenerWithFixedPriority(listener, 1)

  listener = cc.EventListenerCustom:create(HYNotifyEvent.notifyUserAvatar, handler(self, self.onGetUserImg))
  eventDispatcher = self:getEventDispatcher()
  eventDispatcher:addEventListenerWithFixedPriority(listener, 1)

  backListener = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT", handler(self, self.EnterBackGround))
  backEventDispatcher = self:getEventDispatcher()
  backEventDispatcher:addEventListenerWithFixedPriority(backListener, 1)

   
end

--[[
  获取玩家信息
]]
function c:onGetUserInfo(data)
  print('----------获取玩家信息回调---------------')
  local notifyData = data.notifyData
  dump(notifyData,'-------------------notifyData :')
  local playerInfo=cc.DataMgr:getAllPlayerInfo()
  --dump(playerInfo,'-------------PlayerInfo :')
  if notifyData.uid == cc.DataMgr:getActorID() then
    local actorInfo=cc.DataMgr:getActorInfo()
    actorInfo.name=notifyData.name
    actorInfo.sex=notifyData.gender
    actorInfo.PlayerId=notifyData.uid
    playerInfo[1].name=notifyData.name
    playerInfo[1].sex=notifyData.gender
    playerInfo[1].PlayerId=notifyData.uid
    self.playerObj[1]:SetPlayerName(notifyData.name)
    self.playerObj[1]:SetSex(notifyData.gender)
    self.playerObj[1]:SetPlayerID(notifyData.uid)
    --self.playerObj[1]:SetHeadPortraitUrl(notifyData.imageUrl)
    self:SetPlayerSceneInfo(1,cc.DataMgr:getActorInfo())
  else
    local index=cc.DataMgr:getPlayerIndexByID(notifyData.uid)
    playerInfo[index]=cc.DataMgr:getPlayerInfoByID(notifyData.uid)
    playerInfo[index].name=notifyData.name
    playerInfo[index].sex=notifyData.gender
    self.playerObj[index]:SetPlayerName(notifyData.name)
    self.playerObj[index]:SetSex(notifyData.gender)
    self.playerObj[index]:SetPlayerID(notifyData.uid)
    --self.playerObj[index]:SetHeadPortraitUrl(notifyData.imageUrl)
    self:SetPlayerSceneInfo(index,playerInfo[index])
  end
end
--[[
  游戏退出
]]
function c:onGameExit()
  print('-----------主动游戏退出------')
  cc.NetMgr:sendMsg(CLIENT_2_SERVER.QUIT,"pbghost.Empty",{} )
  self.exitScheduler=nil
  self.exitScheduler=cc.Director:getInstance():getScheduler()
  cc.DataMgr:setExitState(true)
  exitScheduler:scheduleScriptFunc(function()
    if cc.DataMgr:getGameOver() then --收到服务器下分的游戏结算协议就不上报平台
      return
    end
    eventCenter:removeEventListenersByTag("TortoiseScene")
    HYGameBridge:getInstance():gameFinish(0, {state = cc.DataMgr:getState(),winnerUid = cc.DataMgr:getActorID()})
  end,1,false)
  --cc.NetMgr:close()
end
--[[
  获取玩家头像
]]
function c:onGetUserImg(data)
  local notifyData = data.notifyData
  local uid        = notifyData.uid                    -- 玩家ID
  local localPath  = notifyData.localPath--notifyData.imageUrl              -- 头像路径
  --dump(data,'---获取头像回调回调')
  dump(notifyData,'-----------获取头像回调   notifyData :')
  if uid == cc.DataMgr:getActorID() then
    local clipView = self:createClipView("img_back.png",localPath)
     if clipView ~= nil then
        local sz = self.playerMesUI[1].head_Frame:getContentSize()
        clipView:align(display.CENTER,sz.width * 0.5,sz.height * 0.5):addTo(self.playerMesUI[1].head_Frame) 
        clipView:setPositionX(clipView:getPositionX()+7.5)
        clipView:setPositionY(clipView:getPositionY()-1)
        self.playerObj[1]:SetHeadPortraitUrl(localPath)
      end
      
  else
    for i=2,self.playerCount do
      if self.playerObj[i]:GetPlayerID()==uid then
        local clipView = self:createClipView("img_back.png",localPath)
        if clipView ~= nil then
          local sz = self.playerMesUI[i].head_Frame:getContentSize()
          clipView:align(display.CENTER,sz.width * 0.5,sz.height * 0.5):addTo(self.playerMesUI[i].head_Frame) 
          clipView:setPositionX(clipView:getPositionX()+7.5)
          clipView:setPositionY(clipView:getPositionY()-1)
          self.playerObj[i]:SetHeadPortraitUrl(localPath)
        end
      end
    end
  end
 
  
end
--[[
  头像圆形遮罩
  返回遮罩对象
]]
function c:createClipView(maskfile,localPath)
    local clippingNode = cc.ClippingNode:create()
    local stencil = display.newSprite(maskfile)--cc.Sprite:create("res/images/common/portrait_bottom_1.png")  -- 遮罩
    clippingNode:setStencil(stencil) --设置遮罩形状
    local w = stencil:getContentSize().width
    local photoView = cc.Sprite:create(localPath) --生成头像

    if photoView == nil then
        return nil
    end

    local imageSize = photoView:getContentSize()
    if imageSize.width>imageSize.height then
        photoView:setScale(w/imageSize.height)
    else
        photoView:setScale(w/imageSize.width)
    end  
    clippingNode:addChild(photoView)
    photoView:setTag(2)
    photoView:setPositionX(photoView:getPositionX()-7)
    photoView:setPositionY(photoView:getPositionY()+1)
    clippingNode:setInverted(false)
    clippingNode:setAlphaThreshold(0.5)
    return clippingNode
end

function c:createClipView2(maskfile,localPath)
    local clippingNode = cc.ClippingNode:create()
    local stencil = display.newSprite(maskfile)--cc.Sprite:create("res/images/common/portrait_bottom_1.png")  -- 遮罩
    clippingNode:setStencil(stencil) --设置遮罩形状
  
    clippingNode:setInverted(true)
    clippingNode:setAlphaThreshold(0.5)
    return clippingNode
end
--[[
 设置玩家场景信息
]]
function c:SetPlayerSceneInfo(index,info)
  print('------Name :',info.name)
  --self.playerMesUI[index].name:setString(info.name)
  StringUtils.cutStringForVisibleWidth(self.playerMesUI[index].name,info.name,210)
  local sprite=(info.sex==1 and display.newSpriteFrame("#Boy.png")) or display.newSpriteFrame("#Girl.png")
  self.playerMesUI[index].sex:setSpriteFrame(sprite)
end
--[[
  设置玩家游戏信息
]]
function c:SetPlayerGameInfo(index,info)
  --dump(info,'--------PlayerInfo :')
  self.playerObj[index]:SetHandCardNum(info.PokerList)
  --dump(info.PokerList,'--------------玩家手牌列表 :')
  self.playerObj[index]:SetPlayerID(info.PlayerId)
  --self.playerObj[index]:SetPlay(info.Sort)
  self.playerObj[index]:SetPosIndex(index)
  self.playerObj[index]:ActiveAI(info.AI)

  HYGameBridge:getUserAvatar(info.PlayerId) --从平台下载玩家头像
  HYGameBridge:getInstance():getUserInfo(info.PlayerId) --从平台下载玩家信息
  --先手出牌玩家
  if info.Sort>0 then

    self.PlayIndex=index
    print('  info.PlayerId  :',info.PlayerId..'----------------DealIndex :',index)
  end
  self.playerCardObjs[index]={}
   for n=1,#info.PokerList do
     local tempCard=info.PokerList[n]
     self.playerCardObjs[index][n]=CardObject.new(i,tempCard,n,info.PlayerId)

   end
  local clickArea=ccui.Button:create()
  local contentSize=self.playerMesUI[index].head_Frame:getContentSize()
  clickArea:loadTextureNormal("StaticImage/Head.png",ccui.TextureResType.localType)
  clickArea:setOpacity(0)
  self.playerMesUI[index].head_Frame:addChild(clickArea,10)
  clickArea:setPosition(cc.p(contentSize.width*0.5,contentSize.height*0.5))

  clickArea:setLocalZOrder(60)
  --clickArea:setGlobalZOrder(60)
  clickArea:addClickEventListener(function()
    print('----弹出玩家信息----')
    HYGameBridge.getInstance():showUserInfo(info.PlayerId)
  end)

  self.playerObj[index]:SetClickArea(clickArea)
end
--[[
  设置语音
]]
function c:SetGameVoice(playerIDList)

  self.platformFunc:Init(self,self.btn_Voice,{{icon=self.playerMesUI[1].voice,playerID=playerIDList[1]},{icon=self.playerMesUI[2].voice,playerID=playerIDList[2]},
    {icon=self.playerMesUI[3].voice,playerID=playerIDList[3]},{icon=self.playerMesUI[4].voice,playerID=playerIDList[4]}},self.spinePosList)
end
--[[
  设置表情
]]
function c:SetEmojiInfo(playerIDList)
  local EmojiChatLayer =  require("app.common.EmojiChatLayer")
  self.emojiChatLayer=EmojiChatLayer.new()
  self.emojiChatLayer:ctorForMulti(cc.DataMgr:getActorID(),cc.p(self.visibleSize.width*0.5, 120+self.visibleOrigin.y*0.2),115,115,true)

  self.emojiChatLayer:addUserInfo(playerIDList[1],self.myPlayerPos)
  self.emojiChatLayer:addUserInfo(playerIDList[2],self.otherPlayerPos[1])
  self.emojiChatLayer:addUserInfo(playerIDList[3],self.otherPlayerPos[2])
  self.emojiChatLayer:addUserInfo(playerIDList[4],self.otherPlayerPos[3],3)
  self.emojiChatLayer:addTo(self,40)
  self.emojiChatLayer:setLocalZOrder(70)
  self.emojiChatLayer:setGlobalZOrder(75)

end

--[[
   设置游戏说明界面
]]
function c:SetGameHelpPanel()
    changeTranslation(HYGameBridge.getInstance():getLanguage()) --调用LangUtil 脚本的切换语言函数
     --游戏说明
    self.gameShowsPanel={
    {
        panel=self.HelpPanel:getChildByName('Panel_1')
    },
    {
        panel=self.HelpPanel:getChildByName('Panel_2')
    }
    }

    self.gameShowsPanel[1].panel:setGlobalZOrder(76)
    self.gameShowsPanel[2].panel:setGlobalZOrder(76)
    

    self.gameShowsPanel[1].txt1=self.gameShowsPanel[1].panel:getChildByName("Text_1")
    self.gameShowsPanel[1].txt2=self.gameShowsPanel[1].panel:getChildByName("Text_2")
    self.gameShowsPanel[1].txt3=self.gameShowsPanel[1].panel:getChildByName("Text_3")
    self.gameShowsPanel[2].txt4=self.gameShowsPanel[2].panel:getChildByName("Text_4")
    self.gameShowsPanel[2].txt5=self.gameShowsPanel[2].panel:getChildByName("Text_5")
    self.gameShowsPanel[2].txt6=self.gameShowsPanel[2].panel:getChildByName("Text_6")
    self.gameShowsPanel[2].txt7=self.gameShowsPanel[2].panel:getChildByName("Text_7")
    self.curShowsPanel=self.gameShowsPanel[1].panel
    for i=2,#self.gameShowsPanel do
        self.gameShowsPanel[i].panel:setVisible(false)
    end
    self.text_PageIndex=self.HelpPanel:getChildByName("Text_PageIndex")
    self.text_PageIndex:setGlobalZOrder(76)
    self.text_PageIndex:setString(tostring(self.pageIndex))
    self.btn_LangPanel=self.HelpPanel:getChildByName("Panel_Button")
    self.btn_LangPanel:setGlobalZOrder(75)
    self.btn_LangPanel:setVisible(false)
    local Button_sa=self.btn_LangPanel:getChildByName("Button_sa")
    Button_sa:addClickEventListener(function()
        self:ChangeLanguage(1)
      end)
    local Button_us=self.btn_LangPanel:getChildByName("Button_us")
    Button_us:addClickEventListener(function()
        self:ChangeLanguage(2)
      end)
    local Button_es=self.btn_LangPanel:getChildByName("Button_es")
    Button_es:addClickEventListener(function()
        self:ChangeLanguage(3)
      end)
    local Button_in=self.btn_LangPanel:getChildByName("Button_in")
    Button_in:addClickEventListener(function()
        self:ChangeLanguage(4)
      end)
    local Button_br=self.btn_LangPanel:getChildByName("Button_br")
    Button_br:addClickEventListener(function()
        self:ChangeLanguage(5)
      end)
    local Button_cn=self.btn_LangPanel:getChildByName("Button_cn")
    Button_cn:addClickEventListener(function()
       self:ChangeLanguage(6)
      end)

    self:SetGameShows(self.gameShowsPanel)


end
--[[
    设置游戏说明
]]
function c:SetGameShows(showsPanel)
    showsPanel[1].txt1:setString(tr('helpTxt1'))
    showsPanel[1].txt2:setString(tr('helpTxt2'))
    showsPanel[1].txt3:setString(tr('helpTxt3'))
    showsPanel[2].txt4:setString(tr('helpTxt4'))
    showsPanel[2].txt5:setString(tr('helpTxt5'))
    showsPanel[2].txt6:setString(tr('helpTxt6'))
    showsPanel[2].txt7:setString(tr('helpTxt7'))
end
--[[
    切换语言
]]
function c:ChangeLanguage(langIndex)
    print('--------------切换语言  :',LangEnum[langIndex])
    changeTranslation(LangEnum[langIndex])
    self:SetGameShows(self.gameShowsPanel)
end
--[[
    说明翻页
    0--向右翻页
    1--向左翻页
]]
function c:GameShowsPageTurn(turnDir)
  --print('---- #self.gameShowsPanel :',#self.gameShowsPanel)
  if turnDir>0 then
    self.pageIndex=((self.pageIndex-1)==0 and 1)or self.pageIndex-1
  else
    self.pageIndex=self.pageIndex+1
    if self.pageIndex+1>=#self.gameShowsPanel+1 then
       self.pageIndex=#self.gameShowsPanel
    end
    --self.pageIndex=((self.pageIndex+1)>=#self.gameShowsPanel and #self.gameShowsPanel)or self.pageIndex+1
  end
  if self.curShowsPanel~=nil then
    self.curShowsPanel:setVisible(false)
  end
  self.gameShowsPanel[self.pageIndex].panel:setVisible(true)
  self.curShowsPanel=self.gameShowsPanel[self.pageIndex].panel
  self.text_PageIndex:setString(tostring(self.pageIndex))
end

--[[
 设置玩家头像
]]
function c:SetPlayerHeadPortrait(index,url)
   local sprite=display.newSpriteFrame("#"..url)
   self.playerMesUI[index].head_Sprite:setSpriteFrame(sprite)
end

--[[
  设置玩家指示界面
]]
function c:SetPlayerGuidePanel(tortoisePanel)
   --玩家操作提示界面-----------
 self.guidePanel=tortoisePanel:getChildByName("Panel_Guide")
 self.guidePanel:setGlobalZOrder(95)
 --print('-----------self.guidePanel :',self.guidePanel)
 self.guidePanel:setOpacity(0)
 self.guidePanel:setVisible(false)

 self.guideHand=self.guidePanel:getChildByName("Guide_Hand")
 self.guideText=self.guidePanel:getChildByName("Text_Guide")
 self.guideText:setString(tr("guide"))
end
--[[
  显示玩家操作提示界面
]]
function c:ShowPlayerGuidePanel()
  self.guidePanel:setVisible(true)
  self.guidePanel:runAction(cc.Sequence:create(cc.FadeTo:create(0.15,255),cc.CallFunc:create(function()
    self.guidePanel:addClickEventListener(function()
    --print('-----------隐藏操作提示界面-----')
    self:HidePlayerGuidePanel()
  end)
    end)))
  local dur=0.3
  self.guideAction=cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(dur,cc.p(50,0)),cc.MoveBy:create(dur,cc.p(-50,0))))
  self.guideHand:runAction(self.guideAction)
end
--[[
    隐藏操作提示界面
]]
function c:HidePlayerGuidePanel()
  if self.guideAction~=nil then
    self.guidePanel:stopAction(self.guideAction)
    self.guideAction=nil
  end
  self.guidePanel:setVisible(false)
end
--[[
  发牌
  playerID --洗牌玩家ID
]]
function c:Deal(msg)
  print('-------------·发牌-------------self.PlayIndex: ',self.PlayIndex)
  local index=self.PlayIndex+1
  local pileIndex=1
  self.onDeal=true
  self.DealList={}
 local function DealFunc()
  if self.onDeal then
  --local variable=self.PlayIndex
    AudioEngine.playEffect("gameMusic/Deal.mp3",false)
    for i=1,33 do
      local remainder=nil
  
   
      local variable=nil
      if i~=33 then
        remainder=(index+(i-1))%4
        variable=(remainder==0 and 4)or remainder
      else
        variable=self.PlayIndex
      end
      self:GenerateCard(variable)
      local sequence=cc.Sequence:create(cc.DelayTime:create(0.07),cc.CallFunc:create(function()
        if not self.onDeal then
          return
        end 
        coroutine.resume(self.coroutine)
        end))
      self:runAction(sequence)
      if i%8==0 then
        self.cardPile[pileIndex]:setVisible(false)
        pileIndex=pileIndex+1
      end
      coroutine.yield()
    end
    
    if not self.onDeal then
      return
    end
    self.DealList={}
    self.onDeal=false
    local isShowZombie=false
   --设置玩家手牌
    for i=1,self.playerCount do
      self.playerObj[i]:SetHandCard(self.playerCardObjs[i])
      --table.insert(winnerIDList,#winnerIDList+1,self.playerObj[i]:GetPlayerID())
      if i==1 then
        for j=1,#self.playerCardObjs[i] do
          local tempCardObj=self.playerCardObjs[i][j]
          if tempCardObj:GetValue()==33 then
            isShowZombie=true
          end
        --print('--------------PlayerCardsScale :',tempCardObj:GetObj():getScale())
        end
      end
    end
    if isShowZombie then
      self:runAction(cc.Sequence:create(cc.DelayTime:create(0.15),cc.CallFunc:create(function() 
        self:BecomeAZombie(1)
      end)))
    end
    cc.DataMgr:setActorCardsCount(#self.playerObj[1]:GetHandCard())
   --计算洗牌玩家位置索引
    local shuffleIndex=cc.DataMgr:getPlayerIndexByID(msg.PlayerId)
    self.BeDrawIndex=shuffleIndex
    print('------------shuffleIndex :',shuffleIndex)
    --洗牌玩家是自身客户端玩家或者是AI并且自身客户端是主机玩家
    local callBack=function()
      self:PlayerShuffle(shuffleIndex,playerID==cc.DataMgr:getActorID(),msg)
    end
    local sequence=cc.Sequence:create(cc.DelayTime:create(0.2),cc.CallFunc:create(callBack))
    self:runAction(sequence)
    print('----------------Complete-------------')
    --[[
    local infoList={}
  --8888888 99999999,223454364,3123124
    local idList={8888888,99999999,223454364,3123124}
    for i=1,4 do
      infoList[i]={}
      local info={
      PlayerId=idList[i],
      ScoreList ={10,7,5,3},
      winnerList =idList,
      State ="NormalFinish"
      }
      infoList[i]=info
    end
    print('-----infoList :',#infoList)
    self:ShowPlayerRankList(infoList)
    ]]
    end

 end
 self.coroutine=coroutine.create(function() 
     --print('----------------DealFunc----------')
    DealFunc()
  end)
 coroutine.resume(self.coroutine)
  --self:ShowPlayerHand(0)
end

--local poker=nil
--[[
 生成牌
]]
function c:GenerateCard(variable)
    local card=nil
    if self.pokerPrefab ==nil then
      self.pokerPrefab=ccui.Button:create()
      card=self.pokerPrefab
    else
      card=self.pokerPrefab:clone()
    end  
    card:setRotation(0)
    table.insert(self.DealList,#self.DealList+1,card)
   --print('self.playerCardNum[variable] :',self.playerCardNum[variable])
   self.playerCardNum[variable]=self.playerCardNum[variable]+1
   if variable==1 then
    --local anglogCards=self.anglogPlayerCards[variable][self.playerCardNum[variable]]
    local anglogCardArr=self.playerObj[variable]:GetHandCardNum()
    --print('  anglogCardArr:',#anglogCardArr)
    local anglogCards=anglogCardArr[self.playerCardNum[variable]]

    --print(' value :',anglogCards)
    local spriteName='Pit_'..tostring(anglogCards)..'.png'
    --print(' SpriteName :',spriteName)
    card:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
   else

    card:loadTextureNormal('Pit_beimian.png',ccui.TextureResType.plistType)

   end
   card:setPosition(self.pokerTablePos.x,self.pokerTablePos.y)
   card:setAnchorPoint(cc.p(0.5,0.5))
   self.playerPanelNode:addChild(card)

   local choose=cc.Sprite:createWithSpriteFrameName("Choose.png")
   choose:setAnchorPoint(cc.p(0.5,0.5))
   choose:setVisible(false)
   card:addChild(choose)
   local size=card:getContentSize()
   choose:setPosition(size.width*0.5,size.height*0.5)
    local angle=(variable-1)*90
    --print(' angle :',angle)
    local rotaAction=cc.RotateBy:create(self.dealAcitonTime,angle)
    card:runAction(rotaAction)
    local startHandCardLen=self.playerObj[variable]:GetStartHandCardLen()
    local medianPoint=math.ceil(startHandCardLen*0.5)
    local endPoint=cc.ControlMgr:CalculateCardPosition(variable,medianPoint,startHandCardLen,self.playerCardNum[variable])
    card:runAction(cc.MoveTo:create(self.dealAcitonTime,cc.p(endPoint.x,endPoint.y)))
    
    self.playerCardObjs[variable][self.playerCardNum[variable]]:SetObj(card)
    self.playerCardObjs[variable][self.playerCardNum[variable]]:SetChoose(choose)
    self.playerCardObjs[variable][self.playerCardNum[variable]]:SetSeatIndex(variable)
    card:setTouchEnabled(false)

end
--[[
  在牌未生成一张新牌
]]
function c:GenerateCardInTagEnd(cardList,seatIndex,CardNum)
  local cardObj=nil
  if self.pokerPrefab ==nil then
    self.pokerPrefab=ccui.Button:create()
    cardObj=self.pokerPrefab
  else
    cardObj=self.pokerPrefab:clone()
  end  
  cardObj:setRotation(0)
  local cardPos=cardList[#cardList]:GetObj():getPosition()
  
  cardObj:setPosition(self.pokerTablePos.x,self.pokerTablePos.y)
  cardObj:setAnchorPoint(cc.p(0.5,0.5))
  self.playerPanelNode:addChild(cardObj)
  local tagEndPos=nil
  if seatIndex==1 then
    local spriteName='Pit_'..tostring(CardNum)..'.png'
    --print(' SpriteName :',spriteName)
    cardObj:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
    tagEndPos=cc.p(cardPos.x+self.cardInterVal,cardPos.y)
  else
    if seatIndex==2 then
      tagEndPos=cc.p(cardPos.x,cardPos.y-self.otherPlayerCardInterVal)
    elseif seatIndex==3 then
      tagEndPos=cc.p(cardPos.x-self.otherPlayerCardInterVal,cardPos.y)
    else
      tagEndPos=cc.p(cardPos.x,cardPos.y+self.otherPlayerCardInterVal)
    end
    cardObj:loadTextureNormal('Pit_beimian.png',ccui.TextureResType.plistType)
  end
  cardObj:setPosition(tagEndPos)
  local choose=cc.Sprite:createWithSpriteFrameName("Choose.png")
  choose:setAnchorPoint(cc.p(0.5,0.5))
  choose:setVisible(false)
  cardObj:addChild(choose)
  local size=cardObj:getContentSize()
  choose:setPosition(size.width*0.5,size.height*0.5)
  local angle=(seatIndex-1)*90
    --print(' angle :',angle)
  cardObj:setRotation(angle)
  cardObj:setTouchEnabled(false)
  local card=CardObject.new(#cardList+1,CardNum,seatIndex,self.playerObj[seatIndex]:GetPlayerID())
  card:SetObj(cardObj)
  return card
end

function c:ShufflePreparatory(handCards,isSelf)
  --print('-------self.shuffleCardCount :',self.shuffleCardCount)
  local tempDeck={}
  for i=1,#handCards do
    table.insert(tempDeck,i,i)
  end
  if isSelf then
    local len=self.shuffleCardCount*2
    for i=1,len do
      local index=math.random(1,#tempDeck)
      if i>self.shuffleCardCount then
        self.destinationDeck[#self.destinationDeck+1]=tempDeck[index]
      else
        self.shuffleDeck[#self.shuffleDeck+1]=tempDeck[index]
      end
      table.remove(tempDeck,index)
    end
  else
    print('----------RandomHandCardLen :',#handCards)
    local len=self.shuffleCardCount*2
    for i=1,len do
      if i<=self.shuffleCardCount then
        self.destinationDeck[i]=tempDeck[#tempDeck-(i-1)]
        self.shuffleDeck[i]=tempDeck[i]
      else
        self.destinationDeck[i]=tempDeck[i-self.shuffleCardCount]
        self.shuffleDeck[i]=tempDeck[#tempDeck-(i-self.shuffleCardCount-1)]
      end
    end
  end

end
--[[
 这个函数是专门做自身客户端洗牌的,会调用玩家的洗牌函数
 并且会向服务端发送新回合开始的协议
 shuffleIndex --洗牌玩家的位置索引

 isSelf --是否是自身客户端洗牌
 pokerList --手牌列表
]]
function c:PlayerShuffle(shuffleIndex,isSelf,washMsg)
  self:PlayerHandsCheck(washMsg,shuffleIndex)
  self.BeDrawIndex=shuffleIndex
  local handCards=self.playerObj[self.BeDrawIndex]:GetHandCard()
  local remainingOneCard=#handCards<=1
  self.shuffleCardCount=math.ceil(washMsg.Count/3)
  print(' -------------------洗牌玩家ID :',self.playerObj[self.BeDrawIndex]:GetPlayerID())
  print('------------------洗牌玩家手牌长度 :',#handCards)
  print('---------------------是否是自身客户端洗牌 :',isSelf)
  --local tempDeck={}
  self.shuffleDeck={} 
  self.destinationDeck={} 

  local function PreparatoryFunc() --洗牌准备
    self:ShufflePreparatory(handCards,isSelf)
  end

  local function ShuffleFunc()
    --洗牌玩家是客户端本身进行洗牌同步
    --洗牌玩家是AI并且自身客户端是主机
    local function ShuffleCallBack(isAI)
      print('----------------洗牌完成回调------------PlayIndex :',self.PlayIndex)
      --cc.DataMgr:setIsAIPlayCard(false)
      if not self.breakLineState then
        self:HandCardGathering(self.PlayIndex)
      end
      --isAI --是防止客户端玩家在这个阶段掉线转AI的情况
    end
    --dump(self.shuffleDeck,'--------------------self.shuffleDeck :')
    --dump(self.destinationDeck,'--------------------self.destinationDeck :')
    self.playerObj[self.BeDrawIndex]:Shuffle(self.shuffleDeck,self.destinationDeck,self.shuffleCardCount,ShuffleCallBack)
  end
  local shuffleSequence=nil
  --洗牌玩家只剩下一张牌了
  if remainingOneCard then
    --self:PlayerTimerPause()
    return 
  else
    if isSelf then
      shuffleSequence=cc.Sequence:create(cc.CallFunc:create(PreparatoryFunc),cc.DelayTime:create(0.10),cc.CallFunc:create(PreparatoryFunc),
      cc.DelayTime:create(0.2),cc.CallFunc:create(ShuffleFunc))
    else
      shuffleWaitTime=0.2
      shuffleSequence=cc.Sequence:create(cc.CallFunc:create(PreparatoryFunc),cc.DelayTime:create(shuffleWaitTime),cc.CallFunc:create(ShuffleFunc))
    end
  end
  self:runAction(shuffleSequence)
  --self:PlayerTimerPause()

end
--[[
  手牌核对

]]
function c:PlayerHandsCheck(msg,seatIndex)
  local hands=self.playerObj[seatIndex]:GetHandCard()
  if seatIndex==1 then
    --[[
    local difference=false
    local pokerList=msg.PokerList
    
    for i=1,#hands do
      if hands[i]:GetValue()~=pokerList[i] then
        difference=true
        break
      end
    end
    if difference then
      print('-------------------------客户端手牌与服务器牌组不一致--------------客户端手牌 长度:',#hands) 
      dump(msg,'---------------------洗牌信息 :')
      dump(hands,'----------------------玩家手牌 :')
      --cc.NetMgr:close()
      --cc.NetMgr:doConnect()
    end
    ]]
  else
    local checkNum=#hands-msg.Count
    local len=math.abs(checkNum)
    if len~=0 then
      print('--------------SeatIndex :',seatIndex)
      print('-------------------------客户端手牌与服务器牌组不一致--------------客户端手牌 长度:',#hands) 
      dump(msg,'---------------------洗牌信息 :')
      dump(hands,'----------------------玩家手牌 :')
      --cc.NetMgr:close()
      --cc.NetMgr:doConnect()
    end
  end

end
--[[
  玩家回合计时
]]
function c:TimingOfPlayerRound(index)
 
  local function TimingFunc()
    print('---------------开始计时')
    local delay=0.1
    local timingCount=(index==1 and delay/self.PlayerRoundTime)or delay/self.OriRoundTime
    if index==1 then
      self.playerMesUI[index].yourTurn:setVisible(true)
      self.playerMesUI[index].name:setVisible(false)
    end
    self.roundTimePercent=100
    self.stopTiming=false
    self.isOutTime=false
    self.playerMesUI[index].head_Frame:setSpriteFrame(self.headFrame_PlaySprite)
    self.playerMesUI[index].progressBarPanel:setVisible(true)
    self.playerMesUI[index].progressBar:setVisible(true)
    self.playerMesUI[index].progressBar:setPercent(self.roundTimePercent)
    local timingCoroutine=nil
    print('--------TimingCount :',timingCount,'----------self.roundTimePercent :',self.roundTimePercent)
    print('------------self.stopTiming :',self.stopTiming)
    while(self.roundTimePercent>0 and not self.stopTiming) do
      
      self.roundTimePercent=self.roundTimePercent-(100*timingCount)
      --print('-----------self.roundTimePercent : ',self.roundTimePercent)
      self.playerMesUI[index].progressBar:setPercent(self.roundTimePercent)
      self.timingAction=cc.Sequence:create(cc.DelayTime:create(delay),cc.CallFunc:create(function()
        if self.timingCoroutine~=nil and self.roundTimePercent>0 then   
          coroutine.resume(self.timingCoroutine)
        elseif self.roundTimePercent<=0 and not self.stopTiming and index==1 then
          print('----self.roundTimePercent :',self.roundTimePercent)
          print('----------操作超时--------------')  
          self.stopTiming=true
          --self.outTimeCount=self.outTimeCount+1
          --local roundTime=self.OriRoundTime-self.outTimeCount*5
          --self.PlayerRoundTime=(roundTime<=5 and 5)or roundTime
          --self:PlayerRoundEnd(index,self.stopTiming)
        end
      end))
      self.playerMesUI[index].progressBar:runAction(self.timingAction)
      coroutine.yield()
    end
  end
  self.timingCoroutine=nil
  self.timingCoroutine=coroutine.create(function() 
     TimingFunc()
  end)

  coroutine.resume(self.timingCoroutine)


end
--[[
   玩家计时暂停
]]
function c:PlayerTimerPause()
  print('-------------------计时暂停')
  self.stopTiming=true
end

--[[
  玩家回合结束
  isOutTime --是否超时
]]
function c:PlayerRoundEnd(index,isOutTime)
  if self.timingCoroutine~=nil then
    --self.playerMesUI[index].progressBar:stopAction(self.timingAction)
    --self.roundTimePercent=0
    self.timingCoroutine=nil
  end
  self:HideTimer(index)

  if isOutTime then
   --玩家操作超时
   --self:OutTimeDrawCard(self.BeDrawIndex)

  end

end
--[[
  隐藏计时器
]]
function c:HideTimer(index)
  if index==1 then
    self.playerMesUI[index].yourTurn:setVisible(false)
    self.playerMesUI[index].name:setVisible(true)
  end
  self.playerMesUI[index].head_Frame:setSpriteFrame(self.headFrame_NormalSprite)
  self.playerMesUI[index].progressBarPanel:setVisible(false)
  self.playerMesUI[index].progressBar:setVisible(false)
end
--[[
  玩家回合开始
  playerID --当前回合玩家的ID
]]
function c:PlayerRoundStart(msg,isReLogin)
    --print('-------------------PlayPlayer IsAI :',self.playerObj[self.PlayIndex]:GetIsAI())
    dump(msg,'-------------回合开始信息 :')
    self.PlayIndex=cc.DataMgr:getPlayerIndexByID(msg.PlayerId)
    self.BeDrawIndex=cc.DataMgr:getPlayerIndexByID(msg.OtherId)

    self:PlayerRoundEnd(self.BeDrawIndex) --隐藏计时器(保险)
    print("---------------开启新的玩家回合----------PlayIndex :",self.PlayIndex.."     BeDrawIndex :",self.BeDrawIndex)
    local controState=0
    local noticeMsg=nil

    if self.PlayIndex==1 then
      noticeMsg={self.playerObj[self.BeDrawIndex]:GetPlayerName()}
    else
      controState=2
      noticeMsg={self.playerObj[self.PlayIndex]:GetPlayerName(),self.playerObj[self.BeDrawIndex]:GetPlayerName()}
    end
    print('----------------抽牌玩家手牌长度 :',#self.playerObj[self.PlayIndex]:GetHandCard())
    print('----------------被抽牌玩家手牌长度 :',#self.playerObj[self.BeDrawIndex]:GetHandCard())
    if not isReLogin then
      self:PlayerControllerMsg(noticeMsg,controState)
    end
    --如果当前回合是客户端本身,就进行抽牌
    if msg.PlayerId==cc.DataMgr:getActorID() then

      --显示遮罩
      self:ShowHandCardShade(self.PlayIndex,self.BeDrawIndex)
      local beDrawPlayerCards=self.playerObj[self.BeDrawIndex]:GetHandCard()
      if #beDrawPlayerCards==1 then
        beDrawPlayerCards[1]:GetObj():setTouchEnabled(true)
      end
      self:DrawACard(self.PlayIndex,self.BeDrawIndex)

    else
      self:ShowHandCardShade(0)
    end
end

--[[
  显示计时器
]]
function c:ShowRoundTimer(index)
  self:TimingOfPlayerRound(index)
end
--[[
  显示手牌遮罩
  当playIndex > 1 时所有的手牌都显示遮罩
]]
function c:ShowHandCardShade(playIndex,beDrawCardIndex)
  if playIndex>1 then
    for i=1,#self.playerObj do
      self.playerObj[i]:HandCardShadeState(true)
    end
  else
    for i=1,#self.playerObj do
      if i~=playIndex and i~= beDrawCardIndex then
        self.playerObj[i]:HandCardShadeState(true)
      else
        self.playerObj[i]:HandCardShadeState(false)
      end
    end
  end
end

--[[
 设置被抽手牌的移动目的位置
 index --抽牌玩家位置
 beDrawIndex ---被抽牌玩家位置
]]
function c:SetCardDestination(index,beDrawIndex)

  local drawCardPlayer=self.playerObj[index] --抽牌玩家
  local skewingMovePos=20*self.adaptionNum.x--大左移状态下小左移的偏移量
  local tempHandCards=drawCardPlayer:GetHandCard()
  local tempEndCardOriPos={x=tempHandCards[#tempHandCards]:GetObj():getPositionX(),y=tempHandCards[#tempHandCards]:GetObj():getPositionY()}
  local fixationPos={x=self.listViewPos[index].x,y=self.listViewPos[index].y}
  local littleLeftMoveTime=0.4  --小左移的动效时间
  --[[
    抽牌的是自身客户端玩家
  ]]
  if drawCardPlayer:GetPlayerID()==cc.DataMgr:getActorID() then
    --local isEvenNumber= (#tempHandCards%2==0 and false)or true 
    local leftMovePos=nil
    --小左移动作
    for i=1,#tempHandCards do
      local skewingMoveItem=tempHandCards[i]:GetObj()
      if self.handCardIsLeftMove then
        leftMovePos=skewingMoveItem:getPositionX()-skewingMovePos
      else
        leftMovePos=skewingMoveItem:getPositionX()-self.cardInterVal*0.5

      end

      skewingMoveItem:runAction(cc.MoveTo:create(littleLeftMoveTime,cc.p(leftMovePos,self.listViewPos[index].y)))
    end
  --[[
    其他客户端玩家或AI抽牌
  ]]
  else
    local leftMovePos=nil
    local skewingAciton=nil
    for i=1,#tempHandCards do
      local skewingMoveItem=tempHandCards[i]:GetObj()
       
      if index==2 then
        leftMovePos=skewingMoveItem:getPositionY()+self.otherPlayerCardInterVal*0.5
        skewingAciton=cc.MoveTo:create(littleLeftMoveTime,cc.p(fixationPos.x,leftMovePos))
      elseif index==3 then
        leftMovePos=skewingMoveItem:getPositionX()+self.otherPlayerCardInterVal*0.5
        skewingAciton=cc.MoveTo:create(littleLeftMoveTime,cc.p(leftMovePos,fixationPos.y))
      elseif index==4 then
        leftMovePos=skewingMoveItem:getPositionY()-self.otherPlayerCardInterVal*0.5
        skewingAciton=cc.MoveTo:create(littleLeftMoveTime,cc.p(fixationPos.x,leftMovePos))
      end
      skewingMoveItem:runAction(skewingAciton)
    end

  end

  local playerCard=drawCardPlayer:GetHandCard()
  local len=#playerCard
  
  print('--------------抽牌玩家抽牌时的手牌长度 Len:',len)
  local posX=0
  local posY=0
  --被抽牌玩家的手牌
  local beDrawPlayerObj=self.playerObj[beDrawIndex]:GetHandCard()
  --local interVal=0
  if index==1 then
    if self.handCardIsLeftMove then 
      posX=tempEndCardOriPos.x-skewingMovePos+self.cardInterVal-self.cardShirinkValue
    else
      posX=tempEndCardOriPos.x+self.cardInterVal*0.5
    end
    posY=fixationPos.y
    --print('-------------PosX :',posX)
  elseif index==2 then
    posX=fixationPos.x
    posY=tempEndCardOriPos.y+self.otherPlayerCardInterVal*0.5-self.otherPlayerCardInterVal
    --print('-------tempCardOriPos.y+skewingMovePos :',tempCardOriPos.y+skewingMovePos..'  #tempHandCards*interVal :',#tempHandCards*interVal)
  elseif index==3 then
    posX=tempEndCardOriPos.x+self.otherPlayerCardInterVal*0.5-self.otherPlayerCardInterVal
    posY=fixationPos.y
   --print('-------tempCardOriPos.x+skewingMovePos :',tempCardOriPos.x+skewingMovePos..'  #tempHandCards*interVal :',#tempHandCards*interVal)
  else 
    posX=fixationPos.x
    posY=tempEndCardOriPos.y-self.otherPlayerCardInterVal*0.5+self.otherPlayerCardInterVal
  --print('-------tempCardOriPos.y+skewingMovePos :',tempCardOriPos.y+skewingMovePos..'  #tempHandCards*interVal :',#tempHandCards*interVal)
  end
  print('-------------PosX :',posX..'       -----------------posY :',posY)
  for i=1,#beDrawPlayerObj do
    beDrawPlayerObj[i]:SetDestination(posX,posY)
  end
end

--[[
 抽牌
 playerIndex --抽牌玩家位置索引
 otherIndex --被抽牌玩家位置索引
]]
function c:DrawACard(playerIndex,otherIndex)
  print("BeDrawIndex :",otherIndex)

  
  self.BeDrawIndex=otherIndex

  local otherPlayerCard=self.playerObj[otherIndex]:GetHandCard()
  local otherLen=#otherPlayerCard
  local medianIndex=math.ceil(otherLen*0.5)
  local duration=0.3
  local action =nil 
  print('--------otherPlayerCard Len :',otherLen..'-------------OtherPlayerHandCardLen :',#self.playerObj[otherIndex]:GetHandCard())
  local playerCard=self.playerObj[playerIndex]:GetHandCard()
  local movePos=nil
  if self.playerObj[playerIndex]:GetPlayerID()==cc.DataMgr:getActorID() then
    if self.actorDrawAction then
      self.curGameState= GAME_STATE.CHOOSE_CARD --选牌阶段
      if otherIndex==3 then
        for n=1,otherLen do
          local tempCardObj=otherPlayerCard[n]:GetObj()
          tempCardObj:setGlobalZOrder(20)
          local clickArea=self.playerObj[otherIndex]:GetClickArea()
          if clickArea~=nil then
            clickArea:setVisible(false)
          end
        end
      end
      self.playerObj[otherIndex]:ActiveHandCardTouch(true)
      return
    end
    self.actorDrawAction=true
    self.curGameState= GAME_STATE.CHOOSE_CARD --选牌阶段
    if otherIndex==3 then
      for n=1,otherLen do
        local tempCardObj=otherPlayerCard[n]:GetObj()
        tempCardObj:setGlobalZOrder(20)
        local clickArea=self.playerObj[otherIndex]:GetClickArea()
        if clickArea~=nil then
          clickArea:setVisible(false)
        end
      end
    end
    --被抽牌玩家手牌长度大于1
    if otherLen>1 then
      for i=1,otherLen do --手牌散开
        local cardObj=otherPlayerCard[i]:GetObj()
        local pos=nil
        if i~=medianIndex then
          if i<medianIndex then
            if otherIndex==2 then
              pos=cc.p(0,self.expandSize*(medianIndex-i))
            elseif otherIndex==3 then
              pos=cc.p(self.expandSize*(medianIndex-i),0)
            elseif otherIndex==4 then
              pos=cc.p(0,-self.expandSize*(medianIndex-i))
            end
          elseif i>medianIndex then
            if otherIndex==2 then
              pos=cc.p(0,-self.expandSize*(i-medianIndex))
            elseif otherIndex==3 then
              pos=cc.p(-self.expandSize*(i-medianIndex),0)
            elseif otherIndex==4 then
              pos=cc.p(0,self.expandSize*(i-medianIndex))
            end
          end
          --dump(pos,'------------pos :')
          local action =nil
          if i==otherLen then
            action =cc.Sequence:create(cc.MoveBy:create(0.4,pos),cc.CallFunc:create(function()
            local popupPos=nil
            local popupActionTime=0.26
            for j=1,otherLen do --手牌弹出
              local cardObj=otherPlayerCard[j]:GetObj()
              if otherIndex==2 then
                popupPos=cc.p(self.popupDis,0)
              elseif otherIndex==3 then
                popupPos=cc.p(0,-self.popupDis)
              elseif otherIndex==4 then
                popupPos=cc.p(-self.popupDis,0)
              end
              if j~=otherLen then
                cardObj:runAction(cc.MoveBy:create(popupActionTime,popupPos))
              else
                local moveByAction=cc.MoveBy:create(popupActionTime,popupPos)
                cardObj:runAction(cc.Sequence:create(moveByAction,cc.CallFunc:create(function() 
                  if otherIndex==4 then
                    --手牌下移
                    local moveDownPos=nil 
                    local index=otherLen
                    for k=1,otherLen do
                      local cardObj=otherPlayerCard[index]:GetObj()
                      moveDownPos=cc.p(cardObj:getPositionX(),self.moveDownPos-(k-1)*(self.expandSize+self.otherPlayerCardInterVal))
                      cardObj:runAction(cc.MoveTo:create(0.3,moveDownPos))
                      index=index-1
                    end
                  end
                  end)))
              end
            end
            end))
        else
          action =cc.MoveBy:create(0.4,pos)
        end
          
        cardObj:runAction(action)
      end
    end

    local sequen=cc.Sequence:create(cc.DelayTime:create(0.75),cc.CallFunc:create(function ()
      if not self.actorFirstControl then
        self.actorFirstControl=true
        self:ShowPlayerGuidePanel()
      end
      --大左移
      --如果抽牌玩家手牌大于等于6,被抽牌玩家手牌大于等于7
      if #playerCard>=6 and #self.playerObj[otherIndex]:GetHandCard()>=7 and otherIndex==4 then
        self.handCardIsLeftMove=true
        local leftMovePos=110+self.visibleOrigin.x
        local leftMoveTime=0.2
        for i=1,#playerCard do
          local item=playerCard[i]:GetObj()
          local value=leftMovePos+self.cardInterVal*(i-1)
          if i~=#playerCard then
            item:runAction(cc.MoveTo:create(leftMoveTime,cc.p(value,item:getPositionY())))
          else
            local shrinkSequen=cc.Sequence:create(cc.MoveTo:create(leftMoveTime,cc.p(value,item:getPositionY())),cc.CallFunc:create(function()
              local medianIndex=math.ceil(#playerCard*0.5)
              print('----medianIndex :',medianIndex..'  #playerCard :',#playerCard)
              local shirinkValue=self.cardShirinkValue
              local shirinkPos=nil
              local shirinkTime=0.25
              for i=1,#playerCard do
                local shirinkItem=playerCard[i]:GetObj()
                if i~=medianIndex then
                  local x=0
                  if i<medianIndex then
                    x=shirinkItem:getPositionX()+(medianIndex-i)*shirinkValue
                    shirinkPos=cc.p(x,shirinkItem:getPositionY())
                  elseif i>medianIndex then
                    x=shirinkItem:getPositionX()-(i-medianIndex)*shirinkValue
                    shirinkPos=cc.p(x,shirinkItem:getPositionY())
                  end
                  if i==#playerCard then
                    local shirinkEndSequen=cc.Sequence:create(cc.MoveTo:create(shirinkTime,shirinkPos),cc.CallFunc:create(function()
                      self.playerObj[otherIndex]:ActiveHandCardTouch(true)
                    end))
                    shirinkItem:runAction(shirinkEndSequen)
                  else
                    shirinkItem:runAction(cc.MoveTo:create(shirinkTime,shirinkPos))
                  end
                end
              end
            end))
            item:runAction(shrinkSequen)
          end
        end 
      else
        self.playerObj[otherIndex]:ActiveHandCardTouch(true)
      end
      end))
      self:runAction(sequen)
    else
      print('--------------------被抽牌玩家只剩下一张手牌---------------')
      local singleCardObj=otherPlayerCard[1]:GetObj()
      otherPlayerCard[1]:SetPosIndex(1)
      cc.ControlMgr:CardPopup(otherIndex,singleCardObj)
    end
  end

end

--[[
  同步抽牌动效
]]
function c:SyncDrawACard(cardIndex)
  local beDrawPlayer=self.playerObj[self.BeDrawIndex]
  local handCards=beDrawPlayer:GetHandCard()
  for i=1,#handCards do
    if handCards[i]:GetPosIndex()==cardIndex then
      _G.SelectionCard=handCards[i]
      print('----同步抽牌 被抽牌的牌索引 :',handCards[i]:GetPosIndex())
      handCards[i].clickCount=1
      handCards[i]:ClickEvent()
      return
    end
  end

end
--[[
  操作超时抽牌
]]
function c:OutTimeDrawCard(beDrawPlayerIndex)
  print('----------------self.curGameState :',self.curGameState)
  if self.curGameState==GAME_STATE.CHOOSE_CARD then
    --
    local drawPlayer=self.playerObj[self.PlayIndex]
    print('-------------抽牌玩家的手牌长度 :',#self.playerObj[self.PlayIndex]:GetHandCard())
    if self.PlayIndex==1 then
      local beDrawHandCards=self.playerObj[beDrawPlayerIndex]:GetHandCard()
      print('-------------被抽牌手牌的长度 :',#beDrawHandCards)
      self.autoDrawCard=true
      if _G.SelectionCard~=nil then
        _G.SelectionCard.clickCount=1
        _G.SelectionCard:ClickEvent()
        return
      end
      
      local beDrawCardLen=#beDrawHandCards  --被抽手牌的长度
      local randomIndex=math.random(1,beDrawCardLen)
      local beDrawCard=beDrawHandCards[randomIndex]
      if beDrawCard~=nil then
        beDrawCard.clickCount=1
        beDrawCard:ClickEvent()
        print('-------------------------被抽牌的牌索引 :',randomIndex)
      else
        self:OutTimeDrawCard(beDrawPlayerIndex)
      end
    end
  end
end

function c:PlayerOpenCard(CardNum)
  if self.PlayIndex~=1 then
    return
  end
    self:runAction(cc.Sequence:create(cc.CallFunc:create(function() 
      local chooseCard=cc.DataMgr:getActorChooseCard()
      print('--------------CardNum :',CardNum)
      cc.DataMgr:setActorChooseCardNum(CardNum)
      --chooseCard:SetValue(CardNum)
      chooseCard:OpenCard(false)
      end),cc.DelayTime:create(0.32),cc.CallFunc:create(function()
        local hands=self.playerObj[self.BeDrawIndex]:GetHandCard()
        cc.ControlMgr:BeDrawHandsRecoverAction(self.BeDrawIndex,hands)
        self:ActorDrawCardRecover()
    end)))
    cc.DataMgr:setDrawCardMsg(nil)
    
    --local time=os.time()
    --local date=os.date("%Y-%m-%d %H:%M:%S",time)
    --print('-------------------DrawCard Data :',date)
end
--[[
 抽牌完成
 playerIndex --抽牌玩家
 otherIndex --被抽牌玩家
 
 drawCard --被抽的牌对象(Card)
]]
function c:DrawCardCompleted(playerIndex,otherIndex,drawPos,drawCard)
  --print(' DrawCardCompleted   playerIndex:',playerIndex..'  otherIndex:',otherIndex)
  cc.DataMgr:setHaveDrawCard(false)
  --cc.DataMgr:setIsChooseCard(false)

  _G.SelectionCard=nil
  if playerIndex == 1 then 
    cc.DataMgr:setIsAIPlayCard(false)
    self.actorDrawAction=false
    if otherIndex==3 then
      local clickArea=self.playerObj[otherIndex]:GetClickArea()
      if clickArea~=nil then
        clickArea:setVisible(true)
      end
      drawCard.item:setGlobalZOrder(0)
    end


  end
  
  cc.DataMgr:setIsSyncTween(false) 
  local cardObj=drawCard
  local removeIndex=cardObj:GetPosIndex()
  local posX=drawPos.x
  local posY=drawPos.y
  local otherPlayerWinState=0

  print('---------被抽的牌所在牌组的索引位置 :',removeIndex..'  --------------------被抽的牌的牌值 :',cardObj:GetValue())
  local playerHandCards_Draw=self.playerObj[playerIndex]:GetHandCard()
  local playerHandCards_BeDraw=self.playerObj[otherIndex]:GetHandCard()
  local insertIndex=#playerHandCards_Draw+1
  cardObj:SetSeatIndex(playerIndex)
  cardObj:SetPosIndex(insertIndex)
  --更新玩家手牌
  table.insert(playerHandCards_Draw,insertIndex,cardObj)
  table.remove(playerHandCards_BeDraw,removeIndex)

  local otherEndIndex=#playerHandCards_BeDraw
 
  self.playerObj[playerIndex].drawCard=cardObj --记录抽到的牌
  --更新玩家手牌
  self.playerObj[playerIndex]:SetHandCard(playerHandCards_Draw)
  self.playerObj[otherIndex]:SetHandCard(playerHandCards_BeDraw)
  print('---------------抽牌玩家抽完牌后的手牌长度 :',#self.playerObj[playerIndex]:GetHandCard())
  print('---------------被抽牌玩家抽完牌后的手牌长度 :',#self.playerObj[otherIndex]:GetHandCard())
  --dump(self.playerObj[playerIndex]:GetHandCardValueList(),'  ---------------抽牌玩家抽完牌后的手牌 :')
  --dump(self.playerObj[otherIndex]:GetHandCardValueList(),'  ---------------被抽牌玩家的手牌 :')
  
  cc.DataMgr:setNormalPlayCardState(true)
  if #self.playerObj[otherIndex]:GetHandCard()==0 then
    print('-------------------被抽牌玩家获得胜利--------- :',otherIndex)
    --被抽牌玩家胜利状态
    otherPlayerWinState=self.playerObj[otherIndex]:PlayerTriumph()
  end
  
  local other=self.playerObj[otherIndex]:GetHandCard()
  --print('After Play Len :',#self.playerCardObjs[playerIndex].."  After Other Len :",#self.playerCardObjs[otherIndex])
  --抽牌玩家是否是自身客户端
  if self.playerObj[playerIndex]:GetPlayerID()==cc.DataMgr:getActorID() then
    local playerHandCards=self.playerObj[playerIndex]:GetHandCard()

    if otherPlayerWinState==0 then
      local oriPosX=other[1]:GetObj():getPositionX()
      local oriPosY=other[1]:GetObj():getPositionY()
      local intervalNum=(self.otherPlayerCardInterVal+self.expandSize)
      --被抽玩家的手牌动效
      for i=1,#other do
        local item=other[i]:GetObj()
        local movePosX=0
        local movePosY=0
        if otherIndex==2 then
          movePosX=oriPosX
          if i<removeIndex then
            movePosY=item:getPositionY()-intervalNum*0.5
          elseif i>=removeIndex then
            movePosY=item:getPositionY()+intervalNum*0.5
          end
        elseif otherIndex==3 then
          if i<removeIndex then
            movePosX=item:getPositionX()-intervalNum*0.5
          elseif i>=removeIndex then
            movePosX=item:getPositionX()+intervalNum*0.5
          end
          movePosY=oriPosY
        elseif otherIndex==4 then
          movePosX=oriPosX
          --print(' removeIndex : ',removeIndex..'-------------Item PosY :',item:getPositionY())
          if i<removeIndex then
              movePosY=item:getPositionY()+intervalNum*0.5
          elseif i>=removeIndex then
              movePosY=item:getPositionY()-intervalNum*0.5
          end
        end
        local movePos=cc.p(movePosX,movePosY)
        item:runAction(cc.MoveTo:create(self.cardTogetherTime,movePos))
      end
    end
    local cardNumIndex=removeIndex-1
    print('-----------cardNumIndex :',cardNumIndex)
    if not cc.DataMgr:getActorTrustState() then

    --客户端不是托管状态就发送抽牌协议
      cc.NetMgr:sendMsg(CLIENT_2_SERVER.GAME_CHOOSE_POKER,"pbghost.ChooseInfo",{PlayerId=self.playerObj[otherIndex]:GetPlayerID(),Index=cardNumIndex})
    else
      local trustCardNum=cc.DataMgr:getTrustCardNum()
      print('-------------------托管抽牌的牌值',trustCardNum)
      self:PlayerOpenCard(trustCardNum)
      local playCardMsg1=cc.DataMgr:getPlayCardMsg()
      if playCardMsg1~=nil then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.35),cc.CallFunc:create(function() 
          local playCardMsg2=cc.DataMgr:getPlayCardMsg()
          self.playerObj[self.PlayIndex]:PlayCard(playCardMsg2)
        end)))
      end
    end
    
  --抽牌玩家是AI或者其他客户端玩家
  elseif self.playerObj[playerIndex]:GetPlayerID()~=cc.DataMgr:getActorID()  then
    if otherPlayerWinState==0 then
      self:HandCardGathering(otherIndex)
    end

    local playCardMsg1=cc.DataMgr:getPlayCardMsg()
    if playCardMsg1~=nil then
      self:runAction(cc.Sequence:create(cc.DelayTime:create(0.35),cc.CallFunc:create(function() 
        local playCardMsg2=cc.DataMgr:getPlayCardMsg()
        self.playerObj[self.PlayIndex]:PlayCard(playCardMsg2)
      end)))
    end
  end

end

function c:ActorDrawCardRecover()
  local player=self.playerObj[self.PlayIndex]:GetHandCard()
  local playerCardMedian=math.ceil(#player*0.5)
  local playerMovePosX=0
  local playerMovePosY=player[1]:GetObj():getPositionY()
  local tempSpacing=player[2]:GetObj():getPositionX()-player[1]:GetObj():getPositionX()
  local lenType=#player%2==0  --手牌是单数还是双数
    --不是大左移情况
  if not self.handCardIsLeftMove then
      --print('-----------------自身客户端大左移操作-----------------')
    local centerSequence=cc.Sequence:create(cc.DelayTime:create(0.4),cc.CallFunc:create(function() 
      self:HandCardGathering(1)
      end))
    self:runAction(centerSequence)
  else
     --大左移
    self.handCardIsLeftMove=false
      for i=1,#player do
        local playerItem=player[i]:GetObj()
        if lenType then
          if i<playerCardMedian then
            playerMovePosX=self.centralPoint_X-(playerCardMedian-i)*tempSpacing
          elseif i==playerCardMedian then
            playerMovePosX=self.centralPoint_X-tempSpacing*0.5
          elseif i==(playerCardMedian+1) then
            playerMovePosX=self.centralPoint_X+tempSpacing*0.5
          else
            playerMovePosX=self.centralPoint_X+(i-(playerCardMedian+1))*tempSpacing
          end
        else
          if i<playerCardMedian then
            playerMovePosX=self.centralPoint_X-(playerCardMedian-i)*tempSpacing
          elseif i==playerCardMedian then
            playerMovePosX=self.centralPoint_X
          else
            playerMovePosX=self.centralPoint_X+(i-playerCardMedian)*tempSpacing
          end
        end
        local action =cc.Sequence:create(cc.DelayTime:create(0.4),cc.MoveTo:create(0.2,cc.p(playerMovePosX,playerMovePosY)))
        if i==#player then
          local function playerCardsDisperse()
            --手牌居中修正
            self:HandCardGathering(1)
          end
          action=cc.Sequence:create(cc.DelayTime:create(0.4),cc.MoveTo:create(0.2,cc.p(playerMovePosX,playerMovePosY)),cc.DelayTime:create(0.1),
            cc.CallFunc:create(playerCardsDisperse))
        end
        playerItem:runAction(action)
      end
  end
end

--[[
  AI抽牌操作
]]
function c:AIStartDrawACard(msg)
    local playPlayerID=msg.PlayerId
    cardIndex=msg.Index
    print('--------------被抽牌AI玩家ID :',playPlayerID..' -----被抽牌的牌索引 :',(cardIndex+1))
    print('--------------抽牌玩家位置索引 :',self.PlayIndex..'    抽牌玩家ID :',self.playerObj[self.PlayIndex]:GetPlayerID())
    local beDrawPlayer=nil
    for i=1,#self.playerObj do
       if self.playerObj[i]:GetPlayerID()==playPlayerID then
        beDrawPlayer=self.playerObj[i]
        local handCards=beDrawPlayer:GetHandCard()
        if self.PlayIndex==1 then
          beDrawPlayer:ActiveHandCardTouch(false)
          if _G.SelectionCard~=nil then
            _G.SelectionCard:IsChoose(false)
          end
          self.autoDrawCard=true 
          cc.DataMgr:setActorTrustState(self.autoDrawCard)
          cc.DataMgr:setTrustCardNum(msg.CardNum)
          --cc.DataMgr:setNormalPlayCardState(false)
          local drawCardMsg=cc.DataMgr:getDrawCardMsg()
          if drawCardMsg~=nil then
            dump(drawCardMsg,'-------------drawCardMsg :')
            local spriteName='Pit_'..msg.CardNum..'.png'
            drawCardMsg.item:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
            return
          end
        end
        --dump(handCards,'-----------抽牌前,被抽玩家的手牌 :')
        print('-----------抽牌前,被抽玩家的手牌长度 :',#handCards)
        for j=1,#handCards do
            if handCards[j]:GetPosIndex()==(cardIndex+1) then 
             
              _G.SelectionCard=handCards[j]
              print('----------------被抽牌的索引 :',j)
              handCards[j].clickCount=1
              handCards[j]:ClickEvent()
              for i=1,#handCards do
                handCards[i]:IsChoose(false)
              end
              --self:runAction(cc.Sequence:create(cc.DelayTime:create(0.13),cc.CallFunc:create(function() handCards[j]:ClickEvent() end)))
              return
            end
        end
        --dump(handCards,' --------------------被抽玩家的手牌信息 :')
        break
       end
    end
end

--[[
  手牌居中修正
  cardIndex  --需要手牌修正的玩家位置索引
]]
function c:HandCardGathering(cardIndex,callBack)
    print('-----------------手牌居中修正------------------')
    local tempCards=self.playerObj[cardIndex]:GetHandCard()
    if #tempCards==0 and callBack~=nil then
      callBack()
      return
    end
    cc.ControlMgr:HandCardGathering(cardIndex,tempCards,callback) 
    
end
--[[
  玩家新的回合开始
  lastPlayerRound  ---上一个回合的玩家位置索引
  
]]
function c:NewGameRound(lastPlayerRound)
  print(' ------------New Game Round ---------- lastPlayerRound :',lastPlayerRound)
  --只剩一个玩家,游戏结束
  if self.playerCount_OnGame==1 then
    return false,0
  end
  local newPlayerRound=(lastPlayerRound+1==5 and 1)or lastPlayerRound+1
  local beDrawPlayer=0
  --local beDrawPlayerHandCards=self.playerObj[lastPlayerRound]:GetHandCard()
  --先确定被抽牌玩家
  --获取被抽牌玩家的状态(是否已经胜利)
  local beDrawPlayerWinState=self.playerObj[lastPlayerRound]:GetPlayerWinState()
  if not beDrawPlayerWinState then
    beDrawPlayer=lastPlayerRound
  else
    local startIndex=0 --开始检查的索引
    if lastPlayerRound-1==0 then 
      startIndex=4
    else
      startIndex=lastPlayerRound-1
    end
    --print(' ----------------startIndex :',startIndex)
    local count =startIndex+2
    for i=startIndex,count do
      local tempCards=self.playerObj[startIndex]:GetHandCard() --获取被抽牌玩家的手牌
      if #tempCards>0 then
        beDrawPlayer=startIndex
        print('------------beDrawPlayer :',beDrawPlayer)
        break
      end
      startIndex=(startIndex-1==0 and 4) or startIndex-1 --被抽牌玩家手牌为空时,重新计算新的被抽牌玩家索引
    end

  end
  --local handCards=self.playerObj[newPlayerRound]:GetHandCard()
  --确定抽牌玩家 
  --获取下一个玩家的状态(是否已经胜利)
  local nextPlayerWinState=self.playerObj[newPlayerRound]:GetPlayerWinState()
  print(" newPlayerRound :",newPlayerRound..'  beDrawPlayer :',beDrawPlayer)
  --local shuffleIndex=0
  if not nextPlayerWinState then
    self.PlayIndex=newPlayerRound
    self.BeDrawIndex=beDrawPlayer
    print('------------------dealIndex :',self.PlayIndex)
    return true,self.BeDrawIndex
  else
    for i=1,2 do
      newPlayerRound=(newPlayerRound+1==5 and 1)or newPlayerRound+1
      local handCards=self.playerObj[newPlayerRound]:GetHandCard() 
      if #handCards>0 then
        self.PlayIndex=newPlayerRound
        self.BeDrawIndex=beDrawPlayer
        print('------------------dealIndex :',self.PlayIndex..'----------self.BeDrawIndex :',self.BeDrawIndex)
        return true,self.BeDrawIndex
      end
    end
  end

  print('---------------游戏结束')
  return false,0

end
--[[
  显示玩家出的牌
]]
function c:ShowPlayCard(destinationPos,cardNum)
  local card=nil
  --[[
  if self.tableCard==nil then
    self.tableCard=ccui.Button:create()
    card=self.tableCard
  else
    card=self.tableCard:clone()
  end
  ]]
  card=ccui.Button:create()
  print('-------------------ShowPlayCard--------------------')
  
  --poker:setRotation(0)
  card:setPosition(destinationPos.x,destinationPos.y)
  card:setAnchorPoint(cc.p(0.5,0.5))
  self.playerPanelNode:addChild(card,10)

  local spriteName='Pit_'..tostring(cardNum)..'.png'
  card:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
  card:setTouchEnabled(false)
  card:setVisible(true)
  --card:setGlobalZOrder(100)

end
--[[
  抽到丧尸牌的效果
]]
function c:BecomeAZombie(index)
  self.playerObj[index]:SetZombieState(true)
  self.hideZombieSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self,self.HideZombieLogo), 4, false)

  local duration=0.6
  self.moon:runAction(cc.FadeTo:create(duration,0))
  self.tombstone:runAction(cc.FadeTo:create(duration,255))
  local upPosX_Left=self.zombieHand_Left:getPositionX()
  local upPosY_Left=200+self.visibleOrigin.y
  local elasticAciton_Left= cc.Sequence:create(cc.DelayTime:create(duration),cc.EaseElasticOut:create(cc.MoveTo:create(duration*2,cc.p(upPosX_Left,upPosY_Left)),0.8))
  self.zombieHand_Left:runAction(elasticAciton_Left)
  local upPosX_Right=self.zombieHand_Right:getPositionX()
  local upPosY_Right=240+self.visibleOrigin.y
  local elasticAciton_Right=cc.Sequence:create(cc.DelayTime:create(duration),cc.EaseElasticOut:create(cc.MoveTo:create(duration*2,cc.p(upPosX_Right,upPosY_Right)),0.8))
  self.zombieHand_Right:runAction(elasticAciton_Right)
  self.zombieLogo:setOpacity(255)
  self.zombieLogo:runAction(cc.Sequence:create(cc.DelayTime:create(duration),cc.ScaleTo:create(duration*0.5,1)))
  --self:PlayerControllerMsg({},4)
  AudioEngine.playEffect("gameMusic/Zombie.mp3") --zombie音效
  cc.DataMgr:setZombieAnimation(true)
end

--[[
  丧尸牌被抽走了
]]
function c:BecomeAMan()
  local duration=0.5
  self.moon:runAction(cc.Sequence:create(cc.DelayTime:create(duration*1.2),cc.FadeTo:create(duration,255)))
  self.tombstone:runAction(cc.Sequence:create(cc.DelayTime:create(duration*1.2),cc.FadeTo:create(duration,0)))
  local upPosX_Left=self.zombieHand_Left:getPositionX()
  local upPosY_Left=-207
  local elasticAciton_Left= cc.EaseElasticIn:create(cc.MoveTo:create(duration*1.7,cc.p(upPosX_Left,upPosY_Left)),0.8)
  self.zombieHand_Left:runAction(elasticAciton_Left)
  local upPosX_Right=self.zombieHand_Right:getPositionX()
  local upPosY_Right=-240
  local elasticAciton_Right=cc.EaseElasticIn:create(cc.MoveTo:create(duration*1.7,cc.p(upPosX_Right,upPosY_Right)),0.8)
  self.zombieHand_Right:runAction(elasticAciton_Right)
  cc.DataMgr:setZombieAnimation(false)

end


function c:HideZombieLogo()
  --if self.playerObj[self.PlayIndex]:GertZombieState() then
    local hideTimes=4
    local duration=0.4
    local spawnAction=cc.Spawn:create(cc.ScaleTo:create(duration,0),cc.FadeTo:create(duration-0.1,0))
    self.zombieLogo:runAction(spawnAction)
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.hideZombieSchedule)
  --end
end
--[[
  游戏结束检测
  true ---游戏结束
]]
function c:GameOverDetection()
  local gamePlayerCount=self.playerCount
  local losePlayerIndex=0
  for i=1,self.playerCount do
    if self.playerObj[i]:GetPlayerWinState() then
      gamePlayerCount=gamePlayerCount-1
    else
      losePlayerIndex=i
    end
  end
  self.playerCount_OnGame=gamePlayerCount
  if self.playerCount_OnGame==1 then
    local losePlayerHandCards=self.playerObj[losePlayerIndex]:GetHandCard()

    --游戏结束
    return #losePlayerHandCards==1 
  end
    return false

end

function c:PlayerVitory(msg)
  print('--------------收到玩家胜利协议  胜利玩家ID :',msg.PlayerId)
  local winIndex=cc.DataMgr:getPlayerIndexByID(msg.PlayerId)
  CCSPlayAction(self.playerMesUI[winIndex].no,msg.Num.."ST_s",0,true)
  self.noEffectArray[winIndex]=true
  self.playerObj[winIndex]:PlayerTriumph()
end

--[[
  记录结束状态
]]
function c:RecordGameOverMsg(msg)
  --dump(msg,'---------------GameOver :')
  print('------------记录游戏结果信息----------')
  cc.DataMgr:setGameOver(true)
  if cc.DataMgr:getExitState() then --玩家已经点击主动退出按钮
    if self.exitScheduler~=nil then
      cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.exitScheduler) --关闭计时器
      self.exitScheduler=nil
    end
    self:GameQuit(msg)
    return
  end
  cc.DataMgr:setGameOverMsg(msg)
  

end

function c:GameError()
  local overMsg=cc.DataMgr:getGameOverMsg()
  self:GameOver(overMsg)
end
--[[
  游戏结束
]]
function c:GameOver(msg)
  print('--------------------------------调用GameOver函数---------------------')
  local dur=0.3
  --dump(self.playerObj,'---------------游戏结束时的玩家状态:')
  local failPlayerPosIndex=0
  for i=1,self.playerCount do
    local handCards=self.playerObj[i]:GetHandCard()
    if not self.playerObj[i]:GetPlayerWinState() then
      if self.playerObj[i]:GetPlayerID()==cc.DataMgr:getActorID() then --失败的是自身客户端
        cc.DataMgr:setGameOver(false)
        local overCard=handCards[1]
        if overCard~=nil then
          handCards[1]:GetObj():setGlobalZOrder(0)
          handCards[1]:GetObj():setLocalZOrder(0)
          handCards[1]:GetObj():setColor({r=255,g=255,b=255,a=255})
        end
        CCSPlayAction(self.playerMesUI[1].no,"4ST_s",0,true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function() 
          self:ShowGameOverPanel(msg,1) 
        end)))
        return
      end
        for j=1,#handCards do
          handCards[j]:SetPosIndex(1)
        end
        local finalCard=handCards[1]
        cc.DataMgr:setLastCard(finalCard)
        if finalCard==nil then
          self:runAction(cc.Sequence:create(cc.DelayTime:create(dur+0.6),cc.CallFunc:create(function()
          self:ShowGameOverPanel(msg,i)
          end)))
          return
        end
        finalCard:GetObj():setGlobalZOrder(50)
        local seatIndex=finalCard:GetSeatIndex()
        local popupPos=nil
        if seatIndex==2 then
          popupPos=cc.p(100,0)
          
        elseif seatIndex==3 then
          popupPos=cc.p(0,-100)
        else
          popupPos=cc.p(-100,0)
        end
        local gameOverAction=nil
        gameOverAction=cc.Sequence:create(cc.MoveBy:create(dur,popupPos),cc.CallFunc:create(function()  
          handCards[1]:OpenCard(true)
          CCSPlayAction(self.playerMesUI[seatIndex].no,"4ST_s",0,true)
          for k=1,self.playerCount do
            self:HideTimer(k)
          end
        end))
        finalCard:GetObj():runAction(gameOverAction)
        failPlayerPosIndex=i
        break
    end
  end
  cc.DataMgr:setGameOver(false)
  self:runAction(cc.Sequence:create(cc.DelayTime:create(dur+0.6),cc.CallFunc:create(function()
    --dump(msg,'--------------------GameInfo :')
    self:ShowGameOverPanel(msg,failPlayerPosIndex)
  end)))

end


--[[
  显示游戏结束界面
]]
function c:ShowGameOverPanel(infoList,failPlayerPosIndex)
  print("------------------------显示游戏结束界面-----------------------------------")
  dump(infoList,'---------------------InfoList :')
  self.GameOverShade:setVisible(true)
 
  --self.GameOverPanel:setVisible(true)
  local gameOverSequen=cc.Sequence:create(cc.ScaleTo:create(0.3,1),cc.DelayTime:create(3),cc.CallFunc:create(function() 
      self:ShowPlayerRankList(infoList)
      local function Quit()
      self:GameQuit(infoList)
      cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.gameOverSchedule)
    end
    self.gameOverSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(Quit, 10, false)
  end))
  self.GameOverPanel:runAction(gameOverSequen)
  if self.playerObj[failPlayerPosIndex]:GetPlayerID()==cc.DataMgr:getActorID() then
    print('---------自身客户端是Zombie')
    self:PlayerControllerMsg({},4)
  else
    self:PlayerControllerMsg({self.playerObj[failPlayerPosIndex]:GetPlayerName()},5)
  end
  AudioEngine.playEffect("gameMusic/Zombie.mp3") --zombie音效
  
  local localPath=self.playerObj[failPlayerPosIndex]:GetHeadPortraitUrl()
  local headView = self:createClipView("img_back.png",localPath)
  local sz = self.failPlayerHead:getContentSize()
  --self.failPlayerHead:setGlobalZOrder(60)
  if headView ~= nil then
    self.failPlayerHead:addChild(headView,50)
    headView:align(display.CENTER,sz.width * 0.5,sz.height * 0.5)
    headView:setPositionX(headView:getPositionX()+7)
    headView:setPositionY(headView:getPositionY())
  end
end

function c:ShowPlayerRankList(infoList)
  local urlPath="StaticImage/"
  local playerRank=0
  local playerRankList={}
  --self.RankPanelShade:setVisible(true)
  --dump(infoList,"-----------------------InfoList :")

  local lastCard=cc.DataMgr:getLastCard()
  if lastCard~=nil then
    if lastCard:GetSeatIndex()~=3 then
      lastCard:GetObj():setGlobalZOrder(0)
    end
    lastCard:GetObj():setColor({r=127,g=127,b=127,a=255})
  end
  self:DisableScene()

 -- CCSTime(tmpNode,1,function()
      --tmpNode:removeSelf()
  --end)
  for i=1,#infoList do
    local winPlayerList=infoList[i].winnerList
    local playerScoreList=infoList[i].ScoreList
    playerRankList[i]={}
    if winPlayerList[i]==cc.DataMgr:getActorID() then
      playerRank=i
      --local tmpNode = display.newSprite("#sprite")
      --tmpNode:align(display.CENTER,x,y):addTo(self.Title,10)
      
      self.playerInfoArr[i].bg:loadTexture(urlPath.."Actor.png")
      self.playerInfoArr[i].bg:setOpacity(255)
      
    end
    local playerIndex=cc.DataMgr:getPlayerIndexByID(winPlayerList[i])
    playerRankList[i].name=self.playerObj[playerIndex]:GetPlayerName()
    playerRankList[i].avatarUrl=self.playerObj[playerIndex]:GetHeadPortraitUrl()
    playerRankList[i].score=playerScoreList[i]
  end
  --dump(playerRankList,'--------------playerRankList :')
  print('------------playerRank :',playerRank)
  if playerRank~=4 then
    --[[
    local effect=cc.Sprite:create("StaticImage/HelpPanel_Close.png")
    effect:setOpacity(255)

    self.Banner:addChild(effect,20)
    effect:setAnchorPoint(cc.p(0.5,0.5))
    effect:setPosition(193,175)
    ]]
    CCSPlayAction(self,playerRank.."ST",0,true)
    self.Title:setVisible(false)
    self.Banner:setVisible(false)
  else
    self.Banner:setVisible(false)
    self.Title:loadTexture(urlPath.."Big_"..playerRank..'.png',0)
  end
  
  for j=1,#self.playerInfoArr do
    --self.playerInfoArr[j].name:setString(playerRankList[j].name)
    StringUtils.cutStringForVisibleWidth(self.playerInfoArr[j].name,playerRankList[j].name,130)
    print('---------------playerRankList[j].avatarUrl :',playerRankList[j].avatarUrl)
    local sz = self.playerInfoArr[j].head:getContentSize()

    local headFrame= self:createClipView("img_back.png",playerRankList[j].avatarUrl)  
    if headFrame ~= nil then
      self.playerInfoArr[j].head:addChild(headFrame,60)
      headFrame:align(display.CENTER,sz.width * 0.5,sz.height * 0.5)
      headFrame:setPositionX(headFrame:getPositionX()+7)
      headFrame:setPositionY(headFrame:getPositionY())
      --headFrame:setGlobalZOrder(98)
      --if headView~=nil then
        --headFrame:addChild(headView)
      --end
    end
    local scoreStr=tostring(playerRankList[j].score)
    for k=1,string.len(scoreStr) do
      local numStr=string.sub(scoreStr,k,k)
      local scoreSprite=cc.Sprite:create(urlPath.."Image_"..numStr..'.png')
      scoreSprite:setAnchorPoint(0.5,0.5)
      scoreSprite:addTo(self.playerInfoArr[j].image_Add,10)
      scoreSprite:setPosition(cc.p(40+(k-1)*36,12.5))
      scoreSprite:setGlobalZOrder(96)
    end
    
  end
  self.btnContinue:addClickEventListener(function() 
    self:GameQuit(infoList)
    if self.gameOverSchedule~=nil then
      cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.gameOverSchedule)
    end
  end)
   self.rankListPanel:setVisible(true)
  self.rankListPanel:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,255),cc.CallFunc:create(function() 
      for i=1,self.playerCount do
        self.playerMesUI[i].headPanel:setVisible(false)
      end
    end)))

end
--[[
  把场景的所有按钮关闭
]]
function c:DisableScene()
  self.btn_Ruturn:setColor({r=77,g=77,b=77,a=255})
  self.btn_Ruturn:setTouchEnabled(false)
  self.btn_Help:setColor({r=77,g=77,b=77,a=255})
  self.btn_Help:setTouchEnabled(false)
  self.btn_Voice:setColor({r=77,g=77,b=77,a=255})
  self.btn_Voice:setTouchEnabled(false)

end

function c:GameQuit(infoList)
    if infoList~=nil then
      for i=1,#infoList do
        local gameInfo=infoList[i]
        if gameInfo.PlayerId==cc.DataMgr:getActorID() then
          self.gameResult={}
          self.gameResult.state=gameInfo.State
          self.gameResult.winnerList=gameInfo.winnerList
          --self.gameResult.no=gameInfo.No
        --向平台发送游戏结束信息
          HYGameBridge:getInstance():setGameResultData(self.gameResult)
          HYGameBridge:getInstance():gameFinish(0, self.gameResult)
        --发送退出协议
          --cc.NetMgr:sendMsg(CLIENT_2_SERVER.QUIT,"pbghost.Empty",{})
          return
        end
      end 
    end
end
--[[
  心跳包事件
]]
function c:listenHeartbeatEvent()
  
  local function callback()
    --print('-----------心跳包事件----------')
    if self.gameHeartbeatTime>= 0 then
      self.gameHeartbeatTime = self.gameHeartbeatTime + 1
        if self.gameHeartbeatTime >= 5 then
         cc.DataMgr:setNoNetTag(true)
        end
        --print('------------------心跳超时')
        if self.gameHeartbeatTime >= 10 then
          print('------------把玩家踢出游戏')
          self.gameResult={}
          self.gameResult.state="UserJoinTimeout"
          self.gameResult.winnerList={}
        --向平台发送游戏结束信息
          HYGameBridge:getInstance():setGameResultData(self.gameResult)
          HYGameBridge:getInstance():gameFinish(0,self.gameResult)

          if self.gameHeartbeatTimerSchedule then 
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.gameHeartbeatTimerSchedule)
          end
          return
        end

      end
  end
  self.gameHeartbeatTimerSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(callback, 1, false)

end

--[[
  游戏断线重连
]]
function c:GameRelogin(msg)
  --dump(msg,'-----------------------断线重连信息 :')
  for i=1,self.playerCount do
    --隐藏计时器
    self:PlayerRoundEnd(i,false)
  end
  self.breakLineState=true
  print('---------------------self.breakLineState :',self.breakLineState)
  self.curGameState=GAME_STATE.RELOGIN
  
  cc.DataMgr:setConnectSuccess(true)
  print('-------当前游戏状态 :', self.curGameState)
  --cc.DataMgr:setIsAIPlayCard(false)
  cc.DataMgr:setIsSyncTween(false)
  --cc.DataMgr:setIsChooseCard(false)
  cc.DataMgr:setHaveDrawCard(false)
  self.onDeal=false
  if self.DealList~=nil then
    for i=1,#self.DealList do
      self.DealList[i]:setVisible(false)
    end
    self.DealList={}
  end

  --重新设置玩家信息
  self:ResetGamePlayerInfo(msg.ReLoginPlayerList)
  local allPlayerInfo=cc.DataMgr:getAllPlayerInfo()
  --self:RecycleAllPlayerHandCard()
  _G.SelectionCard=nil
  for n=1,#self.cardPile do
    self.cardPile[n]:setVisible(false)
  end
  self.gameHeartbeatTime=0
  if msg.IsOver then
    print('-----------------游戏已经结束------------------')
    self:ShowPlayerRankList(msg.WinInfo.Game)
    return
  end 
   --记录当前的抽牌玩家与被抽牌玩家
  for i=1,self.playerCount do
    if self.playerObj[i]:GetPlayerID()==msg.DrawCardPlayerId then
      self.PlayIndex=i
    elseif self.playerObj[i]:GetPlayerID()==msg.BeDrawCardPlayerId then
      self.BeDrawIndex=i
    end
  end
  print('--------------重连时的抽牌玩家的位置索引 :',self.PlayIndex..'  与被抽牌玩家的位置索引 :',self.BeDrawIndex)
  self.actorFirstControl=true
  --重新刷新场景的手牌
  self:RefreshAllPlayerHandCard(allPlayerInfo,msg.ReLoginStatue)

  if msg.ScoreInfo~=nil then
    local scoreInfo=msg.ScoreInfo
    for i=1,#scoreInfo do
      local playerIndex=cc.DataMgr:getPlayerIndexByID(scoreInfo[i].PlayerId)
      if not self.noEffectArray[i] then
        CCSPlayAction(self.playerMesUI[playerIndex].no,scoreInfo[i].Num.."ST_s",0,true)
        self.noEffectArray[i]=true
      end
    end
  end
  if msg.ReLoginStatue=="IN_CARD" then
    print('------------玩家抽牌回合------------')
    --玩家出牌
   
    --玩家回合开始
    cc.DataMgr:setNormalPlayCardState(false)
    local reloginMsg={PlayerId=msg.DrawCardPlayerId,OtherId=msg.BeDrawCardPlayerId}
    self:PlayerRoundStart(reloginMsg,true)
    self:ShowRoundTimer(self.PlayIndex)
  elseif msg.ReLoginStatue=="OUT_CARD" then

  elseif msg.ReLoginStatue=="WASH_CARD" then

  elseif msg.ReLoginStatue=="WAIT" then
    
    if self.BeDrawIndex==1 then
      self.autoDrawCard=true
    end
    --玩家等待
    --所有玩家显示遮罩
    self:ShowHandCardShade(self.PlayIndex)
   
    --隐藏zombieLogo
    self.zombieLogo:setScale(0)
    print('------------玩家等待------------')
  else
    print('-------------玩家胜利-----')
  end
  cc.DataMgr:setIsReloginGame(false)
  cc.DataMgr:setNoNetTag(false)
end
--[[
  重置游戏玩家信息
]]
function c:ResetGamePlayerInfo(playerList)
  local allPlayerIDList={} --所有玩家的ID
  local clientPlayerIDList={}
  local AIIDList={}
  local playerInfoList={}
  local AIAutoEmoji=false
  --自身客户端在数组首位
  for i=1,self.playerCount do
    playerInfoList[i]=playerList[i]
    playerInfoList[i].Seat=i
    if playerInfoList[i].PlayerId==cc.DataMgr:getActorID() then
      local temp=playerInfoList[i]
      playerInfoList[i]=playerInfoList[1]
      playerInfoList[1]=temp
    end
  end

  local playerSeat=playerInfoList[1].Seat
  local nextSeat=(playerSeat+1==5 and 1)or playerSeat+1
  self:PlayerSeatSort(playerInfoList,2,nextSeat)
  --dump(playerInfoList,'---------------------playerInfoList :')
  for n=1,#playerInfoList do
    cc.DataMgr:setPlayerInfo(n,playerInfoList[n])
    self.playerObj[n]:SetPlayerID(tonumber(playerInfoList[n].PlayerId))
    table.insert(allPlayerIDList,#allPlayerIDList+1,playerInfoList[n].PlayerId)
    --print('--------self.playerObj ID :',self.playerObj[n]:GetPlayerID())
    if not self.alreadyLoadPlayerInfo then
      print('--------------self.alreadyLoadPlayerInfo :',self.alreadyLoadPlayerInfo)
      HYGameBridge:getUserAvatar(tonumber(playerInfoList[n].PlayerId)) --从平台下载玩家头像
      HYGameBridge:getInstance():getUserInfo(tonumber(playerInfoList[n].PlayerId)) --从平台下载玩家信息
    end
    if playerInfoList[n].AI then
      table.insert(AIIDList,#AIIDList+1,tonumber(playerInfoList[n].PlayerId))
      AIAutoEmoji=true
    else
      table.insert(clientPlayerIDList,#clientPlayerIDList+1,tonumber(playerInfoList[n].PlayerId))
      --clientPlayerIDList[n]=playerInfoList[n].PlayerId
    end
  end
  --dump(clientPlayerIDList,'--------------------clientPlayerIDList :')
  cc.DataMgr:setGameClientPlayerIDList(clientPlayerIDList)
  if not self.alreadyLoadPlayerInfo then --已经加载过了,就不重复加载了
    self:SetGameVoice(allPlayerIDList)--设置语音
    self:SetEmojiInfo(allPlayerIDList) --设置表情
    self.emojiChatLayer:setIsAIAutoSend(AIAutoEmoji,AIIDList) --AI自动回复表情
    self.alreadyLoadPlayerInfo=true
  end

  
  
end


--[[
   刷新所有玩家的手牌
]]
function c:RefreshAllPlayerHandCard(playerList,state)
  --回收所有玩家的当前手牌
  for n=1,#playerList do
    for i=1,self.playerCount do
      if self.playerObj[i]:GetPlayerID()==playerList[n].PlayerId then
        local refreshHandCard=playerList[n].PokerList
        if #refreshHandCard>0 then
          --dump(refreshHandCard,'-------------refreshHandCard :')
          print('------------------refreshHandCard Len :',#refreshHandCard)
          self:RefreshPlayerHandCard(i,refreshHandCard,state)
          self.playerObj[i]:ActiveAI(playerList[n].AI)


        else
          --该玩家已经胜利

        end
      end
    end
  end
  print('-------------刷新所有手牌-------------')
end
--[[
  刷新单个玩家的手牌
]]
function c:RefreshPlayerHandCard(refreshIndex,cardList,state)
  --dump(cardList,'------------cardList :')
  print('-------------刷新单个玩家的手牌长度 :',#cardList)
  print('-------------刷新玩家的位置 :',refreshIndex)
  local refreshCardTable={}
  local chooseObjList={}
  local cardPos={}
  local refreshPoker=nil
  local medianPoint=math.ceil(#cardList*0.5)
  local angle=90*(refreshIndex-1)
  local isZombie=false --自身玩家手牌是否存在zombie
  local listLen=#cardList
  for i=1,listLen do
   if refreshPoker==nil then
      refreshPoker=ccui.Button:create()
    else
      refreshPoker=refreshPoker:clone()
    end
    cardPos=cc.ControlMgr:CalculateCardPosition(refreshIndex,medianPoint,listLen,i)
    --dump(cardPos,'-----------------------重新生成的牌的位置 :')
    --print('---------------------refreshPoker :',refreshPoker)
    --print('---------------------self.playerPanelNode :',self.playerPanelNode)
    --print('----sate :',state..'  refreshIndex  :',refreshIndex..'   self.actorDrawAction :',self.actorDrawAction)
    if state=="IN_CARD" and refreshIndex==self.BeDrawIndex and self.actorDrawAction then
      local refreshPos_1=0
      if i~=medianPoint then
        if i<medianPoint then
          if frefreshIndex==2 then
              refreshPos_1=self.expandSize*(medianPoint-i)
          elseif frefreshIndex==3 then
              refreshPos_1=self.expandSize*(medianPoint-i)
          end
        elseif i>medianPoint then
          if frefreshIndex==2 then
              refreshPos_1=-self.expandSize*(i-medianPoint)
          elseif frefreshIndex==3 then
              refreshPos_1=-self.expandSize*(i-medianPoint)
          end
        end
      end
      if refreshIndex==2 then
        cardPos.x=cardPos.x+self.popupDis
        cardPos.y=cardPos.y+refreshPos_1
      elseif refreshIndex==3 then
        cardPos.x=cardPos.x+refreshPos_1
        cardPos.y=cardPos.y+self.popupDis
      elseif refreshIndex==4 then
        cardPos.x=cardPos.x-self.popupDis
        cardPos.y=self.moveDownPos-(i-1)*(self.expandSize+self.otherPlayerCardInterVal)
      end
     
    end
    self.playerPanelNode:addChild(refreshPoker)
    refreshPoker:setAnchorPoint(0.5,0.5)
    refreshPoker:setPositionX(cardPos.x)
    refreshPoker:setPositionY(cardPos.y)
    refreshPoker:setRotation(angle)
    
    local refreshChoose=cc.Sprite:createWithSpriteFrameName("Choose.png")
    refreshChoose:setAnchorPoint(cc.p(0.5,0.5))
    refreshChoose:setVisible(false)
    refreshPoker:addChild(refreshChoose)
    local size=refreshPoker:getContentSize()

    refreshChoose:setPosition(67,89) --牌尺寸的一半
    
    table.insert(refreshCardTable,#refreshCardTable+1,refreshPoker)
    table.insert(chooseObjList,#chooseObjList+1,refreshChoose)
    refreshPoker:setTouchEnabled(false)
    if refreshIndex==1 then
      local spriteName='Pit_'..tostring(cardList[i])..'.png'
      refreshPoker:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
      if cardList[i]==33 then
        isZombie=true
      end
    else
      local spriteName='Pit_beimian.png'
      refreshPoker:loadTextureNormal(spriteName,ccui.TextureResType.plistType)
    end
  end
  if refreshIndex==1 then
    if isZombie and not cc.DataMgr:getZombieAnimation() then
      self:BecomeAZombie(refreshIndex)
      --local upPosX_Left=self.zombieHand_Left:getPositionX()
      local upPosY_Left=200+self.visibleOrigin.y
      self.zombieHand_Left:setPositionY(upPosY_Left)
      local upPosY_Right=240+self.visibleOrigin.y
      self.zombieHand_Right:setPositionY(upPosY_Right)
      self.tombstone:setOpacity(255)
    elseif not isZombie then
      self:BecomeAMan()
    end
  end
  --dump(refreshCardTable,'-------refreshCardTable :')
  self.playerCardObjs[refreshIndex]={}
  for i=1,#refreshCardTable do
    self.playerCardObjs[refreshIndex][i]=CardObject.new(i,cardList[i],refreshIndex,self.playerObj[refreshIndex]:GetPlayerID()) 
    self.playerCardObjs[refreshIndex][i]:SetObj(refreshCardTable[i])
    self.playerCardObjs[refreshIndex][i]:SetChoose(chooseObjList[i])
  end
  --刷新玩家手牌列表
  self.playerObj[refreshIndex]:SetHandCard(self.playerCardObjs[refreshIndex])
  self.playerObj[refreshIndex]:SetPosIndex(refreshIndex)
  self.playerObj[refreshIndex]:SetPlayerWinState(#cardList==0)

end
--[[
  回收所有玩家的手牌
]]
function c:RecycleAllPlayerHandCard()
  cc.DataMgr:setRecycleState(true)
   for i=1,self.playerCount do
    --隐藏计时器
      self:PlayerRoundEnd(i,false)
    end

  local recycleCards={}
  --[[
  for i=1,4 do
    local hands=self.playerObj[i]:GetHandCard()
    local cardObj=hands[i]:GetObj()
    local chooseObj=hands[i]:GetChoose()
    cardObj:setVisible(false)
    if cardObj~=nil then
      if chooseObj~=nil then
        chooseObj:removeSelf()
        chooseObj=nil
      end
      cardObj:removeSelf()
      cardObj=nil
    end
    self.playerObj[i]:SetHandCard(nil)
  end
  ]]
  
  local panelChildren=self.playerPanelNode:getChildren()
  for i=1,#panelChildren do
    panelChildren[i]:setVisible(false)
    panelChildren[i]:removeSelf()
    panelChildren[i]=nil
  end
  --[[
  for j=1,#self.playCardArr do
    --self.playCardArr[j]:setVisible(false)
    self.playCardArr[j]:removeSelf()
    self.playCardArr[j]=nil
  end
  self.playCardArr={}
  ]]
  self.playerPanelNode:setVisible(true)
  print('--------------场景清空-------------')
end
--[[
  回收玩家手牌
]]
function c:RecyclePlayerHands(recycleIndex,cardList)
  local hands=self.playerObj[recycleIndex]:GetHandCard()
  if recycleIndex~=1 then
    local handsLen=#hands
    if handsLen-#cardList==0 then
      return
    end
  end
  print('-------------被回收的玩家的索引 :',recycleIndex)
  print('-------------被回收的玩家的手牌长度 :',#hands)
  print('-------------服务器的手牌长度 :',#cardList)
  for i=1,#hands do
    local cardObj=hands[i]:GetObj()
    local chooseObj=hands[i]:GetChoose()
    if cardObj~=nil then
      if chooseObj~=nil then
        chooseObj:removeSelf()
        chooseObj=nil
      end
      cardObj:removeSelf()
      cardObj=nil
    end
  end
  self.playerObj[recycleIndex]:SetHandCard(nil)
end

--[[
  其他玩家的座位排序
  seatIndex 开始座位

]]
function c:PlayerSeatSort(playerInfoList,seatIndex,nextSeat)
  local allPlayerInfo=playerInfoList
  for i=seatIndex,#allPlayerInfo do
      if allPlayerInfo[i].Seat==nextSeat then
        local temp=allPlayerInfo[seatIndex]
        allPlayerInfo[seatIndex]=allPlayerInfo[i]
        allPlayerInfo[i]=temp
        if seatIndex~=3 then
          local seat=(nextSeat+1==5 and 1) or nextSeat+1
          --print('--------seat :',seat)
          self:PlayerSeatSort(playerInfoList,seatIndex+1,seat)
          return
        end
      end
  end
  --dump(allPlayerInfo,'----------allPlayerInfo :')
end
--[[
  玩家操作信息
  controlState --操作状态 
  0--自身客户端抽牌
  1--自身客户端出牌
  2--其他玩家抽牌
  3--其他玩家出牌
  4--结算界面zombie 公告(自身客户端)
  5--结算界面zombie 公告(其他玩家)
]]
function c:PlayerControllerMsg(msg,controlState)
  --dump(msg,'--------------公告 MSG :')
  if device.platform~="windows" then
    local content=""
    if controlState==0 then
      --content=string.format("%s\n%s",tr("tip1"),msg[1])
      content=string.format(tr("tip1"),msg[1])
    elseif controlState==1 then
      --content=string.format("%s%s ",tr("tip3"),msg[1])
      content=string.format(tr("tip3"),msg[1])
    elseif controlState==2 then
      --content=string.format("%s %s\n%s",msg[1],tr("tip2"),msg[2])
      content=string.format(tr("tip2"),msg[1],msg[2])
    elseif controlState==3 then
      --content=string.format("%s %s %s",msg[1],tr("tip4"),msg[2])
      content=string.format(tr("tip4"),msg[1],msg[2])
    elseif controlState==4 then
      content=tr("tip5")
    else
      --content=string.format("%s %s",msg[1],tr("tip6"))
      content=string.format(tr("tip6"),msg[1])
    end
    self.text_GameMsg:setString(content)
  else
    local player1="Player1"
    local player2="Player2"
    if controlState==0 then
      --content=string.format("%s\n%s",tr("tip1"),msg[1])
      content=string.format(tr("tip1"),player1)
    elseif controlState==1 then
      --content=string.format("%s%s ",tr("tip3"),msg[1])
      content=string.format(tr("tip3"),player1)
    elseif controlState==2 then
      --content=string.format("%s %s\n%s",msg[1],tr("tip2"),msg[2])
      content=string.format(tr("tip2"),player1,player2)
    elseif controlState==3 then
      --content=string.format("%s %s %s",msg[1],tr("tip4"),msg[2])
      content=string.format(tr("tip4"),player1,player2)
    elseif controlState==4 then
      content=tr("tip5")
    else
      --content=string.format("%s %s",msg[1],tr("tip6"))
      content=string.format(tr("tip6"),player1)
    end
    self.text_GameMsg:setString(content)
  end
end


return c