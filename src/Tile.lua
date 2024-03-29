--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]] Tile = Class {}

local shineDuration = 3

function Tile:init(x, y, color, variety, isShiny)

    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    self.isShiny = isShiny or false

    -- alpha for shine animation
    self.shineAlpha = 0

end

function Tile:shine()
    Timer.tween(shineDuration, {
        [self] = {
            shineAlpha = 1
        }
    }):finish(function()
        -- reduce alpha to 0 then restart
        Timer.tween(shineDuration, {
            [self] = {
                shineAlpha = 0
            }
        }):finish(function()
            self:shine(shineDuration)
        end)
    end)
end

function Tile:render(x, y)
     
    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety], self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety], self.x + x, self.y + y)

	-- -- draw our transition rect; is normally fully transparent, unless we're moving to a new state
    -- love.graphics.setColor(1, 1, 1, self.transitionAlpha)
    -- love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
	
	-- draw shine
	love.graphics.setColor(1, 1, 1, self.shineAlpha)
	love.graphics.draw(gTextures['shine'], self.x + x, self.y + y)

end
