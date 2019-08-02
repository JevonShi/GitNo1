
-- 是否开启debug模式
kIsDebug = true
if kIsDebug then
    package.path = package.path .. ";src/?.lua"
    local breakSocketHandle, debugXpCall = require("LuaDebug")("localhost", 7003)
    function __G__TRACKBACK__(errorMessage)
        debugXpCall()
        print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
        print(debug.traceback("", 2))
    end

    cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakSocketHandle, 0.3, false)
else
    function __G__TRACKBACK__(errorMessage)
        print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
        print(debug.traceback("", 2))
    end
end

-- game controller
package.path = package.path .. ";src/?.lua"
cc.FileUtils:getInstance():addSearchPath("res/")

xpcall(function()
    require("app.game").new():startup()
end, __G__TRACKBACK__)
