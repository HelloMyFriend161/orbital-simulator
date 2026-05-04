-- very scuffed code
-- please mind my terrible variable naming

-- ########################################### PERSONAL NOTE ###########################################
-- add dot support blabla the input thing
-- debug button

--[[  ORBITAL VARIABLES  ]] --
local posx = 0
local posy = 0

local scale = 200

local eccoff = .005
local eccoffstd = .005
local eccoffmin = .0001
local eccoffmax = .05

local orboff = 100
local orboffstd = 100
local orboffmin = 10
local orboffmax = 1000

--[[  ESSENTIAL ORBITAL VARIABLES  ]] --

local orbitals= {
    ["radius"]  = {k = 1, v = tonumber(0)},
    ["sma"]  = {k = 2, v = tonumber(0)},
    ["ecc"]  = {k = 3, v = tonumber(0)},
    ["smi"]  = {k = 4, v = tonumber(0)},
    ["apo"]  = {k = 5, v = tonumber(0)},
    ["peri"]  = {k = 6, v = tonumber(0)},
}

--[[  OTHER VARIABLES  ]] --
local eccmin = 0
local eccmax = 1 - eccoffmin

local factor = 1
local facstd = 1
local facmin = .5
local facmax = 5

local sfac = 10000
local pfac = 20

local minscale = 15
local maxscale = 3000

local chairscale = 5
local ellscale = .025

local mx
local my

local inpmode = false
local inpnum = tonumber(0)
local dspmodes = {
    [1] = "Radius",
    [2] = "Semi Major Axis",
    [3] = "Eccentricity"
}
local mode = 1
local keydown = false
local currkey = 0

local debug = false

-- [[ RANDOM FUNCTIONS IDK ]]
local function zoom(z)
    if z == "-" and scale > minscale then scale = scale - (scale * scale / sfac) * factor
    elseif z == "+" and scale < maxscale then scale = scale + (scale * scale / sfac) * factor end
end

local function move(z) -- goofy ahh code pls don't analyze too deep
    if z == "w" then posy = posy + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "a" then posx = posx + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "s" then posy = posy - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "d" then posx = posx - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5) end
end

-- [[ ACTUAL START OF CODE ]]
function love.load()
    love.window.setVSync(0)
    love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})
    love.window.maximize()

    orbitals.radius.v  = 6371
    orbitals.sma.v  = 80000
    orbitals.ecc.v  = .9
end

function love.update()
    if love.keyboard.isDown("escape") then
            love.event.quit()
        end
    
    mx = love.graphics.getPixelWidth() / 2
    my = love.graphics.getPixelHeight() / 2

    if inpmode == true then

        if love.keyboard.isDown("backspace") then
            inpmode = false
        end
        if love.keyboard.isDown("delete") then
            inpnum = 0
        end
        
        for i = 1, 9 do
            local key = "kp"..i
            if love.keyboard.isDown(key) and dspmodes[i] then
                mode = i
            end
        end

        for i = 0, 9 do
            local key = i
            if love.keyboard.isDown(key) and keydown == false then
                keydown = true
                currkey = i
                inpnum = tonumber(inpnum..key)
            end
            if not love.keyboard.isDown(key) and currkey == key then
                keydown = false
            end
        end

        if love.keyboard.isDown("return") then
            local i = 1
            for x, y in pairs(orbitals) do
                if orbitals[x].k == mode then
                    orbitals[x].v = inpnum
                end
            end

            currkey = 0
            inpnum = 0
            inpmode = false
        end

    elseif inpmode == false then

        if love.keyboard.isDown("e") then zoom("-") end
        if love.keyboard.isDown("q") then zoom("+") end
        if scale < minscale then scale = minscale end
        if scale > maxscale then scale = maxscale end

        if love.keyboard.isDown("w") then move("w") end
        if love.keyboard.isDown("s") then move("s") end
        if love.keyboard.isDown("a") then move("a") end
        if love.keyboard.isDown("d") then move("d") end

        if love.keyboard.isDown("r") and orbitals.ecc.v  < eccmax then
            orbitals.ecc.v  = orbitals.ecc.v  + eccoff
        end
        if love.keyboard.isDown("f") and orbitals.ecc.v  > eccmin then
            orbitals.ecc.v  = orbitals.ecc.v  - eccoff
        end
        if orbitals.ecc.v  > eccmax then orbitals.ecc.v  = eccmax end
        if orbitals.ecc.v  < eccmin then orbitals.ecc.v  = eccmin end

        if love.keyboard.isDown("t") then
            orbitals.sma.v  = orbitals.sma.v  + orboff
        end
        if love.keyboard.isDown("g") and orbitals.sma.v  > orbitals.radius.v  then
            orbitals.sma.v  = orbitals.sma.v  - orboff
        end
        if orbitals.sma.v  < orbitals.radius.v  then orbitals.sma.v  = orbitals.radius.v  end

        if love.keyboard.isDown("2") then
            eccoff = eccoffstd
            orboff = orboffstd
            factor = facstd
        end
        if love.keyboard.isDown("1") then
            eccoff = eccoffmin
            orboff = orboffmin
            factor = facmin
        end
        if love.keyboard.isDown("3") then
            eccoff = eccoffmax
            orboff = orboffmax
            factor = facmax
        end

        if love.keyboard.isDown("/") then
            inpmode = true
        end

    end

    orbitals.smi.v  = orbitals.sma.v *math.sqrt(1-(orbitals.ecc.v ^2))

    orbitals.apo.v  = (orbitals.sma.v *(1+orbitals.ecc.v ))
    orbitals.peri.v  = (orbitals.sma.v *(1-orbitals.ecc.v ))
