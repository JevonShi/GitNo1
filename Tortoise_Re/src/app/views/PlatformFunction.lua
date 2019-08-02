require("hygame.init")
--[[
    平台语音接入
]]
PlatformFunction = class("PlatformFunction")

local c=PlatformFunction

local TOP_ZORDER=12
function c:ctor(class)
	self.sceneClass=class
    --self.micStatus=0
end

--[[
    场景对象与玩家语音图标
]]
function c:Init(sceneObj,voiceBtn,voiceIconList,voiceSpinePos)
	self.sceneObj=sceneObj
	print('--------self.sceneObj :',self.sceneObj)
	self.windowsSize=cc.Director:getInstance():getWinSize()

	self.userPosList=voiceSpinePos --语音光圈动效位置
	--self.userPos2={x=display.cx+280,y=display.height-222}

	--local Frame_3=cc.Sprite:createWithSpriteFrameName("Frame_3")
	--Frame_3:align(display.CENTER_TOP,self.userPos1.x,self.userPos1.y)
	--Frame_3:addTo(self.sceneObj,TOP_ZORDER +12)
    print('-----voiceBtn :',voiceBtn)
    self:Init_Voice(voiceBtn,voiceIconList)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	--监听语音开启事件
	local getImageListener=cc.EventListenerCustom:create(HYNotifyEvent.notifyUserMicStatus, handler(self, self.notifyUserMicStatuFunc)) 
    eventDispatcher:addEventListenerWithSceneGraphPriority(getImageListener, self.sceneObj)  
    --监听玩家说话事件
    local getImageListener=cc.EventListenerCustom:create( HYNotifyEvent.notifyUserSpeakStatus, handler(self, self.notifyUserSpeakStatusFunc)) 
    eventDispatcher:addEventListenerWithSceneGraphPriority(getImageListener, self.sceneObj)  

	
end
--[[
 初始化voice 按钮
]]
function c:Init_Voice(voiceBtn,voiceIconList)
    --self.userPanel2:setGlobalZOrder(50)
    self.playerVoiceIcon=voiceIconList
    --self.micStatus=0
	local spriteName= "button_voice_1.png"
    --self.micStatus=0
    self.voiceBtn=voiceBtn
     --启动/关闭语音
     local function buttonVolumeEvent()
         print('-----------------语音按钮-----------self.micStatus :',self.micStatus)
        if self.micStatus==1 then
            HYGameBridge.getInstance():reqCloseMic()
        else
            HYGameBridge.getInstance():reqOpenMic()
        end
        
    end
    self.voiceBtn:addClickEventListener(buttonVolumeEvent)


    if HYGameBridge.getInstance().isVoiceSupport  and  HYGameBridge.getInstance():isVoiceSupport() then
        HYGameBridge.getInstance():reqUserMicStatus()
        self.voiceBtn:loadTextureNormal("button_voice_2.png",ccui.TextureResType.plistType)
        self.playerVoiceIcon[1].icon:setSpriteFrame(display.newSpriteFrame("#Icon_Music B.png"))
    end
    
end

--[[
	
]]
function c:notifyUserMicStatuFunc(evt)
    local data = evt.notifyData
    for k,v in pairs(data) do
        self:showUserStatus(v.uid,v.status)
    end
    --dump(evt,"輸出============》》")
end
--[[
	切换麦克风状态
]]
function c:showUserStatus(uid,statu)
    --print('------------uid :',uid,'  ---------statu :',statu..'  -----------------self.micStatus :',self.micStatus)
    local spr = display.newSpriteFrame("#Icon_Music B.png")
    local rspr = display.newSpriteFrame("#Icon_Mute.png")
    if cc.DataMgr:getActorID() == uid then
        self.micStatus = statu
        if self.micStatus==1 then --1是開啓
        	self.voiceBtn:loadTextureNormal("button_voice_2.png",ccui.TextureResType.plistType)
			 self.playerVoiceIcon[1].icon:setSpriteFrame(spr)
        else
        	self.voiceBtn:loadTextureNormal("button_voice_1.png",ccui.TextureResType.plistType)
             self.playerVoiceIcon[1].icon:setSpriteFrame(rspr)
        end 
    else
        for i=2,4 do
            if uid==self.playerVoiceIcon[i].playerID then
                if statu==1 then
			        self.playerVoiceIcon[i].icon:setSpriteFrame(spr)
                else
                    self.playerVoiceIcon[i].icon:setSpriteFrame(rspr)
                end
            end 
        end
    end
end


function c:notifyUserSpeakStatusFunc(evt)
    local data = evt.notifyData
    --dump(data,'----------------玩家语音: ')
    for k,v in pairs(data) do
        self:showUserSpeek(v)
    end
    --dump(evt,"輸出打印-----》》")
end


function c:showUserSpeek(uid)
    local userPanel = self.userPosList[1]
    if cc.DataMgr:getActorID() ~= uid then
        for i=2,#self.playerVoiceIcon do
            if self.playerVoiceIcon[i].playerID==uid then
                userPanel=self.userPosList[i]
            end
        end
    end
    local spine = self:createSpineAnimation("huxihuan/huxihuan","animation",false)
    spine:setScale(0.9)
    --print('------------- self.sceneObj.myHeadbk :',self.sceneObj.myHeadbk)
    --self.sceneObj:addChild(spine,12)
    spine:addTo(userPanel,-5)
    --spine:setLocalZOrder(80)
    --spine:setGlobalZOrder(80)
    spine:setPosition(cc.p(45,45))

    --userPanel:setLocalZOrder(1)
end

--[[
    播放语音效果序列帧动画
]]
function c:createSpineAnimation(fileName,animationName,isLoop,callback)
    --print('---------播发序列帧动画------')
    --local size = cc.Director:getInstance():getWinSize()
    local skeletonNode = sp.SkeletonAnimation:create("spine/"..fileName..".json",
            "res/spine/"..fileName..".atlas", 1)
    skeletonNode:setAnimation(0, animationName, isLoop)
    --self.skeletonNode:addAnimation(0, "hit", false)
    skeletonNode:setDebugBonesEnabled(false)
    skeletonNode:retain()
    local that = self
    skeletonNode:registerSpineEventHandler(
            function(event)
                if callback and callback ~= nil then
                    callback()
                end
                if not isLoop then
                    skeletonNode:removeFromParent()
                end
            end
    ,sp.EventType.ANIMATION_COMPLETE)
    --print('----------skeletonNode :',skeletonNode)
    return skeletonNode
end
