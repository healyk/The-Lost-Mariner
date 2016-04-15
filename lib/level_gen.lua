-- This is the width of the entire dungeon.
DUNGEON_DEFAULT_WIDTH = 50
DUNGEON_DEFAULT_HEIGHT = 50

-- How much room to give around the dungeon
DUNGEON_PADDING_SIZE = 20

-----------------------------------
-- LevelGenState
-----------------------------------
LevelGenState = LevelGenState or {}

--
-- When entering, the first parameter should be the depth to generate.  It
-- can be a table with multiple depths
--
function LevelGenState.enter(oldState, params)
  LevelGenState.depths = params
  
  if type(LevelGenState.depths) ~= 'table' then
    LevelGenState.depth = LevelGenState.depths
    LevelGenState.depths = {}
  else
    LevelGenState.depth = table.remove(LevelGenState.depths)
  end
  
  LevelGenState.theme = LevelGen.DepthThemes[LevelGenState.depth]
end

function LevelGenState.init()

end

--
-- Performs the 'overall' logic of level generation
--
-- This performs once piece at a time to stop the game from freezing
--
function LevelGenState.update(game, dt)
  if LevelGenState.step == nil then
    LevelGenState.step = LevelGen.makeStep(game.builderRng, DUNGEON_DEFAULT_WIDTH, DUNGEON_DEFAULT_HEIGHT, LevelGenState.depth)
  end
  
  if LevelGenState.step.step == LevelGen.STEP_BUILD_LAYOUT then
    LevelGenState.theme.build(LevelGenState.step)
    logmsg("LevelGen: Generating theme layout", LevelGenState.step.iteration, dt)
    
  elseif LevelGenState.step.step == LevelGen.STEP_PLACE_EXITS then
    LevelGen.placeExits(LevelGenState.step)
    logmsg("LevelGen: placing exits", dt)
    LevelGenState.step.step = LevelGen.STEP_PAD_LAYOUT
    
  elseif LevelGenState.step.step == LevelGen.STEP_PAD_LAYOUT then
    LevelGen.padLayout(LevelGenState.step)
    logmsg("LevelGen: padding layout", dt)
    LevelGen.dumpLayout(LevelGenState.step.layout, 'levelgen')
    LevelGenState.step.step = LevelGen.STEP_FINALIZE_LEVEL
    
  elseif LevelGenState.step.step == LevelGen.STEP_FINALIZE_LEVEL then
    LevelGen.finalizeLevel(LevelGenState.step)
    logmsg("LevelGen: finalizing layout", dt)
    LevelGenState.step.step = LevelGen.STEP_SPAWN_ITEMS
  
  elseif LevelGenState.step.step == LevelGen.STEP_SPAWN_ITEMS then
    LevelGen.populateItems(LevelGenState.step)
    logmsg("LevelGen: populating items", dt)
    LevelGenState.step.step = LevelGen.STEP_FINISHED
    
  elseif LevelGenState.step.step == LevelGen.STEP_FINISHED then
    game:addNewLevel(LevelGenState.step.level)
    LevelGenState.step = nil
    
    if LevelGenState.depths == nil or #LevelGenState.depths == 0 then
      switchState(InGame)
    else
      LevelGenState.depth = table.remove(LevelGenState.depths)
    end
  end
end

function LevelGenState.draw(game)
  local width, height, flags = love.window.getMode()
  local str = "Generating levels..."
  
  love.graphics.clear(0, 0, 0)
  Graphics.drawString(str, (width / 16 / 2) - (str:len() / 2), height / 16 / 2)
end

-----------------------------------
-- CaveGen
--
-- Contains functionality specific to generating Caverns
-----------------------------------
CaveGen = CaveGen or {}

--
-- Generates a layout layout based on caverns.
--
function CaveGen.build(levelGenStep)
  if levelGenStep.layout == nil then
    levelGenStep.layout = LevelGen.create(levelGenStep.width, levelGenStep.height, LevelGen.TILE_FLOOR)
    LevelGen.randomFill(levelGenStep.layout, LevelGen.TILE_WALL, levelGenStep.rng, 45)
  end
  
  if levelGenStep.iteration < LevelGen.MAX_CAVERN_ITERATIONS then
    CaveGen.buildCavernsIteration(levelGenStep)
  else
    local result = LevelGen.checkReachable(levelGenStep.layout)
    
    if result == 0 then
      levelGenStep.step = LevelGen.STEP_PLACE_EXITS
    else
      logmsg("buildCaverns: not all tiles reachable, regenerating", result)
      levelGenStep.layout = nil
      levelGenStep.iteration = 0
    end
  end
end

