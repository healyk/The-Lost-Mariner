Tiles = Tiles or {}

--
-- Tiles Structure
--
-- Sprites
--   Tiles.ThemeName.sprites[1] = { 0, 0 }
-- 
--   Sprites are a list of position in the graphics used to generate sprites
--   Sprite ranges:
--     Walls  - 1  to 10
--     Floors - 11 to 20

function Tiles.init()
  for name, theme in pairs(Tiles) do
    for index, point in ipairs(theme.sprites) do
      Resources.levelSprites[name]
    end
  end
end