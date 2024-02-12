--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]] Board = Class {}

-- one in shinyChance chance for a tile to be shiny
local shinyChance = 32

local colorCount = 8

function Board:init(x, y, level)

    self.x = x
    self.y = y
    self.matches = {}

    self.level = level or 1

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do

        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            local tileVariety = self.level < 6 and math.random(self.level) or math.random(6)

            local isShiny = math.random(shinyChance) == 1

            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(colorCount), tileVariety, isShiny))

            -- if the tile is shiny, shine it
            if self.tiles[tileY][tileX].isShiny then
                self.tiles[tileY][tileX]:shine()
            end
        end
    end

    local matches, _, potentialMatches = self:calculateMatches()

    if matches or potentialMatches < 2 then

        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- flag to check if there is a potential match
    local potentialMatches = 0

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color
        local shinyInMatch = self.tiles[y][1].isShiny

        matchNum = 1

        -- every horizontal tile
        for x = 2, 8 do

            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                if self.tiles[y][x].isShiny then
                    shinyInMatch = true
                end

                matchNum = matchNum + 1
            else

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then

                    local match = {}

                    local startOfMatch = x - matchNum
                    local endOfMatch = x - 1

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do

                        -- if the tile is shiny add all the tiles in the row else add only the matched tiles

                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])
                    end

                    -- if shiny in match add all the tiles in the row
                    if shinyInMatch then

                        if startOfMatch > 1 then
                            for x2 = 1, startOfMatch - 1, 1 do
                                table.insert(match, self.tiles[y][x2])
                            end
                        end

                        if endOfMatch < 8 then
                            for x2 = endOfMatch + 1, 8, 1 do
                                table.insert(match, self.tiles[y][x2])
                            end
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                elseif potentialMatches < 2 then

                    local twoMatch = matchNum == 2

                    -- check the next tile to determine potential match
                    local gapMatch = x + 1 <= 8 and self.tiles[y][x + 1].color == colorToMatch

                    if gapMatch then
                        -- check if the tiles above or below the gap match colorToMatch
                        local aboveTileMatch = y - 1 > 0 and self.tiles[y - 1][x].color == colorToMatch
                        local belowTileMatch = y + 1 <= 8 and self.tiles[y + 1][x].color == colorToMatch

                        if aboveTileMatch or belowTileMatch then
                            potentialMatches = potentialMatches + 1
                        end

                    elseif twoMatch then
                        -- check if the tiles above, below, or right match colorToMatch
                        local rightAboveTileMatch = y - 1 > 0 and self.tiles[y - 1][x].color == colorToMatch
                        local rightBelowTileMatch = y + 1 <= 8 and self.tiles[y + 1][x].color == colorToMatch
                        local rightTileMatch = x + 1 <= 8 and self.tiles[y][x + 1].color == colorToMatch

                        -- check if the tiles above, below, or left of tile to the left of the match match colorToMatch
                        local leftAboveTileMatch = false
                        local leftBelowTileMatch = false
                        local leftTileMatch = false

                        local swapTileX = x - 3

                        if swapTileX > 0 and y > 1 then
                            leftAboveTileMatch = y - 1 > 0 and self.tiles[y - 1][swapTileX].color == colorToMatch
                            leftBelowTileMatch = y + 1 <= 8 and self.tiles[y + 1][swapTileX].color == colorToMatch
                            leftTileMatch = swapTileX > 1 and self.tiles[y][swapTileX - 1].color == colorToMatch
                        end

                        if rightTileMatch or leftTileMatch or rightAboveTileMatch or rightBelowTileMatch or
                            leftAboveTileMatch or leftBelowTileMatch then
                            potentialMatches = potentialMatches + 1
                        end
                    end

                end

                matchNum = 1

                shinyInMatch = self.tiles[y][x].isShiny

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end

                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}

            local startOfMatch = 8 - matchNum + 1

            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            if shinyInMatch then

                for x2 = 1, startOfMatch - 1, 1 do
                    table.insert(match, self.tiles[y][x2])
                end
            end

            table.insert(matches, match)
        elseif matchNum == 2 and potentialMatches < 2 then
            local leftAboveTileMatch = false
            local leftBelowTileMatch = false
            local leftTileMatch = false

            local swapTileX = x - 3

            leftAboveTileMatch = y - 1 > 0 and self.tiles[y - 1][swapTileX].color == colorToMatch
            leftBelowTileMatch = y + 1 <= 8 and self.tiles[y + 1][swapTileX].color == colorToMatch
            leftTileMatch = swapTileX > 1 and self.tiles[y][swapTileX - 1].color == colorToMatch

            if leftTileMatch or leftAboveTileMatch or leftBelowTileMatch then
                potentialMatches = potentialMatches + 1
            end
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color
        local shinyInMatch = self.tiles[1][x].isShiny

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                if self.tiles[y][x].isShiny then
                    shinyInMatch = true
                end

                matchNum = matchNum + 1
            else

                if matchNum >= 3 then

                    local match = {}

                    local startOfMatch = y - matchNum
                    local endOfMatch = y - 1

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                    end

                    -- if shiny in match add all the tiles in the column
                    if shinyInMatch then

                        if startOfMatch > 1 then
                            for y2 = 1, startOfMatch - 1, 1 do
                                table.insert(match, self.tiles[y2][x])
                            end
                        end

                        if endOfMatch < 8 then
                            for y2 = endOfMatch + 1, 8, 1 do
                                table.insert(match, self.tiles[y2][x])
                            end
                        end
                    end

                    table.insert(matches, match)
                elseif potentialMatches < 2 then

                    local twoMatch = matchNum == 2

                    -- check the next tile to determine potential match
                    local gapMatch = y + 1 <= 8 and self.tiles[y + 1][x].color == colorToMatch

                    if gapMatch then
                        -- check if the tiles left or right the gap match colorToMatch
                        local rightTileMatch = x + 1 <= 8 and self.tiles[y][x + 1].color == colorToMatch
                        local leftTileMatch = x - 1 > 0 and self.tiles[y][x - 1].color == colorToMatch

                        if rightTileMatch or leftTileMatch then
                            potentialMatches = potentialMatches + 1
                        end

                    elseif twoMatch then
                        -- check if the tiles right, left, or below match colorToMatch
                        local belowRightTileMatch = x + 1 <= 8 and self.tiles[y][x + 1].color == colorToMatch
                        local belowLeftTileMatch = x - 1 > 0 and self.tiles[y][x - 1].color == colorToMatch
                        local belowTileMatch = y + 1 <= 8 and self.tiles[y + 1][x].color == colorToMatch

                        -- check if the tiles right, left, or above of tile to the left of the match match colorToMatch
                        local aboveRightTileMatch = false
                        local aboveLeftTileMatch = false
                        local aboveTileMatch = false

                        local swapTileY = y - 3

                        if swapTileY > 0 then
                            aboveRightTileMatch = x + 1 <= 8 and self.tiles[swapTileY][x + 1].color == colorToMatch
                            aboveLeftTileMatch = x - 1 > 0 and self.tiles[swapTileY][x - 1].color == colorToMatch
                            aboveTileMatch = swapTileY > 1 and self.tiles[swapTileY - 1][x].color == colorToMatch
                        end

                        if belowRightTileMatch or belowLeftTileMatch or belowTileMatch or aboveTileMatch or
                            aboveRightTileMatch or aboveLeftTileMatch then
                            potentialMatches = potentialMatches + 1
                        end
                    end

                end

                matchNum = 1

                shinyInMatch = self.tiles[y][x].isShiny

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end

                colorToMatch = self.tiles[y][x].color
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}

            local startOfMatch = 8 - matchNum + 1

            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            if shinyInMatch then
                for y2 = 1, startOfMatch - 1, 1 do
                    table.insert(match, self.tiles[y2][x])
                end
            end

            table.insert(matches, match)
        elseif matchNum == 2 and potentialMatches < 2 then
            local aboveRightTileMatch = false
            local aboveLeftTileMatch = false
            local aboveTileMatch = false

            local swapTileY = y - 3

            aboveRightTileMatch = x + 1 <= 8 and self.tiles[swapTileY][x + 1].color == colorToMatch
            aboveLeftTileMatch = x - 1 > 0 and self.tiles[swapTileY][x - 1].color == colorToMatch
            aboveTileMatch = swapTileY > 1 and self.tiles[swapTileY - 1][x].color == colorToMatch

            if aboveTileMatch or aboveRightTileMatch or aboveLeftTileMatch then
                potentialMatches = potentialMatches + 1
            end
        end
    end

    -- loop through matches and score them
    local score = 0

    for k, match in pairs(matches) do
        local multiplier = 1

        -- give multiplier for shape matches
        for j, tile in pairs(match) do
            if tile.variety ~= 1 then
                for i = j + 1, #match, 1 do
                    if tile.variety == match[i].variety then
                        multiplier = multiplier < 3 and multiplier + 1 or multiplier

                    end
                end

            end
        end

        score = score + #match * multiplier
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches, score, potentialMatches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do

            -- if our last tile was a space...
            local tile = self.tiles[y][x]

            if space then

                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then

                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true

                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                local tileVariety = self.level < 6 and math.random(self.level) or math.random(6)

                local isShiny = math.random(shinyChance) == 1

                -- new tile with random color and variety
                local tile = Tile(x, y, math.random(colorCount), tileVariety, isShiny)
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }

                -- if the tile is shiny, shine it
                if tile.isShiny then
                    tile:shine()
                end
            end
        end
    end

    -- recalculate potential matches
    local _, _, potentialMatches = self:calculateMatches()

    if potentialMatches < 2 then
        print('No potential matches, reinitializing board')

        self:initializeTiles()
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end
