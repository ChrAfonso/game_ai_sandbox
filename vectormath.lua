function v2_copy(v1)
	return { v1[1], v1[2] }
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

function v2_rotate_deg(v, th)
	return v2_rotate_rad(v, th * math.pi / 180)
end

function v2_rotate_rad(v, th)
	return {
		v[1] * math.cos(th) + v[2] * -math.sin(th),
		v[1] * math.sin(th) + v[2] * math.cos(th)
	}
end

function v2_angle_between(v1, v2, smaller)
	smaller = smaller or false
	
	-- TODO: This does not return angles > 180!
	local angle = math.acos((v2_dot(v1, v2))/(v2_magnitude(v1) * v2_magnitude(v2)))
	
	if smaller == true then
		angle = math.min(angle, v2_angle_between(v2, v1, false))
	end

	return angle
end

function v2_magnitude(v)
	return math.sqrt(v[1] * v[1] + v[2] * v[2])
end

function v2_distance(position1, position2)
	return v2_magnitude(v2_sub(position2, position1))
end

function v2_intersect_lines(p1, v1, p2, v2)
	if v2_angle_between(v1, v2) == 0 then
		return nil
	end
	
	-- crossing point: p1 + a * v1 = p2 + b * v2
	local a = v2_cross(v2_sub(p2, p1), v2)/v2_cross(v1, v2)
	local b = v2_cross(v2_sub(p2, p1), v1)/v2_cross(v1, v2)
	-- debug:
	print("DEBUG v2_cross: a:" .. a .. ", b: " ..b)
	return v2_add(p1, v2_scale(v1, a))
end

function v2_normalize(v)
	local l = v2_magnitude(v) 
	if l > 0 then
		return v2_scale(v, 1/l)
	else
		return { 0, 0 }
	end
end

function v2_dot(v1, v2)
	return (v1[1] * v2[1]) + (v1[2] * v2[2])
end

function v2_cross(v1, v2)
	return (v1[1] * v2[2]) - (v2[1] * v1[2])
end

function v2_look_at(position, target_position)
	return v2_normalize(v2_sub(target_position, position))
end

