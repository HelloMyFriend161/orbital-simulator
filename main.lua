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
local radius

local sma
local smi
local apo
local peri

local ecc

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

local function zoom(z)
    if z == "-" and scale > minscale then scale = scale - (scale * scale / sfac) * factor
    elseif z == "+" and scale < maxscale then scale = scale + (scale * scale / sfac) * factor end
end
local function move(z)
    if z == "w" then posy = posy + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "a" then posx = posx + math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "s" then posy = posy - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5)
    elseif z == "d" then posx = posx - math.floor((((scale * scale / (sfac / pfac)) * pfac) * factor) + .5) end
end

function love.load()
    love.window.setVSync(0)
    love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})
    love.window.maximize()

    radius = 6371
    sma = 80000
    ecc = .9
end

function love.update()
    if love.keyboard.isDown("escape") == true then
        love.event.quit()
    end

    mx = love.graphics.getPixelWidth() / 2
    my = love.graphics.getPixelHeight() / 2

    if love.keyboard.isDown("e") then zoom("-") end
    if love.keyboard.isDown("q") then zoom("+") end
    if scale < minscale then scale = minscale end
    if scale > maxscale then scale = maxscale end

    if love.keyboard.isDown("w") then move("w") end
    if love.keyboard.isDown("s") then move("s") end
    if love.keyboard.isDown("a") then move("a") end
    if love.keyboard.isDown("d") then move("d") end

    if love.keyboard.isDown("r") and ecc < eccmax then
        ecc = ecc + eccoff
    end
    if love.keyboard.isDown("f") and ecc > eccmin then
        ecc = ecc - eccoff
    end
    if ecc > eccmax then ecc = eccmax end
    if ecc < eccmin then ecc = eccmin end

    if love.keyboard.isDown("t") then
        sma = sma + orboff
    end
    if love.keyboard.isDown("g") and sma > radius then
        sma = sma - orboff
    end
    if sma < radius then sma = radius end

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

    smi = sma*math.sqrt(1-(ecc^2))

    apo = (sma*(1+ecc))
    peri = (sma*(1-ecc))
end

function love.draw()
    love.graphics.setColor(1,1,1,1)

    local perstrt = mx + ((posx + radius) / scale)
    local peredge = mx + ((posx + peri) / scale)

    local apostrt = mx + ((posx - radius) / scale)
    local apoedge = mx + ((posx - apo) / scale)

    local ellx = mx + (posx - (sma - (sma * (peri / sma)))) / scale
    local elly = my + (posy / scale)

    love.graphics.print("Apo. : "..apo.."km ("..apo-radius.."km)", apoedge + 10, my + (posy / scale) - 16)
    love.graphics.print("Apo. : "..apo.."km ("..apo-radius.."km)", mx + ((posx - radius) / scale), my + ((posy + radius) / scale) + 24)
    love.graphics.print("Per. : "..peri.."km ("..peri-radius.."km)", peredge + 10, my + (posy / scale))
    love.graphics.print("Per. : "..peri.."km ("..peri-radius.."km)", mx + ((posx - radius) / scale), my + ((posy + radius) / scale) + 36)
    love.graphics.print("Ecc. :"..ecc, mx + ((posx - radius) / scale), my + ((posy + radius) / scale) + 12)
    love.graphics.print("SMaA :"..sma.."km", mx + ((posx - radius) / scale), my + ((posy + radius) / scale) + 60)
    love.graphics.print("SMiA :"..smi.."km", mx + ((posx - radius) / scale), my + ((posy + radius) / scale) + 72)
    
    love.graphics.print(scale, 12, love.graphics.getPixelHeight() - 24)
    love.graphics.print(posx..":"..posy, 12, love.graphics.getPixelHeight() - 36)
    love.graphics.print("offsets : "..eccoff.." : "..orboff.." : "..factor, 12, love.graphics.getPixelHeight() - 48)
    
    love.graphics.circle("line", mx + (posx / scale), my + (posy / scale), radius / scale)
    
    love.graphics.setColor(0.5,0.5,1,1)
    love.graphics.ellipse("line", ellx, elly, sma / scale, smi / scale)
    
    love.graphics.line(perstrt, my + (posy / scale), peredge, my + (posy / scale))
    love.graphics.line(apostrt, my + (posy / scale), apoedge, my + (posy / scale))
    
    love.graphics.setColor(1,1,1,.25)
    love.graphics.line(ellx, elly - (smi / scale), ellx, elly + (smi / scale))
    love.graphics.line(ellx - (sma / scale), elly, ellx + (sma / scale), elly)

    local chair = (ellscale * sma) / scale
    love.graphics.line(ellx - chair, elly - chair, ellx + chair, elly + chair)
    love.graphics.line(ellx - chair, elly + chair, ellx + chair, elly - chair)

    love.graphics.line(mx - chairscale, my + chairscale, mx + chairscale, my - chairscale)
    love.graphics.line(mx - chairscale, my - chairscale, mx + chairscale, my + chairscale)
end
