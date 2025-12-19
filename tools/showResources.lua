-- Inspecting sizes of SGDK assets in out/release/synbols.txt
-- by Mikhail Bratus | https://github.com/D0NM/SGDKlua

local showMaxAssetsCount = 20
local defaultPathToFile = '../out/release/symbol.txt'

-- read and parse symbol.txt

local function parse_symbol_file(filepath)
    local symbols = {}

    local file = io.open(filepath, "r")
    if not file then
        error("Cannot open file: " .. filepath)
    end

    for line in file:lines() do
        -- skip empty lines
        line = line:match("^%s*(.-)%s*$") -- r l spaces trim
        if line ~= "" then
            -- parse line by pattern
            local hex_offset, resource_type, resource_name = line:match("^(%x+)%s+(%S+)%s+(.*)$")
            if hex_offset and resource_type and resource_name then
                -- should end with "_size"
                if resource_name:sub(-5) == "_size" then
                    -- convert hex
                    local offset = tonumber(hex_offset, 16)
                    table.insert(symbols, {
                        name = resource_name,
                        size = offset -- use offset as size
                    })
                end
            end
        end
    end

    file:close()
    return symbols
end

local function sort_symbols_by_size(symbols)
    table.sort(symbols, function(a, b)
        return a.size > b.size
    end)
end

-- Function: prints top resources matching the filter(s)
-- filter: string OR table of strings (substrings to search for)
local function printTopResources(symbols, filter)
    -- Convert single string to table for uniform processing
    local filters
    if type(filter) == "string" then
        filters = {filter}
    elseif type(filter) == "table" then
        filters = filter
    else
        error("Filter must be a string or a table of strings")
    end

    -- Filter symbols: name must contain at least one of the substrings
    local filtered = {}
    for _, symbol in ipairs(symbols) do
        for _, substring in ipairs(filters) do
            if string.find(symbol.name, substring, 1, true) then -- literal search (no regex)
                table.insert(filtered, symbol)
                break -- found at least one match - sufficient
            end
        end
    end

    -- Sort filtered symbols by size (descending)
    sort_symbols_by_size(filtered)

    -- Create header: join filters with "|"
    local filter_str = table.concat(filters, "|")

    -- Print top results
    print(string.format("Top %i resources (filter: '%s'):", showMaxAssetsCount, filter_str))
    print("-------------------------")
    for i = 1, math.min(showMaxAssetsCount, #filtered) do
        print(string.format("%2d. %-40s %8d", i, filtered[i].name, filtered[i].size))
    end
    print() -- empty line for separation
end

local function main(filepath)
    local symbols = parse_symbol_file(filepath)
    
    printTopResources(symbols, "palette")
    printTopResources(symbols, "font")
    printTopResources(symbols, "pcm")
    printTopResources(symbols, "xgm")
    printTopResources(symbols, {"map1", "map2", "map4", "map5", "map6", "map7", "map8"})
    printTopResources(symbols, "metatiles")
    printTopResources(symbols, "tileset")
    printTopResources(symbols, "tilemap")
    printTopResources(symbols, "sprite_animation")
end

local filepath
-- check args
if #arg < 1 then
    print("use script: lua script.lua <path_to_symbol.txt>")
    filepath = defaultPathToFile
else
    filepath = arg[1]
end
main(filepath)
