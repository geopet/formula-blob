pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- blob race 0.1.0
-- by @geopet

function _init()
    -- initalize things here

    -- logging variables
    logging = true
    log_msg = ""

    -- game state variable
    state = "start"
    arrow_phase = rnd(1)
    lock_timer = 0

    -- blob sprite variables
    selected_blob = 0
    blob1_sprite = 3
    blob2_sprite = 5

    -- race variables
    blob1_x = nil
    blob1_y = nil
    blob2_x = nil
    blob2_y = nil
    blob1_speed = nil
    blob2_speed = nil
    race_winner = nil

    -- race odds
    win_probability = {
        start_line = 10,
        finish_line = 120,
        track_length = nil,
        total_speed = nil,
        blob1_expected_time = nil,
        blob2_expected_time = nil,
        blob1_odds = nil,
        blob2_odds = nil
    }

    -- player boost table
    player_boost = {
        meter = nil,
        active = false,
        overheating = false,
        overheating_timer = nil,
        amount = nil
    }

    -- opponent boost table
    opponent_boost = {
        meter = nil,
        active = false,
        overheating = false,
        overheating_timer = nil,
        amount = nil,
        timer = nil,
        cooldown = nil,
        did_breakdown = false
    }
end

-->8

function _update()
    if (state == "start") then
        -- set blob speed
        blob1_speed = (0.5 * rnd(1)) + 0.08
        blob2_speed = (0.5 * rnd(1)) + 0.08

        win_probability.total_speed = blob1_speed + blob2_speed

        -- testing values
        -- blob1_speed = 0.1
        -- blob2_speed = 0.1

        set_win_probability()

        if (btnp(4)) then -- 🅾️ button (z key)
            state = "choose"
        end
        log_msg = "start state"
    elseif (state == "choose") then
        if (log_msg == "start state") then
            log_msg = "b1 t: " .. win_probability.blob1_expected_time .. " b2 t: " .. win_probability.blob2_expected_time
        end
        if (btnp(0)) then -- left blob (1)
            selected_blob = 1
            sfx(0)
            log_msg = "b1 o: " .. win_probability.blob1_odds .. "b1 t: " .. win_probability.blob1_expected_time
        elseif (btnp(1)) then -- right blob (2)
            selected_blob = 2
            sfx(0)
            log_msg = "b2 o: " .. win_probability.blob2_odds .. "b2 t: " .. win_probability.blob2_expected_time
        elseif (btnp(4)) then
            if selected_blob != 0 then
                sfx(1)
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
            blob1_x = 10
            blob2_x = 10
            blob1_y = 50
            blob2_y = 70

            -- player boost setup
            player_boost.meter = 100
            player_boost.active = false
            player_boost.overheating = false
            player_boost.overheating_timer = 0
            player_boost.amount = 0

            -- opponent boost setup
            opponent_boost.meter = 100
            opponent_boost.active = false
            opponent_boost.overheating = false
            opponent_boost.overheating_timer = 0
            opponent_boost.amount = 0
            opponent_boost.timer = 0
            opponent_boost.cooldown = 0
            opponent_boost.did_breakdown = false

            race_winner = 0
        end

        log_msg = "countdown timer: " .. lock_timer
    elseif (state == "racing") then

        update_player_overheat()
        update_opponent_overheat()
        player_boost_check()
        opponent_boost_check()
        opponent_boost_cooldown_check()
        update_blobs_speed()
        win_condition_check()

    elseif (state == "result") then
        if (btnp(4)) then
            state = "start"
        end
        log_msg = "result state"
    end
end

-->8

