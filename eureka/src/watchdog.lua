local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local service
local agent = {}

function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr)
    agent[fd] = skynet.newservice("agent")
    skynet.call(agent[fd], "lua", "start", {service = service, client = fd, watchdog = skynet.self()})
end

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(service, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
end


function SOCKET.close(fd)
    print("socket close", fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    print("socket error", fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
    skynet.call(service, "lua", "open", conf)
end

function CMD.close(fd)
    close_agent(fd)
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(session, source, cmd, subcmd, ...)
                if cmd == "socket" then
                    -- socket api don't need return
                    local f = SOCKET[subcmd]
                    f(...)
                else
                    local f = assert(CMD[cmd])
                    skynet.ret(skynet.pack(f(subcmd, ...)))
                end
            end
        )

        service = skynet.newservice("tcpservice")
    end
)
