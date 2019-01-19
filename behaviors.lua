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
		self.rotate_distance = get_rotate_distance(self, self.target, self.next_target, self.dps, self.speed_current)
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
function get_rotate_distance(bot, target, next_target, dps, speed)
	local angle = math.deg(v2_angle_between(v2_sub(target.position, bot.position), v2_sub(next_target.position, target.position), true))
	bot.next_angle = angle
	return (speed * angle) / (2 * dps); -- 1, not 3600, because: speed here is in pixels/s, not /hour
end

