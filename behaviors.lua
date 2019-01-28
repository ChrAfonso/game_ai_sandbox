function idle(self, dt)
	-- do nothing
	self.direction = { 0, 0 }

	self.color = { 128, 128, 128 }
end

function wander(self, dt)
	self.speed_target = math.random() * self.speed_max
	self.direction = v2_rotate_deg(self.direction, ((math.random() * 2) - 1) * self.turnspeed * dt)
	
	self.color = { 0, 255, 0 }
end

-- utility behavior for formations, or fall-back for edge cases
function snap_to_target(self)
	if self.target then
		self.position = v2_copy(self.target.position)
	end
end

function seek(self, dt)
	self.speed_target = self.speed_max

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

function arrive(self, dt)
	seek(self, dt)
	
	self.arrive_distance = self.arrive_distance or 25
	if self.target then 
		local target_dist = v2_magnitude(v2_sub(self.target.position, self.position))
		if target_dist < self.arrive_distance then
			self.speed_target = self.speed_max * (target_dist / self.arrive_distance)
		else
			self.speed_target = self.speed_max
		end
	end

	self.color = { 255, 127, 0 }
end

function investigate(self, dt)
	if not self.behavior_state then
		self.behavior_state = arrive
	end

	if not self.target then
		return
	else
		if self.behavior_state == arrive then
			arrive(self, dt)
			
			if v2_magnitude(v2_sub(self.target.position, self.position)) < self.arrive_distance then
				-- arrived
				self.behavior_state = wander
				self.cooldown = math.random(5, 15)
			end
		elseif self.behavior_state == wander then
			self.cooldown = self.cooldown - dt
			
			wander(self, dt)
			
			if(self.cooldown < 0) then
				self.behavior_state = arrive
			end
		end
	end
end

-- requires table targets (waypoint list)
function fly_waypoints(self, dt)
	-- init?
	if self.target == nil then
		self.target = self.targets[1]
		self.target_index = 2
		self.next_target = self.targets[2]
	end
	if self.state == nil then
		self.state = "track_to"
		self.dps = 180 -- change constant
	end
	
	-- move
	self.speed_target = self.speed_max
	
	if self.state == "track_to" then
		self.rotate_distance, self.rotate_debug = get_rotate_distance(self, self.target, self.next_target, self.dps, self.speed_current)
		if v2_distance(self.position, self.target.position) < self.rotate_distance then
			self.state = "rotate_to"
			local angle = math.deg(v2_angle_between(v2_sub(self.target.position, self.position), v2_sub(self.next_target.position, self.target.position), false))
			if angle < 180 then
				self.rotate_sign = 1
			else
				self.rotate_sign = -1
			end
		else
			self.direction = v2_look_at(self.position, self.target.position)
		end
		self.color = { 255, 255, 0 }
	elseif self.state == "rotate_to" then
		local angle_reached = (math.deg(v2_angle_between(self.direction, v2_sub(self.next_target.position, self.target.position)), true) < 3) 
		if angle_reached then
			-- rotate end, lock on to next target
			self.target = self.next_target
			local next_index = self.target_index + 1
			if next_index > #self.targets then
				next_index = 1
			end
			
			self.target_index = next_index
			self.next_target = self.targets[next_index]
			self.state = "track_to"
		else
			self.direction = v2_rotate_deg(self.direction, dt * self.dps * self.rotate_sign)
		end
		self.color = { 255, 0, 128 }
	end
	-- TODO: arc between
end

-- util
function math_sign(num)
	if num ~= 0 then
		return num / math.abs(num)
	else 
		return 0
	end
end

function get_rotate_distance(bot, target, next_target, dps, speed)
	--TODO
	local v1 = v2_normalize(v2_sub(target.position, bot.position))
	local v2 = v2_normalize(v2_sub(next_target.position, target.position))
	
	local sign = math_sign(v2_cross(v1, v2)) -- negative for right

	-- determine turn radius at speed
	local r = (360/bot.dps * speed) / (2*math.pi)
	-- get parallel lines - IMPORTANT: direction to other point - left/right? hardcoded sign is for right turns only...
	local n1 = v2_rotate_deg(v1, 90 * sign)
	local n2 = v2_rotate_deg(v2, 90 * sign)
	local p1 = v2_add(bot.position, v2_scale(n1, r))
	local p2 = v2_add(next_target.position, v2_scale(n2, r))

	-- intersect to get Cross point
	local c = v2_intersect_lines(p1, v1, p2, v2)
	if not c then
		return 0 -- parallel: just continue
	end

	-- add -normal * r to C, get turn start point
	local p_start_rot = v2_sub(c, n1)

	-- get distance from target
	return v2_distance(target.position, p_start_rot), {center=c, pstart=p_start_rot, r=r, v1=v1, v2=v2, n1=n1, n2=n2, p1=p1, p2=p2 }
end

