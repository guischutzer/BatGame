--
--  Platformer Tutorial
--

local name = require "sonar"
local name = require "moving"


local loader = require "AdvTiledLoader/Loader"
local sti = require "sti"

-- set the path to the Tiled map files
loader.path = "maps/"



local HCC = require "HC"
local Timer = require "hump.timer"
local Camera = require "hump.camera"
local Gamestate = require "hump.gamestate"
local Vector = require "hump.vector-light"

--GAMESTATES
local menu = {}
local game = {}
local pause = {}

local hero

local collider
local allSolidTiles
local moving = {}

function love.load()
  levelLoad()
end

function levelLoad()

  collider = HCC.new()

  --Handles Gamestates
  Gamestate.registerEvents()
  Gamestate.switch(menu)

  tiles = {}

  love.graphics.setDefaultFilter("nearest")
  debug = false
  tilesize = 32

	-- load the level and bind to variable map
	map = sti.new("maps/level5.lua")


  --Variables related to Kat invulnerability

  invul = false
  invul_timer = Timer.new()
  blink = false

  titl = love.graphics.newImage("img/titl.png")

  -- Variables related to  animation
  walk_frame = 1 --walk animation frame
  walk_timer = Timer.new()
  walking = false
  walk_img = love.graphics.newImage("img/walk_frames.png")
  idle_img = love.graphics.newImage("img/idle.png")
  fall_img = love.graphics.newImage("img/fall.png")
  walk_quad = {}
  --walking frames
	setupHero(32,32)

  for i = 0,7 do
    walk_quad[i] = love.graphics.newQuad(1+33*i, 0, tilesize, 49, walk_img:getWidth(), walk_img:getHeight())
  end

  back_img = love.graphics.newImage("img/darkness.jpg")

