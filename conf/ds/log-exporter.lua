function set_labels(_, timestamp, record)
    local labels = record["labels"] or {}

    for k, v in pairs(record) do
        local full_prefix = "__tags_monitor_log_"
        if string.sub(k, 1, #full_prefix) == full_prefix then
            local new_key = string.sub(k, 8)
            labels[new_key] = v
        end
    end
    record["labels"] = labels
    return 2, timestamp, record
end