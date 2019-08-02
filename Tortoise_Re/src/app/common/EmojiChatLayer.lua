--[[
    name: EmojiChatLayer.lua
    description: 表情聊天界面
    date: 2019.03.13
]]

EmojiType = {
    Emoticon = 0, --动态或静态表情图
    RegularText=1, --系统预设语句
    InputText=2, --用户输入语句
}
EmojiTypeString = {
    [0] ="Emoticon", --动态或静态表情图
    [1] ="RegularText", --系统预设语句
    [2] ="InputText", --用户输入语句
}

-- 对话相对于头像显示位子
ChatShowDirection = {
    RightTop = 0,
    RightBottom = 1,
    LeftBottom = 2,
    LeftTop = 3,
}

EVT_RecvEmoji = "EVT_RecvEmoji" --接收表情事件
EVT_SendEmoji = "EVT_SendEmoji" --发送表情事件

local emojiDist = 120
local EmojiChatLayer = class("EmojiChatLayer", function(icon)
    return display.newLayer()
end)

local AIAutoSendList = {[1001] = 150, [1002] =80,[1003] = 80,[1004] = 150, [1005] = 50,[1006] = 50,[1007] = 50} 

function EmojiChatLayer:ctor()
end

--[[
    selfPos: 自己方显示最左边位置
    rivalPos: 对手显示的最右边位置
    emojiPos: 常用表情放置的位置
    emojiDst: 常用表情间的间距
    openBtnDst: 打开按钮和常用表情间的距离
    selfPlayerId: 自己方玩家Id，用于判断是自己发送的还是对方发送的
    isSelfTextBlue: 自己方聊天文字颜色是否是绿色，聊天颜色有绿色红色两种，自己是绿色，对方就是红色
    selfChatDir: 自己显示对话框相对自己头像方位，默认右上方
    rivalChatDir: 对手显示对话框相对于对手头像方位，默认左下方
    isVertical: 表情排布方向是否是竖向的，默认为false， 19.04.24
]]
function EmojiChatLayer:ctorFor2(selfPos, rivalPos, emojiPos, emojiDst, openBtnDst, selfPlayerId, isSelfTextBlue, selfChatDir, rivalChatDir, isVertical)
    self._selfPos = cc.p(375, 100)
    self._rivalPos = cc.p(375, 1400)
    self._emojiPos = cc.p(375, 300)
    self._emojiDst = emojiDst
    self._openBtnDst = openBtnDst
    self._selfPlayerId = selfPlayerId
    if selfPos then
        self._selfPos = selfPos
    end
    if rivalPos then
        self._rivalPos = rivalPos
    end
    if emojiPos then
        self._emojiPos = emojiPos
    end
    self._isVertical = isVertical or false
    self._isSelfTextBlue = isSelfTextBlue == nil and true or isSelfTextBlue
    self._selfChatDir = selfChatDir or ChatShowDirection.RightTop
    self._rivalChatDir = rivalChatDir or ChatShowDirection.LeftBottom

    self:init()
end


--[[
    selfPlayerId: 自己方玩家Id，用于判断是自己发送的还是对方发送的
    emojiPos: 常用表情放置的位置
    emojiDst: 常用表情间的间距
    openBtnDst: 打开按钮和常用表情间的距离
    isSelfTextBlue: 自己方聊天文字颜色是否是绿色，聊天颜色有绿色红色两种，自己是绿色，对方就是红色
    isVertical: 表情排布方向是否是竖向的，默认为false， 19.04.24
]]
function EmojiChatLayer:ctorForMulti(selfPlayerId, emojiPos, emojiDst, openBtnDst, isSelfTextBlue, isVertical)
    self._emojiPos = cc.p(375, 300)
    self._emojiDst = emojiDst
    self._openBtnDst = openBtnDst
    self._selfPlayerId = selfPlayerId
    if emojiPos then
        self._emojiPos = emojiPos
    end
    self._isVertical = isVertical or false
    self._isSelfTextBlue = isSelfTextBlue == nil and true or isSelfTextBlue
    self._selfChatDir = selfChatDir or ChatShowDirection.RightTop
    self._rivalChatDir = rivalChatDir or ChatShowDirection.LeftBottom
    
    self._userInfoList = {}

    self:init()