----[[
  for y = 1, map.height do
  		for x = 1, map.width do
  			if map.layers["grass"].data[y][x] ~= nil then
          for k, v in pairs(map:getTileProperties("grass", x, y)) do
            --print(k, v)
          end
          --print("-----")

          if setContains(map:getTileProperties("grass", x, y), "solid") then
    				local ti = collider:rectangle((x-1)*32, (y-1)*32, 32, 32)
            --print("adicionado")
            if setContains(map:getTileProperties("grass", x, y), "oneWay") then
              ti.oneWay = true
              print("OW")
            end
            table.insert(tiles, ti)
          end
          --else print("não adicionado") end
          --print(x)
          --print(y)

			end

      if map.layers["moving"].data[y][x] ~= nil then
        local ti = collider:rectangle((x-1)*32, (y-1)*32, 64, 32)
        table.insert(moving, Mov(hero, ti, true))
        print("FOUND")
      end

      if map.layers["moving2"].data[y][x] ~= nil then
        local ti = collider:rectangle((x-1)*32, (y-1)*32, 64, 32)
        table.insert(moving, Mov(hero, ti, false))
        print("FOUND")
      end

		end
  end


  old = {
    x = -1000,
    y = -1000
  }
  sum_x = 0
  sum_y = 0
  x_history = {0, 0, 0, 0}
  y_history = {0, 0, 0, 0}

  gravity = (hero.y_speed_base^2)/(2 * hero.jump_height)
  i = 0
  cam = Camera(hero:center())
  par = Camera(hero:center())

  gravity = 400
	jump_height = -300
  j_Pack = 0.5
  j_Pack_Max = 0.5


  ss = collider:circle(50,1,1)
  s = Sonar(hero, ss)

  --sonar = collider:circle(10, -1, -1)
  --sonar.behavior = parado
  --sonar.ativar = ativaSonar
  --sonar.ativo = false

  --sonar.kek = iniciar

end

function setContains(set, key)
    return set[key] ~= nil
end

function abs(x)
  if (x < 0) then return -x end
  return x
end

function min(x,y)
  if (x < y) then return x end
  return y
end


function game:update(dt)

  s:update(dt)
  for i, j in pairs(collider:collisions(s.shape)) do
    --s.shape:move(j.x, j.y)
    if not i.oneWay then s:colidiu() end
  end

  xOld, yOld = hero:center()
  mx, my = cam:mousePosition()
  mx, my = mx / 2, my / 2

  --local mx, my = love.mouse.getPosition();

  todo = {}

  -- Timers
  walk_timer.update(dt)
  invul_timer.update(dt)


  --hero:move(0, 800*dt)

  if love.mouse.isDown("l") and not s.ativo then
    s:ativar(xOld, yOld, mx, my)
  end

  --print(#todo)

	-- do all the input and movement

	--handleInput(dt)

	-- update the collision detection

	--updateHero(dt)

  if hero.jetpack_fuel > 0 -- we can still move upwards
	and love.keyboard.isDown(" ") then -- and we're actually holding space
		hero.jetpack_fuel = hero.jetpack_fuel - dt -- decrease the fuel meter
		hero.y_speed = hero.y_speed + jump_height * (dt / hero.jetpack_fuel_max)
    hero.air = true
	end

  if love.keyboard.isDown("d") then
    hero.flip = false
    hero.x_speed = hero.x_speed_max
  elseif love.keyboard.isDown("a") then
    hero.x_speed = - hero.x_speed_max
    hero.flip = true
  else
    hero.x_speed = 0
  end

  if hero.y_speed ~= 0 or hero.air == true then -- we're probably jumping
		hero:move(0, hero.y_speed * dt)
		hero.y_speed = hero.y_speed + gravity * dt
    dx, dy = 0,0
    for shape, delta in pairs(collider:collisions(hero)) do
          --hero:move(delta.x, delta.y)
          --colidir(dt, hero, delta.x, delta.y)
          table.insert(todo, shape)
          if shape.oneWay and hero.y_speed < 100 then delta.y = 0 end
          dx = dx + delta.x
          dy = dy + delta.y
          if delta.y ~= old.y then hero:move(0,delta.y) end
          old.y = delta.y
    end
    if abs(dy) < 0.11 then dy = 0 end


    if dy > 0 then
      hero.y_speed = 1
    end

		if dy < 0 then -- we hit the ground again
			hero.y_speed = 0
			--hero:move(0,dy)
    if dy == 0 then hero.air = true end
      hero.jetpack_fuel = hero.jetpack_fuel_max
      hero.air = false
		end
	end

  dx, dy = 0, 0
  hero:move(hero.x_speed * dt, 0)
  for shape, delta in pairs(collider:collisions(hero)) do
        --hero:move(delta.x, delta.y)
        --colidir(dt, hero, delta.x, delta.y)
          table.insert(todo, shape)
          if (shape.oneWay) and hero.y_speed < 100 then delta.x = 0 end
          dx = dx + delta.x
          dy = dy + delta.y
          if delta.x ~= old.x then hero:move(delta.x,0) end
          old.x = delta.x
  end
  if abs(dx) < 0.11 then dx = 0 end
  if dx < 0 or dx > 0 then
    hero.x_speed = 0
    hero:move(dx/2, 0)
  end

  for _, mov in pairs(moving) do
    mov:update(dt)
  end

  local xNew, yNew = hero:center()


  if (#todo == 0) then
    --print("rsrs")
    hero.air = true
  end

  dxCam, dyCam = xNew - xOld, yNew - yOld
  cam:move(2 * (dxCam),2 * (dyCam))
  par:move(1 * (dxCam),1 * (dyCam))


  local cx, cy = hero:bbox()
  map:setDrawRange(cx - 500, cy - 400 ,1000, 800)

  --print(hero.air)


end

function menu:draw()
  --love.graphics.setBackgroundColor(255, 192, 203)
  --love.graphics.setColor(255,255,255)
  --love.graphics.draw(idle_img, 50 ,50, 0, 20)
  --love.graphics.setColor(72,118,255)
  --love.graphics.print("KAT VS THE WORLD", 0, 0, 0, 8)
  --love.graphics.print("PRESS SPACE FOR GAMEZ", 0, 600, 0, 6)
  love.graphics.draw(titl, 0, 0)
end

--DRAW DO PAUSE
function pause:draw()

  local h_x, h_y = hero:center()



  par:attach()
  love.graphics.draw(back_img, 0, 0, 0, 4, 2, -40, -40)
  par:detach()

  cam:attach()
  -- scale everything 2x
  love.graphics.scale(2,2)

  -- draw the level
  map:draw()
  -- draw the hero as a rectangle

  for _,t in pairs(todo) do
    t:draw('fill')
  end

  -- debugs stuff
  if debug then
    hero:draw("fill")
    print(hero.flip)
  end
  --Draw Kat
  if not blink then
    if hero.y_speed ~= 0 then
      love.graphics.draw(fall_img, h_x - (3/4)*tilesize + (hero.flip and 6/4*tilesize or 0), h_y - 48/2, 0, (hero.flip and -1 or 1), 1)
    elseif hero.x_speed == 0 then
      love.graphics.draw(idle_img, h_x - tilesize/2 + (hero.flip and tilesize or 0), h_y - 48/2, 0, (hero.flip and -1 or 1), 1)
      if walk_handle then
        walk_timer.cancel(walk_handle)
        walking = false
        walk_frame = 1
      end
    else
      if not walking then
        walk_handle = walk_timer.every(1/12, animTimer)
        walking = true
      end
      love.graphics.draw(walk_img, walk_quad[walk_frame], h_x - tilesize/2 + (hero.flip and tilesize or 0), h_y - 48/2 , 0, (hero.flip and -1 or 1), 1)
    end
  end

  --End Draw Kat

  --Draw Filter
  love.graphics.setColor(0,0,0,200)
  love.graphics.rectangle("fill", h_x -500, h_y-500, 1000,1000)
  love.graphics.setColor(255,255,255)
  love.graphics.print("PAUSE PAUSE PAUSE PAUSE", h_x - 50, h_y-38)

  cam:detach()
end

function game:draw()

  par:attach()
  love.graphics.draw(back_img, -450, -450, 0, 4, 2, -40, -40)
  par:detach()

  cam:attach()
  -- scale everything 2x
  love.graphics.scale(2,2)

  -- draw the level
  map:drawLayer(map.layers["grass"])
  -- draw the hero as a rectangle
  for _, mov in pairs(moving) do
    mov:draw()
  end

  -- debugs stuff
  if debug then
    for _,t in pairs(todo) do
      t:draw('fill')
    end
    hero:draw("fill")
    print(hero.flip)
  end

  --Draw Kat
if not blink then
  local h_x, h_y = hero:center()
    if hero.y_speed ~= 0 then
      love.graphics.draw(fall_img, h_x - (3/4)*tilesize + (hero.flip and 6/4*tilesize or 0), h_y - 48/2, 0, (hero.flip and -1 or 1), 1)
    elseif hero.x_speed == 0 then
      love.graphics.draw(idle_img, h_x - tilesize/2 + (hero.flip and tilesize or 0), h_y - 48/2, 0, (hero.flip and -1 or 1), 1)
      if walk_handle then
        walk_timer.cancel(walk_handle)
        walking = false
        walk_frame = 1
      end
    else
      if not walking then
        walk_handle = walk_timer.every(1/12, animTimer)
        walking = true
      end
      love.graphics.draw(walk_img, walk_quad[walk_frame], h_x - tilesize/2 + (hero.flip and tilesize or 0), h_y - 48/2 , 0, (hero.flip and -1 or 1), 1)
    end
  end

  --End Draw Kat


  if not s.ativo and debug then love.graphics.line(xOld, yOld, mx, my) end

  --s.shape:draw('fill')
  s:draw()

  cam:detach()


end

function animTimer()
  walk_frame = walk_frame%7 +1
end

function invul_activate()
  if invul then return end
  invul = true
  local t = 0
  invul_timer.during(4, function(dt)
    t = t + dt
    blink = (t%.2) < .1
  end, function()
    invul = false
    blink = false
  end)
end

function setupHero(x,y)

	hero = collider:rectangle(x,y,32,35)

  hero.jetpack_fuel = 0.3
  hero.jetpack_fuel_max = 0.1

	hero.x_speed = 0
  hero.x_acc = 100
  hero.x_speed_base = 100
  hero.x_speed_max = 200

  hero.y_speed_base = -400
  hero.y_speed = 0
  hero.air = true
  hero.l_wall = false
  hero.r_wall = false

  hero.jump_height = 10
  hero.pode_pular = true

  hero.flip = false
	--hero.img = love.graphics.newImage("img/hero.png")

end

function menu:keyreleased(key)
  if key == " " then
    Gamestate.switch(game)
  end
end

function pause:keyreleased(key)
  if key == "p" then
    Gamestate.switch(game)
  end
end

function game:keyreleased(key)
  if key == " " then
    hero.pode_pular = true

  elseif key == "b" then
    if debug == false then
       debug = true
    else
       debug = false
    end

  elseif key == "h" then
    if hardonDebug == false then
      hardonDebug = true
    else
      hardonDebug = false
    end

  elseif key == "i" then
    invul_activate()

  elseif key == "p" then
    Gamestate.switch(pause)
  end
end
--[[
function handleInput(dt)

  if love.keyboard.isDown(" ")
  and hero.pode_pular
  and hero.air == false then
      hero.air = true
      hero.pode_pular = false
      hero.y_speed = hero.y_speed_base
  end

	if love.keyboard.isDown("left") then
    hero.flip = true
    if hero.x_speed >= 0 then
      if hero.x_speed >= hero.x_speed_base then
        hero.x_speed = -hero.x_speed
      else
        hero.x_speed = -hero.x_speed_base
      end
    elseif hero.x_speed > -hero.x_speed_max then
       hero.x_speed = hero.x_speed - (100 * dt)
    else
      hero.x_speed = -hero.x_speed_max
    end
	elseif love.keyboard.isDown("right") then
    hero.flip = false -- flag para inverter o desenho
    if hero.x_speed <= 0 then
      if hero.x_speed <= -hero.x_speed_base then
        hero.x_speed = -hero.x_speed
      else
        hero.x_speed = hero.x_speed_base
      end
    elseif hero.x_speed < hero.x_speed_max then
       hero.x_speed = hero.x_speed + (100 * dt)
    else
       hero.x_speed = hero.x_speed_max
    end
  else
    hero.x_speed = 0
  end


end
]]--
function updateHero(dt)


  if hero.air == true then -- we're falling
    hero.y_speed = hero.y_speed + gravity * dt
    hero:move(0, hero.y_speed*dt)
  end

  hero.air = true

  hero:move(hero.x_speed*dt, 0)

end
