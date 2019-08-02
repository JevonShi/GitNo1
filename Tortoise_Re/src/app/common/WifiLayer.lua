--[[
-------------------------------
1-wifi信号坐标
2-wifi信号图片
3-提示字体样式和多语言
4-网络事件监听 ping,error,close,connected

5-游戏结束关闭监听(close不用处理)
----------------------------------------------------------
local WifiLayer = require("app.common.WifiLayer")
self:addChild(WifiLayer:create(),1)

--------------------------------------------------------------
]]--
--local LoadingLayer = require("app.common.LoadingLayer")
WifiRes = {
    --- 2 信号图片 提示字体
    backImageName="res/images/common/zhiyingkuang.png",
    backImageName2="res/images/common/tipssanjiao.png",
    iconImageName="res/images/common/wifi1.png",
    errorImageName = "res/images/common/wangluotishidi1.png",
    wifiBtnImage ="res/images/common/tmd.png",
    textTip1=tr("If you have these 2, there will be a significant delay in the operation"),
    textTip2=tr("Bad connection with your opponent"),
    textTip3=tr("Network unavailable"),
    textTip4=tr("Reconnect successfully"),
    textTip5=tr("Network reconnection")
}

--! 信号强度
local SignalPower = {
    kLevel1 = 1,
    kLevel2 = 2,
    kLevel3 = 3,
    kLevel4 = 4
}

        -- { image="res/images/common/1.png", text=tr("Network stability, no delay") },
        -- { image="res/images/common/2.png", text=tr("Network stability, almost no delay") },
        -- { image="res/images/common/3.png", text=tr("Operation may be delayed")    },
        -- { image="res/images/common/4.png", text=tr("Serious operation delay")     }

--! 
local basePath = "res/images/common/"
--! ui配置
local arrSignalConfig = {
    [SignalPower.kLevel1] = { mobile="xinhao4.png", mobileEx="4.png", wifi="wifi1.png", wifiEx="wifi5-4.png", color=cc.c3b(255,0,0),      tips=tr("Serious operation delay")},
    [SignalPower.kLevel2] = { mobile="xinhao3.png", mobileEx="3.png", wifi="wifi2.png", wifiEx="wifi5-3.png", color=cc.c3b(0xff, 0x7e,0), tips=tr("Operation may be delayed")},
    [SignalPower.kLevel3] = { mobile="xinhao2.png", mobileEx="2.png", wifi="wifi3.png", wifiEx="wifi5-2.png", color=cc.c3b(0,255,0), tips=tr("Network stability, almost no delay")},
    [SignalPower.kLevel4] = { mobile="xinhao1.png", mobileEx="1.png", wifi="wifi4.png", wifiEx="wifi5-1.png", color=cc.c3b(0,255,0), tips=tr("Network stability, no delay")}
}

local bTip = false
local wifiToast = "wifi_tip_toast"
local nameOfToastError = "nameOfToastError"
local M = class("WifiLayer", function()
    return display.newLayer()
end)
function M:ctor(x,y)
    local size  = cc.Director:getInstance():getWinSize()
    self.positionY = size.height- 107 -- 1 信号坐标
    self.positionX = size.width - 250
    if x ~=nil and y~= nil then
        self.positionX = x
        self.positionY = y
    end
    self.tipToast = nil
    self.lastPingValue = 300           --! 最近一次的ping值
    self:initIcon()
    self:registerEventListener()
    self.bReconect = false
    
end

function M:initIcon( ... )
  self:onGamPing({notifyData=40})
  self:refreshUI(SignalPower.kLevel4)
end

