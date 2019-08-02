--DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
--CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = true

-- disable create unexpected global variable
--CC_DISABLE_GLOBAL = true
-- for module display
CC_DESIGN_RESOLUTION = {
    width = 750,
    height = 1500,
    --autoscale = "SHOW_ALL",
    autoscale = "NO_BORDER",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        if ratio <= 1.34 then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            return {autoscale = "NO_BORDER"}
            --return {autoscale = "SHOW_ALL"}
        end
    end
    --]]
}