function _draw()
    cls() -- clear the screen

    local speed_mod = abs(sin(time() * 2))
    local bobbing_offset = sin((time() * 1.5) + arrow_phase) * 2 * speed_mod
    local wiggle_offset = sin((time() * 3) + arrow_phase) * 2 * speed_mod
    local blob_pulse = sin((time() * 2) + arrow_phase) * 1.5 * speed_mod
    local blob_pulse_2 = sin((time() * 2.5) + arrow_phase) * 1.5 * speed_mod

    -- blob sprite animation
    local blob1_sprite_frame = blob1_sprite + flr(time() * 2.5) % 2
    local blob1_flip = flr(time() * 2) % 2 == 1
    local blob2_sprite_frame = blob2_sprite + flr(time() * 1.5) % 2
    local blob2_flip = flr(time()) % 2 == 1

    if (state == "start") then
        print("welcome to blob race!", 20, 20, 7)
        print("version 0.1.0", 20, 30, 12)
        print("press 🅾️ or z to start", 20, 90, 10)

        print_log_msg(log_msg)
    elseif (state == "choose") then
        print("choose your blob!", 30, 20, 7)

        -- draw blobs
        sspr(blob1_sprite_frame * 8, 0, 8, 8, 30-12, 55-12 + blob_pulse, 24, 24, blob1_flip, false)
        sspr(blob2_sprite_frame * 8, 0, 8, 8, 90-12, 55-12 + blob_pulse_2, 24, 24, blob2_flip, false)

        -- highlight selected blob
        if (selected_blob == 1) then
            print("⬇️", 27 + wiggle_offset, 35 + bobbing_offset, 7)
        elseif (selected_blob == 2) then
            print("⬇️", 87 + wiggle_offset, 35 + bobbing_offset, 7)
        end

        -- add labels
        print("blob 01", 17, 72, 11)
        print("speed: " .. blob1_speed, 7, 82, 11)

        print("blob 02", 77, 72, 12)
        print("speed: " .. blob2_speed, 67, 82, 12)

        print("use ⬅️ or ➡️ to choose", 20, 95, 9)
        print("press 🅾️ or z to select!", 15, 105, 10)

        -- print log message
        print_log_msg(log_msg)
    elseif (state == "locked_in") then
        print("your blob racer is ready!", 15, 20, 12)

        if (selected_blob == 1) then
            sspr(blob1_sprite_frame * 8, 0, 8, 8, 52, 42 + blob_pulse, 24, 24, blob1_flip, false)
        else
            sspr(blob2_sprite_frame * 8, 0, 8, 8, 52, 42 + blob_pulse_2, 24, 24, blob2_flip, false)
        end

        print("press 🅾️ or z to start race!", 10, 90, 10)
        print("press ❎ or x to boost!", 20, 100, 14)

        print_log_msg(log_msg)
    elseif (state == "countdown") then
        if (lock_timer < 30) then
            announcer_opt = {string = "racers on the ready...", x = 25, y = 30, color = 14}
            countdown_opt = {string = "3", x = 60, y = 50, color = 7}
        elseif (lock_timer < 60) then
            announcer_opt = {string = "on your marks...", x = 37, y = 30, color = 13}
            countdown_opt = {string = "2", x = 60, y = 50, color = 10}
        elseif (lock_timer < 90) then
            announcer_opt = {string = "get set...", x = 47, y = 30, color = 12}
            countdown_opt = {string = "1", x = 60, y = 50, color = 9}
        elseif (lock_timer < 120) then
            announcer_opt = {string = "and they're off!", x = 37, y = 30, color = 11}
            countdown_opt = {string = "go!", x = 60, y = 50, color = 8}
        else
            announcer_opt = {string = "there's a problem on the track!", x = 20, y = 30, color = 14}
            countdown_opt = {string = "false start!", x = 60, y = 50, color = 14}
        end

        countdown_msg(announcer_opt, countdown_opt)

        print_log_msg(log_msg)
    elseif (state == "racing") then
        print("the race is on!", 35, 20, 11)

        if (player_boost.overheating) then
            print("boost overheat!", 35, 30, 8)
        else
            print("press ❎ or x to boost!", 20, 30, 9)
        end

        sspr(blob1_sprite_frame * 8, 0, 8, 8, blob1_x - 12, blob1_y - 12, 24, 24, false, false)
        sspr(blob2_sprite_frame * 8, 0, 8, 8, blob2_x - 12, blob2_y - 12, 24, 24, false, false)

        if (logging) then
            print("blob1_x: " .. blob1_x .. " speed: " .. blob1_speed, 0, 90, 6)
            print("blob2_x: " .. blob2_x .. " speed: " .. blob2_speed, 0, 100, 6)
        end

        print_log_msg(log_msg)
    elseif (state == "result") then
        print("the race is over!!", 30, 20, 11)
        print("the winner is blob " .. race_winner .. "!", 25, 30, 14)

        if (race_winner == selected_blob) then
            print("you won!", 48, 50, 12)
            print("congratulations!", 31, 60, 12)
        else
            print("you didn't win", 36, 50, 9)
            print("better luck next time!", 22, 60, 9)
        end

        print("press 🅾️ or z to play again", 11, 90, 10)

        print_log_msg(log_msg)
    end
end

-->8
-- helper functions

function set_win_probability()
    win_probability.track_length = win_probability.finish_line - win_probability.start_line
    win_probability.blob1_expected_time = (win_probability.track_length/blob1_speed)/30
    win_probability.blob2_expected_time = (win_probability.track_length/blob2_speed)/30
    win_probability.blob1_odds = blob1_speed/win_probability.total_speed
    win_probability.blob2_odds = blob2_speed/win_probability.total_speed
end

function countdown_msg(announcer_opt, countdown_opt)
    print(announcer_opt.string, announcer_opt.x, announcer_opt.y, announcer_opt.color)
    print(countdown_opt.string, countdown_opt.x, countdown_opt.y, countdown_opt.color)
end