--! 刷新函数 
function M:refreshUI( signalPower )
    local nameOfSignal = "nameOfSignal"
    self:removeChildByName(nameOfSignal)                     --! 移除之前的


    --! 默认最弱
    if signalPower == nil or tonumber(signalPower) == nil then
        signalPower = SignalPower.kLevel1
    end

    local size = cc.Director:getInstance():getWinSize()
    local x =0
    local y =0

    local node = cc.Node:create()
    node:setPosition(cc.p(self.positionX,self.positionY))
    node:setName(nameOfSignal)
    self:addChild(node)

    --! 信号类型
    local signalType = HYGameBridge:getInstance():getNetworkStatus()
    if signalType == nil or signalType==Network.NONE then
        signalType = Network.MOBILE
    end
    --! 外框图片
    local fileFrame = basePath.."wifidi.png"
    local sprFrame  = cc.Sprite:create(fileFrame)
    node:addChild(sprFrame)

    local sizeOfFrame = sprFrame:getContentSize()

    --! 图片颜色
    local color = arrSignalConfig[signalPower].color

    for k, v in pairs(arrSignalConfig) do
        if k <= signalPower then
            local filePath = basePath..v.mobile
            if signalType == Network.WIFI then
                filePath = basePath..v.wifi
            end
            local sprIcon    = cc.Sprite:create(filePath)
            local sizeOfIcon = sprIcon:getContentSize()
            sprIcon:setColor(color)
            sprIcon:setPosition(6+sizeOfIcon.width/2, sizeOfFrame.height/2)
            sprFrame:addChild(sprIcon)
        end        
   end

    --! 300ms
    local lbPing = display.newTTFLabel({     
        text = self.lastPingValue.."ms",
        font = "",
        size = 15,
        color = color
    })        
    local sizeOfLabel = lbPing:getContentSize()
    lbPing:setPosition(cc.p(sizeOfFrame.width-6-sizeOfLabel.width/2, sizeOfFrame.height/2))
    sprFrame:addChild(lbPing)

    --! 
    local btn  = ccui.Button:create(fileFrame, fileFrame)
    btn:setPosition(cc.p(sprFrame:getPosition()))
    btn:setScale9Enabled(true)
    btn:setOpacity(0)
    btn:setContentSize(cc.size(sizeOfFrame.width, sizeOfFrame.height*2))
    btn:addTouchEventListener(function(sender, eventType)
               if eventType== 2 and self.tipToast == nil then
                self:showWifiDetailDailog(WifiRes.textTip1)
            end
        end)
    node:addChild(btn)

    self.node = node
end
-----------------4-网络事件监听 -------------------
function M:registerEventListener( ... )
     eventCenter:on("SKEVNT_ERROR" , function(e)
        self:onSocketError()
    end , "WifiLayer")

    eventCenter:on("SKEVNT_PING" , function(e)
        self:onGamPing(e.msg)
    end , "WifiLayer")

    eventCenter:on("SKEVNT_CONNECTED" , function(e)
        self:onConnected(e.msg)
    end , "WifiLayer")

    eventCenter:on("SKEVNT_CLOSE" , function(e)
        self:onSocketClosed(e.msg)
    end , "WifiLayer")

    eventCenter:on("SKEVNT_STATUSE" , function(e)
        self:refreshUI(e.msg)
    end , "WifiLayer")

end

--------------5-游戏结束关闭监听
function M:removeListener( ... )
    eventCenter:removeEventListenersByTag("WifiLayer")
end

function M:onConnected( ... )
    --LoadingLayer.hide()
    if self.bReconect then
        self:showError(WifiRes.textTip4)
    end
    self.bReconect = false
end

function M:onSocketClosed( ... )
    self:showError(WifiRes.textTip3)
   -- LoadingLayer.show()
    self.bReconect = true
end

    function M:onGamPing(data)
    self.lastPingValue = math.floor(data.notifyData)
    if self.lastPingValue>250 then
        self:changeState(SignalPower.kLevel1)
    elseif self.lastPingValue >100 and self.lastPingValue<=250 then
        self:changeState(SignalPower.kLevel2)
    elseif self.lastPingValue> 40 and self.lastPingValue<=100 then
        self:changeState(SignalPower.kLevel3)
    elseif self.lastPingValue<= 40 then
        self:changeState(SignalPower.kLevel4)
    else    
    end

end

function M:onSocketError()
    self:showError(WifiRes.textTip3)
end
function M:showError(msg)                     --! 移除 之前的
    local node = self:initErrorView(msg)
    node:setName(nameOfToastError)
    return node
