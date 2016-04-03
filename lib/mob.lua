Mob = initClass()

function Mob.create()
  local self = setmetatable({}, Mob)
  self.armor = 0
  self.dodge = 0
  self.accuracy = 0
  self.name = 'mob'
  self.player = false
  return self
end

function Mob:dealDamage(minDmg, maxDmg)
  dmg = love.math.random(minDmg, maxDmg) - self.armor
  self.health = self.health - dmg
  
  return dmg
end

--
-- Player
--
Player = initClass({}, Mob)

function Player.create()
  local self = setmetatable(Mob.create(), Player)

  self.x = 1
  self.y = 1
  
  self.sprite = Resources.tiles:makeSprite(0, 2)
  self.name = 'Player'
  self.player = true

  self.health = 50
  self.maxHealth = 50
  self.inventory = Inventory.create(20)

  return self
end

--
-- Enemy
--
Enemy = initClass({}, Mob)

function Enemy.create()
  local self = setmetatable(Mob.create(), Enemy)
  
  self.sprite = Resources.tiles:makeSprite(0, 2, { 192, 0, 0 })
  self.name = 'evil thing'
  self.x = 1
  self.y = 1
  self.health = 10
  self.maxHealth = 10
  self.armor = 1
  
  return self
end