function update_player_overheat()
    if (player_boost.overheating) then
        player_boost.overheating_timer += 1

        if (player_boost.overheating_timer > 60) then
            player_boost.overheating = false
            player_boost.overheating_timer = 0
            player_boost.amount = 0.01
            -- log_msg = "overheat off!"
        else
            player_boost.active = false
            player_boost.amount = -0.5
            -- log_msg = "overheating! no boost!"
        end
    elseif (not player_boost.overheating) then
            player_boost.amount = 0
            -- log_msg = "racing..."
    end
end

function update_opponent_overheat()
    if (opponent_boost.overheating) then
        opponent_boost.overheating_timer += 1

        if (opponent_boost.overheating_timer > 60) then
            opponent_boost.overheating = false
            opponent_boost.overheating_timer = 0
            opponent_boost.amount = 0.01
            -- log_msg = "overheat off!"
        else
            opponent_boost.active = false
            opponent_boost.amount = -0.5
            -- log_msg = "opponent overheating! no boost!"
        end
    elseif (not opponent_boost.overheating) then
            opponent_boost.amount = 0
            -- log_msg = "racing..."
    end
end

function player_boost_check()
    if (btn(5) and not player_boost.overheating) then -- press ❎ to boost
        if (player_boost.meter > 0) then
            player_boost.active = true
            player_boost.meter -= 5
            player_boost.amount = 1.5
            -- log_msg = "player boost meter: " .. player_boost.meter
            sfx(3)
        else
            player_boost.overheating = true
            player_boost.overheating_timer = 0
            player_boost.active = false
            player_boost.meter = 0
            sfx(2)
        end
    else
        player_boost.active = false
    end
end

function opponent_boost_check()
    if (opponent_boost.active and not opponent_boost.overheating) then
        if (opponent_boost.meter > 0) then
            opponent_boost.meter -= 5
            opponent_boost.amount = 1.5
            sfx(5)
            --log_msg = "opponent boost timer: " .. opponent_boost.timer
        else
            opponent_boost.overheating = true
            opponent_boost.overheating_timer = 0
            opponent_boost.active = false
            opponent_boost.meter = 0
            opponent_boost.did_breakdown = true
            sfx(4)
            --log_msg = "opponent boost meter: " .. opponent_boost.meter
        end
    else
        opponent_boost.active = false
    end
end

function opponent_boost_cooldown_check()
    local opponent_boost_random = rnd(1)
    local random_timer = flr(opponent_boost_random * 50)

    if (not opponent_boost.active and not opponent_boost.overheating and opponent_boost.cooldown == 0) then
        if (opponent_boost_random < 0.05) then
            if (opponent_boost.timer <= random_timer) then
                if (opponent_boost.meter > 0) then
                    opponent_boost.active = true -- boost away!
                    sfx(5)
                end
            end
        else
            opponent_boost.active = false -- didn't meet random chance
        end
    elseif (not opponent_boost.active and not opponent_boost.overheating and opponent_boost.cooldown > 0) then
        opponent_boost.cooldown -= 1
        opponent_boost.active = false
    elseif (opponent_boost.active and opponent_boost.timer >= random_timer) then
        opponent_boost.active = false
        opponent_boost.timer = 0
        opponent_boost.cooldown = 30
    elseif (opponent_boost.active and opponent_boost.timer < random_timer) then
        opponent_boost.timer += 1
        opponent_boost.active = true
    end
end

function update_blobs_speed()
    if (selected_blob == 1) then
        blob1_x += blob1_speed + player_boost.amount
        blob2_x += blob2_speed + opponent_boost.amount
    else
        blob2_x += blob2_speed + player_boost.amount
        blob1_x += blob1_speed + opponent_boost.amount
    end
end

function win_condition_check()
    if race_winner == 0 then
        if (blob1_x >= 120) then
            race_winner = 1
            state = "result"
        elseif (blob2_x >= 120) then
            race_winner = 2
            state = "result"
        end
    end
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
00000000080cc0800ba00ab000cccc0000cccc0000eeee0000eeee00000000000000000000000000000000000000000000000000000000000000000000000000
00700700088888800b0bb0b00ccacac00ccacac00eedede00eedede0000000000000000000000000000000000000000000000000000000000000000000000000
00077000080cc0800b0000b00cccccc00cccccc00eeeeee00eeeeee0000000000000000000000000000000000000000000000000000000000000000000000000
00077000088888800babbab00ccbabc00ccbabc00ee232e00ee232e0000000000000000000000000000000000000000000000000000000000000000000000000
0070070008c88c800bbbbbb00cccccc00cccacc00eee3ee00eee3ee0000000000000000000000000000000000000000000000000000000000000000000000000
0000000008cccc800babbab000cccc0000cccc0000eeee0000e33e00000000000000000000000000000000000000000000000000000000000000000000000000
000000000088880000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
460100001035011350103501135010350113501035011350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
370100002a7502b7502c7502d7502e7502f7502475025750267502775028750297503675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490800000c6501865024650306503c650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
270500001803226032180322603218032260321803226032000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
57080000376462b6561f6463762611616296561d65600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
270800000c5370e537115371353715537175371853700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507
