ipc = {}

local MP = minetest.get_modpath("ipc")
dofile(MP.."/http.lua")
dofile(MP.."/file.lua")

if minetest.get_modpath("mtt") and mtt.enabled then
    dofile(MP.."/file.spec.lua")
end