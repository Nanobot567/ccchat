-- computercraft chat, a simple chat client

local screenX, screenY = term.getSize()

local linetext = ""
local sendout = ""
local msgstack = {}
local pingtimer = 0
local color = colors.red
local name = "anon"
local port, ownport, modem
local configfile
local contacts = {}
local modemname = ""
local commands = {
    ["help"]="help command. usage: /help [command]",
    ["connect"]="connect to a port. usage: /connect <port/contact name>",
    ["contact"]="the /contact command manages your contacts. contacts are shortcuts for ports.\n\nexample: `/contact add john 8`, `/connect john` is the same as `/connect 8`.\n\nusage: /contact add <name> <port>, /contact delete <name>, /contact list",
    ["ping"]="ping the person connected to you. usage: /ping",
    ["clear"]="clears the message stack. usage: /clear",
    ["color"]="changes your name color and ui color. usage: /color <#1-16>",
    ["nick"]="changes your name. usage: /nick <name>",
    ["save"]="saves your current configuration. usage: /save"
}

table.sort(commands)

local colorTable = {colors.white,
                    colors.orange,
                    colors.magenta,
                    colors.lightBlue,
                    colors.yellow,
                    colors.lime,
                    colors.pink,
                    colors.gray,
                    colors.lightGray,
                    colors.cyan,
                    colors.purple,
                    colors.blue,
                    colors.brown,
                    colors.green,
                    colors.red,
                    colors.black}