function CaveGen.buildCavernsIteration(levelGenStep)
  local layout = levelGenStep.layout
  local newLayout = nil

  newLayout = LevelGen.create(layout.width, layout.height, LevelGen.TILE_FLOOR)

  for x = 0, layout.width do
    for y = 0, layout.height do
      local count1 = LevelGen.tileCount(layout, x, y, 1, LevelGen.TILE_WALL)
      local count2 = LevelGen.tileCount(layout, x, y, 2, LevelGen.TILE_WALL)

      if count1 >= 5 or count2 <= 2 then
        newLayout[x][y] = LevelGen.TILE_WALL
      else
        newLayout[x][y] = LevelGen.TILE_FLOOR
      end
    end
  end
  
  levelGenStep.layout = newLayout
  levelGenStep.iteration = levelGenStep.iteration + 1
end

-----------------------------------
-- LevelGen
--
-- Contains the general level generation functionality.
-----------------------------------
LevelGen = LevelGen or {}

-- Step defs
LevelGen.STEP_BUILD_LAYOUT = 0
LevelGen.STEP_PLACE_EXITS = 1
LevelGen.STEP_PAD_LAYOUT = 2
LevelGen.STEP_FINALIZE_LEVEL = 3
LevelGen.STEP_FINISHED = 4
LevelGen.STEP_SPAWN_ITEMS = 5

-- Tile defs
LevelGen.TILE_FLOOR = 1
LevelGen.TILE_WALL = 2
LevelGen.TILE_DOWNSTAIRS = 3
LevelGen.TILE_UPSTAIRS = 4

LevelGen.MAX_CAVERN_ITERATIONS = 9

function LevelGen.makeStep(rng, width, height, depth)
  return {
    rng = rng,
    depth = depth,
    width = width,
    height = height,
    layout = nil,
    iteration = 0,
    level = nil,
    step = LevelGen.STEP_BUILD_LAYOUT
  }
end

-- List of available themes
-- 
--   * Caverns

LevelGen.DepthThemes = {
  -- Depths 1, 2, and 3
  CaveGen, CaveGen, CaveGen
}

--
-- Helpers for LevelGen
--
function LevelGen.create(width, height, fill)
  local layout = {}
  
  for x = 0, width do
    layout[x] = {}
    for y = 0, height do
      layout[x][y] = fill
    end
  end
  
  layout.width = width
  layout.height = height
  
  return layout
end

--
-- Pads a level created only using the dungeon sizes with the default padding
--
function LevelGen.padLayout(levelGenStep)
  local layout = levelGenStep.layout
  local newLayout = LevelGen.create(DUNGEON_DEFAULT_WIDTH + (DUNGEON_PADDING_SIZE * 2), 
                                    DUNGEON_DEFAULT_HEIGHT + (DUNGEON_PADDING_SIZE * 2), LevelGen.TILE_WALL)
  
  for x = 0, layout.width do
    for y = 0, layout.height do
      newLayout[x + DUNGEON_PADDING_SIZE][y + DUNGEON_PADDING_SIZE] = layout[x][y]
    end
  end

  newLayout.walkable = layout.walkable
  levelGenStep.layout = newLayout
end

local layoutMapping = {
  [LevelGen.TILE_FLOOR] =      FLOOR_TYPE,
  [LevelGen.TILE_WALL] =       WALL_TYPE,
  [LevelGen.TILE_DOWNSTAIRS] = DOWNSTAIRS_TYPE,
  [LevelGen.TILE_UPSTAIRS] =   UPSTAIRS_TYPE
}

--
-- Builds the actual layout from a layout
--
function LevelGen.finalizeLevel(levelGenStep)
  local layout = levelGenStep.layout
  local level = Level.create(DUNGEON_DEFAULT_WIDTH + (2 * DUNGEON_PADDING_SIZE),
                             DUNGEON_DEFAULT_HEIGHT + (2 * DUNGEON_PADDING_SIZE))
  
  for x = 0, (layout.width - 1) do
    for y = 0, (layout.height - 1) do
      local layoutTile = layout[x][y]
      
      level:getTile(x, y).tileType = layoutMapping[layoutTile]
        
      if layoutTile == LevelGen.TILE_UPSTAIRS then
        level.enterance = { x, y }
      elseif layoutTile == LevelGen.TILE_DOWNSTAIRS then
        level.exit = { x, y }
      end
    end
  end
  
  levelGenStep.level = level

  level.depth = levelGenStep.depth
  level.theme = levelGenStep.theme
  level.walkable = layout.walkable
end

