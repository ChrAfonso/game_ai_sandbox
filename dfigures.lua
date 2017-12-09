require "behaviors"

dance = {}

-- follow leader, target fixed offset
function dance.follow_leader(self, dt)
	if self.leader then
		-- init?
		self.offset = self.offset or { 0, 10 } 
		self.target = self.target or {}
		
		-- update target at offset from leader
		self.target.position = v2_add(self.leader.position, self.offset)

		-- delegate
		snap_to_target(self)
		
		self.direction = v2_look_at(self.position, self.leader.position)
	end
end

-- circle around leader
function dance.circle_leader(self, dt)
	-- init?
	self.rotate_speed = self.rotate_speed or 90 -- deg/s
	
	-- update
	if self.offset ~= nil then
		self.offset = v2_rotate_deg(self.offset, self.rotate_speed * dt)
	end

	dance.follow_leader(self, dt)
end
