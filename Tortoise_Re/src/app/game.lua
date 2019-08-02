require("app.init")
--local audioPlay = require("hygame.audio.Audio")
local json = require("json")
local game = class("Game")
GAME_TEXTURE_DATA_FILENAME = "Pack_1.plist"
GAME_TEXTURE_IMAGE_FILENAME = "Pack_1.png"

local BG_SOUND_RES = "sounds/bg.mp3"

G_BgId = 0


function CCSPlayAction(node,animation_name,index,loop)
	node:setVisible(true)
    print('----animation_name :',animation_name)
    local csbAnimation = cc.CSLoader:createNode(animation_name..".csb")
    local csbAnimationTimeLine = cc.CSLoader:createTimeline(animation_name..".csb")
    node:addChild(csbAnimation,10)

 	local csz = node:getContentSize()
    print('---------------csb',csbAnimation)
    print('----csbAnimationTimeLine :',csbAnimationTimeLine)
    csbAnimation:runAction(csbAnimationTimeLine)
    --csbAnimation:setPositionX(csz.width * 0.5)
    --csbAnimation:setPositionY(csz.height * 0.5)
    csbAnimationTimeLine:gotoFrameAndPlay(index and index or 0,loop)
end

function CCSTime(node,time,fun)
	node:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.CallFunc:create(fun)))
end



--随机种子
math.randomseed(tostring(os.time()):reverse():sub(1, 7))

--[[
]]

function game:startup()
    --播放背景音乐
    --local fullpath = cc.FileUtils:getInstance():fullPathForFilename(BG_SOUND_RES)
    --G_BgId = audioPlay.play(fullpath,true,0.5)

	HYGameBridge:getInstance():gameStart()
    cc.FileUtils:getInstance():addSearchPath("res/")
    --加载图集
    display.loadSpriteFrames(GAME_TEXTURE_DATA_FILENAME, GAME_TEXTURE_IMAGE_FILENAME)

    self:enterMainScene()
end

function game:enterMainScene()
   -- display.replaceScene(require("app.scenes.MainScene").new(), "fade", 0.6, display.COLOR_WHITE)
   print('-------------加载场景------------')
   display.replaceScene(require("app.scenes.TortoiseScene").new(),"fade", 0.6, display.COLOR_WHITE)
end



return game
