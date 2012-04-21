-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local debug = true

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()

if(debug) then
    physics.setDrawMode( "hybrid" )
end

local mathlibapi = require("mathlib")

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH = display.contentWidth, display.contentHeight
local halfW, halfH = screenW * 0.5, screenH * 0.5
local globeRadius = screenH * 0.25
local globeX, globeY = halfW

local globe = display.newImageRect("globe.jpg", 300, 300)


-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
--
-----------------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view

	-- create a grey rectangle as the backdrop
    local background = display.newRect(0, 0, screenW, screenH)
    background:setFillColor(100, 125, 255, 255)

    globe.x, globe.y = halfW, halfH
    physics.addBody(globe, { density = 1.0, friction = 0.3, bounce = 0.3, radius = globeRadius })
    globe:addEventListener("touch", globe)

    -- Add center fake "mouse" joint to pin to center of screen.
    globe.centerJoint = physics.newJoint("touch", globe, halfW, halfH )
    globe.centerJoint.maxForce = 400000 -- Set high maxforce to minimize jiggle

    -- all display objects must be inserted into group
	group:insert( background )
    group:insert( globe )
end


function globe:touch(event)
end

function loadAsteroidsFile( event )
    local LEVEL_FILE = "myfile.txt"
    local path = system.pathForFile( LEVEL_FILE, system.DocumentsDirectory )
    local file = io.open( path, "r" )

    for line in file:lines() do
        print( line )
    end

    io.close( file )
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view

	physics.start()

end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view

	physics.stop()

end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view

	package.loaded[physics] = nil
	physics = nil
end

function onScreenTouch(event)
    local ex = event.x
    local ey = event.y

    if(globe.touchJoint and globe.touchJoint.maxForce) then
        if event.phase == "moved" then
            globe.touchJoint:setTarget( ex, ey)
        end
        if event.phase == "ended" or event.phase == "cancelled" then
            globe.touchJoint:removeSelf()
        end
    end
    if event.phase == "began" then
        if globe.touchJoint and globe.touchJoint.maxForce then
            globe.touchJoint:removeSelf()
        end
        globe.touchJoint = physics.newJoint( "touch", globe, event.x, event.y )
        globe.touchJoint.maxForce = 4000
    end
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

Runtime:addEventListener("touch", onScreenTouch)

-----------------------------------------------------------------------------------------

return scene