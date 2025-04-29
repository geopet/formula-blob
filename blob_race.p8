pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- blob race
-- by @geopet

-- game state variable
state = "start"
selected_blob = 0
logging = true
log_msg = ""

function _init()
    -- inialize things here
end

function _update()
    if (state == "start") then
        if (btnp(4)) then -- 🅾️ button (z key)
            state = "choose"
        end
    elseif (state == "choose") then

        if (btnp(0)) then -- left blob (1)
            selected_blob = 1
            log_msg = "left blob selected"
        elseif (btnp(1)) then -- right blob (2)
            selected_blob = 2
            log_msg = "right blob selected"
        end

        if (btnp(4)) then
            state = "racing"
        end
    elseif (state == "racing") then
        if (btnp(4)) then
            state = "result"
        end
    elseif (state == "result") then
        if (btnp(4)) then
            state = "start"
        end
    end
end

function _draw()
    cls() -- clear the screen
    local bobbing_offset = sin(time() * 1.5) * 2
    local wiggle_offset = sin(time() * 3) * 2

    if (state == "start") then
        print("welcome to blob race!", 20, 20, 7)
        print("press 🅾️ to start", 20, 40, 6)
    elseif (state == "choose") then
        print("choose your blob!", 20, 20, 7)

        -- draw blobs
        circfill(30, 60, 8, 11) -- left blob (color 11 = light blue)
        circfill(90, 60, 8, 8) -- right blob (color 8 = red)

        -- add labels
        print ("1", 29, 57, 0)
        print ("2", 89, 57, 0)

        -- print log message
        if (logging) then 
            print(log_msg, 0, 120, 5)
        end

        -- highlight selected blob
        if (selected_blob == 1) then
            print("⬇️", 27 + wiggle_offset, 45 + bobbing_offset, 7)
        elseif (selected_blob == 2) then
            print("⬇️", 87 + wiggle_offset, 45 + bobbing_offset, 7)
        end

        print("press 🅾️ to lock in", 20, 90, 6)
    elseif (state == "racing") then
        print("the race is on!", 20, 20, 7)
        print("press 🅾️ to see result", 20, 40, 6)
    elseif (state == "result") then
        print("the race is over!!", 20, 20, 7)
        print("press 🅾️ to play again", 20, 0, 6)
    end
end
__gfx__
000000000088880000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080cc0800ba00ab000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700088888800b0bb0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000080cc0800b0000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000088888800babbab000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070008c88c800bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008cccc800babbab000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000088880000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
