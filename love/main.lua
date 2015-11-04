--
--  Platformer Tutorial
--

local loader = require "AdvTiledLoader/Loader"
-- set the path to the Tiled map files
loader.path = "maps/"

local HC = require "HardonCollider"

local hero
local collider
local allSolidTiles

function love.load()

	-- load the level and bind to variable map
	map = loader.load("level.tmx")

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
  move = {x=0, y=0}
  i = 0

end

function love.update(dt)

	-- do all the input and movement

	handleInput(dt)

	-- update the collision detection

	updateHero(dt)
	collider:update(dt)


end

function love.draw()

	-- scale everything 2x
	love.graphics.scale(2,2)

	-- draw the level
	map:draw()

	-- draw the hero as a rectangle
	hero:draw("fill")

  love.graphics.print(hero.y_speed)
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
  -- io.write("x_history = {")
  for i,val in ipairs(x_history) do
    if val > 0 then
      sum_x = sum_x + val
    else
      sum_x = sum_x - val
    end
    --io.write(val)
    -- if i ~= 4 then io.write(", ") end
  end
  -- io.write("}\n")

  sum_y = 0
  -- io.write("y_history = {")
  for i,val in ipairs(y_history) do
    if val > 0 then
      sum_y = sum_y + val
    else
      sum_y = sum_y - val
    end
    -- io.write(val)
    -- if i ~= 4 then io.write(", ") end
  end
  -- io.write("}\n")

  --print("------------------------------")
  --print("sum_x = " .. sum_x .. " mtv_x = " .. mtv_x .. "\nsum_y = " .. sum_y .. " mtv_y = " .. mtv_y) -- " mtv_x = " .. mtv_x .. " mtv_y = " .. mtv_y)
  if mtv_y < 0
  and sum_x + old.x <= 4 -- no canto, esse valor não ultrapassa 4!!
  and sum_x >= 0 then
    hero_shape.air = false
    hero_shape.y_speed = 0
  elseif mtv_y > 1.5
  and mtv_y ~= sum_y then
    hero_shape.y_speed = 0
  end

  print(hero_shape:center())
  
  if sum_x >= 0.5 then hero.speed_x = 0 end

  -- if hero.air == true then
  --   print("lnx = " .. last_nonzero_x .. " ON hero.air")
  -- else
  --   print("lnx = " .. last_nonzero_x)
  -- end

  -- if mtv_x > 0 then
  --   hero.l_wall = true
  -- elseif mtv_x < 0 then
  --   hero.r_wall = true
  -- end

	-- why not in one function call? because we will need to differentiate between the axis later

  if mtv_x ~= old.x then hero_shape:move(mtv_x, 0) end
  if mtv_y ~= old.y then hero_shape:move(0, mtv_y) end

  old.x = mtv_x
  old.y = mtv_y


end

function setupHero(x,y)

	hero = collider:addRectangle(x,y,16,16)

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
    flip = true
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
    flip = false -- flag para inverter o desenho
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
	local layer = map.tl["ground"]

	for tileX=1,map.width do
		for tileY=1,map.height do

			local tile

			if layer.tileData[tileY] then
				tile = map.tiles[layer.tileData[tileY][tileX]]
			end

			if tile and tile.properties.solid then
				local ctile = collider:addRectangle((tileX-1)*16,(tileY-1)*16,16,16)
				ctile.type = "tile"
				collider:addToGroup("tiles", ctile)
				collider:setPassive(ctile)
				table.insert(collidable_tiles, ctile)
			end

		end
	end

	return collidable_tiles
end
