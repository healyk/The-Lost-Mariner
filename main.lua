require('lib/util')
require('lib/graphics')
require('lib/level')
require('lib/mob')
require('lib/item')
require('lib/level_gen')
require('lib/game')
require('lib/ingame')

Resources = {}
game = nil
state = InGame

function switchState(newState)
  local oldState = state
  
  if oldState.leave then
    oldState.leave(newState)
  end
  
  if newState.enter then
    newState.enter(oldState)
  end
  
  state = newState
end

function initStates()
  InventoryState.init()
end

function love.load()
  Logger.initLog("game.log")
  Graphics.init()
  Graphics.setFont('data/graphics/font.png', 16, 16)
  Resources.tiles = SpriteSheet.create('data/graphics/graphics.png', 32, 32)
  
  Resources.levelSprites = {}
  Resources.levelSprites.wall = Resources.tiles:makeSprite(1, 0)
  Resources.levelSprites.floor = Resources.tiles:makeSprite(1, 1)
  Resources.levelSprites.upstairs = Resources.tiles:makeSprite(2, 1)
  Resources.levelSprites.downstairs = Resources.tiles:makeSprite(3, 1)
  
  Resources.uiSprites = SpriteSheet.create('data/graphics/ui.png', 16, 16)
  
  initStates()
  logmsg("Game initialized")
  
  game = Game.create()
end

function love.draw()
  if state.draw then
    state.draw(game)
  end
end

function love.keyreleased(key, scancode)
  if state.keyreleased then
    state.keyreleased(game, key, scancode)
  end
end

function love.update(dt)
  if state.update then
    state.update(game, dt)
  end
end