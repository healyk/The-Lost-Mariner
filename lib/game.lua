Game = Game or {}
Game.__index = Game

DUNGEON_DEFAULT_WIDTH = 100
DUNGEON_DEFAULT_HEIGHT = 100

MAX_MESSAGE_SIZE = 20

function Game.create()
  local self = setmetatable({}, Game)
  
  self.builderRng = love.math.newRandomGenerator(os.time())
  for i = 0, 100 do
    self.builderRng:random()
  end

  self.player = Player.create()
  self.turnCount = 0
  self.msglog = {}
  
  self.depth = 1
  self.levels = {}
  
  return self
end

local levelMapping = {
  [LevelGen.TILE_WALL] = WALL_TYPE,
  [LevelGen.TILE_DOWNSTAIRS] = DOWNSTAIRS_TYPE,
  [LevelGen.TILE_UPSTAIRS] = UPSTAIRS_TYPE
}

--
-- Adds a new level to the game.
--
function Game:addNewLevel(level)
  self.levels[level.depth] = level
  
  if level.depth == 1 then
    local playerX, playerY = level.enterance[1], level.enterance[2]
    self:spawnMob(self.player, playerX, playerY)
    --self:spawnMob(Enemy.create(), 5, 5)
    --level:spawnItem(Dagger.create(), 10, 10)
  end
end

function Game:spawnMob(mob, x, y)
  return self:getCurrentLevel():spawnMob(mob, x, y)
end

function Game:removeMob(mob)
  return self:getCurrentLevel():removeMob(mob)
end

function Game:handlePlayerMoveMessage(newTile)
  if newTile.item then
    local item = newTile.item[1]
    local msg = ""
    if #newTile.item == 1 then
      msg = string.format("You see %s here", addArticle(item.name))
    else
      msg = string.format("You see a %s here and %d other items", item.name, (#newTile.item - 1))
    end
    
    game:logMessage(msg)
  end
end

function Game:moveMobBy(x, y, deltaX, deltaY)
  local newX = x + deltaX
  local newY = y + deltaY

  local level = self:getCurrentLevel()
  local tile = level:getTile(x, y)
  local newTile = level:getTile(newX, newY)
  
  -- Validate movement is possible
  if (not Level.TileTypes[newTile.tileType].blocksMovement) and newTile.mob == nil then
    local mob = tile.mob
    local newMob = newTile.mob
    
    if mob then
      mob.x = newX
      mob.y = newY
    end
    
    if newMob then
      newMob.x = x
      newMob.y = y
    end

    tile.mob = newMob
    newTile.mob = mob
    
    if mob.player then
      self:handlePlayerMoveMessage(newTile)
    end
    
    if Level.TileTypes[tile.tileType].leave then
      Level.TileTypes[tile.tileType].leave(game, mob, tile)
    end
    
    if Level.TileTypes[newTile.tileType].enter then
      Level.TileTypes[newTile.tileType].enter(game, mob, tile)
    end

    return true
  else
    return false
  end
end

function Game:attack(attacker, defender)
  local toHit = 50  - attacker.accuracy + defender.dodge
  local chance = love.math.random(100)
  if chance > toHit then
    dmg = defender:dealDamage(2, 4)
    
    -- Check for crit
    if chance > 95 then
      dmg = dmg * 2
      self:logMessage(string.format("%s deals a critical hit to %s for %d damage", 
                      attacker.name, addArticle(defender.name), dmg))
    else
      self:logMessage(string.format("%s deals %d to the %s", 
                      attacker.name, dmg, addArticle(defender.name)))
    end
    
    if defender.health <= 0 then
      self:getCurrentLevel():removeMob(defender)
      self:logMessage("The " .. defender.name .. " dies")
    end
  else
    if chance > 50  - attacker.accuracy then
      self:logMessage("The " .. defender.name .. " dodges the " .. attacker.name .. "'s attack")
    else
      self:logMessage("The " .. attacker.name .. " misses the " .. defender.name)
    end
  end
end

-- Should be called after the player has acted, to advance the enemies/game environment
function Game:advance()
  self.turnCount = self.turnCount + 1
end

function Game:logMessage(msg)
  table.insert(self.msglog, msg)
  
  if #self.msglog > MAX_MESSAGE_SIZE then
    table.remove(self.msglog, #self.msglog)
  end
end

--
-- Gets the current level
--
function Game:getCurrentLevel()
  return self.levels[self.depth]
end

function Game:switchLevel(newDepth)
  local oldLevel = self:getCurrentLevel()
  local newLevel = self.levels[newDepth]

  oldLevel:removeMob(self.player)
  
  if newDepth > self.depth then
    newLevel:spawnMob(self.player, newLevel.enterance[1], newLevel.enterance[2])
  else
    newLevel:spawnMob(self.player, newLevel.exit[1], newLevel.exit[2])
  end
  self.depth = newDepth
end
