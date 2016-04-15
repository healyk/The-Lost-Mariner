--
-- Item
--
Item = initClass()

function Item.create()
  local self = setmetatable({}, Item)
  self.name = 'item'
  return self
end

Items = {}
Items.Types = {}
Items.Types.Melee = {}

--
-- Dagger
--
Dagger = initClass({}, Item)

function Dagger.create()
  local self = setmetatable(Item.create(), Dagger)
  
  self.minDamage = 1
  self.maxDamage = 4
  self.accuracy = 10
  self.sprite = Resources.tiles:makeSprite(0, 3)
  self.name = 'dagger'
  
  return self
end

table.insert(Items.Types.Melee, Dagger)

--
-- Inventory
--
Inventory = initClass()

function Inventory.create(size, equips)
  local self = setmetatable({}, Inventory)
  
  self.size = size
  self.items = {}
  
  if equips then
    self.equips = {}
    for k, v in pairs(equips) do
      self.equips[k] = v
    end
  end

  return self
end
