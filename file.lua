local path = minetest.get_worldpath() .. "/ipc"
minetest.mkdir(path)

local function get_filename(modname, direction)
    return path .. "/" .. modname .. "_" .. direction .. "_" .. os.time() .. math.random(999)
end

local FileIPC = {}
local FileIPC_mt = { __index = FileIPC }

function ipc.create_file_channel(modname, opts)
    local self = {
        modname = modname,
        opts = opts or {},
        callbacks = {},
        tx_queue = {},
        run = true
    }
    local ch = setmetatable(self, FileIPC_mt)
    minetest.after(1, ch.worker, ch)
    return ch
end

-- public api

function FileIPC:add_callback(fn)
    table.insert(self.callbacks, fn)
end

function FileIPC:send(msg)
    table.insert(self.tx_queue, msg)
end

function FileIPC:close()
    self.run = false
end

-- internal api

function FileIPC:flush()
    if #self.tx_queue > 0 then
        -- flush tx queue
        local filename = get_filename(self.modname, "tx")
        minetest.safe_file_write(filename, minetest.write_json(self.tx_queue))
        self.tx_queue = {}
    end
end

-- TODO: remove old tx files periodically

function FileIPC:worker()
    if not self.run then
        return
    end

    self:flush()

    -- fetch incoming messages
    local list = minetest.get_dir_list(path, false)
    for _, filename in ipairs(list) do
        local prefix = string.sub(filename, 1, #self.modname + 3)
        local suffix = string.sub(filename, #self.modname + 4)
        local mtime = tonumber(suffix)
        if prefix == self.modname .. "_rx" and type(mtime) == "number" then
            -- read
            local f = assert(io.open(path .. "/" .. filename, "r"))
            local json = f:read("*all")
            f:close()

            -- delete
            os.remove(path .. "/" .. filename)

            -- parse and distribute
            local messages = minetest.parse_json(json)
            for _, msg in ipairs(messages) do
                for _, callback in ipairs(self.callbacks) do
                    callback(msg)
                end
            end
        end
    end

    minetest.after(0.2, self.worker, self)
end