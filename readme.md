IPC Library for minetest

Supports http and files as transport layer

State: **WIP**

# Api

```lua
local ch
if http then
    ch = ipc.create_http_channel(modname, http, url, opts)
else
    ch = ipc.create_file_channel(modname, opts)
end

-- rx
ch:add_callback(function(msg)
    -- TODO
end)

-- tx
ch:send({ x = 123 })

-- close
ch:close()
```

# License

MIT