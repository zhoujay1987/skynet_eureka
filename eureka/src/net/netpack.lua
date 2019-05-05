require "skynet"

---@type class netpack
local netpack = {}

local head = 0x11
local version = 0x1
local checksum = 0

function netpack.pack(serial, cmd, session, protobuf) 
    if protobuf then
       return string.pack(">BBI4HI4HLc"..#protobuf, head, version, #protobuf, checksum, serial, cmd, session, protobuf)
    end
    return string.pack(">BBI4HI4HL", head, version, 0, checksum, serial, cmd, session)
end

function netpack.unpack(msg) 
    local head, version, length, checksum, serial, cmd, session = string.unpack(">BBI4HI4HL", msg)
    if length > 0 then
        local protobuf = string.unpack(">c" .. length, msg, 23)
        return head, version, length, checksum, serial, cmd, session, protobuf
    end
    return head, version, length, checksum, serial, cmd, session
end

return netpack