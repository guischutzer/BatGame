--
--  Platformer Tutorial
--

local loader = require "AdvTiledLoader/Loader"
-- set the path to the Tiled map files
loader.path = "maps/"

local HC = require "HardonCollider"
local Timer = require "hump.timer"
local Camera = require "hump.camera"

local hero
local collider
local allSolidTiles

function love.load()

  love.graphics.setDefaultFilter("nearest")
  debug = false
  tilesize = 32

	-- load the level and bind to variable map
	map = loader.load("level2.tmx")

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




	-- load HardonCollider, set callback to on_collide and size of 100
	collider = HC(128, on_collide)

	-- find all the tiles that we can collide with
	allSolidTiles = findSolidTiles(map)

	-- set up the hero object, set him to position 32, 32
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

  walk_timer.update(dt)


	-- do all the input and movement

	handleInput(dt)

	-- update the collision detection

	updateHero(dt)
	collider:update(dt)

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

function on_collide(dt, shape_a, shape_b, mtv_x, mtv_y)

	-- seperate collision function for entities
	collideHeroWithTile(dt, shape_a, shape_b, mtv_x, mtv_y)

end

function collideHeroWithTile(dt, shape_a, shape_b, mtv_x, mtv_y)

	-- sort out which one our hero shape is
	local hero_shape, tileshape
	if shape_a == hero and shape_b.type == "tile" then
		hero_shape = shape_a
	elseif shape_b == her and shape_a.type == "tile" then
		hero_shape = shape_b
	else
		-- none of the two shapes is a tile, return to upper function
		return
	end


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

	hero = collider:addRectangle(x,y,32,49)

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

function findSolidTiles(map)


	local collidable_tiles = {}

	-- get the layer that the tiles are on by name
	local layer = map.tl["grass"]

	for tileX=1,map.width do
		for tileY=1,map.height do

			local tile

			if layer.tileData[tileY] then
				tile = map.tiles[layer.tileData[tileY][tileX]]
			end

			if tile and tile.properties.solid then
				local ctile = collider:addRectangle((tileX-1)*32,(tileY-1)*32,32,32)
				ctile.type = "tile"
				collider:addToGroup("tiles", ctile)
				collider:setPassive(ctile)
				table.insert(collidable_tiles, ctile)
			end

		end
	end

	return collidable_tiles
end
