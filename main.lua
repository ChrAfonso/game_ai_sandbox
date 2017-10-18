-- globals
screenw = 800
screenh = 600

game = {}
game.bots = {}

mouse = { position = { screenw/2, screenh/2 }}

-- game
function game:create_bot(behavior, position, direction, speed, turnspeed)
	local bot = {}
	
	bot.behavior = behavior or idle
	
	bot.position = position or get_random_position()
	bot.direction = direction or get_random_direction()
	
	bot.speed = speed or math.random() * 100
	bot.turnspeed = turnspeed or math.random() * 360
	
	table.insert(self.bots, bot)
	
	return bot
end

function game:add_time(dt)
	for _, bot in ipairs(game.bots) do
		bot:behavior(dt)
	end
end

function add_bot(behavior)
	return game:create_bot(behavior)
end

function remove_bot(bot)
	if #game.bots > 0 then
		table.remove(game.bots, 1)	
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

-- behaviors
function move_bot(bot, dt)
	bot.position = v2_add(bot.position, v2_scale(bot.direction, bot.speed * dt))
end

function idle(self, dt)
	self.color = { 128, 128, 128 }
	-- do nothing
end

function seek(self, dt)
	self.color = { 255, 0, 0 }

	if self.target ~= nil then
		self.direction = v2_normalize(v2_sub(self.target.position, self.position))
	else
		-- keep direction
	end

	move_bot(self, dt)
end

function wander(self, dt)
	self.color = { 0, 255, 0 }
	
	self.direction = v2_rotate(self.direction, ((math.random() * 2) - 1) * self.turnspeed * dt)
	
	move_bot(self, dt)
end

-- love
function love.load()
	love.window.setMode(screenw, screenh)
	
	math.randomseed(os.time())
	math.random() -- throw away first value
	
	add_bot(idle)
	add_bot(wander)
	add_bot(seek)
	add_bot(seek).target = mouse
end

function love.draw()
	love.graphics.clear()

	local defaultcolor = { 255, 255, 255 }

	for _, bot in ipairs(game.bots) do
		local color = bot.color or defaultcolor
		love.graphics.setColor(color[1], color[2], color[3])
		love.graphics.circle("fill", bot.position[1], bot.position[2], 5)
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
	elseif k == "escape" then
		os.exit()
	end
end