end
--[[
    添加玩家信息
    uid：玩家Id
    showPos：显示位置
    chatDir：显示对话框相对自己头像方位，默认右上方
]]
function EmojiChatLayer:addUserInfo(uid, showPos, chatDir)
    local userInfo = {uid = uid, 
    showPos = showPos,
    chatDir = chatDir or ChatShowDirection.RightTop}

    table.insert(self._userInfoList, userInfo)
end

function EmojiChatLayer:init()
    cc.SpriteFrameCache:getInstance():addSpriteFrames("emojiChat/emojiChat.plist")
    self._isBlockingMsg = false -- 是否屏蔽消息
    self._isAIAutoSend =  false
    self._isCanSend = true -- 发送一秒钟内不可再次发送


    self._emojiConfig = {}
    -- 获取表情配置
    if device.platform == "windows" then
        local strJson = cc.FileUtils:getInstance():getStringFromFile("emoticon/emojiChatConfig.json")
        self._emojiConfig = json.decode(strJson)
        self:createChatLayer()
    else
        HYGameBridge.getInstance():getEmojiConfig()
        print("发送获取表情配置请求")
    end

    --注册表情消息接收函数
	local listener = cc.EventListenerCustom:create(EVT_RecvEmoji, handler(self, self.onReceiveEmojiMsg))
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self) 

    local getImageListener = cc.EventListenerCustom:create(HYNotifyEvent.notifyEmojiConfig, handler(self, self.onGetEmojiConfig)) 
    eventDispatcher:addEventListenerWithSceneGraphPriority(getImageListener, self)  


    eventCenter:on("PLAYER_EXPRESSIONS_EVENT" , function(e) 
        self:onReceiveEmojiMsg(e)
    end , "roomControl")
end

function EmojiChatLayer:onGetEmojiConfig(evt)
    local notifyData = evt.notifyData
    self._emojiConfig = notifyData
    print("收到大厅表情配置", notifyData)
    self:createChatLayer()
end

