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

function v2_magnitude(v)
	return math.sqrt(v[1] * v[1] + v[2] * v[2])
end

function v2_normalize(v)
	local l = v2_magnitude(v) 
	if l > 0 then
		return v2_scale(v, 1/l)
	else
		return { 0, 0 }
	end
end

