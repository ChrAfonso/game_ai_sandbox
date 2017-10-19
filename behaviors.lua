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
