--
-- InGame State
--
InGame = InGame or {}

local levelView = LevelView.create()

function InGame.drawMessageLog(game)
  for i = 0, 4 do
    local index = #game.msglog - i
    if game.msglog[index] ~= nil then
      Graphics.drawString(game.msglog[index], 0, 42 + i)
    end
  end
end

function InGame.drawHud(game)
  Graphics.drawString("Health " .. game.player.health .. "/" .. game.player.maxHealth, 42, 2)
  Graphics.drawString("Turn   " .. game.turnCount, 42, 3)
end

function InGame.draw(game)
  levelView:setPosition(game.player.x, game.player.y)
  levelView:draw(game, game.player.x, game.player.y)
  InGame.drawHud(game)
  InGame.drawMessageLog(game)
end

function InGame.update(game, dt)

end

MOVE_KEYS = {
  up    = {  0, -1 },
  down  = {  0,  1 },
  right = {  1,  0 },
  left  = { -1,  0 }
}

function InGame.keyreleased(game, key, scancode)
  local moveKey = MOVE_KEYS[key]
  
  if moveKey then
    local newX = game.player.x + moveKey[1]
    local newY = game.player.y + moveKey[2]
    local mob = game.level:getTile(newX, newY).mob
  
    if mob ~= nil then
      if game:attack(game.player, mob) then
        game:advance()
      end
    elseif game:moveMobBy(game.player.x, game.player.y, moveKey[1], moveKey[2]) then
      game:advance()
    end
  elseif key == 'i' then
    switchState(InventoryState)
  end
end

--
-- Inventory State
--
InventoryState = InventoryState or {}

function InventoryState.init()
  InventoryState.sprites = {}
  InventoryState.sprites['ui-item-slot'] = Resources.uiSprites:makeSprite(0, 0, { 128, 128, 128 })
end

function InventoryState.enter(oldState)
  InventoryState.selectedItem = 1
end

function InventoryState.draw(game)
  Graphics.drawString('Inventory', 2, 0)
  local inv = game.player.inventory
  
  local y = 1
  for i = 1, inv.size do
    local item = inv.items[i]
    local x = (i % 5) + 1
    
    Graphics.renderSprite(InventoryState.sprites['ui-item-slot'], x * TILE_SIZE, y * TILE_SIZE)
    
    if item then
      Graphics.renderSprite(item.sprite, x * TILE_SIZE, y * TILE_SIZE)
    end
    
    if i % 5 == 0 then
      y = y + 1
    end
  end
end

function InventoryState.update(game, dt)

end

function InventoryState.keyreleased(game, key, scancode)
  if key == 'escape' then
    switchState(InGame)
  end
end