function love.load()
	player = { -- nice and organised.
		x = 0,
		y = 0,
		image_r = love.graphics.newImage("placeholder.png"),
    image_l = love.graphics.newImage("redlohecalp.png"),
    y_velocity_base = 100,
    x_velocity_base = 100,
		y_velocity = 0,
    jetpack_fuel = 0.3, -- note: not an actual jetpack. variable is the time (in seconds)
		-- you can hold spacebar and jump higher.
		jetpack_fuel_max = 0.5,
    x_velocity = 0,
    x_velocity_max = 200,
    direita = 1
	}
	gravity = 500
	jump_height = 300
  flip = 0

	winW, winH = love.graphics.getWidth(), love.graphics.getHeight() -- this is just
	-- so we can draw it in a fabulous manner.
end

function love.update(dt)

  -- dinâmica do pulo (usando jetpack_fuel do exemplo do tutorial)
	if love.keyboard.isDown(" ") then
    if player.jetpack_fuel > 0 then
      if player.y_velocity == 0 then player.y_velocity = player.y_velocity_base end
		  player.jetpack_fuel = player.jetpack_fuel - dt
		  player.y_velocity = player.y_velocity + jump_height * (dt / player.jetpack_fuel_max)
    end
  elseif player.y == 0 then
    player.jetpack_fuel = player.jetpack_fuel_max
  end

  -- movimento lateral
  if love.keyboard.isDown("right") then
    flip = 0 -- flag para inverter o desenho
    if player.x_velocity <= 0 then
      player.x_velocity = player.x_velocity_base
    elseif player.x_velocity < player.x_velocity_max then
       player.x_velocity = player.x_velocity + (100 * dt)
    else
       player.x_velocity = player.x_velocity_max
    end
  elseif love.keyboard.isDown("left") then
    flip = 1
    if player.x_velocity >= 0 then
      player.x_velocity = -player.x_velocity_base
    elseif player.x_velocity > -player.x_velocity_max then
       player.x_velocity = player.x_velocity - (100 * dt)
    else
      player.x_velocity = -player.x_velocity_max
    end
  else
    player.x_velocity = 0
  end



	if player.y_velocity ~= 0 then -- we're probably jumping
		player.y = player.y + player.y_velocity * dt -- dt means we wont move at
		-- different speeds if the game lags
		player.y_velocity = player.y_velocity - gravity * dt
		if player.y < 0 then -- we hit the ground again
			player.y_velocity = 0
			player.y = 0
		end
	end

  player.x = player.x + player.x_velocity * dt
end

function love.draw()
	love.graphics.rectangle("fill", 0, winH / 2, winW, winH / 2)
	love.graphics.translate(winW / 2, winH / 2) -- you don't need to understand this

  if flip == 1 then
	 love.graphics.draw(player.image_l, player.x, -player.y, 0, 1, 1, 64, 103) -- trust me
	-- on the origin position. just trust me.
  else
    love.graphics.draw(player.image_r, player.x, -player.y, 0, 1, 1, 64, 103)
  end
end
