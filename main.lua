-- very scuffed code
-- please mind my terrible variable naming

-- ########################################### PERSONAL NOTES ###########################################
-- error catching at line 227 ish

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

local orbitals = {
    radius  = {k = 1, v = 0},
    sma  = {k = 2, v = 0},
    ecc  = {k = 3, v = 0},
    apo  = {k = 4, v = 0},
    peri  = {k = 5, v = 0},
    smi  = {k = 6, v = 0},
}
local stored = {
    apo = 0,
    per = 0,
}

--[[  OTHER VARIABLES  ]] --
local eccmin = 0
local eccmax = 1 - eccoffmin^2

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
local pchairscale = .05

local mx
local my

local inpmode = false
local inpnum = ""
local dspmodes = {
    [1] = "Radius",
    [2] = "Semi Major Axis",
    [3] = "Eccentricity",
    [4] = "Apoapsis",
    [5] = "Periapsis"
}
local mode = 1

local keydown = false
local currkey = 1
local lastkey

--[[ CHANGE THIS IF YOU WANT BUT KEEP IN MIND SOME KEYS WONT WORK ]]
local keymap = {
    up = "w",
    down = "s",
    left = "a",
    right = "d",
    zoomin = "e",
    zoomout = "q",
    debug = "tab",
    cancel = "delete",
    undo = "backspace",
    confirm = "return",
    inpmode = "/",
    eccup = "r",
    eccdown = "f",
    smaup = "t",
    smadown = "g",
    resetpos = "kp0",
    followellipse = "kp."
}

local followellipse = false
local debug = false

local perstrt
local peredge

local apostrt
local apoedge

local pposx
local pposy

local ellx
local elly

-- [[ RANDOM FUNCTIONS IDK ]]
local function zoom(z)
    if z == "-" and scale > minscale then scale = scale - (scale * scale / sfac) * factor
    elseif z == "+" and scale < maxscale then scale = scale + (scale * scale / sfac) * factor end
end

local function move(z) -- goofy ahh code pls don't analyze too deep
    if z == keymap.up then posy = posy + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == keymap.down then posy = posy - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == keymap.left then posx = posx + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == keymap.right then posx = posx - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5) end
end

local function calculate_vars()
    mx = love.graphics.getPixelWidth() / 2
    my = love.graphics.getPixelHeight() / 2

    perstrt = mx + ((posx + orbitals.radius.v ) / scale)
    peredge = mx + ((posx + orbitals.peri.v ) / scale)

    apostrt = mx + ((posx - orbitals.radius.v ) / scale)
    apoedge = mx + ((posx - orbitals.apo.v ) / scale)

    pposx = mx + (posx / scale)
    pposy = my + (posy / scale)
    
    ellx = mx + (posx - (orbitals.sma.v  - (orbitals.sma.v  * (orbitals.peri.v  / orbitals.sma.v )))) / scale
    elly = pposy
end

-- [[ ACTUAL START OF CODE ]]
function love.load()
    love.window.setVSync(0)
    love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})
    love.window.maximize()

    orbitals.radius.v  = 6371
    orbitals.sma.v  = 80000
    orbitals.ecc.v  = .9
    
    calculate_vars()
end

