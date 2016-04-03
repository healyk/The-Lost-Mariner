SpriteSheet = SpriteSheet or {}
SpriteSheet.__index = SpriteSheet

function SpriteSheet.create(filename, spriteWidth, spriteHeight)
  local self = setmetatable({}, SpriteSheet)
  
  self.filename = filename
  self.image = love.graphics.newImage(filename)
  self.spriteWidth = spriteWidth
  self.spriteHeight = spriteHeight
  
  return self
end

function SpriteSheet:makeSprite(x, y, color)
  local quad = love.graphics.newQuad(x * self.spriteWidth,
                                     y * self.spriteHeight,
                                     self.spriteWidth,
                                     self.spriteHeight,
                                     self.image:getWidth(),
                                     self.image:getHeight())
                                     
  return { self.image, quad, color }
end

Graphics = Graphics or {}

--
-- Initializes the graphics system
--
-- params:
--   spriteWidth, spriteHeight - width and height of tiles in pixels
--
function Graphics.init()
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)
end

function Graphics.setFont(file, width, height)
  Graphics.font = love.graphics.newImage(file)
  Graphics.fontWidth = width
  Graphics.fontHeight = height
  Graphics.fontQuads = {}

  for x = 0, 15 do
    for y = 0, 15 do
      local chr = x + (y * 16)
      local quad = love.graphics.newQuad(x * width, y * height, width, height,
                                         Graphics.font:getWidth(), Graphics.font:getHeight())
      Graphics.fontQuads[chr] = quad
    end
  end
end

function Graphics.renderSprite(sprite, x, y, bgColor) 
  if bgColor ~= nil then
    local width = Graphics.spriteWidth * Graphics.scaleX
    local height = Graphics.spriteHeight * Graphics.scaleY

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", pixelX, pixelY, width, height)
  end
  
  local color = sprite[3]
  if not color then
    color = { 255, 255, 255 }
  end
  love.graphics.setColor(color)
  love.graphics.draw(sprite[1], sprite[2], x, y)
end

function Graphics.drawString(str, x, y, color)
  local pixelY = y * Graphics.fontWidth
  if color == nil then
    color = { 255, 255, 255 }
  end
  
  love.graphics.setColor(color)
  for i = 1, str:len() do
    local pixelX = (x + i) * Graphics.fontHeight
    local chr = str:byte(i)

    love.graphics.draw(Graphics.font, Graphics.fontQuads[chr], pixelX, pixelY)
  end
end