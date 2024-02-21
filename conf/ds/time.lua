function ensure_time(_, timestamp, record)
    local timeField = "time"

    -- 如果 record 中已经有了 time 字段，则不做处理
    if record[timeField] then
        return 0, timestamp, record
    end

    -- 将秒级时间戳转换为可用于 os.date 函数的格式
    local sec = math.floor(timestamp)
    local nsec = math.floor((timestamp - sec) * 1e9)

    -- 将时间戳转换为指定格式的日期字符串
    local zone = os.date("%z", timestamp)
    zone = tostring(zone)
    if string.len(zone) > 0 then
        -- add `:` to zone, change +0800 to +08:00
        zone = tostring(zone):gsub("^(%+)(%d%d)(%d%d)$", "%1%2:%3")
    else
        zone = "Z"
    end

    -- 生成日期字符串
    local dateStr = os.date("%Y-%m-%dT%H:%M:%S", sec) .. string.format(".%09d", nsec) .. zone
    record[timeField] = dateStr

    return 2, timestamp, record
end
