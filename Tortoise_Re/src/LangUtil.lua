-- ------------------------------------------------------
local textMap = {}

s_lang = HYGameBridge.getInstance():getLanguage()
--! 初始化
function initTranslation()
    local lang = s_lang--HYGameBridge.getInstance():getLanguage() -- cc.NativeBridge:getInstance():getLanguage()
    local defaultPath = "res/lang/en_us/text.txt"
    local path = "res/lang/"..lang.."/text.txt"

    --print("android: lang path:"..path,s_lang)
   
    if not cc.FileUtils:getInstance():isFileExist(path) then
        path = defaultPath
    end

    local strJson = cc.FileUtils:getInstance():getStringFromFile(path)
    --dump(strJson,'-------------------------strJson :')
    if strJson ~= nil and strJson ~= "" then
        textMap = json.decode(strJson)
    end
    
end

function changeTranslation( lang )
    s_lang = lang
    local defaultPath = "res/lang/en_us/text.txt"
    local path = "res/lang/"..lang.."/text.txt"
   -- print("android: lang path:"..path)

    if not cc.FileUtils:getInstance():isFileExist(path) then
        path = defaultPath
    end

    local strJson = cc.FileUtils:getInstance():getStringFromFile(path)
    if strJson ~= nil and strJson ~= "" then
        textMap = json.decode(strJson)
    end


end

--! 翻译 功能函数
function tr( key )
    if textMap == nil then
        return key
    end

    if textMap[key] ~= nil then
        return textMap[key]
    end
    return key 
end

--! 获取语言对应的ttf
-- en_us : 英文 美国            游戏支持
-- zh_cn : 中文                 游戏支持
-- hi_in : 印地语 -- 印度       游戏支持
-- es_es  : 西班牙语            游戏支持
-- ar_sa  : 阿拉伯语            游戏支持
-- pt_br  : 葡萄牙语--巴西      游戏支持

local ttfMap = {}
ttfMap["zh_cn"] = ""      --! 默认系统字体
ttfMap["en_us"] = "res/fnt/SansSerifExbFLF.ttf"   
ttfMap["hi_in"] = ""      --! 默认系统字体
ttfMap["es_es"] = "res/fnt/SansSerifExbFLF.ttf"   
ttfMap["pt_br"] = "res/fnt/SansSerifExbFLF.ttf"   
ttfMap["ar_sa"] = ""      --! 默认系统字体

--! 获取默认的ttf文件，没有则返回""
function langTTFPath(  )
    local lang = s_lang--HYGameBridge.getInstance():getLanguage() -- cc.NativeBridge:getInstance():getLanguage()

    local ttfPath = ttfMap[lang]
    if ttfPath == nil then
        ttfPath = ""
    end
    print("android: lang:"..lang.." ttfPath:"..ttfPath)
    return ttfPath
end

--! require的时候直接加载
initTranslation()
---------------------------------------------------------------