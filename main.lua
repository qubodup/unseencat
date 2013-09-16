function love.load()

  anim8 = require("lib/anim8")

  success = love.graphics.setMode(800, 600)

  -- images
  imgBackground = love.graphics.newImage("data/bg.png")
  spriteAnimals = love.graphics.newImage("data/player.png")
  spriteAlert = love.graphics.newImage("data/alarm.png")

  -- cat
  posCat = { 300, 300 }
  centerCat = { 0, 0 } -- will be updated a load end anyway
  moveCat = { 0, 0 }
  speedCat = 2

  -- stats
  miceEaten = 0
  gongplayed = false

  -- sounds
  sounds = {
    noms = {
      love.audio.newSource("data/cat-nom1.ogg"),
      love.audio.newSource("data/cat-nom2.ogg"),
    },
    hm = {
      love.audio.newSource("data/speedmouse-hm1.ogg"),
      love.audio.newSource("data/speedmouse-hm2.ogg"),
    },
    detect = {
      love.audio.newSource("data/speedmouse-detect1.ogg"),
      love.audio.newSource("data/speedmouse-detect2.ogg"),
      love.audio.newSource("data/speedmouse-detect3.ogg"),
    },
    lost = {
      love.audio.newSource("data/speedmouse-lost1.ogg"),
      love.audio.newSource("data/speedmouse-lost2.ogg"),
      love.audio.newSource("data/speedmouse-lost3.ogg"),
    },
    gong = love.audio.newSource("data/gong.ogg"),
    meowtalk = love.audio.newSource("data/meowloop.ogg"),
  }

  --love.graphics.setColor(255, 255, 255)
  --love.graphics.setBackgroundColor(33, 33 ,33)

  -- cat
  gridCat = anim8.newGrid(48,48, 128, 64)
  animCat = anim8.newAnimation(gridCat('1-2', 1), .1)

  -- alarm
  alertYellow = love.graphics.newQuad( 0, 0, 32, 32, 64, 32 )
  alertRed = love.graphics.newQuad( 32, 0, 32, 32, 64, 32 )

  -- mice
  gridMouse = anim8.newGrid(32,32, 128, 64)
  mice = {}
  miceCount = 30

  -- game state
  gamestate = "pregame" -- can also be "ingame" and "postgame"

end

function startPlay()

  gamestate = "ingame"

  sounds.gong:stop()
  sounds.gong:play()

  -- initiate mice
  for i = 1, miceCount do
    mice[i] = {
      pos = { math.random(0, 39) * 20, math.random(1, 31) * 16 + 32 },
      center = {},
      move = { 0, 0 },
      timerChoice = math.random(2,4),
      timerSpotted = 0,
      timerAlarmed = 0,
      anim = anim8.newAnimation(gridMouse(4, '1-2'), (math.random() / 10) * 2 ),
      status = "normal", -- normal, spotted, alarmed
    }
  end

  -- update center coordinates of cat and mice
  updateCenter()

end

function updateMice(dt)
  for i,v in ipairs(mice) do

    local catIsNear = distance( v.center, centerCat ) < 100
    -- cat discovery logic
    if catIsNear then

      --status = "normal", -- normal, spotted, alarmed
      -- normal to spotted
      if v.status == "normal" then
        mice[i].status = "spotted"
        mice[i].timerSpotted = 1
        -- surprise sound
        local j = math.random(1,2)
        sounds.hm[j]:stop()
        sounds.hm[j]:play()
      end
    end

    -- spotted to alarmed and spotted to normal
    if v.status == "spotted" and v.timerSpotted <= 0 then
      mice[i].timerSpotted = 0
      if catIsNear then
        mice[i].timerAlarmed = 3
        mice[i].status = "alarmed"
        local j = math.random(1,3)
        --sounds.detect[j]:stop()
        --sounds.detect[j]:play()
        if sounds.detect[j]:isStopped() then sounds.detect[j]:play() end
      else
        mice[i].status = "normal"
        local j = math.random(1,3)
        --sounds.lost[j]:stop()
        if sounds.lost[j]:isStopped() then sounds.lost[j]:play() end
      end
    end

    -- alarmed to normal
    if v.status == "alarmed" and v.timerAlarmed <= 0 then
      mice[i].timerAlarmed = 0
      mice[i].status = "normal"
    end

    -- spotted timer
    if v.status == "spotted" and v.timerSpotted > 0 then
      mice[i].timerSpotted = v.timerSpotted - dt
    end

    -- alarmed timer
    if v.status == "alarmed" and v.timerAlarmed > 0 then
      mice[i].timerAlarmed = v.timerAlarmed - dt
    end

    -- movement timer
    if v.timerChoice > 0 then
      mice[i].timerChoice = v.timerChoice - dt
    end
    if v.timerChoice <= 0 then
      mice[i].timerChoice = math.random(2,4)
      mice[i].move[1] = math.random() * 2 - 1
      mice[i].move[2] = math.random() * 2 - 1
    end
    mice[i].move[1] = mice[i].move[1] + (math.random()) - .5
    mice[i].move[2] = mice[i].move[2] + (math.random()) - .5

    -- speed limit
    if mice[i].status == "alarmed" then
      if     mice[i].move[1] > 4  then mice[i].move[1] = 4
      elseif mice[i].move[1] < -4 then mice[i].move[1] = -4 end
      if     mice[i].move[2] > 4  then mice[i].move[2] = 4
      elseif mice[i].move[2] < -4 then mice[i].move[2] = -4 end
    else
      if     mice[i].move[1] > 2  then mice[i].move[1] = 2
      elseif mice[i].move[1] < -2 then mice[i].move[1] = -2 end
      if     mice[i].move[2] > 2  then mice[i].move[2] = 2
      elseif mice[i].move[2] < -2 then mice[i].move[2] = -2 end
    end

    -- location limit
    if mice[i].status ~= "alarmed" then
      if     mice[i].pos[1] > 768 then mice[i].move[1] = -1 * math.abs(mice[i].move[1])
      elseif mice[i].pos[1] < 0   then mice[i].move[1] = 1 * math.abs(mice[i].move[1]) end
      if     mice[i].pos[2] > 568 then mice[i].move[2] = -1 * math.abs(mice[i].move[2])
      elseif mice[i].pos[2] < 16  then mice[i].move[2] = 1 * math.abs(mice[i].move[2]) end
    end

    -- move
    mice[i].pos[1] = v.pos[1] + v.move[1]
    mice[i].pos[2] = v.pos[2] + v.move[2]

    -- animation update
    mice[i].anim:update(dt)

    -- save mice
    if mice[i].status == "alarmed" then
      if mice[i].pos[1] > 768 or mice[i].pos[1] < 0 or mice[i].pos[2] > 568 or mice[i].pos[2] < 16 then
        -- save mouse
        table.remove(mice, i)
      end
    end
  end
