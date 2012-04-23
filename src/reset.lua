local storyboard = require("storyboard")
local scene = storyboard.newScene()

function scene:createScene(event)
    local group = self.view
end

function scene:enterScene(event)
    local group = self.view
    storyboard.purgeScene("level1")
    storyboard.gotoScene("level1", fade, 250)
end

function scene:exitScene()
    local group = self.view
end

function scene:destroyScene()
    local group = self.view
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene