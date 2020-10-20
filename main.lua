do
    package.cpath = package.cpath .. ";/Users/yuegangyang/.vscode/extensions/tangzx.emmylua-0.3.49/debugger/emmy/mac/emmy_core.dylib"
    package.cpath = package.cpath .. ";C:/Users/yuqi/.vscode/extensions/tangzx.emmylua-0.3.49/debugger/emmy/windows/x64/emmy_core.dll"
    local dbg = require("emmy_core")
    dbg.tcpListen("localhost", 9966)
end


local astar = require("astar")
local graphics = love.graphics
local mouse = love.mouse


local map_width = 40
local map_height = 30

local tile_size = 20
local tile_size_inv = 1.0 / 20
local tile_draw_size = tile_size - 2


local tile_start = nil
local tile_end = nil

local find_path = nil
local find_failed = false


local function create_map()
    local mathRandom = math.random
    local map = {}
    for i = 1, map_width do
        map[i] = map[i] or {}
        local map_row = map[i]

        for j = 1, map_height do
            map_row[j] = mathRandom(0, 2)
        end
    end
    astar.init_map(map, map_width, map_height)
end


local function on_mouse_click(x, y)
    local tile_x, tile_y = math.floor(x * tile_size_inv) + 1, math.floor(y  * tile_size_inv) + 1
    if tile_start == nil then
        tile_start = {x = tile_x, y = tile_y}
    elseif tile_end == nil then
        tile_end = {x = tile_x, y = tile_y}

        find_path = astar.find_path(tile_start, tile_end)
        if not find_path then
            find_failed = true
        end        
    else
        tile_start = nil
        tile_end = nil
        find_path = nil
        find_failed = false
    end
end

local function get_tile_center(item) 
    return (item.x - 0.5) * tile_size, (item.y - 0.5) * tile_size
end

local function draw_tile(tile_x, tile_y, r, g, b, a) 
    graphics.setColor(r, g, b, a)
    graphics.rectangle("fill", (tile_x - 1) * tile_size + 1, (tile_y - 1) * tile_size + 1, tile_draw_size, tile_draw_size)
end

local function draw_map() 
    local map = astar.get_map()
    for i = 1, map_width do
        local row = map[i]
        for j = 1, map_height do
            if row[j] == 0 then
                draw_tile(i, j, 0, 0, 0, 1)
            else
                draw_tile(i, j, 0, 1, 0, row[j] * 0.2 + 0.5)
            end
        end
    end
end

local function draw_touch()
    if tile_start ~= nil then
        draw_tile(tile_start.x, tile_start.y, 1, 1, 0, 1)
    end
    if tile_end ~= nil then
        draw_tile(tile_end.x, tile_end.y, 1, 1, 0, 1)
    end
end

local function draw_path()    
    if find_path == nil then
        return
    end

    graphics.setColor(1, 1, 0, 1)
    for i = 1, #find_path - 1 do
        local x1, y1 = get_tile_center(find_path[i])
        local x2, y2 = get_tile_center(find_path[i + 1])
        graphics.line(x1, y1, x2, y2)
    end
end

function love.load()
    math.randomseed(os.time())
    create_map()
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        on_mouse_click(x, y)
    end    
end

function love.draw()
    -- body
    draw_map()
    draw_touch()
    draw_path()

    if find_failed then
        graphics.setColor(1, 1, 1, 1)
        graphics.printf("Find path failed!", 100, 100, 100)
    end
end