function initClass(obj, parent)
	local klass = obj or {}
	klass.__index = klass
  
  if parent then
    setmetatable(klass, { __index = parent })
  end
  
  return klass
end

function require_all(dir)
  files = love.filesystem.getDirectoryItems(dir)
  
  for _, file in ipairs(files) do
    if love.filesystem.isFile(file) then
      require(file)
    end
  end
end

function isUpperCase(letter)
  return letter < 96
end

function isVowel(letter)
  return letter == 96 or
         letter == 101 or
         letter == 105 or
         letter == 111 or
         letter == 117
end

--
-- Given a name this will add 'a' or 'an' to it.  If the first letter
-- is capitalized it will add 'the' instead.
--
function addArticle(name)
  local firstLetter = name:byte(1)
  
  -- Uppercase letter
  if isUpperCase(firstLetter) then
    return name
  elseif isVowel(firstLetter) then
    return "an " .. name
  else
    return "a " .. name
  end
end

Logger = Logger or {}

function Logger.initLog(filename)
  local initStr = "Initializing Log File\r\n"
  Logger.filename = filename
  return love.filesystem.write(Logger.filename, initStr, initStr:len())
end

function logmsg(msg, ...)
  args = { ... }
  if #args > 0 then
    for i, v in ipairs(args) do
      msg = msg .. '; ' .. tostring(v)
    end
  end

  msg = msg .. "\r\n"
  love.filesystem.append(Logger.filename, msg, msg:len())
end