end

function updateCenter()
  centerCat = { posCat[1] + 24, posCat[2] + 24 }
  for i = 1, #mice do
    mice[i].center = {
      mice[i].pos[1] + 16,
      mice[i].pos[2] + 16,
    }
  end
end

function love.update(dt)

  -- input
  if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
    moveCat[2] = -1
  elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
    moveCat[2] = 1
  else
    moveCat[2] = 0
  end
  if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
    moveCat[1] = -1
  elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
    moveCat[1] = 1
  else
    moveCat[1] = 0
  end

  -- cat movement
  posCat[1] = posCat[1] + moveCat[1] * speedCat
  posCat[2] = posCat[2] + moveCat[2] * speedCat

  -- cat animation
  if moveCat[1] ~= 0 or moveCat[2] ~= 0 then
    animCat:update(dt)
  end

  -- eat mice
  updateCenter()

  for i = #mice, 1, -1 do
    if distance(mice[i].center, centerCat) < 20 then
      table.remove(mice, i)
      -- eat sound
      local j = math.random(1,2)
      sounds.noms[j]:stop()
      sounds.noms[j]:play()
      -- eat counter
      miceEaten = miceEaten + 1
    end
  end

  -- mice
  updateMice(dt)

  if gamestate ~= "pregame" and #mice == 0 and not gongplayed then
    sounds.gong:stop()
    sounds.gong:play()
    gongplayed = true
  end
end

function distance(p1, p2)
  return math.sqrt((p1[1] - p2[1]) ^ 2 + (p1[2] - p2[2]) ^ 2)
end

function love.draw(dt)
  -- draw bg
  love.graphics.draw(imgBackground, 0, 0)

  -- draw mice
  for i = 1, #mice do
    mice[i].anim:draw(spriteAnimals, mice[i].pos[1], mice[i].pos[2])
    --  alarm
    if mice[i].status == "spotted" then
      love.graphics.drawq(spriteAlert, alertYellow, mice[i].pos[1], mice[i].pos[2] - 32 )
    elseif mice[i].status == "alarmed" then
      love.graphics.drawq(spriteAlert, alertRed, mice[i].pos[1], mice[i].pos[2] - 32 )
    end
  end

  -- draw cat
  animCat:draw(spriteAnimals, posCat[1], posCat[2])

  love.graphics.print("Mice Eaten: " .. miceEaten, 360, 8 )

  love.graphics.print("Game by Iwan 'qubodup' Gabovitch made at Berlin Mini Jam, September 13, 2013", 160, 578 )

  if gamestate == "pregame" then
    love.graphics.print("Feeling peckish?\nWell, I think I hear some mice.\n\nJust start moving (Arrow keys or WASD) to play...", 160, 180 )
  elseif gamestate ~= "pregame" and #mice == 0 then
    love.graphics.print("You delightfully devoured " .. miceEaten .. " out of " .. miceCount .. " mice this lovely afternoon!\n\n" .. emotion(miceEaten), 160, 180 )
  end

end

function emotion(eated)
  if eated == 30 then
    return "Splendid!"
  elseif eated > 20 then
    return "Jolly good!"
  elseif eated > 10 then
    return "Fair enough!"
  elseif eated > 0 then
    return "Tough luck!"
  elseif eated == 0 then
    return "Better luck next cat!"
  end
end

function love.keypressed(key)
  if key == "escape" or key == "q" then
    love.event.push("quit")
  elseif gamestate == "pregame" then
    startPlay()
  end
end
