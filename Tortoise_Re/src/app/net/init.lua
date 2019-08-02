require("app.net.CMD")
require("app.net.NetMgr")

local basePBFilePath = cc.FileUtils:getInstance():fullPathForFilename("res/pb/game.pb")
local basebuffer = read_protobuf_file_c(basePBFilePath)
protobuf.register(basebuffer)