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
physics.setGravity(0,0)

if(debug) then
    physics.setDrawMode( "hybrid" )
end

local mathlibapi = require("mathlib")

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH = display.contentWidth, display.contentHeight
local halfW, halfH = screenW * 0.5, screenH * 0.5
local globeRadius = screenH * 0.25
local globeX, globeY = halfW, halfH

local globe = display.newImageRect("globe.jpg", 300, 300)

local LEVEL_FILE = "level.txt"
local ASTEROID_VELOCITY = 50
local asteroids = {}

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
--
-----------------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
    asteroids = scene:loadAsteroidsFile()
    scene:createAsteroidsCallbacks() -- on game start...

    local group = self.view

	-- create a grey rectangle as the backdrop
    local background = display.newRect(0, 0, screenW, screenH)
    background:setFillColor(100, 125, 255, 255)

    globe.x, globe.y = halfW, halfH
    physics.addBody(globe, { density = 1.0, friction = 0.3, bounce = 0.5, radius = globeRadius })
    globe:addEventListener("touch", globe)

    -- Add center fake "mouse" joint to pin to center of screen.
    globe.centerJoint = physics.newJoint("touch", globe, halfW, halfH )
    globe.centerJoint.maxForce = 400000 -- Set high maxforce to minimize jiggle

    -- all display objects must be inserted into group
	group:insert( background )
    group:insert( globe )
end

function scene:loadAsteroidsFile()
    local path = system.pathForFile( LEVEL_FILE, system.ResourceDirectory )
    local file = io.open( path, "r" )

    local waves = {}
    for line in file:lines() do
        table.insert(waves, ParseCSVLine(line, ','))
    end
    io.close( file )
    return waves
end

function scene:createAsteroidsCallbacks()
    local asteroidCreationDelay = 0 -- in ms

    for index, wave in ipairs(asteroids) do
        for index, value in ipairs(wave) do
            if index == 1 then
                asteroidCreationDelay = value
            else
                if(value == 'o') then
                    local closure = function() return scene:addAsteroid( index * 90 ) end
                    timer.performWithDelay(asteroidCreationDelay, closure)
                end
            end
        end
    end
end

function scene:delayDestroy(asteroid)
end

function scene:addAsteroid(angle)
    local point = {x = globeX + globeRadius + 100, y = globeY}
    local center = {x = globeX, y = globeY }

    local spawnLocation = rotateAboutPoint(point, center, angle, false)

    local asteroid = display.newCircle(spawnLocation.x, spawnLocation.y, 10)
    physics.addBody(asteroid, {radius = 10})

    local velocityPair = rotatePoint({x= (-1) * ASTEROID_VELOCITY,y=0},angle)

    asteroid:setLinearVelocity(velocityPair.x,velocityPair.y)
    asteroid.isAsteroid = true

    local group = self.view
    group:insert(asteroid)

    function asteroid:postCollision( self, event )
        asteroid:delayDestroy()
    end

    function asteroid:delayDestroy()
        local closure = function()
            if not (asteroid.removeSelf == nil) then
                asteroid:removeSelf()
                -- Put scoring here
            end
        end
        timer.performWithDelay(50, closure)
    end

    asteroid:addEventListener("postCollision", asteroid)
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

function ParseCSVLine (line,sep)
    local res = {}
    local pos = 1
    sep = sep or ','
    while true do
        local c = string.sub(line,pos,pos)
        if (c == "") then break end
        if (c == '"') then
            -- quoted value (ignore separator within)
            local txt = ""
            repeat
                local startp,endp = string.find(line,'^%b""',pos)
                txt = txt..string.sub(line,startp+1,endp-1)
                pos = endp + 1
                c = string.sub(line,pos,pos)
                if (c == '"') then txt = txt..'"' end
                -- check first char AFTER quoted string, if it is another
                -- quoted string without separator, then append it
                -- this is the way to "escape" the quote char in a quote. example:
                --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
                until (c ~= '"')
            table.insert(res,txt)
            assert(c == sep or c == "")
            pos = pos + 1
        else
            -- no quotes used, just look for the first separator
            local startp,endp = string.find(line,sep,pos)
            if (startp) then
                table.insert(res,string.sub(line,pos,startp-1))
                pos = endp + 1
            else
                -- no separator found -> use rest of string and terminate
                table.insert(res,string.sub(line,pos))
                break
            end
        end
    end
    return res
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