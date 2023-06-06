local HttpIPC = {}
local HttpIPC_mt = { __index = HttpIPC }

function ipc.create_http_channel(modname, http, url, opts)
    local self = {
        modname = modname,
        url = url,
        http = http,
        opts = opts or {},
        callbacks = {},
        tx_queue = {},
        tx_triggered = false,
        run = true
    }
    local ch = setmetatable(self, HttpIPC_mt)
    minetest.after(1, ch.rx, ch)
    return ch
end

-- public api

function HttpIPC:add_callback(fn)
    table.insert(self.callbacks, fn)
end

function HttpIPC:send(msg, immediately)
    table.insert(self.tx_queue, msg)
    if immediately then
        -- send directly
        self:tx()
    elseif not self.tx_triggered then
        -- send delayed
        minetest.after(0.5, self.tx, self)
        self.tx_triggered = true
    end
end

function HttpIPC:close()
    self.run = false
end

-- internal api

function HttpIPC:tx()
    if not self.run then
        return
    end

    -- flush tx queue
    self.http.fetch({
        url = self.url,
        extra_headers = self.opts.extra_headers,
        timeout = 10,
        method = "POST",
        data = minetest.write_json(self.tx_queue)
    }, function(res)
        if not res.succeeded or res.code ~= 200 then
            minetest.log("error", "[ipc] http tx error, " ..
                "status: " .. res.code .. " response: " .. (res.data or "<none>"))
        end
    end)
    self.tx_queue = {}
    self.tx_triggered = false
end

function HttpIPC:rx()
    if not self.run then
        return
    end

    -- fetch incoming messages
    self.http.fetch({
        url = self.url,
        extra_headers = self.extra_headers,
        timeout = 30,
        method = "GET"
    }, function(res)
        if res.succeeded and res.code == 200 and res.data ~= "" then
            local messages = minetest.parse_json(res.data)
            for _, msg in ipairs(messages) do
                for _, callback in ipairs(self.callbacks) do
                    callback(msg)
                end
            end
        else
            print("[ipc] http rx error: " .. res.code)
        end
        minetest.after(1, self.rx, self)
    end)
end