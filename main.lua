function love.load()

    wf = require 'libraries/windfield'

    world = wf.newWorld(0, 0 )
    
    -- Set up collision classes
    world:addCollisionClass('Player')
    world:addCollisionClass('Wall', {ignores = {'Wall'}})  -- Walls don't collide with each other
    

    camera = require 'libraries/camera'
    cam = camera()



    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter('nearest', 'nearest')  
    


    sti = require 'libraries/sti'

    gameMap = sti('maps/testMap.lua')
    
    sounds = {}
    sounds.blip = love.audio.newSource("sounds/blip.wav", "static")
    sounds.blip:setVolume(1.0)  -- Set to maximum volume (0.0 to 1.0)
    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.1)  -- Set music volume lower (0.0 to 1.0)

    -- Load custom font (Tan Nimbus) - adjust size as needed (24 is the font size)
    local success, customFont = pcall(love.graphics.newFont, "fonts/TanNimbus.ttf", 24)
    if success then
        font = customFont
    else
        -- Fallback to default font with larger size if Tan Nimbus font file not found
        font = love.graphics.newFont(24)
        
    end
 

    player = {}
    player.x = 400
    player.y = 250
    player.scale = 0.75  -- 25% smaller (75% of original size)
    player.collider = world:newBSGRectangleCollider(player.x, player.y, 113 * player.scale, 167 * player.scale, 10 * player.scale)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('Player')
    player.speed = 300
    player.sprite = love.graphics.newImage("sprites/cat.png")
    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")

    player.grid = anim8.newGrid(113, 167, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    player.animations = {}

    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)
    
    player.anim = player.animations.left



    background = love.graphics.newImage("sprites/background.png")

    walls = {}
    if gameMap.layers["walls"] then
        for i, obj in pairs(gameMap.layers["walls"].objects) do
            -- Skip objects with invalid dimensions (Box2D requires area > epsilon)
            if obj.width > 0 and obj.height > 0 then
                local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                wall:setType('static')
                wall:setCollisionClass('Wall')
                table.insert(walls, wall)
            end
        end
    end


    sounds.music:play()
end 


function love.update(dt)

    local isMoving = false

    local vx, vy = 0, 0


    if love.keyboard.isDown("right") then
        vx = player.speed
        player.anim = player.animations.right
        isMoving = true
    end 

    if love.keyboard.isDown("left") then
        vx = player.speed * -1
        player.anim = player.animations.left
        isMoving = true
    end

    if love.keyboard.isDown("down") then
        vy = player.speed
        player.anim = player.animations.down
        isMoving = true
    end

    if love.keyboard.isDown("up") then
        vy = player.speed * -1
        player.anim = player.animations.up
        isMoving = true
    end

    if isMoving then
        player.collider:setLinearVelocity(vx, vy)
    else
        player.collider:setLinearVelocity(0, 0)
        player.anim:gotoFrame(2)
    end

    world:update(dt)

    -- Check for collision with walls and play sound
    if player.collider:enter('Wall') then
        sounds.blip:stop()  -- Stop any existing blip sound to allow immediate replay
        sounds.blip:play()
    end

    player.x = player.collider:getX()
    player.y = player.collider:getY()

    player.anim:update(dt)


    cam:lookAt(player.x, player.y)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then
        cam.x = w/2
    end
    if cam.y < h/2 then
        cam.y = h/2
    end
    
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    if cam.x > mapW - w/2 then
        cam.x = mapW - w/2
    end
    if cam.y > mapH - h/2 then
        cam.y = mapH - h/2
    end

    
    
end

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["ground"])
        gameMap:drawLayer(gameMap.layers["trees"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, player.scale, player.scale, 83.75, 56.5)
        --world:draw()
    cam:detach()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0, 0)  -- Bright red (R, G, B)
    love.graphics.print("ArQ", 10, 10)
    love.graphics.setColor(1, 1, 1)  -- Reset to white so other graphics aren't affected
end
