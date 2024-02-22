function ensure_time(_, timestamp, record)
    local timeField = "time"

    -- 如果 record 中已经有了 time 字段，则不做处理
    if record[timeField] then
        return 0, timestamp, record
    end

    -- 将秒级时间戳转换为可用于 os.date 函数的格式
    local sec = math.floor(timestamp)
    local nsec = math.floor((timestamp - sec) * 1e9)

    -- 将时间戳转换为指定格式的日期字符串, zone=UTC
    local dateStr = os.date("!%Y-%m-%dT%H:%M:%S", sec) .. string.format(".%09d", nsec) .. "Z"

    record[timeField] = dateStr

    return 2, timestamp, record
end

-- -- invoke ensure_time for benchmark
-- local socket = require("socket")
-- local record = { time = "2021-01-01T00:00:00Z" }
-- local _, _, record = ensure_time(nil, socket.gettime(), record)
-- print(record["time"])