function readConfig()
    local invalidconfig = false

    configfile = fs.open("config/ccchat/config.cc","r")

    if configfile ~= nil or fs.exists("config/ccchat/config.cc") then    
        local lines = {}
        while true do
            local line = configfile.readLine()
            if not line then break end
            lines[#lines+1] = line
        end

        configfile.close()

        if lines == nil or #lines < 4 then
            invalidconfig = true
        end

        -- config file format:
        -- user's name
        -- user's modem location
        -- user's port
        -- user's last connected port
        -- user's color
        -- contact1 name,contact1 port
        -- contact2 name,contact2 port
        -- etc..
    
        if not invalidconfig then
            name = table.remove(lines, 1)
            modemname = tostring(table.remove(lines, 1))
            modem = peripheral.wrap(modemname)
            if modem == nil then
                invalidconfig = true
            else
                ownport = tonumber(table.remove(lines, 1))
                modem.open(ownport)
                port = tonumber(table.remove(lines, 1))
                color = tonumber(table.remove(lines, 1))
                local thiscontact
                for i,v in ipairs(lines) do
                    s = string.split(v, ",")
                    contacts[s[1]] = tonumber(s[2])
                end
            end
        end
    else
        invalidconfig = true
    end
    return invalidconfig
end

function writeConfig()
    local f = fs.open("config/ccchat/config.cc","w")
    f.write(name.."\n"..modemname.."\n"..ownport.."\n"..port.."\n"..tostring(color))
    
    for k,v in pairs(contacts) do
        f.write("\n"..k..","..tostring(v))
    end
    f.close()
end

function sortContacts()
    local function compare(a,b)
        return a[1] < b[1]
    end

    table.sort(contacts, compare)
end

function string.split(str, sep)
    if sep == nil then
        sep = "%s"
    end

    local t={}
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end

function echo(text)
    local chr = ""
    local x,y
    for i=1, #text do
        x, y = term.getCursorPos()
        chr = string.sub(text, i, i)
        if chr == "\n" then
            term.setCursorPos(1, y+1)
        else
            if x == screenX then
                term.setCursorPos(1, y+1)
            end
            term.write(chr)
        end
    end
end

function updateScreen()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(color)
    echo("ccchat by nanobot567\n")
    echo(string.rep("-",screenX-1).."\n")
    term.setTextColor(colors.white)

    for i,v in ipairs(msgstack) do
        if v[1] == nil or v[1] == "" then
            if v[2] ~= "" then
                echo(v[2].."\n")
            end
        else
            echo("[")
            if v[3] ~= nil then
                term.setTextColor(v[3])
            end
            echo(v[1])
            term.setTextColor(colors.white)
            echo("] "..v[2].."\n")
        end
    end
        
    term.setCursorPos(1, screenY-1)
    term.setTextColor(color)
    echo(string.rep("-", screenX-1).."\n")
    term.setTextColor(colors.white)
end

function send(typ, ...)
    local args = {typ, ...}
    modem.transmit(port, ownport, args)
end

function makeMultiline(text)
    local lines = {}
                    
    while #text+#name+3 >= screenX do
        table.insert(lines, string.sub(text, 1, screenX-(#name+4)-1))
        text = string.sub(text, screenX-(#name+4), #text)
    end
    table.insert(lines, text)

    return lines
end

function speak(name, text, snd, namecolor)
    for i,v in ipairs(makeMultiline(text)) do
        if #msgstack+1 == screenY-3 then
            table.remove(msgstack, 1)
        end

        if i == 1 then
            table.insert(msgstack, {name,text,namecolor})
        else
            table.insert(msgstack, {"",""})
        end
    
        
        if snd == true then
            if i == 1 then
                send("say", name, v, namecolor)
            else
                send("rawsay", "", v)
            end
        end
    end
end



if readConfig() then
    local m
    fs.makeDir("config/ccchat")

    term.clear()
    term.setCursorPos(1, 1)
    echo("-- ccchat --\n\n")

    local periphs = peripheral.getNames()

    for i,v in ipairs(periphs) do
        echo(v.." ("..peripheral.getType(v)..")\n")
    end

    while modem == nil do
        echo("\nEnter the location of your modem from this list.\n")
        m = io.read("*l")
        modemname = m

        modem = peripheral.wrap(m)
    
        if modem == nil then
            echo("\nmodem does not exist!!\n")
        end
    end

    echo("Enter the port you would like to be on.\n")
    ownport = tonumber(io.read("*l"))

    modem.open(ownport)

    echo("Enter the computer port that you would like to connect to.\n")
    port = tonumber(io.read("*l"))

    echo("Enter your username.\n")
    name = io.read("*l")
end

speak("@", "RX "..tostring(ownport)..", TX "..tostring(port))

os.pullEvent = os.pullEventRaw
send("join", name)

updateScreen()

function update()
    local event, a, b, c, d, e = os.pullEvent()

    if event == "char" or event == "key" or event == "modem_message" then
        updateScreen()
        if event == "char" then
            linetext = linetext..a
        elseif event == "key" then
            if a == 28 or a == 257 then
                local args = string.split(linetext)
                local cmd = args[1]
                if cmd == "/quit" then
                    os.queueEvent("terminate")
                elseif cmd == "/connect" then
                    port = tonumber(args[2])
                    if port ~= nil then
                        speak("@", "RX "..tostring(ownport)..", TX "..tostring(port))
                        send("join", name)
                    else
                        for k,v in pairs(contacts) do
                            if args[2] == k then
                                port = tonumber(v)
                                speak("@", "RX "..tostring(ownport)..", TX "..tostring(port))
                                send("join", name)
                            end
                        end
                    end
                elseif cmd == "/contact" then
                    if #args == 1 then
                        speak("@", commands["/contact"])
                    end

                    if args[2] == "add" then
                        speak("@", args[3].." = "..args[4])
                        contacts[args[3]] = tonumber(args[4])
                        sortContacts()
                    elseif args[2] == "delete" or args[2] == "del" then
                        speak("@", "deleted "..args[3])
                        contacts[args[3]] = nil
                        sortContacts()
                    elseif args[2] == "list" then
                        speak("@", "your contacts:")
                        for k,v in pairs(contacts) do
                            speak("@", k.." = "..tostring(v))
                        end
                    end
                elseif cmd == "/ping" then
                    speak("@", "pinging...")
                    pingtimer = os.clock()
                    send("pingask", name)
                elseif cmd == "/clear" then
                    msgstack = {}
                elseif cmd == "/color" then
                    local c = tonumber(args[2])
                    if c ~= nil and c > 0 and c < 17 then
                        color = colorTable[c]
                    end
                elseif cmd == "/nick" then
                    local oldname = name
                    speak("@",name.." is now known as "..args[2])
                    name = args[2]
                elseif cmd == "/save" then
                    speak("@", "saved config.")
                    writeConfig()
                elseif cmd == "/help" then
                    if #args == 1 then
                        speak("@", "commands in ccchat:")
                        for k,v in pairs(commands) do
                            speak("@", k)
                        end
                    else
                        local helptext = commands[string.split(args[2],"/")[1]]
                        if helptext ~= nil then
                            speak("@", helptext)
                        end
                    end
                else
                    speak(name, linetext, true, color)
                end
                updateScreen()
                linetext = ""
            elseif a == 14 or a == 259 then
                linetext = string.sub(linetext, 1, #linetext-1)
            end
        
        elseif event == "modem_message" then
            -- format: table. first value type, second content
            if type(d) == "table" and #d >= 2 then
                if d[1] == "join" then
                    speak("@", d[2].." joined")
                elseif d[1] == "leave" then
                    speak("@", d[2].." left")
                elseif d[1] == "say" then
                    speak(d[2], d[3], false, d[4])
                elseif d[1] == "rawsay" then
                    speak("", d[3])
                elseif d[1] == "pingask" then
                    send("pingsend", name, e) -- fix ping ask and send
                elseif d[1] == "pingsend" then
                    speak("@", d[2].."'s response went "..tostring(d[3]).." blocks in "..os.clock()-pingtimer.."ms.")
                    pingtimer = 0
                end
            end
            updateScreen()
        end
        
        term.setCursorPos(1, screenY)
        echo("> "..linetext.."_")
    elseif event == "terminate" then
        writeConfig()
        send("leave", name)
        modem.closeAll()
        term.clear()
        term.setCursorPos(1,1)
        echo("bye!\n\n")
        error()
    end
end

while true do
    update()
end

