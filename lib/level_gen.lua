LevelGen = LevelGen or {}

--
-- LevelGens
--

LevelGen.TILE_FLOOR = 1
LevelGen.TILE_WALL = 2

function LevelGen.buildCaves(width, height, rng)
  local level = LevelGen.create(width, height, LevelGen.TILE_FLOOR)
  LevelGen.log = "cavegen start\r\n--------------\r\n"
  
  LevelGen.randomFill(level, LevelGen.TILE_WALL, rng, 40)

  local newLevel = nil
  for i = 0, 9 do
    newLevel = LevelGen.create(level.width, level.height, LevelGen.TILE_FLOOR)

    for x = 0, level.width do
      for y = 0, level.height do
        local count1 = LevelGen.tileCount(level, x, y, 1, LevelGen.TILE_WALL)
        local count2 = LevelGen.tileCount(level, x, y, 2, LevelGen.TILE_WALL)

        if count1 >= 5 or count2 <= 2 then
          newLevel[x][y] = LevelGen.TILE_WALL
        else
          newLevel[x][y] = LevelGen.TILE_FLOOR
        end
      end
    end
    
    level = newLevel
  end

  local result = LevelGen.checkReachable(level)
  if result == 0 then
    love.filesystem.append("levelgen", LevelGen.log, LevelGen.log:len())
    return level
  else
    logmsg("buildCaves: not all tiles reachable, regenerating", result)
    LevelGen.log = LevelGen.log .. "Reachable result: " .. result .. "\r\n"
    love.filesystem.append("levelgen", LevelGen.log, LevelGen.log:len())
    return LevelGen.buildCaves(width, height, rng)
  end
end

--
-- Helpers for levelgen
--
function LevelGen.create(width, height, fill)
  local level = {}
  
  for x = 0, width do
    level[x] = {}
    for y = 0, height do
      level[x][y] = fill
    end
  end
  
  level.width = width
  level.height = height
  
  return level
end

--
-- Checks an already generated level to see if all walkable squares are reachable.
-- Returns 0 if all tiles are reachable, otherwise it will return the number of unreached tiles
-- Will fill in level.walkable with a list of walkable tiles.  This can be used later for
-- various generators (items, enemies, and so forth)
--
function LevelGen.checkReachable(level)
  level.walkable = {}
  
  -- Find all walkable tiles
  for x = 0, level.width do
    for y = 0, level.height do
      if level[x][y] == LevelGen.TILE_FLOOR then
        table.insert(level.walkable, { x, y })
      end
    end
  end
  
  -- Copy the list
  local walkableCopy = {}
  for k, v in pairs(level.walkable) do
    table.insert(walkableCopy, v)
  end
 
  local firstPoint = table.remove(walkableCopy)
  local msg = "Removing first point " .. firstPoint[1] .. ', ' .. firstPoint[2] .. "\r\n"
  LevelGen.log = LevelGen.log .. msg
  LevelGen.removeWalkable(walkableCopy, firstPoint)
  
  return #walkableCopy
end

--
-- This is used by LevelGen.checkReachable
--
function LevelGen.removeWalkable(walkables, point)
  local x = point[1]
  local y = point[2]
  local otherPoints = { 
    { x, y - 1},
    { x, y + 1},
    { x - 1, y },
    { x + 1, y }
  }
  
  for i, p in pairs(otherPoints) do
    local index = -1
    for i, p2 in pairs(walkables) do
      if p2[1] == p[1] and p2[2] == p[2] then
        index = i
        break
      end
    end

    local newPoint = table.remove(walkables, index)
    
    if newPoint then
      LevelGen.log = LevelGen.log .. "removing point " .. newPoint[1] .. ', ' .. newPoint[2] .. "\r\n"
      LevelGen.removeWalkable(walkables, newPoint)
    end
  end
end

-- Randomly puts 'fill' into places in the level based on rng
--    level     - level to fill
--    fill      - what to fill with
--    rng       - random number generator
--    threshold - If rng returns a random below it then fill happens.  Should be between 0 and 100
function LevelGen.randomFill(level, fill, rng, threshold)
  for x = 0, level.width do
    for y = 0, level.height do
      number = rng:random(1, 100)
      if number < threshold then
        level[x][y] = fill
      end
    end
  end
end

-- Counts the number of tiles around a given position 
function LevelGen.tileCount(level, x, y, distance, value)
  local count = 0

  for x2 = x - distance, x + distance do
    for y2 = y - distance, y + distance do
      if x2 < 0 or y2 < 0 or x2 > level.width or y2 > level.height then
        -- Ignore out of bounds
      elseif (x2 == x and y2 == y) then
        -- Ignore origin point
      elseif level[x2][y2] == value then
        count = count + 1
      end
    end
  end
  
  return count
end
