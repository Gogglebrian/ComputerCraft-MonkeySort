function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function splitString(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, trim(match));
    end
    return result;
end


function isEmptyLine(s)
	if string.find(s, "%a+", 1, false) == nil then
		return true
	else
		return false
	end
end

-- checks if array contains value
function contains(list, x)
	if (#list == 0) then
		return false
	end
	for _, v in ipairs(list) do
		if v == x then return true end
	end
	return false
end

return {trim = trim, isEmptyLine = isEmptyLine, contains = contains, tableLength = tableLength, splitString = splitString}
