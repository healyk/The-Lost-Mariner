--
-- Level
--
Level = Level or {}
Level.__index = Level

FLOOR_TYPE = 'floor'
WALL_TYPE = 'wall'

function Level.isFloorTile(tile)
  return true
  --return tile.tileType == FLOOR_TYPE
end

function Level.create(width, height)
  local self = setmetatable({}, Level)
  
  self.width = width
  self.height = height
  self.tiles = {}
  self.mobs = {}
  
  for x = 0, self.width do
    self.tiles[x] = {}
    
    for y = 0, self.height do
      self.tiles[x][y] = { 
        tileType = FLOOR_TYPE,
        mob = nil,
        item = nil
      }
    end
  end
  
  return self
end

function Level:setTilesFromString(str)
  local index = 1
  local y = 0
  
  for x = 0, self.width do
    if str:len() >= index then
      return
    end
  
    if(str:sub(index, index) == '\n') then
      index = index + 1
      y = y + 1
      x = 0
    end
  
    local c = str:sub(index, index)
    if c == '#' then
      self:getTile(x, y).tileType = WALL_TYPE
    else
      self:getTile(x, y).tileType = FLOOR_TYPE
    end
    
    index = index + 1
  end
end

function Level:isInBounds(x, y)
  return x >= 0 and y >= 0 and x < self.width and y < self.height
end

function Level:getTile(x, y)
  if self:isInBounds(x, y) then
    return self.tiles[x][y]
  else
    return nil
  end
end

function Level:spawnMob(mob, x, y)
  local tile = self:getTile(x, y)
  
  if Level.isFloorTile(tile) and tile.mob == nil then
    self:getTile(x, y).mob = mob
    mob.x = x
    mob.y = y

    table.insert(self.mobs, mob)

    return true
  else
    return false
  end
end

function Level:removeMob(mob)
  local tile = self:getTile(mob.x, mob.y)
  tile.mob = nil
  
  local index = -1
  for i, listMob in ipairs(self.mobs) do
    if mob == listMob then
      index = i
    end
  end

  if index ~= -1 then
    table.remove(self.mobs, index)
    return true
  else
    return false
  end
end

function Level:spawnItem(item, x, y)
  local tile = self:getTile(x, y)
  
  if Level.isFloorTile(tile) then
    if tile.item == nil then
      tile.item = { item }
    else
      table.insert(tile.item, item)
    end
  end
end

--
-- Level View
--
-- Used to render Levels
--
LevelView = LevelView or { }
LevelView.__index = LevelView

RENDER_TILES_WIDE = 20
RENDER_TILES_HIGH = 20
TILE_SIZE = 32

function LevelView.create()
  local self = setmetatable({}, LevelView)
  
  self.centerX = 0
  self.centerY = 0
  
  return self
end

function LevelView:drawMob(mob, x, y)
  Graphics.renderSprite(mob.sprite, x * TILE_SIZE, y * TILE_SIZE)
  local healthSize = (mob.health / mob.maxHealth)
  
  if healthSize > .66 then
    love.graphics.setColor({ 0, 255, 0 })
  elseif healthSize > .33 then
    love.graphics.setColor({ 255, 255, 0 })
  else
    love.graphics.setColor({ 255, 0, 0 })
  end

  -- Draw the health bar
  local spriteWidth = TILE_SIZE
  local spriteHeight = TILE_SIZE
  love.graphics.rectangle('fill', 
                          x * spriteWidth,
                          (y * spriteHeight) + (spriteHeight - 2),
                          healthSize * spriteWidth,
                          2)
end

function LevelView:setPosition(x, y)
  self.centerX = x
  self.centerY = y
end

function LevelView:draw(game)
  local level = game.level
  local offX = self.centerX - (RENDER_TILES_WIDE / 2)
  local offY = self.centerY - (RENDER_TILES_HIGH / 2)

  for x = 0, RENDER_TILES_WIDE do
    for y = 0, RENDER_TILES_HIGH do
      local tile = level:getTile(x + offX, y + offY)
      
      if tile then
        local sprite = Resources.levelSprites[tile.tileType]
        Graphics.renderSprite(sprite, x * TILE_SIZE, y * TILE_SIZE)

        if tile.mob then
          self:drawMob(tile.mob, x, y)
        elseif tile.item then
          local item = tile.item[1]
          
          Graphics.renderSprite(item.sprite, x * TILE_SIZE, y * TILE_SIZE)
        end
      end
    end
  end
end