function love.update()
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    if love.keyboard.isDown(keymap.debug) and keydown == false then
        keydown = true
        currkey = 10
        lastkey = keymap.debug
        debug = not debug
    end

    if inpmode == true then

        if love.keyboard.isDown(keymap.cancel) then
            inpmode = false
        end

        if love.keyboard.isDown(keymap.undo) and keydown == false then
            if #inpnum > 1 then
                keydown = true
                currkey = 10
                lastkey = keymap.undo
                inpnum = inpnum:sub(1, #inpnum - 1)
            else
                inpnum = ""
            end
        end

        if love.keyboard.isDown(".") and keydown == false and not inpnum:find("%.") then
            keydown = true
            currkey = 10
            lastkey = "."
            inpnum = inpnum.."."
        end
        if love.keyboard.isDown("e") and keydown == false and not inpnum:find("%.") then
            keydown = true
            currkey = 10
            lastkey = "e"
            inpnum = inpnum.."e"
        end
        if love.keyboard.isDown("-") and keydown == false and not inpnum:find("%.") then
            keydown = true
            currkey = 10
            lastkey = "-"
            inpnum = inpnum.."-"
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
                inpnum = inpnum..key
            end
            if not love.keyboard.isDown(key) and currkey == key then
                keydown = false
            end
        end

        if love.keyboard.isDown(keymap.confirm) then
            for _, y in pairs(orbitals) do
                if y.k == mode then
                    if inpnum == nil or inpnum == "" or inpnum:sub(1,1) == "e" or inpnum:sub(1,1) == "-" then
                        y.v = tonumber(0)
                    else
                        if inpnum:sub(-1) == "e" or inpnum:sub(-1) == "-" then
                            inpnum = inpnum:sub(1, #inpnum - 1)
                        elseif inpnum:find("-") ~= nil and inpnum:find("e") == nil then
                            inpnum = inpnum:gsub("-","")
                        end
                        if dspmodes[mode] ~= "Apoapsis" and dspmodes[mode] ~= "Periapsis" then
                            y.v = tonumber(inpnum)
                        else
                            if dspmodes[mode] == "Apoapsis" then
                                stored.apo = tonumber(inpnum)
                            elseif dspmodes[mode] == "Periapsis" then
                                stored.per = tonumber(inpnum)
                            end
                            if not (stored.apo == 0 or stored.per == 0) then
                                orbitals.ecc.v = (stored.apo-stored.per)/(stored.apo+stored.per)
                                orbitals.sma.v = (stored.per + stored.apo)/2
                            end
                        end
                    end
                end
            end

            currkey = 0
            inpnum = ""
            inpmode = false
        end

    elseif inpmode == false then

        if love.keyboard.isDown(keymap.zoomin) then zoom("-") end
        if love.keyboard.isDown(keymap.zoomout) then zoom("+") end
        if scale < minscale then scale = minscale end
        if scale > maxscale then scale = maxscale end

        if love.keyboard.isDown(keymap.up) then move(keymap.up) end
        if love.keyboard.isDown(keymap.down) then move(keymap.down) end
        if love.keyboard.isDown(keymap.left) then move(keymap.left) end
        if love.keyboard.isDown(keymap.right) then move(keymap.right) end

        if love.keyboard.isDown(keymap.eccup) and orbitals.ecc.v  < eccmax then
            orbitals.ecc.v  = orbitals.ecc.v  + eccoff
        end
        if love.keyboard.isDown(keymap.eccdown) and orbitals.ecc.v  > eccmin then
            orbitals.ecc.v  = orbitals.ecc.v  - eccoff
        end
        if orbitals.ecc.v  > eccmax then orbitals.ecc.v  = eccmax end
        if orbitals.ecc.v  < eccmin then orbitals.ecc.v  = eccmin end

        if love.keyboard.isDown(keymap.smaup) then
            orbitals.sma.v  = orbitals.sma.v  + orboff
        end
        if love.keyboard.isDown(keymap.smadown) and orbitals.sma.v  > orbitals.radius.v  then
            orbitals.sma.v  = orbitals.sma.v  - orboff
        end
        if orbitals.sma.v  < orbitals.radius.v  then orbitals.sma.v  = orbitals.radius.v  end

        if love.keyboard.isDown("1") then
            eccoff = eccoffmin
            orboff = orboffmin
            factor = facmin
        end
        if love.keyboard.isDown("2") then
            eccoff = eccoffstd
            orboff = orboffstd
            factor = facstd
        end
        if love.keyboard.isDown("3") then
            eccoff = eccoffmax
            orboff = orboffmax
            factor = facmax
        end

        if love.keyboard.isDown(keymap.inpmode) then
            inpmode = true
        end

        if love.keyboard.isDown(keymap.resetpos) then
            posx, posy = 0, 0
        end
        if love.keyboard.isDown(keymap.followellipse) and keydown == false then
            keydown = true
            currkey = 10
            lastkey = keymap.followellipse

            followellipse = not followellipse
        end
    end

    if lastkey ~= nil then
        if not love.keyboard.isDown(lastkey) and currkey == 10 then
            keydown = false
        end
    end

    if followellipse == true then
        posx = (pposx - ellx) * scale
        posy = 0
    end

    orbitals.smi.v  = orbitals.sma.v *math.sqrt(1-(orbitals.ecc.v ^2))

    orbitals.apo.v  = (orbitals.sma.v *(1+orbitals.ecc.v ))
    orbitals.peri.v  = (orbitals.sma.v *(1-orbitals.ecc.v ))
end

function love.draw()

    love.graphics.setColor(1,1,1,1)

    calculate_vars()

    -- [[ ORBITAL PROFILE INFO TEXT ]]
    love.graphics.print("Apo. : "..orbitals.apo.v .."km ("..orbitals.apo.v -orbitals.radius.v .."km)", apoedge + 10, pposy - 16)
    love.graphics.print("Apo. : "..orbitals.apo.v .."km ("..orbitals.apo.v -orbitals.radius.v .."km)", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 24)
    love.graphics.print("Per. : "..orbitals.peri.v .."km ("..orbitals.peri.v -orbitals.radius.v .."km)", peredge + 10, pposy)
    love.graphics.print("Per. : "..orbitals.peri.v .."km ("..orbitals.peri.v -orbitals.radius.v .."km)", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 36)
    love.graphics.print("Ecc. :"..orbitals.ecc.v , mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 12)
    love.graphics.print("SMaA :"..orbitals.sma.v .."km", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 60)
    love.graphics.print("SMiA :"..orbitals.smi.v .."km", mx + ((posx - orbitals.radius.v ) / scale), my + ((posy + orbitals.radius.v ) / scale) + 72)
    
    love.graphics.circle("line", pposx, pposy, orbitals.radius.v  / scale)
    love.graphics.line(pposx, pposy - ((pchairscale * orbitals.radius.v) / scale), pposx, pposy + ((pchairscale * orbitals.radius.v) / scale))
    love.graphics.line(pposx - ((pchairscale * orbitals.radius.v) / scale), pposy, pposx + ((pchairscale * orbitals.radius.v) / scale), pposy)
    
    -- [[ ORBITAL ELLIPSE RENDERING ]] --
    love.graphics.setColor(0.5,0.5,1,1)
    love.graphics.ellipse("line", ellx, elly, orbitals.sma.v  / scale, orbitals.smi.v  / scale)
    
    love.graphics.line(perstrt, pposy, peredge, pposy)
    love.graphics.line(apostrt, pposy, apoedge, pposy)
    
    love.graphics.setColor(1,1,1,.25)
    love.graphics.line(ellx, elly - (orbitals.smi.v  / scale), ellx, elly + (orbitals.smi.v  / scale))
    love.graphics.line(ellx - (orbitals.sma.v  / scale), elly, ellx + (orbitals.sma.v  / scale), elly)

    -- [[ CROSSHAIR AND STUFF IDK ]]
    local chair = (ellscale * orbitals.sma.v ) / scale --CROSSHAIR NOT CHAIR AS IN SITTING THING
    love.graphics.line(ellx - chair, elly - chair, ellx + chair, elly + chair)
    love.graphics.line(ellx - chair, elly + chair, ellx + chair, elly - chair)

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
            love.graphics.print(x.." "..y.v   , 12, 12 * i)
            i = i + 1
        end
        love.graphics.print((ellx * scale), 12, 12 * i)

        love.graphics.print(scale, 12, love.graphics.getPixelHeight() - 24)
        love.graphics.print(posx..":"..posy, 12, love.graphics.getPixelHeight() - 36)
        love.graphics.print("offsets : "..eccoff.." : "..orboff.." : "..factor, 12, love.graphics.getPixelHeight() - 48)

        love.graphics.setColor(1,1,1,.25)
        love.graphics.line(mx - chairscale, my + chairscale, mx + chairscale, my - chairscale)
        love.graphics.line(mx - chairscale, my - chairscale, mx + chairscale, my + chairscale)
    end
end
