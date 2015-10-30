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
	collider = HC(100, on_collide)

	-- find all the tiles that we can collide with
	allSolidTiles = findSolidTiles(map)

	-- set up the hero object, set him to position 32, 32
	setupHero(32,32)

  old = {
    x = -1000,
    y = -1000
  }

  gravity = (hero.y_speed_base^2)/(2 * hero.jump_height)

end

function love.update(dt)

	-- do all the input and movement

	handleInput(dt)
	updateHero(dt)

	-- update the collision detection


	collider:update(dt)



end

function love.draw()

	-- scale everything 2x
	love.graphics.scale(2,2)

	-- draw the level
	map:draw()

	-- draw the hero as a rectangle
	hero:draw("fill")
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

  hero_shape.air = false
  hero_shape.y_speed = 0

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
    flip = 1
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

  if hero.air then -- we're falling
		hero.y_speed = hero.y_speed + gravity * dt
    hero:move(0, dt * hero.y_speed)
	end

  print(hero.x_speed)
  hero:move(hero.x_speed*dt, 0)

  hero.air = true

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