--
-- Spawns items on the level
--
function LevelGen.populateItems(levelGenStep)
  local level = levelGenStep.level
  
  local i = 0
  while i < 20 do
    local index = levelGenStep.rng:random(#Items.Types.Melee)
    local item = Items.Types.Melee[index]
    
    index = levelGenStep.rng:random(#level.walkable)
    local point = level.walkable[index]
    
    item = item.create()
    level:spawnItem(item, point[1], point[2])
    i = i + 1
  end
end

--
-- Checks an already generated layout to see if all walkable squares are reachable.
-- Returns 0 if all tiles are reachable, otherwise it will return the number of unreached tiles
-- Will fill in layout.walkable with a list of walkable tiles.  This can be used later for
-- various generators (items, enemies, and so forth)
--
function LevelGen.checkReachable(layout)
  layout.walkable = {}
  local walkables = {}
  
  -- Find all walkable tiles
  for x = 0, layout.width do
    for y = 0, layout.height do
      if layout[x][y] == LevelGen.TILE_FLOOR then
        table.insert(walkables, { x, y })
      end
    end
  end
 
  local firstPoint = table.remove(walkables)
  LevelGen.removeWalkable(layout, walkables, firstPoint)
  
  -- Simple fix for the walkable problem -- if it's less than a certain threshold just fill those tiles
  if #walkables <= 100 and #walkables > 0 then
    logmsg("CaveGen: Filling small gap", #walkables)
    while #walkables > 0 do
      local point = table.remove(walkables)
      layout[point[1]][point[2]] = LevelGen.TILE_WALL
    end
  end
  
  return #walkables
end

--
-- This is used by LevelGen.checkReachable
--
function LevelGen.removeWalkable(layout, walkables, point)
  local x = point[1]
  local y = point[2]
  local otherPoints = { 
    { x, y - 1},
    { x, y + 1},
    { x - 1, y },
    { x + 1, y }
  }
  
  for i, p in pairs(otherPoints) do
    for index, p2 in pairs(walkables) do
      if p2[1] == p[1] and p2[2] == p[2] then
        local newPoint = table.remove(walkables, index)
    
        if newPoint then
          LevelGen.removeWalkable(layout, walkables, newPoint)
          table.insert(layout.walkable, newPoint)
        end
      end
    end
  end
end

--
-- Randomly puts 'fill' into places in the layout based on rng
--    layout    - layout to fill
--    fill      - what to fill with
--    rng       - random number generator
--    threshold - If rng returns a random below it then fill happens.  Should be between 0 and 100
--
function LevelGen.randomFill(layout, fill, rng, threshold)
  for x = 0, layout.width do
    for y = 0, layout.height do
      number = rng:random(1, 100)
      if number < threshold then
        layout[x][y] = fill
      end
    end
  end
end

--
-- Counts the number of tiles around a given position 
--
function LevelGen.tileCount(layout, x, y, distance, value)
  local count = 0

  for x2 = x - distance, x + distance do
    for y2 = y - distance, y + distance do
      if x2 < 0 or y2 < 0 or x2 > layout.width or y2 > layout.height then
        -- Ignore out of bounds
      elseif (x2 == x and y2 == y) then
        -- Ignore origin point
      elseif layout[x2][y2] == value then
        count = count + 1
      end
    end
  end
  
  return count
end

--
-- Places an upstairs and downstair in the layout
--
-- Level should have a walkable array already when calling this function.
--
function LevelGen.placeExits(levelGenStep)
  local rng = levelGenStep.rng
  local layout = levelGenStep.layout

  local helper = function(exitTile)
    -- Get a random reachable point
    local index = rng:random(1, #layout.walkable)
    local point = layout.walkable[index]
    
    -- Choose a random direction to find a wall
    local dir = {
      { 0, -1 },
      { 0, 1 },
      { 1, 0 },
      { -1, 0 }
    }
    
    index = rng:random(1, 4)
    dir = dir[index]
    
    -- Now walk that direction until we encounter a wall or a layout boundry
    local prevPoint = point
    while layout[point[1]] and (layout[point[1]][point[2]] ~= LevelGen.TILE_WALL) and
          (point[1] > 0 and point[2] > 0 and point[1] < layout.width and point[2] < layout.height) do
      logmsg("LevelGen: Exit Tile Walk", exitTile, point[1], point[2])
      prevPoint = point
      point[1] = point[1] + dir[1]
      point[2] = point[2] + dir[2]
    end
    
    -- Place the exit tile
    if layout[point[1]] then
      layout[point[1]][point[2]] = exitTile
      return true
    else
      logmsg("LevelGen: Can't place exit: " .. point[1] .. ", " .. point[2])
      return false
    end
  end

  -- Sometimes a bad position is selected (usually the algorithm wanders off out of the
  -- map bounds).  In these cases we just keep trying till we get something good.
  while not helper(LevelGen.TILE_UPSTAIRS) do
    logmsg("LevelGen: problem placing exit, retrying")
  end
  while not helper(LevelGen.TILE_DOWNSTAIRS) do
    logmsg("LevelGen: problem placing exit, retrying")
  end
end

--
-- Debug function.  Dumps the layout to a file.
--
function LevelGen.dumpLayout(layout, filename)
  local str = ""
  for y = 0, layout.width do
    for x = 0, layout.height do
      if layout[x][y] == LevelGen.TILE_FLOOR then
        str = str .. "."
      elseif layout[x][y] == LevelGen.TILE_WALL then
        str = str .. "#"
      elseif layout[x][y] == LevelGen.TILE_DOWNSTAIRS then
        str = str .. ">"
      elseif layout[x][y] == LevelGen.TILE_UPSTAIRS then
        str = str .. "<"
      else
        str = str .. "?"
      end
    end
    
    str = str .. "\r\n"
  end
  
  love.filesystem.write(filename, str, str:len())
end