end
function M:initErrorView(msg)
    --- 适配界面
    local view = cc.Director:getInstance():getOpenGLView()
    local visibleSize = view:getVisibleSize()
    local visibleOrigin = view:getVisibleOrigin()

    local size  = cc.Director:getInstance():getWinSize()
    local toast = ccui.Scale9Sprite:create(WifiRes.errorImageName )   -- 底框

    local tipText = display.newTTFLabel({               -- ToastUtil.label:clone()                     -- label 从cocostudio 加载
        text = msg,
        font = "",
        size = 28,
        color = cc.c3b(255, 255, 255)
    })        
    tipText:enableOutline(cc.c4b(255,255,255,255), 2)
    tipText:setAnchorPoint(cc.p(0.5, 0.5))
    toast:addChild(tipText)
    local textWidth = tipText:getContentSize().width
    if textWidth>size.width-50 then
        tipText:setDimensions(size.width-50, 0)
    end
    
    local textHeight = tipText:getContentSize().height+10
    local tSize = toast:getContentSize()
    if textHeight < tSize.height then
        textHeight = tSize.height
    end
    cc.Director:getInstance():getRunningScene():addChild(toast,10003)
    toast:setPosition(cc.p(size.width/2, visibleOrigin.y + visibleSize.height-textHeight/2 ))

    tipText:setPosition( cc.p( size.width/2, textHeight/2+5 ) )

    toast:setPreferredSize(cc.size(size.width,textHeight))
    tipText:runAction(cc.Sequence:create(
        cc.DelayTime:create(2),
        cc.FadeOut:create(0.5),
        cc.CallFunc:create(function ( ... )
            toast:removeFromParent()
        end)
    ))
    return toast
end
function M:initView(msg,name)
    local size  = cc.Director:getInstance():getWinSize()
    local toast = ccui.Scale9Sprite:create(WifiRes.backImageName)   -- 底框
    local tipText = display.newTTFLabel({     
        text = msg,
        font = "",
        size = 24,
        color = cc.c3b(0x4a, 0x4a, 0x4a),
        -- dimensions = cc.size(size.width-200, 0)
    })        

    local maxWith = 460
    if tipText:getContentSize().width > maxWith then
        tipText:setDimensions(maxWith, 0)
    end

    -- tipText:enableOutline(cc.c4b(0,0,0,255), 2)
    tipText:setAnchorPoint(cc.p(0.5, 0.5))
    toast:addChild(tipText)

    local textHeight = tipText:getContentSize().height+10
    local tSize = toast:getContentSize() -- toast:getOriginalSize()
    if textHeight < tSize.height then
        textHeight = tSize.height
    end

    local textWidth = tipText:getContentSize().width+30
    cc.Director:getInstance():getRunningScene():addChild(toast,10000) 

    tipText:setPosition( cc.p( textWidth/2, textHeight/2+5 ) )
    toast:setPreferredSize(cc.size(textWidth,textHeight))
    -- tipText:setPosition(cc.p(textWidth/2,textHeight/2))
    local bg2 = cc.Sprite:create(WifiRes.backImageName2)
    toast:addChild(bg2)
    bg2:setAnchorPoint(cc.p(0,1))
    bg2:setPosition(cc.p(textWidth-6,textHeight-bg2:getContentSize().height/2))
     -- toast:setPosition(cc.p(self.positionX-toast:getContentSize().width/2-40, 20+bg2:getContentSize().height/2-sizeOfToast.height/2+self.positionY))
    toast:setPosition(cc.p(self.positionX-toast:getContentSize().width/2-40, bg2:getContentSize().height/2-textHeight/2+self.positionY))

    tipText:runAction(cc.Sequence:create(
        cc.DelayTime:create(2.5),
        cc.FadeOut:create(0.5),
        cc.CallFunc:create(function ( ... )
            toast:removeFromParent()
            self.tipToast = nil
        end)
    ))
    toast:setName(wifiToast)
    return toast
end

local nameOfWifiDetail = "nameOfWifiDetail"
function M:removeWifiDetailDialog( ... )
    cc.Director:getInstance():getRunningScene():removeChildByName(nameOfWifiDetail)
end

