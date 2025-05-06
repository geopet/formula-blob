pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- blob race 0.1.0
-- by @geopet

-- logging variables
logging = true
log_msg = ""

-- game state variable
state = "start"
selected_blob = 0
arrow_phase = rnd(1)
lock_timer = 0

-- race variables
blob1_x = nil
blob1_y = nil
blob2_x = nil
blob2_y = nil
blob1_speed = nil
blob2_speed = nil
race_winner = nil

-- boost variables
player_boost_meter = nil
player_boost_active = false
player_overheat = false
overheat_timer = nil

function _init()
    -- inialize things here
end

function _update()
    if (state == "start") then
        log_msg = "start state"
        if (btnp(4)) then -- 🅾️ button (z key)
            state = "choose"
        end
    elseif (state == "choose") then
        if (log_msg == "start state") then
            log_msg = "choose state"
        end
        if (btnp(0)) then -- left blob (1)
            selected_blob = 1
            sfx(0)
            log_msg = "left blob selected"
        elseif (btnp(1)) then -- right blob (2)
            selected_blob = 2
            sfx(0)
            log_msg = "right blob selected"
        elseif (btnp(4)) then
            if selected_blob != 0 then
                sfx(1)
                lock_timer = 0
                state = "locked_in"
            else
                log_msg = "please select a blob first"
            end
        end
    elseif (state == "locked_in") then
        log_msg = "locked in blob " .. selected_blob
        if (btnp(4)) then
            state = "countdown"
        end
    elseif (state == "countdown") then
        lock_timer += 1
        if (lock_timer > 119) then
            state = "racing"

            -- blob setup
            blob1_x = 20
            blob2_x = 20
            blob1_y = 50
            blob2_y = 70
            blob1_speed = (0.5 * rnd(1)) + 0.08
            blob2_speed = (0.5 * rnd(1)) + 0.08

            -- boost setup
            player_boost_meter = 100
            player_boost_active = false
            player_overheat = false

            -- testing values
            -- blob1_speed = 0.3
            -- blob2_speed = 0.3

            race_winner = 0
        end

        log_msg = "countdown timer: " .. lock_timer
    elseif (state == "racing") then
        local boost_amount = 0

        if (player_overheat) then

            overheat_timer += 1

            if (overheat_timer > 60) then
                player_overheat = false
                overheat_timer = 0
                boost_amount = 0.01
                log_msg = "overheat off!"
            else
                player_boost_active = false
                boost_amount = -0.5
                log_msg = "overheating! no boost!"
            end
        else
            log_msg = "racing..."
        end

        if (btn(5) and not player_overheat) then -- press ❎ to boost
            if (player_boost_meter > 0) then
                player_boost_active = true
                player_boost_meter -= 5
                boost_amount = 1.5
            else
                player_overheat = true
                overheat_timer = 0
                player_boost_active = false
                player_boost_meter = 0

                log_msg = "boost meter depleted!"
            end
        else
            player_boost_active = false
        end

        if (selected_blob == 1) then
            blob1_x += blob1_speed + boost_amount
            blob2_x += blob2_speed
        else
            blob2_x += blob2_speed + boost_amount
            blob1_x += blob1_speed
        end

        -- race winner logic
        if race_winner == 0 then
            if (blob1_x >= 120) then
                race_winner = 1
                state = "result"
            elseif (blob2_x >= 120) then
                race_winner = 2
                state = "result"
            end
        end
    elseif (state == "result") then
        if (btnp(4)) then
            state = "start"
        end
    end
end

