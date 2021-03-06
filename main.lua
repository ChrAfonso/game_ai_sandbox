require "vectormath"
require "behaviors"

-- global values/settings
screenw = 800
screenh = 600

speed_min = 20
speed_max = 100
turnspeed_min = 20
turnspeed_max = 360

debug_draw = false

-- global objects
game = {}
game.bots = {}

mouse = { position = { screenw/2, screenh/2 }}

-- game
function game:create_bot(behavior, position, direction, speed, turnspeed)
	local bot = {}
	
	bot.behavior = behavior or idle
	
	bot.position = position or get_random_position()
	bot.direction = direction or get_random_direction()
	
	bot.speed_max = speed or math.random(speed_min, speed_max)
	bot.acceleration = 10

	bot.speed_current = 0
	bot.speed_target = 0
	bot.turnspeed = turnspeed or math.random(turnspeed_min, turnspeed_max)
	
	table.insert(self.bots, bot)
	
	return bot
end

function game:remove_all_bots()
	-- TODO: add more cleanup when it becomes necessary
	while #self.bots > 0 do
		local bot = self.bots[#self.bots]
		bot.target = nil
		table.remove(self.bots, #self.bots)
	end
end

function game:add_time(dt)
	for _, bot in ipairs(game.bots) do
		update_bot(bot, dt)
	end
end

function game:make_seek_targets_flee()
	for _, bot in ipairs(self.bots) do
		if bot.behavior == seek and bot.target then
			bot.target.behavior = flee
			bot.target.target = bot
		end
	end
end

-- game util
function add_bot(behavior)
	return game:create_bot(behavior)
end

function remove_bot(bot)
	if #game.bots > 0 then
		table.remove(game.bots, #game.bots)
	end
end

-- bots
function update_bot(bot, dt)
	bot:behavior(dt)
	move_bot(bot, dt)
end

function move_bot(bot, dt)
	local speed_diff = bot.speed_target - bot.speed_current
	if(speed_diff > 0.01) then
		bot.speed_current = bot.speed_current + speed_diff * bot.acceleration * dt
	else
		bot.speed_current = bot.speed_target
	end
	
	bot.position = v2_add(bot.position, v2_scale(bot.direction, bot.speed_current * dt))
	
	-- HACK wraparound:
	if bot.position[1] < 0 then
		bot.position[1] = bot.position[1] + screenw
	elseif bot.position[1] >= screenw then
		bot.position[1] = bot.position[1] - screenw
	elseif bot.position[2] < 0 then
		bot.position[2] = bot.position[2] + screenh
	elseif bot.position[2] >= screenh then
		bot.position[2] = bot.position[2] - screenh
	end
end

function draw_bot(bot)
	local fillmode = "fill"
	if bot.visible == false then
		if debug_draw then
			fillmode = "line"
		else
			return
		end
	end

	local color = bot.color or default_bot_color
	love.graphics.setColor(color[1], color[2], color[3])
	love.graphics.circle(fillmode, bot.position[1], bot.position[2], 5)
	
	if debug_draw then
		-- heading
		love.graphics.line(bot.position[1], bot.position[2], bot.position[1] + bot.direction[1]*10, bot.position[2] + bot.direction[2]*10)
		
		-- line to target
		if bot.target ~= nil then
			local draw_line = true
			if bot.behavior == investigate then
				if bot.behavior_state == wander then
					draw_line = false
					love.graphics.print(string.format("%.0f", bot.cooldown), bot.position[1] - 5, bot.position[2] - 20)
				end
			end

			if draw_line then
				love.graphics.line(bot.position[1], bot.position[2], bot.target.position[1], bot.target.position[2])
			end
		end
	end	
end


-- love
function love.load()
	love.window.setMode(screenw, screenh)
	
	math.randomseed(os.time())
	math.random() -- throw away first value
end

function love.draw()
	love.graphics.clear()

	local defaultcolor = { 255, 255, 255 }

	for _, bot in ipairs(game.bots) do
		draw_bot(bot)
	end
end

function love.update(dt)
	local mx, my = love.mouse.getPosition()
	mouse.position = { mx, my }
	
	game:add_time(dt)
end

function love.keypressed(k)
	if k == "=" or k == "+" then
		add_bot()
	elseif k == "-" then
		remove_bot()
	
	elseif k == "0" then
		game:remove_all_bots()

	elseif k == "1" then
		add_bot(idle)
	elseif k == "2" then
		add_bot(wander)
	
	elseif k == "m" then
		add_bot(seek).target = mouse
	elseif k == "3" then
		if love.keyboard.isDown("lshift", "rshift") then
			add_bot(seek).target = game.bots[math.random(1, #game.bots - 1)] -- -1: Don't seek yourself
		else
			add_bot(seek).target = game.bots[#game.bots - 1]
		end
	elseif k == "4" then
		if love.keyboard.isDown("lshift", "rshift") then
			add_bot(flee).target = game.bots[math.random(1, #game.bots - 1)] -- -1: Don't seek yourself
		else
			add_bot(flee).target = game.bots[#game.bots - 1]
		end
	
	elseif k == "5" then
		if love.keyboard.isDown("lshift", "rshift") then
			add_bot(arrive).target = game.bots[math.random(1, #game.bots - 1)] -- -1: Don't seek yourself
		else
			add_bot(arrive).target = game.bots[#game.bots - 1]
		end

	elseif k == "6" then
		if love.keyboard.isDown("lshift", "rshift") then
			add_bot(investigate).target = game.bots[math.random(1, #game.bots - 1)] -- -1: Don't seek yourself
		else
			add_bot(investigate).target = game.bots[#game.bots - 1]
		end
	
	elseif k == "k" then
		game:make_seek_targets_flee()

	elseif k == "d" then
		debug_draw = not debug_draw

	elseif k == "escape" then
		os.exit()
	end
end

-- vector utils
function get_random_position()
	return { math.random() * screenw, math.random() * screenh }
end

function get_random_direction()
	return v2_rotate_deg({ 0, 1 }, math.random() * 360)
end