end

function love.draw()

    love.graphics.setColor(1,1,1,1)

    local perstrt = mx + ((posx + orbitals.radius.v ) / scale)
    local peredge = mx + ((posx + orbitals.peri.v ) / scale)

    local apostrt = mx + ((posx - orbitals.radius.v ) / scale)
    local apoedge = mx + ((posx - orbitals.apo.v ) / scale)

    local ellx = mx + (posx - (orbitals.sma.v  - (orbitals.sma.v  * (orbitals.peri.v  / orbitals.sma.v )))) / scale
    local elly = my + (posy / scale)

    -- [[ ORBITAL PROFILE INFO TEXT ]]
    love.graphics.print("Apo. : "..orbitals.apo.v .."km ("..orbitals.apo.v -orbitals.radius.v .."km)", apoedge + 10, my + (posy / scale) - 16)
    love.graphics.print("Apo. : "..orbitals.apo.v .."km ("..orbitals.apo.v -orbitals.radius.v .."km)", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 24)
    love.graphics.print("Per. : "..orbitals.peri.v .."km ("..orbitals.peri.v -orbitals.radius.v .."km)", peredge + 10, my + (posy / scale))
    love.graphics.print("Per. : "..orbitals.peri.v .."km ("..orbitals.peri.v -orbitals.radius.v .."km)", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 36)
    love.graphics.print("Ecc. :"..orbitals.ecc.v , mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 12)
    love.graphics.print("SMaA :"..orbitals.sma.v .."km", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 60)
    love.graphics.print("SMiA :"..orbitals.smi.v .."km", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 72)
    
    love.graphics.circle("line", mx + (posx / scale), my + (posy / scale), orbitals.radius.v  / scale)
    
    -- [[ ORBITAL ELLIPSE RENDERING ]] --
    love.graphics.setColor(0.5,0.5,1,1)
    love.graphics.ellipse("line", ellx, elly, orbitals.sma.v  / scale, orbitals.smi.v  / scale)
    
    love.graphics.line(perstrt, my + (posy / scale), peredge, my + (posy / scale))
    love.graphics.line(apostrt, my + (posy / scale), apoedge, my + (posy / scale))
    
    love.graphics.setColor(1,1,1,.25)
    love.graphics.line(ellx, elly - (orbitals.smi.v  / scale), ellx, elly + (orbitals.smi.v  / scale))
    love.graphics.line(ellx - (orbitals.sma.v  / scale), elly, ellx + (orbitals.sma.v  / scale), elly)

    -- [[ CROSSHAIR AND STUFF IDK ]]
    local chair = (ellscale * orbitals.sma.v ) / scale --CROSSHAIR NOT CHAIR AS IN SITTING THING
    love.graphics.line(ellx - chair, elly - chair, ellx + chair, elly + chair)
    love.graphics.line(ellx - chair, elly + chair, ellx + chair, elly - chair)

    love.graphics.line(mx - chairscale, my + chairscale, mx + chairscale, my - chairscale)
    love.graphics.line(mx - chairscale, my - chairscale, mx + chairscale, my + chairscale)

    love.graphics.print(tostring(inpmode), 0, 0)
    
    love.graphics.setColor(1,1,1,1)
    if inpmode == true then
        love.graphics.print("Input Mode", mx - 48, my / 100, 0, 1.5)
        love.graphics.print("Mode : "..mode.." ("..dspmodes[mode]..")", mx - 60, my * 1.025)
        love.graphics.print(">"..inpnum, mx - 60, (my * 1.025) + 12)
    end

    if debug == true then
        local i = 1
        for x, y in pairs(orbitals) do
            love.graphics.print(x.." "..orbitals[x].v   , 12, 12 * i)
            i = i + 1
        end

        love.graphics.print(scale, 12, love.graphics.getPixelHeight() - 24)
        love.graphics.print(posx..":"..posy, 12, love.graphics.getPixelHeight() - 36)
        love.graphics.print("offsets : "..eccoff.." : "..orboff.." : "..factor, 12, love.graphics.getPixelHeight() - 48)
    end
end
