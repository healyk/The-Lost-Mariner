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
  self.level = LevelGen.buildCaverns(self.builderRng, 1)
  self.turnCount = 0
  self.msglog = {}
  
  local playerX, playerY = self.level.playerStart[1], self.level.playerStart[2]
  self:spawnMob(self.player, playerX, playerY)
  self:spawnMob(Enemy.create(), 5, 5)
  self.level:spawnItem(Dagger.create(), 10, 10)
  
  return self
end

local levelMapping = {
  [LevelGen.TILE_WALL] = WALL_TYPE,
  [LevelGen.TILE_DOWNSTAIRS] = DOWNSTAIRS_TYPE,
  [LevelGen.TILE_UPSTAIRS] = UPSTAIRS_TYPE
}

--
-- Creates the initial level
--
function Game:makeLevel(rng)
  local level = Level.create(DUNGEON_DEFAULT_WIDTH, DUNGEON_DEFAULT_HEIGHT)
  love.filesystem.write("levelgen", "", 0)
  local levelgen = LevelGen.buildCavernsLayout(DUNGEON_DEFAULT_WIDTH, DUNGEON_DEFAULT_HEIGHT, rng)
  
  for x = 0, (level.width - 1) do
    for y = 0, (level.height - 1) do
      if levelgen[x][y] ~= LevelGen.TILE_FLOOR then
        level:getTile(x, y).tileType = levelMapping[levelgen[x][y]]
      elseif x == 0 or y == 0 or x == (level.width - 1) or (y == level.height - 1) then
        level:getTile(x, y).tileType = WALL_TYPE
      end
    end
  end
  
  return level
end

function Game:spawnMob(mob, x, y)
  return self.level:spawnMob(mob, x, y)
end

function Game:removeMob(mob)
  return self.level:removeMob(mob)
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

  local tile = self.level:getTile(x, y)
  local newTile = self.level:getTile(newX, newY)
  
  -- Validate movement is possible
  if Level.isFloorTile(newTile) and newTile.mob == nil then
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
      self.level:removeMob(defender)
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