function _draw()
    cls() -- clear the screen

    local speed_mod = abs(sin(time() * 2))
    local bobbing_offset = sin((time() * 1.5) + arrow_phase) * 2 * speed_mod
    local wiggle_offset = sin((time() * 3) + arrow_phase) * 2 * speed_mod
    local blob_pulse = sin((time() * 2) + arrow_phase) * 1.5 * speed_mod
    local blob_pulse_2 = sin((time() * 2.5) + arrow_phase) * 1.5 * speed_mod

    if (state == "start") then
        print("welcome to blob race!", 20, 20, 7)
        print("press 🅾️ to start", 20, 40, 6)

        print_log_msg(log_msg)
    elseif (state == "choose") then
        print("choose your blob!", 20, 20, 7)

        -- draw blobs
        circfill(30, 60, 8 + blob_pulse, 11) -- left blob (color 11 = light blue)
        circfill(90, 60, 8 + blob_pulse_2, 8) -- right blob (color 8 = red)

        -- add labels
        print ("1", 29, 57, 0)
        print ("2", 89, 57, 0)

        -- print log message
        print_log_msg(log_msg)

        -- highlight selected blob
        if (selected_blob == 1) then
            print("⬇️", 27 + wiggle_offset, 45 + bobbing_offset, 7)
        elseif (selected_blob == 2) then
            print("⬇️", 87 + wiggle_offset, 45 + bobbing_offset, 7)
        end

        print("press 🅾️ to lock in", 20, 90, 6)
    elseif (state == "locked_in") then
        print("you've locked in on blob " .. selected_blob, 20, 20, 7)
        print("press 🅾️ to race!", 20, 40, 6)

        print_log_msg(log_msg)
    elseif (state == "countdown") then
        if (lock_timer < 30) then
            announcer_opt = {string = "racers on the ready...", x = 25, y = 30, color = 7}
            countdown_opt = {string = "3", x = 60, y = 50, color = 7}
        elseif (lock_timer < 60) then
            announcer_opt = {string = "on your marks...", x = 37, y = 30, color = 7}
            countdown_opt = {string = "2", x = 60, y = 50, color = 10}
        elseif (lock_timer < 90) then
            announcer_opt = {string = "get set...", x = 47, y = 30, color = 7}
            countdown_opt = {string = "1", x = 60, y = 50, color = 9}
        elseif (lock_timer < 120) then
            announcer_opt = {string = "and they're off!", x = 37, y = 30, color = 7}
            countdown_opt = {string = "go!", x = 60, y = 50, color = 8}
        else
            announcer_opt = {string = "there's a problem on the track!", x = 20, y = 30, color = 14}
            countdown_opt = {string = "false start!", x = 60, y = 50, color = 14}
        end

        countdown_msg(announcer_opt, countdown_opt)

        print_log_msg(log_msg)
    elseif (state == "racing") then
        print("the race is on!", 20, 20, 7)

        circfill(blob1_x, blob1_y, 8, 11)
        circfill(blob2_x, blob2_y, 8, 8)

        if (logging) then
            print("blob1_x: " .. blob1_x .. " speed: " .. blob1_speed, 0, 90, 6)
            print("blob2_x: " .. blob2_x .. " speed: " .. blob2_speed, 0, 100, 6)
        end

        print_log_msg(log_msg)
    elseif (state == "result") then
        print("the race is over!!", 20, 20, 7)
        print("the winner is blob " .. race_winner, 20, 40, 7)

        if (race_winner == selected_blob) then
            print("you guessed the right blob!", 0, 60, 7)
            print("congratulations!", 0, 70, 9)
            print("you are always right!", 0, 80, 8)
        else
            print("you guessed the wrong blob...", 0, 60, 14)
            print("better luck next time!", 0, 70, 12)
        end

        print("press 🅾️ to play again", 20, 90, 6)

        print_log_msg(log_msg)
    end
end

function countdown_msg(announcer_opt, countdown_opt)
    print(announcer_opt.string, announcer_opt.x, announcer_opt.y, announcer_opt.color)
    print(countdown_opt.string, countdown_opt.x, countdown_opt.y, countdown_opt.color)
end

function print_log_msg()
    if logging then
        if (log_msg != "") then
            print("log: " .. log_msg, 0, 120, 5)
        else
            print("log: na", 0, 120, 5)
        end
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
__sfx__
460100001035011350103501135010350113501035011350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
370100002a7502b7502c7502d7502e7502f7502475025750267502775028750297503675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490800000c6501865024650306503c650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000