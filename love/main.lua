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

end

function love.update(dt)

  local xOld, yOld = hero:center()

  todo = {}

  walk_timer.update(dt)

  --hero:move(0, 800*dt)

  for shape, delta in pairs(HCC.collisions(hero)) do
        --hero:move(delta.x, delta.y)
        colidir(dt, hero, delta.x, delta.y)
        table.insert(todo, shape)
    end

  --print(#todo)

	-- do all the input and movement

	handleInput(dt)

	-- update the collision detection

	updateHero(dt)

  local xNew, yNew = hero:center()

  cam:move(2 * (xNew - xOld),2 * (yNew - yOld))
  par:move(1 * (xNew - xOld),1 * (yNew - yOld))


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

function colidir(dt, hero_shape, mtv_x, mtv_y)

  table.insert(x_history, 4, mtv_x)
  table.remove(x_history, 1)

  table.insert(y_history, 4, mtv_y)
  table.remove(y_history, 1)

  sum_x = 0
  if hardonDebug then io.write("x_history = {") end
  for i,val in ipairs(x_history) do
    if val > 0 then
      sum_x = sum_x + val
    else
      sum_x = sum_x - val
    end
    if hardonDebug then io.write(val) end
    if hardonDebug and i ~= 4 then io.write(", ") end
  end
  if hardonDebug then io.write("}\n") end

  sum_y = 0
  if hardonDebug then io.write("y_history = {") end
  for i,val in ipairs(y_history) do
    if val > 0 then
      sum_y = sum_y + val
    else
      sum_y = sum_y - val
    end
    if hardonDebug then io.write(val) end
    if hardonDebug and i ~= 4 then io.write(", ") end
  end
  if hardonDebug then io.write("}\n") end

  if hardonDebug then print("------------------------------") end
  if hardonDebug then print("sum_x = " .. sum_x .. " mtv_x = " .. mtv_x .. "\nsum_y = " .. sum_y .. " mtv_y = " .. mtv_y) end
  if mtv_y < 0
  and sum_x + old.x <= 4 -- no canto, esse valor não ultrapassa 4!!
  and sum_x >= 0 then
    hero_shape.air = false
    hero_shape.y_speed = 0
  elseif mtv_y > 1.5
  and mtv_y ~= sum_y
  and sum_x == 0 then
    hero_shape.y_speed = 0
  end

  if sum_x >= 0.5 then hero.speed_x = 0 end

	-- why not in one function call? because we will need to differentiate between the axis later

  if mtv_x ~= old.x then hero_shape:move(mtv_x, 0) end
  if mtv_y ~= old.y then hero_shape:move(0, mtv_y) end

  old.x = mtv_x
  old.y = mtv_y


end



function setupHero(x,y)

	hero = HCC.rectangle(x,y,32,49)

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
