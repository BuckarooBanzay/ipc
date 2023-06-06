mtt.register("ipc.file", function(callback)
    -- simple smoke test
    local ch = ipc.create_file_channel("mymod")
    ch:send({ my = "message" })
    ch:flush()
    ch:close()
    callback()
end)