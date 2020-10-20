local math = math
local table = table
local ipairs = ipairs

local m = {}
m.map = nil
m.width = 0
m.height = 0
m.start_pos = nil
m.end_pos = nil

m.open_list = {}
m.close_list = {}

local item_pool = {}
local function spwan_item(x, y)
    local item
    if #item_pool > 0 then
        item = table.remove(item_pool)
    else
        item = {}
    end
    item.x = x
    item.y = y
    item.w = m.map[x][y]

    return item
end

local function despwan_list(list)
    while #list > 0 do
        local item = table.remove(list)
        table.insert(item_pool, item)
    end
end

local function clean_list_item()
end

local function calc_h(item)
    local end_pos = m.end_pos
    return math.abs(item.x - end_pos.x) + math.abs(item.y - end_pos.y)
end

local function calc_g(item, parent)
    if parent == nil then
        return 0
    end

    local d =  math.abs(item.x - parent.x) + math.abs(item.y - parent.y)
    if d == 1 then
        return parent.g + (item.w + parent.w) * 0.5
    end
    return parent.g + (item.w + parent.w) * 0.5 * 1.414
end

local function calc_h_g(item, parent)
    item.h = calc_h(item)
    item.g = calc_g(item, parent)
    item.parent = parent
end

local function check_nearest_in_open_list()
    local min_f = m.height * m.width
    local index = 0
    for i, v in ipairs(m.open_list) do
        local f = v.h + v.g
        if min_f > f then
            min_f = f
            index = i
        end
    end
    return index
end

local function index_of_list(list, x, y)
    for index, value in ipairs(list) do
        if value.x == x and value.y == y then
            return index
        end
    end
    return nil
end

local function try_add_tile_to_open_list(parent, x, y)
    if index_of_list(m.close_list, x, y) == nil then
        local next_index = index_of_list(m.open_list, x, y)
        if next_index == nil then
            local next_item = spwan_item(x, y)
            calc_h_g(next_item, parent)
            table.insert(m.open_list, next_item)
        else
            local old_item = m.open_list[next_index]
            local new_g = calc_g(old_item, parent)
            if new_g < old_item.g then
                old_item.g = new_g
                old_item.parent = parent
            end
        end
    end
end

local tile_surround_x = {-1, -1, -1, 0, 1, 1, 1, 0}
local tile_surround_y = {1, 0, -1, -1, -1, 0, 1, 1}

local function get_map_weight(x, y)
    if x > 0 and y > 0 and x <= m.width and y <= m.height then
        return m.map[x][y]
    end
    return 0
end

local function get_tile_surround_weight(item, index)            
    local x2 = item.x + tile_surround_x[index]
    local y2 = item.y + tile_surround_y[index]
    return get_map_weight(x2, y2)
end

local function check_surround_tile(item)
    local x = item.x
    local y = item.y
    local surround_len = #tile_surround_x

    for i, v in ipairs(tile_surround_x) do
        local x1 = x + v
        local y1 = y + tile_surround_y[i]
       
        local weight = get_map_weight(x1, y1)
        if weight > 0 then
            if i % 2 == 1 then                    
                if get_tile_surround_weight(item, (i - 2 + surround_len) % surround_len + 1) > 0 
                    or get_tile_surround_weight(item, (i + surround_len) % surround_len + 1) > 0 then
                    try_add_tile_to_open_list(item, x1, y1)                  
                end
            else
                try_add_tile_to_open_list(item, x1, y1)
            end
        end
    end        
end


function m.init_map(map, tile_width, tile_height)
    m.map = map
    m.width = tile_width
    m.height = tile_height
end

function m.get_map()
    return m.map
end

function m.find_path(start_pos, end_pos)
    assert(start_pos.x and start_pos.y, "start_pos need has value!")
    assert(end_pos.x and end_pos.y, "end_pos need has value!")
    
    m.start_pos = start_pos
    m.end_pos = end_pos

    despwan_list(m.close_list)

    local start_tile = spwan_item(start_pos.x, start_pos.y)
    calc_h_g(start_tile, nil)
    table.insert(m.open_list, start_tile)

    local tile_end = nil
    while #m.open_list > 0 do
        local index = check_nearest_in_open_list()
        local item = table.remove(m.open_list, index)        
        table.insert(m.close_list, item)
        if item.x == end_pos.x and item.y == end_pos.y then
            tile_end = item
            break
        end
        check_surround_tile(item)
    end

    despwan_list(m.open_list)

    if not tile_end then
        return nil
    end

    local path = {}
    local item = tile_end
    while item do
        table.insert(path, item)
        item = item.parent
    end
    return path
end

return m