function EmojiChatLayer:createChatLayer()
    print('-----创建快捷表情列表------')
    -- 创建快捷表情列表
    local moduleConfig = self._emojiConfig
    local shortCutEmojis = moduleConfig.emojis
    local winSize = cc.Director:getInstance():getWinSize()
    local visibleOrigin = cc.Director:getInstance():getVisibleOrigin()

    -- 创建常用表情节点，用于显示隐藏常用表情
    self._shortCutEmojiNode = cc.Node:create()
        :addTo(self,50)
        :setPosition(self._emojiPos)
    --self._shortCutEmojiNode:setGlobalZOrder(75)
    for i, v in pairs(shortCutEmojis) do
        local icon = v.icon
        icon = self:getPullPathOfFile(icon)
        local iconBtn = ccui.Button:create(icon, icon, icon, ccui.TextureResType.localType)
            :addTo(self._shortCutEmojiNode)
            :setPressedActionEnabled(true)

        if self._isVertical then
            iconBtn:setPosition(0, 20 - (i - (#shortCutEmojis + 1) / 2) * self._emojiDst)
        else
            iconBtn:setPosition((i - (#shortCutEmojis + 1) / 2) * self._emojiDst, 20)
        end
        iconBtn.emojiId = v.id
        iconBtn:addClickEventListener(function(sender)
                self:onEmojiBtnClicked(sender.emojiId)
            end)
        -- 表情Icon
        local iconSprite = cc.Sprite:createWithSpriteFrameName("xiapaibiaoqingdi.png")
            :setPosition(iconBtn:getContentSize().width / 2, iconBtn:getContentSize().height / 2 - 47)
         iconBtn:addChild(iconSprite, -1)
    end

    -- 创建打开界面按钮
    local btnIcon = "gengduo.png"
    self._openPageBtn = ccui.Button:create(btnIcon, btnIcon, btnIcon, ccui.TextureResType.plistType)
    self._openPageBtn:addTo(self)
        :setPressedActionEnabled(true)
    if not self._isVertical then
        self._openPageBtn:setPosition(self._emojiPos.x + ((#shortCutEmojis - 1) / 2) * self._emojiDst + self._openBtnDst, self._emojiPos.y)
    else
        self._openPageBtn:setPosition(self._emojiPos.x, self._emojiPos.y - ((#shortCutEmojis - 1) / 2) * self._emojiDst - self._openBtnDst)
    end
    

    -- 创建表情界面
    self._secondaryLayer = cc.CSLoader:createNode("emojiChat/EmojiChatLayer.csb")
        :addTo(self,50)
        :setVisible(false)
    --self._secondaryLayer:setGlobalZOrder(70)   
    local bkgSprite = self._secondaryLayer:getChildByName("bkgSprite")
    if self._isVertical then
        bkgSprite:setPosition(self._openPageBtn:getPositionX() - 152 - 94 , self._openPageBtn:getPositionY() - 96 + 200)
        if self._openPageBtn:getPositionX() < winSize.width / 2 then
            bkgSprite:setPosition(self._openPageBtn:getPositionX() + 152 + 94 , self._openPageBtn:getPositionY() - 96 + 200)
        end
    else
        bkgSprite:setPosition(self._openPageBtn:getPositionX() - 152 , self._emojiPos.y + 200)
    end
    local emojiScrollView = bkgSprite:getChildByName("emojiScrollView")
    local presetTextNode = bkgSprite:getChildByName("presetTextNode")
    self._switchBtn = bkgSprite:getChildByName("switchBtn")
    self._switchBtn:addClickEventListener(handler(self, self.onSwitchBtnClicked))
    local textNode = bkgSprite:getChildByName("textNode")
    local textBtn = textNode:getChildByName("textBtn")

    self._openPageBtn:addClickEventListener(function(sender)
            self._secondaryLayer:setVisible(true)
            self:showMoreEmojiEntranceAction()
            emojiScrollView:jumpToLeft()
            -- self._shortCutEmojiNode:setVisible(false)
        end)

    -- 注册刺激界面点击响应
    local function onTouchBegan(touch, event)
        if not self._secondaryLayer:isVisible() then
            return false
        end
        
        local size = bkgSprite:getContentSize()
        size.width = size.width * bkgSprite:getScaleX() 
        size.height = size.height * bkgSprite:getScaleY()

        local anchor = bkgSprite:getAnchorPoint()
        local x = bkgSprite:getPositionX()
        local y = bkgSprite:getPositionY()

        x = x - size.width * anchor.x
        y = y - size.height * anchor.y

        local nodeRect = cc.rect(x, y, size.width, size.height)
        if not cc.rectContainsPoint(nodeRect, touch:getLocation()) then
            self:closeSecondaryLayer()
            return true
        end
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    local eventDispatcher = self._secondaryLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, bkgSprite)

    --创建不常用表情列表
    local moreEmojiList = moduleConfig.moreEmojis
    local emojiViewSize = emojiScrollView:getInnerContainer():getContentSize()
    
    self._moreEmojiBtnList = {} -- 更多表情按钮列表，用于显示出现动画
    for i, v in pairs(moreEmojiList) do
        local emojiBtn =  ccui.Button:create("biaoqingdi.png", "biaoqingdi.png", "biaoqingdi.png", ccui.TextureResType.plistType)
            :setPosition(240 + (i - 0.5) * emojiDist - 10, emojiViewSize.height / 2 - 10)
            :setPressedActionEnabled(true)
        emojiScrollView:addChild(emojiBtn)
        emojiBtn.emojiId = v.id
        emojiBtn:addClickEventListener(function(sender)
            self:closeSecondaryLayer()
            self:onEmojiBtnClicked(sender.emojiId)
        end)
        table.insert(self._moreEmojiBtnList, emojiBtn)
        local icon = v.icon
        icon = self:getPullPathOfFile(icon)
        local iconSprite = cc.Sprite:create(icon)
            :setPosition(emojiBtn:getContentSize().width / 2, emojiBtn:getContentSize().height / 2 + 17)
            :addTo(emojiBtn)
    end
    -- 重置scrollView内部大小
    if #moreEmojiList * emojiDist > emojiViewSize.width - 240 then
        emojiScrollView:getInnerContainer():setContentSize(cc.size(#moreEmojiList * emojiDist + 240, emojiViewSize.height))
    else
        emojiScrollView:getInnerContainer():setContentSize(cc.size(emojiViewSize.width + 0.1, emojiViewSize.height))
    end
    emojiScrollView:setScrollBarEnabled(false)
    

    -- 创建常用语句列表
    local presetTextList = moduleConfig.texts
    for i, v in pairs(presetTextList) do
        local icon = "wenbendi.png"
        local iconBtn = ccui.Button:create(icon, icon, icon, ccui.TextureResType.plistType)
            :setPosition((0.5 - (i % 2))  * 190, (- math.floor((i + 1) / 2) + 1) * 64 - 18)
            :addTo(presetTextNode)
            :setScale9Enabled(true)
            :setContentSize(cc.size(168, 52))
            :setPressedActionEnabled(true)
        local textLabel = display.newTTFLabel({
            text = v.text,
            font = "",
            size = 26,
            color = cc.c3b(0x5e, 0x3f, 0x35)})
        textLabel:setPosition(iconBtn:getContentSize().width / 2, iconBtn:getContentSize().height / 2 + 2)
            :addTo(iconBtn)
        iconBtn.presetId = v.id
        iconBtn:addClickEventListener(function(sender)
            self:closeSecondaryLayer()
            self:onPresetBtnClicked(sender.presetId)
        end)
    end

    -- 创建输入框
    local editBox = ccui.EditBox:create(cc.size(362, 46), "shurudi.png", ccui.TextureResType.plistType)
    editBox:addTo(textNode)
        :setPlaceHolder(tr("click to input"))
        :setPlaceholderFontColor(cc.c3b(0x91, 0x91, 0x91))
        :setPlaceholderFontSize(26)
        :setInputMode(6)
        :setFontSize(26)
        -- :setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
        :setReturnType(2)
        :setMaxLength(20)
        :setFontColor(cc.c3b(0x5e, 0x3f, 0x35))
        :setEnabled(false)
    
    -- 创建真实输入框
    self._editBoxBkg = ccui.Scale9Sprite:createWithSpriteFrameName("shurukuangdi.png")
        :setContentSize(cc.size(winSize.width - visibleOrigin.x * 2, 136))
        :setPosition(winSize.width / 2, 68 + visibleOrigin.y)
        :addTo(self)
        :setVisible(false)
    -- 创建输入框
    local realEditBox = ccui.EditBox:create(cc.size(self._editBoxBkg:getContentSize().width - 126, 76), "shurukuang.png", ccui.TextureResType.plistType)
    realEditBox:addTo(self._editBoxBkg)
        :setPlaceHolder(tr("click to input"))
        :setPlaceholderFontColor(cc.c3b(0x91, 0x91, 0x91))
        :setPlaceholderFontSize(32)
        :setInputMode(6)
        :setFontSize(32)
        :setReturnType(2)
        :setMaxLength(20)
        :setFontColor(cc.c3b(0x5e, 0x3f, 0x35))
        :setEnabled(false)
        :setPosition(self._editBoxBkg:getContentSize().width / 2 - 34, self._editBoxBkg:getContentSize().height / 2)
        
    if realEditBox.setKeyboardGapHeight then
        realEditBox:setKeyboardGapHeight(50)
        print("editBox gapHeight", realEditBox:GetKeyboardGapHeight())
    end
    realEditBox:registerScriptEditBoxHandler(function(strEventName,sender)
        print("editBox event:"..strEventName)
        if strEventName == "return" then
            -- 检查当前是否可以发送
            if not self:checkIsCanSend() then
                return
            else
                self:sendTimeCountDown()
            end

            local text = realEditBox:getText()
            realEditBox:setText("")
            editBox:setText("")
            print("发送输入文字", text)

            -- 内容为空，不发送
            if text == "" then
                return
            end

            self._secondaryLayer:setVisible(false)
            self._shortCutEmojiNode:setVisible(true)
            
            self:sendEmojiMsg(EmojiType.InputText, 0, text)
        elseif strEventName == "ended" then
            Scheduler.performWithDelayGlobal(function()
                self._editBoxBkg:setVisible(false)
            end, 0.2)
            local text = realEditBox:getText()
            editBox:setText(text)
        end
    end)
    -- 创建发送按钮
    local sendIcon = "fasong.png"
    local sendBtn = ccui.Button:create(sendIcon, sendIcon, sendIcon, ccui.TextureResType.plistType)
        :setPosition(self._editBoxBkg:getContentSize().width - 50, self._editBoxBkg:getContentSize().height / 2)
        :addTo(self._editBoxBkg)
        :setPressedActionEnabled(true)
        :addClickEventListener(function(sender)
            
            -- 检查当前是否可以发送
            if not self:checkIsCanSend() then
                return
            else
                self:sendTimeCountDown()
            end

            local text = editBox:getText()
            editBox:setText("")
            realEditBox:setText("")
            print("发送输入文字", text)

            -- 内容为空，不发送
            if text == "" then
                return
            end

            self._secondaryLayer:setVisible(false)
            self._shortCutEmojiNode:setVisible(true)
            self:sendEmojiMsg(EmojiType.InputText, 0, text)
        end)
    
    textBtn:addClickEventListener(function(sender)
        self._editBoxBkg:setVisible(true)
        realEditBox:touchDownAction(realEditBox, ccui.TouchEventType.ended)
        self._secondaryLayer:setVisible(false)
    end)
end
--[[
function EmojiChatLayer:onSwitchBtnClicked(sender)
    self._isBlockingMsg = not self._isBlockingMsg
    
    -- 修改按钮显示状态
    local switchTextureName = self._isBlockingMsg and "rules_x.png" or "you.png"
    self._switchBtn:loadTextures(switchTextureName, switchTextureName, switchTextureName, ccui.TextureResType.plistType)
    
    local openTextureName = self._isBlockingMsg and "rules_x.png" or "button_questions.png"
    self._openPageBtn:loadTextures(openTextureName, openTextureName, openTextureName, ccui.TextureResType.plistType)
end
]]
-- 根据表情id获取表情信息
function EmojiChatLayer:getEmojiInfoById(emojiId)
    for i, v in pairs(self._emojiConfig.emojis) do
        if v.id == emojiId then
            return v
        end
    end
    for i, v in pairs(self._emojiConfig.moreEmojis) do
        if v.id == emojiId then
            return v
        end
    end
    return {}
end

-- 根据表情id获取表情信息
function EmojiChatLayer:getPresetTextInfoById(presetId)
    for i, v in pairs(self._emojiConfig.texts) do
        if v.id == presetId then
            return v
        end
    end
    return {}
end
-- 表情按钮点击相应
function EmojiChatLayer:onEmojiBtnClicked(emojiId)
    -- 检查当前是否可以发送
    if not self:checkIsCanSend() then
        return
    else
        self:sendTimeCountDown()
    end

    self:sendEmojiMsg(EmojiType.Emoticon, emojiId, "")
end
-- 表情按钮点击相应
function EmojiChatLayer:onPresetBtnClicked(presetId)
    -- 检查当前是否可以发送
    if not self:checkIsCanSend() then
        return
    else
        self:sendTimeCountDown()
    end
    
    self:sendEmojiMsg(EmojiType.RegularText, presetId, "")
end

function EmojiChatLayer:closeSecondaryLayer()
    self._secondaryLayer:setVisible(false)
    self._shortCutEmojiNode:setVisible(true)
end
--[[
    接收表情
]]
function EmojiChatLayer:onReceiveEmojiMsg(event)
    local msgData = event.notifyData
    local emojiType = EmojiType[msgData.emojiType]

    local bkgWidth = 122 --背景大小

    local showNode = cc.Node:create()
        :addTo(self)
    local chatNode = nil

    local textColor = cc.c3b(0xe6, 0x4e, 0x5d) -- 红色字体
    if self._isSelfTextBlue == (msgData.uid == self._selfPlayerId) then
        textColor = cc.c3b(0x40, 0xa4, 0xc7) -- 蓝色字体
    end
    
    if emojiType == EmojiType.Emoticon then
        local spineName = self:getEmojiInfoById(msgData.emojiId).animation
        if spineName == nil then 
            print("接收到表情本地没有对应信息", msgData.emojiId)
            return
        end
        spineName = self:getPullPathOfFile(spineName)
        local strLen = string.len( spineName)
        local subStr = string.sub(spineName, strLen - 4, strLen)
        if string.sub(spineName, strLen - 4, strLen) == ".skel" then
            spineName = string.sub(spineName, 0, strLen - 5)
        end
        chatNode = sp.SkeletonAnimation:createWithBinaryFile(spineName .. ".skel", spineName .. ".atlas", 1)
            :addTo(showNode)
            :setPosition(0, -10)
        chatNode:setAnimation(0, "index", true)

        if self._isAIAutoSend and msgData.uid == self._selfPlayerId then
            self:showAIAutoEmoji()
        end

        -- 播放表情音效
        --Audio.play(self:getEmojiInfoById(msgData.emojiId).audio)
        AudioEngine.playEffect(self:getEmojiInfoById(msgData.emojiId).audio)
    elseif emojiType == EmojiType.RegularText then
        local text = self:getPresetTextInfoById(msgData.emojiId).text
        if text == nil then 
            print("接收到短语本地没有对应信息", msgData.emojiId)
            return
        end
        --print('--------------Message Content :',text)
        --self.textLen=nil
        self.textLen=string.len(text)
        if self.textLen<6 then
            self.textPosValue=0.5
        else
            self.textPosValue=0.1
        end
        chatNode = cc.Label:create()
            :addTo(showNode)
            :setSystemFontSize(30)
            :setTextColor(textColor)
            :setString(text)
            :setPosition(0, 23)
            :setAnchorPoint(0.5,0.5)
        bkgWidth = chatNode:getContentSize().width + 70
        --print('--------------------bkgWidth :',bkgWidth)
    elseif emojiType == EmojiType.InputText then
        local text = msgData.emojiText
        self.textLen=string.len(text)
        if self.textLen<8 then
            self.textPosValue=0.35
        elseif self.textLen<16 then
            self.textPosValue=0.25
        else
            self.textPosValue=-0.05
        end

        chatNode = cc.Label:create()
            :addTo(showNode)
            :setSystemFontSize(30)
            :setTextColor(textColor)
            :setString(text)
            :setPosition(0, 23)
            :setAnchorPoint(0.5,0.5)
        bkgWidth = chatNode:getContentSize().width + 70
        --print('--------------------bkgWidth :',bkgWidth)
    end

    local showPos = self._selfPos
    local showDir = self._selfChatDir

    -- 只有两个玩家的情况
    if self._selfPos then
        if msgData.uid == self._selfPlayerId then
            if self._selfShowNode then
                self._selfShowNode:removeFromParent()
            end
            showPos = self._selfPos
            showDir = self._selfChatDir
            self._selfShowNode = showNode
            self._selfShowNode:runAction(cc.Sequence:create(cc.DelayTime:create(2.2), 
            cc.CallFunc:create(function ()
                self._selfShowNode:removeFromParent()
                self._selfShowNode = nil
            end)))
        else
            if self._rivalShowNode then
                self._rivalShowNode:removeFromParent()
            end
            self._rivalShowNode = showNode
            showPos = self._rivalPos
            showDir = self._rivalChatDir
            self._rivalShowNode:runAction(cc.Sequence:create(cc.DelayTime:create(2.2), 
            cc.CallFunc:create(function ()
                self._rivalShowNode:removeFromParent()
                self._rivalShowNode = nil
            end)))
        end
    else -- 有多个玩家的情况
        local userInfo = nil
        for i, info in pairs(self._userInfoList) do
            if info.uid == msgData.uid then
                userInfo = info
            end
        end

        if not userInfo then
            showNode:removeSelf()
            return
        end

        if userInfo.showNode then
            userInfo.showNode:removeSelf()
            userInfo.showNode = nil
        end

        showPos = userInfo.showPos
        showDir = userInfo.chatDir
        userInfo.showNode = showNode
        userInfo.showNode:runAction(cc.Sequence:create(cc.DelayTime:create(2.2), 
        cc.CallFunc:create(function ()
            userInfo.showNode:removeFromParent()
            userInfo.showNode = nil
        end)))
    end
    chatNode:setLocalZOrder(1)
    local bkgSprite = nil
    local bkgName = "wenbenqipao.png"
    if emojiType == EmojiType.Emoticon then
        bkgName = "duihuaqipao.png"
    end
    if showDir == ChatShowDirection.RightTop then
        -- 
        bkgSprite = ccui.Scale9Sprite:createWithSpriteFrameName(bkgName)
        chatNode:setPosition(9, chatNode:getPositionY())
    elseif showDir == ChatShowDirection.RightBottom then
        bkgName = "wenbenqipaoyou.png"
        if emojiType == EmojiType.Emoticon then
            bkgName = "biaoqingqipaoyou.png"
        end
        bkgSprite = ccui.Scale9Sprite:createWithSpriteFrameName(bkgName)
        bkgSprite:setScaleX(-1)
        chatNode:setPosition(9, chatNode:getPositionY())
    elseif showDir == ChatShowDirection.LeftBottom then
        bkgName = "wenbenqipaoyou.png"
        if emojiType == EmojiType.Emoticon then
            bkgName = "biaoqingqipaoyou.png"
        end
        bkgSprite = ccui.Scale9Sprite:createWithSpriteFrameName(bkgName)
        chatNode:setPosition(-9, chatNode:getPositionY())
    elseif showDir == ChatShowDirection.LeftTop then
        bkgSprite = ccui.Scale9Sprite:createWithSpriteFrameName(bkgName)
        bkgSprite:setScaleX(-1)
        chatNode:setPosition(-9, chatNode:getPositionY())
    end
    bkgSprite:addTo(showNode)
    --bkgSprite:setAnchorPoint(0,0.5)
    --showNode:setAnchorPoint(0,0.5)
    local winSize = cc.Director:getInstance():getWinSize()
    showNode:setPosition(showPos)
    bkgSprite:setContentSize(cc.size(bkgWidth, bkgSprite:getContentSize().height))
    bkgSprite:setPosition(0, 24)
    if showPos.x < winSize.width / 2 then
       --print('------------------1')
        showPos = cc.p(showPos.x + bkgWidth / 2, showPos.y)
        showNode:setPosition(cc.p(showPos.x - bkgWidth / 2, showPos.y - 50))
    else
        
        if emojiType == EmojiType.Emoticon then
            showPos = cc.p(showPos.x - bkgWidth*0.5, showPos.y)
        else
            showNode:setAnchorPoint(0.5,0.5)
            --print('----------self.textPosValue :',self.textPosValue)
            --print('-------------------showDir :',showDir)
            if showDir == ChatShowDirection.LeftTop then
                if self.textLen<6 then
                    showPos = cc.p(showPos.x-bkgWidth*self.textPosValue, showPos.y+10)
                else
                    --print('------------------------------Good Luck')
                    showPos = cc.p(showPos.x-bkgWidth*0.5, showPos.y+10)
                end
                
            else
                showPos = cc.p(showPos.x-bkgWidth*self.textPosValue, showPos.y+10)
            end
        end
        showNode:setPosition(cc.p(showPos.x - bkgWidth / 2, showPos.y-50))
    end

    showNode:setScale(0.3)
    showNode:runAction(cc.Sequence:create(cc.Spawn:create(cc.EaseSineOut:create(cc.MoveTo:create(0.2, showPos)), 
    cc.EaseSineIn:create(cc.ScaleTo:create(0.2, 1.2))),
    cc.ScaleTo:create(0.1, 0.95),
    cc.ScaleTo:create(0.05, 1),
    cc.DelayTime:create(1.5),
    cc.ScaleTo:create(0.1, 1.1),
    cc.ScaleTo:create(0.15, 0)))
end

-- 发送完成，禁止一秒发送
function EmojiChatLayer:sendTimeCountDown()
    self._isCanSend = false

    Scheduler.performWithDelayGlobal(function()
        self._isCanSend = true
    end, 1)
end

-- 检查是否可以发送
function EmojiChatLayer:checkIsCanSend()
    if self._isBlockingMsg then
        local winSize = cc.Director:getInstance():getWinSize()
        local textLabel = cc.Label:create()
            :addTo(self)
            :setSystemFontSize(30)
            :setTextColor(cc.c4b(255, 0, 0, 255))
            :setString(tr("can`t send"))
            :setPosition(winSize.width / 2, winSize.height / 2)
        textLabel:runAction(cc.Sequence:create(cc.MoveBy:create(1, cc.p(0, 100)),
        cc.FadeTo:create(0.3, 0),
        cc.RemoveSelf:create()))

        return false
    end
    -- if not self._isCanSend then
    --     local winSize = cc.Director:getInstance():getWinSize()
    --     local textLabel = cc.Label:create()
    --         :addTo(self)
    --         :setSystemFontSize(30)
    --         :setTextColor(cc.c4b(255, 0, 0, 255))
    --         :setString(tr("send later"))
    --         :setPosition(winSize.width / 2, winSize.height / 2)
    --     textLabel:runAction(cc.Sequence:create(cc.MoveBy:create(1, cc.p(0, 100)),
    --     cc.FadeTo:create(0.3, 0),
    --     cc.RemoveSelf:create()))
    -- end

    return self._isCanSend
end

function EmojiChatLayer:getPullPathOfFile(filePath)
    if device.platform == "windows" then
        return filePath
    else
        if not self._appResPathList then
            self._appResPathList = HYGameBridge.getInstance():getAppResSearchPathSync()
        end

        for i, v in pairs(self._appResPathList) do
            local fullPath = v .. filePath
            if cc.FileUtils:getInstance():isFileExist(fullPath) then
                return fullPath
            end
        end

        return ""
    end
end

function EmojiChatLayer:showMoreEmojiEntranceAction()
    for i, v in pairs(self._moreEmojiBtnList) do
        v:setScale(1)
        v:runAction(cc.Sequence:create(cc.ScaleTo:create(0.05, 1.15), cc.ScaleTo:create(0.1, 1)))
    end
end

-- 发送表情消息
function EmojiChatLayer:sendEmojiMsg(emojiType, emojiId, emojiText)
    
    -- 发送文字
    local sendData = {}
    sendData.emojiType = EmojiTypeString[emojiType]
    sendData.emojiId = emojiId
    sendData.emojiText = emojiText
    sendData.uid = self._selfPlayerId


    cc.NetMgr:sendMsg( 1003 , "pbghost.EmojiInfo" , sendData )
    --[[
    local event = cc.EventCustom:new(EVT_SendEmoji)
	event.notifyData = sendData
    cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    ]]
end

-- 对方AI自动回复表情
function EmojiChatLayer:showAIAutoEmoji()
    local aiEmojiState=cc.DataMgr:getAIEmojiState()
    -- 自动回复的概率是50%
    if math.random() > 0.5 or aiEmojiState then
        return
    end
    cc.DataMgr:setAIEmojiState(true)
    local scheduler=cc.Director:getInstance():getScheduler()
    scheduler:scheduleScriptFunc(function() cc.DataMgr:setAIEmojiState(false) end,1,false)
    local emojiNum = #self._emojiConfig.emojis + #self._emojiConfig.moreEmojis
    local randomEmojiIndex = math.random(1, emojiNum)
    local emojiId = self:getAISendRandomId()
    -- if randomEmojiIndex > #self._emojiConfig.emojis then
    --     emojiId = self._emojiConfig.moreEmojis[randomEmojiIndex - #self._emojiConfig.emojis].id
    -- else
    --     emojiId = self._emojiConfig.emojis[randomEmojiIndex].id
    -- end
    local randomAIIndex=math.random(1,#self._aiIDList)
    local sendEmojiAIID=self._aiIDList[randomAIIndex]
    Scheduler.performWithDelayGlobal(function()
        local event = {notifyData = {}}
        event.notifyData.emojiId = emojiId
        event.notifyData.emojiType = EmojiTypeString[EmojiType.Emoticon]
        event.notifyData.uid = sendEmojiAIID
        print('----------------自动回复表情的AI 玩家ID :',event.notifyData.uid)
        
        self:onReceiveEmojiMsg(event)
    end, math.random() * 2 + 2)
end

-- 设置是否有AI自动发送功能
function EmojiChatLayer:setIsAIAutoSend(AIAutoSend, aiIDList)
    self._isAIAutoSend = AIAutoSend
    self._aiIDList ={}
    self._aiIDList = aiIDList
end

-- 获取AI发送的表情的随机 Id
function EmojiChatLayer:getAISendRandomId()
    local totalRate = 0
    for i, v in pairs(AIAutoSendList) do
        totalRate = totalRate + v
    end
    local randomRate = totalRate * math.random()
    local emojiId = AIAutoSendList[1001]
    local curRate = 0
    for i, v in pairs(AIAutoSendList) do
        curRate = curRate + v
        if curRate >= randomRate then
            emojiId = i
            break
        end
    end

    return emojiId
end
return EmojiChatLayer