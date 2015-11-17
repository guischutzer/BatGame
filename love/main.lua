--
--  Platformer Tutorial
--

local loader = require "AdvTiledLoader/Loader"
local sti = require "sti"

-- set the path to the Tiled map files
loader.path = "maps/"



local HCC = require "HC"
local Timer = require "hump.timer"
local Camera = require "hump.camera"


local hero
local collider
local allSolidTiles

function love.load()

  tiles = {}

  love.graphics.setDefaultFilter("nearest")
  debug = false
  tilesize = 32

	-- load the level and bind to variable map
	map = sti.new("maps/level2.lua")

  -- Variables related to  animation
  walk_frame = 1 --walk animation frame
  walk_timer = Timer.new()
  walking = false
  walk_img = love.graphics.newImage("img/walk_frames.png")
  idle_img = love.graphics.newImage("img/idle.png")
  fall_img = love.graphics.newImage("img/fall.png")
  walk_quad = {}
  --walking frames
  for i = 0,7 do
    walk_quad[i] = love.graphics.newQuad(1+33*i, 0, tilesize, 49, walk_img:getWidth(), walk_img:getHeight())
  end

  back_img = love.graphics.newImage("img/darkness.jpg")

----[[
  for y = 1, map.height do
  		for x = 1, map.width do
  			if map.layers[1].data[y][x] ~= nil then
  				local ti = HCC.rectangle((x-1)*32, (y-1)*32, 32, 32)
          table.insert(tiles, ti)
          --print(x)
          --print(y)
			end
		end
  end
	setupHero(32,32)


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

end

function love.update(dt)

  local xOld, yOld = hero:center()

  todo = {}

  walk_timer.update(dt)

  --hero:move(0, 800*dt)



  --print(#todo)

	-- do all the input and movement

	--handleInput(dt)

	-- update the collision detection

	--updateHero(dt)


  if (hero.y_speed == 0) then hero.y_speed = hero.y_speed + 0.0001 end

  if hero.jetpack_fuel > 0 -- we can still move upwards
	and love.keyboard.isDown(" ") then -- and we're actually holding space
		hero.jetpack_fuel = hero.jetpack_fuel - dt -- decrease the fuel meter
		hero.y_speed = hero.y_speed + jump_height * (dt / hero.jetpack_fuel_max)
	end
  if love.keyboard.isDown("right") then
    hero.x_speed = hero.x_speed_max
  end
  if love.keyboard.isDown("left") then
    hero.x_speed = - hero.x_speed_max
  end
  if hero.y_speed ~= 0 then -- we're probably jumping
		hero:move(0, hero.y_speed * dt) -- dt means we wont move at
		-- different speeds if the game lags
		hero.y_speed = hero.y_speed + gravity * dt
    dx, dy = 0,0
    for shape, delta in pairs(HCC.collisions(hero)) do
          --hero:move(delta.x, delta.y)
          --colidir(dt, hero, delta.x, delta.y)
          table.insert(todo, shape)
          dx = dx + delta.x
          dy = dy + delta.y
    end
		if dy < 0 then -- we hit the ground again
			hero.y_speed = 0
			hero:move(0,dy)
      hero.jetpack_fuel = hero.jetpack_fuel_max
		end
	end

  dx, dy = 0, 0
  hero:move(hero.x_speed * dt, 0)
  for shape, delta in pairs(HCC.collisions(hero)) do
        --hero:move(delta.x, delta.y)
        --colidir(dt, hero, delta.x, delta.y)
        table.insert(todo, shape)
        dx = dx + delta.x
        dy = dy + delta.y
  end
  if dx < 0 or dx > 0 then
    hero.x_speed = 0
    hero:move(dx, 0)
  end


  local xNew, yNew = hero:center()

  dxCam, dyCam = xNew - xOld, yNew - yOld

  if dxCam > -1 and dxCam < 1 then dxCam = 0 end
  if dyCam > -1 and dyCam < 1 then dyCam = 0 end

  cam:move(2 * (dxCam),2 * (dyCam))
  par:move(1 * (dxCam),1 * (dyCam))


end



function love.draw()

  par:attach()
  love.graphics.draw(back_img, 0, 0, 0, 4, 4, -40, -40)
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
    love.graphics.print(hero.y_speed)
  end

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

  cam:detach()


end

function animTimer()
  walk_frame = walk_frame%7 +1
end



function setupHero(x,y)

	hero = HCC.rectangle(x,y,32,49)

  hero.jetpack_fuel = 0.3
  hero.jetpack_fuel_max = 0.3

	hero.x_speed = 0
  hero.x_acc = 100
  hero.x_speed_base = 100
  hero.x_speed_max = 200

  hero.y_speed_base = -400
  hero.y_speed = 0
  hero.air = true
  hero.l_wall = false
  hero.r_wall = false

  hero.jump_height = 100
  hero.pode_pular = true

  hero.flip = false
	--hero.img = love.graphics.newImage("img/hero.png")

end

function love.keyreleased(key)
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
  end
end

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

function updateHero(dt)


  if hero.air == true then -- we're falling
    hero.y_speed = hero.y_speed + gravity * dt
    hero:move(0, hero.y_speed*dt)
  end

  hero.air = true

  hero:move(hero.x_speed*dt, 0)

end
