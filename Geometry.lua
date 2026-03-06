---@param x number
---@param y number
---@return number
function AngleBetweenCoords(x1, x2, y1, y2)
    -- value is returned in radians
    return Atan2(y2 - y1, x2 - x1)
end

---@param x number
---@param y number
---@param stepsize number
---@param angle number
---@return number, number
function PolarStep(x,y,stepsize,angle)
    -- Assumes angle in radians
    local new_x = x + stepsize * math.cos(angle)
    local new_y = y + stepsize * math.sin(angle)
    return new_x, new_y
end

---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@return number
function Distance(x1,x2, y1, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end