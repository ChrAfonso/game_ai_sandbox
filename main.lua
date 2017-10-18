-- global values/settings
screenw = 800
screenh = 600

speed_min = 50
speed_max = 100
turnspeed_min = 20
turnspeed_max = 180

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
	
	bot.speed = speed or math.random(speed_min, speed_max)
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
	bot.position = v2_add(bot.position, v2_scale(bot.direction, bot.speed * dt))

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

-- behaviors
function idle(self, dt)
	-- do nothing
	self.direction = { 0, 0 }

	self.color = { 128, 128, 128 }
end

function wander(self, dt)
	self.direction = v2_rotate(self.direction, ((math.random() * 2) - 1) * self.turnspeed * dt)
	
	self.color = { 0, 255, 0 }
end

function seek(self, dt)
	if self.target ~= nil then
		self.direction = v2_normalize(v2_sub(self.target.position, self.position))
	else
		-- keep direction
	end
	
	self.color = { 255, 0, 0 }
end

function flee(self, dt)
	seek(self, dt)
	self.direction = v2_scale(self.direction, -1)

	self.color = { 255, 255, 0 }
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
		local color = bot.color or defaultcolor
		love.graphics.setColor(color[1], color[2], color[3])
		love.graphics.circle("fill", bot.position[1], bot.position[2], 5)
		
		if debug_draw then
			-- heading
			love.graphics.line(bot.position[1], bot.position[2], bot.position[1] + bot.direction[1]*10, bot.position[2] + bot.direction[2]*10)
			
			-- seek
			if bot.behavior == seek and bot.target then
				love.graphics.line(bot.position[1] + 1, bot.position[2], bot.target.position[1] + 1, bot.target.position[2])
			elseif bot.behavior == flee and bot.target then
				love.graphics.line(bot.position[1] - 1, bot.position[2], bot.target.position[1] - 1, bot.target.position[2])
			end
		end
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
		add_bot(seek).target = game.bots[#game.bots - 1]
	elseif k == "#" then
		add_bot(seek).target = game.bots[math.random(1, #game.bots - 1)] -- -1: Don't seek yourself
	
	elseif k == "4" then
		add_bot(flee).target = game.bots[#game.bots - 1]
	elseif k == "$" then
		add_bot(flee).target = game.bots[math.random(1, #game.bots - 1)]
	
	elseif k == "k" then
		game:make_seek_targets_flee()

	elseif k == "d" then
		debug_draw = not debug_draw

	elseif k == "escape" then
		os.exit()
	end
end

-- vector
function get_random_position()
	return { math.random() * screenw, math.random() * screenh }
end

function get_random_direction()
	return v2_rotate({ 0, 1 }, math.random() * 360)
end

function v2_add(v1,v2)
	return { v1[1] + v2[1], v1[2] + v2[2] }
end

function v2_sub(v1,v2)
	return { v1[1] - v2[1], v1[2] - v2[2] }
end

function v2_scale(v, s)
	return { v[1] * s, v[2] * s }
end

function v2_rotate(v, th)
	return {
		v[1] * math.cos(th) + v[2] * -math.sin(th),
		v[1] * math.sin(th) + v[2] * math.cos(th)
	}
end

function v2_normalize(v)
	local l = math.sqrt(v[1] * v[1] + v[2] * v[2])
	if l > 0 then
		return v2_scale(v, 1/l)
	else
		return { 0, 0 }
	end
end


