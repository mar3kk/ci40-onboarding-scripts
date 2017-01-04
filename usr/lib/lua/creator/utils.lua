
module("creator.utils", package.seeall)


local jsonc = require("luci.jsonc")

function fileToString(file)
  local f = io.open(file, "r")
  if (f == nil) then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

function stringTofile(file, content)
  local f = io.open(file, "w+")
  f:write(content)
  f:close()
end

function findLinkForKey(jsonString, key)
  for k, v in pairs( jsonString ) do
     for k2, v2 in pairs( v ) do
       for k3, v3 in pairs(v2) do
         if v3 == key then
           return v2
         end
       end
     end
  end
  return nil
end

function loadJsonFromFile(file)
  local content = fileToString(file)
  if (content == nil) then
    return nil
  end
  return jsonc.parse(content)
end

function creatorError(msg_)
    error({msg = tostring(msg_)})
end