function M:showWifiDetailDailog( ... )
    local size  = cc.Director:getInstance():getWinSize()
    local toast = ccui.Scale9Sprite:create(WifiRes.backImageName)   -- 底框

    --! 图文配置
    local signalType  =  HYGameBridge:getInstance():getNetworkStatus()
    if signalType == nil or signalType == Network.NONE then
        signalType = Network.MOBILE
    end

    local countOfRow  = #arrSignalConfig
    local arrTextConfig = {}
    for i=countOfRow, 1, -1 do
        local config = { image=basePath..arrSignalConfig[i].mobileEx, text=arrSignalConfig[i].tips }
        if signalType == Network.WIFI then
            config.image = basePath..arrSignalConfig[i].wifiEx
        end
        --dump(config)
        table.insert(arrTextConfig, config)
    end

    local sizeOfImage = cc.Director:getInstance():getTextureCache():addImage(arrTextConfig[1].image):getContentSize()
    local spaceY = 14
    local maxWidthOfLine = 1
    local arrLineNode = {}
    -- local countOfRow  = #arrTextConfig
    for k, v in pairs(arrTextConfig) do
        local filePath = v.image
        local strText  = v.text
        local node     = cc.Node:create()
        local sprImage = cc.Sprite:create(filePath)      --! 图片
        sprImage:setPosition(cc.p(16+sizeOfImage.width/2, 0))
        node:addChild(sprImage)
        local lbText = display.newTTFLabel({            --! 文字
            text = strText,
            font = "",
            size = 22,
            color = cc.c3b(0x4a, 0x4a, 0x4a),
            -- dimensions = cc.size(0, 0)
        })        
        local sizeOfText = lbText:getContentSize()
        lbText:setPosition(cc.p( sprImage:getPositionX() + sizeOfImage.width/2 + 6 + sizeOfText.width/2, 0 ))
        node:addChild(lbText)
        local widthOfLine = lbText:getPositionX() + sizeOfText.width/2 + 6
        if maxWidthOfLine < widthOfLine then
            maxWidthOfLine = widthOfLine
        end
        local posY = (countOfRow - k+1)*spaceY + (countOfRow-k)*sizeOfImage.height + sizeOfImage.height/2
        node:setPosition(cc.p( 0,  posY))
        toast:addChild(node)
    end

    local sizeOfToast = cc.size( maxWidthOfLine, sizeOfImage.height*countOfRow + spaceY*(countOfRow+1) )
    toast:setPreferredSize( sizeOfToast )

    local rootNode = cc.Node:create()
    rootNode:setName(nameOfWifiDetail)
    cc.Director:getInstance():getRunningScene():addChild(rootNode, 10003) 
    rootNode:addChild(toast)

     -- bg frame
    local fileButton = "res/images/common/zhiyingkuang.png"
    local btnCancel = ccui.Button:create(fileButton, fileButton, fileButton, 0)
    btnCancel:setScale9Enabled(true)
    btnCancel:setPosition(size.width/2, size.height/2)
    btnCancel:setContentSize(size)
    btnCancel:setOpacity(0)
    btnCancel:addTouchEventListener(function(sender, eventType)
        -- if 1== eventType then
            rootNode:removeFromParent()
        -- end
    end)
    rootNode:addChild(btnCancel)

    --! 3s 之后移除
    rootNode:runAction(cc.Sequence:create( cc.DelayTime:create(3), cc.RemoveSelf:create() ))

    local bg2 = cc.Sprite:create(WifiRes.backImageName2)                              --! 三角形
    toast:addChild(bg2)
    bg2:setAnchorPoint(cc.p(0,1))
    bg2:setPosition(cc.p(sizeOfToast.width-6, sizeOfToast.height-bg2:getContentSize().height/2))
    toast:setPosition(cc.p(self.positionX-toast:getContentSize().width/2-70, bg2:getContentSize().height/2-sizeOfToast.height/2+self.positionY))
    toast:setName(wifiToast)
    return toast
end

function M:showWifiToast(msg)
    if self.tipToast ~= nil then
        self.tipToast:removeFromParent()
        self.tipToast = nil
    end
    self:removeWifiDetailDialog()
    self.tipToast = self:initView(msg)
end

function M:changeState(signalPower)

    --! for test
    -- signalPower = 1

    self:refreshUI(signalPower)   

    --! 最弱 提示
    if signalPower == SignalPower.kLevel1 then

        local strKey = "WifiTips"
        local userDefault = cc.UserDefault:getInstance()
        local strVal = userDefault:getStringForKey(strKey)
        if strVal == nil or strVal == ""  then
            userDefault:setStringForKey(strKey, "show")
            self:showWifiToast(WifiRes.textTip2)  
        end
        --! 提示一次
        if bTip==false then
            self:showActions(3)
            bTip = true
        end
    end
end

function M:showActions(index)
    if index<1 then
        return
    end
    index = index -1
    local sequence = cc.Sequence:create(
        cc.ScaleTo:create(0.2,1.3),
        cc.ScaleTo:create(0.3,1),
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(function ( ... )
            self:showActions(index)
        end)
        )
    self.node:runAction(sequence)
    self.node:runAction(cc.ScreenShaker:actionWithDuration(0.2,3,3))
end
return M
