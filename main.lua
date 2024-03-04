Input = require('libraries.boipushy.Input')
anim8 = require('libraries.anim8.anim8')


function love.load()
	fBirdPosition = 0.0
	fBirdVelocity = 0.0
	fBirdAcceleration = 0.0
	fGravity = 200.0
	fLevelPosition = 1500.0 

	fSectionWidth = 0.0
	listSection = { 0, 0, 0, 0, 0}

	bHasCollided = false
	bResetGame = false
    bGameOver = false

	nAttemptCount = 0
	nFlapCount = 0
	nMaxFlapCount = 0
    nScore = 0

    nUnitSize = 12
    SCREEN_WIDTH = 80 * nUnitSize
    SCREEN_HEIGHT = 48 * nUnitSize

    nBirdX = SCREEN_WIDTH / 3.0

    love.window.setTitle("LÖVE Flappy Bird")
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

    bResetGame = true
    fSectionWidth = SCREEN_WIDTH / (#listSection - 1)
    sounds = {}
    sounds.hit = love.audio.newSource("assets/sfx/hit.wav", "static")
    sounds.hit:setVolume(1)
    sounds.point = love.audio.newSource("assets/sfx/point.wav", "static")
    sounds.point:setVolume(1)
    sounds.wing = love.audio.newSource("assets/sfx/wing.wav", "static")
    sounds.wing:setVolume(1)

    input = Input()
    input:bind('space', 'space')
    input:bind('1', '1')
    input:bind('2', '2')
    input:bind('3', '3')
    input:bind('4', '4')
    input:bind('5', '5')
    input:bind('6', '6')
    input:bind('escape', 'escape')

    PIPE_IMG = love.graphics.newImage("assets/sprite/pipe-red.png")
    PIPE_IMG_I = love.graphics.newImage("assets/sprite/pipe-red-i.png")
    BG_IMG = love.graphics.newImage("assets/sprite/background-day.png")
    BASE_IMG = love.graphics.newImage("assets/sprite/base.png")
    BIRD_IMG = love.graphics.newImage("assets/sprite/bird.png")
    local birdGrid = anim8.newGrid(34, 24, BIRD_IMG:getWidth(), BIRD_IMG:getHeight())
    birdAnim = anim8.newAnimation(birdGrid('1-3',1), 0.1)
    GAME_OVER_IMG = love.graphics.newImage("assets/sprite/gameOver_bg.png")
    BASIC_FONT = love.graphics.newFont("assets/fonts/04B_19.ttf", 32)
end

function love.update(dt)
    if bResetGame then
        bHasCollided = false
        bResetGame = false
        listSection = { 0, 0, 0, 0, 0}
        fSectionWidth = SCREEN_WIDTH / (#listSection - 1)
        fBirdAcceleration = 0.0
        fBirdVelocity = 0.0
        fBirdPosition = SCREEN_HEIGHT / 2.0
        nFlapCount = 0
        nAttemptCount = nAttemptCount + 1
        bGameOver = false
        fLevelPosition = 500.0
        nScore = 0
    end


    if bHasCollided then
        -- Do nothing until user releases space
        bGameOver = true
        if input:released("space") then 
            bResetGame = true 
        end
    elseif not bGameOver then
        if input:pressed("space") and (fBirdVelocity >= (fGravity / 40.0) )then
            sounds.wing:play()
            fBirdAcceleration = 0.0
            --fBirdVelocity = -fGravity / 2
            fBirdVelocity = -100
            nFlapCount = nFlapCount + 1
            if nFlapCount > nMaxFlapCount then 
                nMaxFlapCount = nFlapCount
            end
        else
            fBirdAcceleration = fBirdAcceleration + (fGravity * dt)
        end

        if fBirdAcceleration >= fGravity then 
            fBirdAcceleration = fGravity
        end

        fBirdVelocity = fBirdVelocity + (fBirdAcceleration * dt)
        fBirdPosition = fBirdPosition + (fBirdVelocity * dt)
        fLevelPosition = fLevelPosition + (14.0 * dt * nUnitSize)

        if fLevelPosition > fSectionWidth then
            fLevelPosition = fLevelPosition - fSectionWidth
            table.remove(listSection, 1)
            local i = love.math.random(0, SCREEN_HEIGHT - (20 * nUnitSize))
            if i <= (10 * nUnitSize) then i = 0 end
            table.insert(listSection, i)
        end
        handlePlayerInput()
        checkCollision()
    end

    birdAnim:update(dt)
end

function love.draw()
    drawBackground()
    drawSections()
    drawBase()
    drawBird() 
    drawScore()
    if bGameOver then
        drawGameOver()
    end
end

function drawBackground()
    love.graphics.draw(BG_IMG, 0, 0)
end

function drawSections()
    local nSection = 0
    local nGapSize = 8 * nUnitSize
    for idx, value in pairs(listSection) do
        if value ~= 0 then
            local xPos =  nSection * fSectionWidth + 10 * nUnitSize - fLevelPosition                 
            love.graphics.draw(PIPE_IMG, xPos,   SCREEN_HEIGHT - value)
            love.graphics.draw(PIPE_IMG_I, xPos, SCREEN_HEIGHT - value - nGapSize - PIPE_IMG_I:getHeight())
            if math.floor(xPos + PIPE_IMG:getWidth() / 2) == math.floor(nBirdX) then
                nScore = nScore + 1
                if (nScore % 5) == 0 then
                    local i = love.math.random(0, SCREEN_HEIGHT - (20 * nUnitSize))
                    if i <= (10 * nUnitSize) then i = 0 end
                    table.insert(listSection, i)
                end
                sounds.point:play()
            end
        end
        nSection = nSection + 1
    end
end

function drawBase()
    love.graphics.draw(BASE_IMG, 0, SCREEN_HEIGHT - BASE_IMG:getHeight())
end

function drawBird() 
    birdAnim:draw(BIRD_IMG, nBirdX, fBirdPosition)
end

function drawGameOver()
    love.graphics.draw(GAME_OVER_IMG, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 0, 1, 1, GAME_OVER_IMG:getWidth() / 2, GAME_OVER_IMG:getHeight() / 2)
end

function drawScore()
    love.graphics.setFont(BASIC_FONT)
    love.graphics.print("Score : "..nScore, 0, 0)

    local font = love.graphics.getFont()
    local gravityText = "Gravity : "..fGravity
    local textWidth = font:getWidth(gravityText)
    love.graphics.print(gravityText, SCREEN_WIDTH - textWidth, 0)
end

function checkCollision()
    --collide with base
    if fBirdPosition + BIRD_IMG:getHeight() > SCREEN_HEIGHT - BASE_IMG:getHeight() then
        sounds.hit:play()
        bHasCollided = true
    end

    local nBirdWidth = (BIRD_IMG:getWidth() / 3) - 5
    local nBirdHeight = BIRD_IMG:getHeight() - 5
    local nSection = 0
    local nGapSize = 8 * nUnitSize
    for idx, value in pairs(listSection) do
        if value ~= 0 then
            local nPipeXPos       = nSection * fSectionWidth + 10 * nUnitSize - fLevelPosition
            local nPipeWidth      = PIPE_IMG_I:getWidth()
            local nPipeHeight     = PIPE_IMG_I:getHeight()
            local nBottomPipeYPos = SCREEN_HEIGHT - value  
            local nTopPipeYPos    = SCREEN_HEIGHT - value - nGapSize - PIPE_IMG_I:getHeight()               
            --bottom
            if nBirdX          < nPipeXPos + nPipeWidth and 
               nPipeXPos       < nBirdX + nBirdWidth and
               fBirdPosition   < nBottomPipeYPos + nPipeHeight and
               nBottomPipeYPos < fBirdPosition + nBirdHeight then
                sounds.hit:play()
                bHasCollided = true
            end
            --top
            if nBirdX          < nPipeXPos + nPipeWidth and 
               nPipeXPos       < nBirdX + nBirdWidth and
               fBirdPosition   < nTopPipeYPos + nPipeHeight and
               nTopPipeYPos < fBirdPosition + nBirdHeight then
                sounds.hit:play()
                bHasCollided = true
            end
        end
        nSection = nSection + 1
    end
end

function handlePlayerInput()
    if input:released("1") then 
        fGravity = 100
    elseif input:released("2") then
        fGravity = 200
    elseif input:released("3") then
        fGravity = 300
    elseif input:released("4") then
        fGravity = 400
    elseif input:released("5") then
        fGravity = 500
    elseif input:released("6") then
        fGravity = 600
    elseif input:released("escape") then
        love.event.quit()
    end
end