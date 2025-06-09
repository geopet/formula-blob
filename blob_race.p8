pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- blob race 0.1.0
-- by @geopet

function _init()
    -- initalize things here

    -- logging variables
    logging = false
    log_msg = ""

    quick_log = {
        scale = nil,
        boost_bonus = nil
    }

    -- game state variable
    state = "game-start"
    arrow_phase = rnd(1)
    lock_timer = 0
    current_music = -1
    is_muted = false

    -- start screen parade variables
    parade_blobs = {}
    local sprite_index = {}
    local blob_sprites = {16, 17, 18, 19, 20}
    add(sprite_index, blob_sprites[flr(rnd(#blob_sprites)) + 1])

    for i = 2, 30 do
        local new_sprite
        repeat
            new_sprite = blob_sprites[flr(rnd(#blob_sprites)) + 1]
        until (new_sprite != sprite_index[#sprite_index])
        add(sprite_index, new_sprite)
    end

    for i = 1, #sprite_index do
        local blob = {
            sprite = sprite_index[i],
            offset = i * 32,
            flip_x = rnd(1) < 0.5,
            flip_y = rnd(1) < 0.1
        }
        add(parade_blobs, blob)
    end

    -- blob sprite variables
    selected_blob = 0
    blob1_sprite = 3
    blob2_sprite = 5

    false_start = {
        blob1 = {target = 0, current = 0},
        blob2 = {target = 0, current = 0}
    }

    -- race variables
    blob1_x = nil
    blob1_y = nil
    blob2_x = nil
    blob2_y = nil
    blob1_speed = nil
    blob2_speed = nil
    race_winner = nil
    game_over = nil

    -- scoring variables
    score = {
        player = nil,
        opponent = nil,
        player_wins = nil,
        opponent_wins = nil,
        player_losses = nil,
        opponent_losses = nil
    }

    -- race win probability variables
    win_probability = {
        start_line = 10,
        finish_line = 120,
        track_length = nil,
        total_speed = nil,
        blob1_expected_time = nil,
        blob2_expected_time = nil,
        blob1 = nil,
        blob2 = nil,
        blob1_moneyline = nil,
        blob2_moneyline = nil
    }

    boost_meter = {
        fastest_blob = nil,
        bonus = nil,
        strength_base = 1.5,
        strength_balance = nil
    }

    -- player boost table
    player_boost = {
        meter = nil,
        active = false,
        overheating = false,
        overheating_timer = nil,
        amount = nil,
        amount_modified = nil
    }

    -- opponent boost table
    opponent_boost = {
        meter = nil,
        active = false,
        overheating = false,
        overheating_timer = nil,
        amount = nil,
        amount_modified = nil,
        timer = nil,
        cooldown = nil,
        did_breakdown = false
    }
end

-->8

function _update()

    if (btnp(3)) then -- ⬇️ / down arrow to mute
        is_muted = not is_muted
    end

    music_player()

    if (state == "game-start") then
        lock_timer = 0
        game_score_init()

        if (btnp(4)) then -- 🅾️ button (z key)
            state = "race-init"
        end
        log_msg = ""
    elseif (state == "race-init") then
        lock_timer = 0

        -- set blob speed
        blob1_speed = (0.5 * rnd(1)) + 0.08
        blob2_speed = (0.5 * rnd(1)) + 0.08

        -- testing values
        -- blob1_speed = 0.1
        -- blob2_speed = 0.1

        win_probability.total_speed = blob1_speed + blob2_speed

        set_fastest_blob(blob1_speed, blob2_speed)
        calculate_boost_bonus(blob1_speed, blob2_speed)
        calculate_boost_strength(blob1_speed, blob2_speed)
        set_win_probability()
        set_racer_moneyline()

        state = "choose"
    elseif (state == "choose") then
        if (log_msg == "start state") then
            log_msg = "b1 t: " .. win_probability.blob1_expected_time .. " b2 t: " .. win_probability.blob2_expected_time
        end
        if (btnp(0)) then -- left blob (1)
            selected_blob = 1
            sfx(0)
            -- log_msg = "b1 wp: " .. win_probability.blob1 .. "b1 t: " .. win_probability.blob1_expected_time
            -- log_msg = "b1 wp: " .. win_probability.blob1 .. " b1 ml: " .. win_probability.blob1_moneyline
            log_msg = quick_log.scale .. " " .. quick_log.boost_bonus .. " " .. (1.5 * quick_log.scale)
        elseif (btnp(1)) then -- right blob (2)
            selected_blob = 2
            sfx(0)
            -- log_msg = "b2 wp: " .. win_probability.blob2 .. "b2 t: " .. win_probability.blob2_expected_time
            -- log_msg = "b2 wp: " .. win_probability.blob2 .. " b2 ml: " .. win_probability.blob2_moneyline
            log_msg = quick_log.scale .. " " .. quick_log.boost_bonus .. " " .. (1.5 * quick_log.scale)
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
            sfx(16)
            state = "countdown"
        end
    elseif (state == "countdown") then

        -- trigger false starts randomly
        if (rnd(1) < 0.02 and false_start.blob1.target == 0 and false_start.blob1.current == 0) then
            false_start.blob1.target = flr(rnd(37)) + 4
        end
        if (rnd(1) < 0.02 and false_start.blob2.target == 0 and false_start.blob2.current == 0) then
            false_start.blob2.target = flr(rnd(37)) + 4
        end

        -- update blob false start positions
        for blob in all({"blob1", "blob2"}) do
            local fs = false_start[blob]

            if fs.target > 0 then
                -- moving forward to target
                if fs.current < fs.target then
                    fs.current += 3
                else
                    -- reached target, start going back
                    fs.target = 0
                end
            elseif fs.current > 0 then
                -- moving back to 0
                fs.current -= 3
            end
        end

        lock_timer += 1

        if (lock_timer == 30) then
            sfx(16)
        elseif (lock_timer == 60) then
            sfx(16)
        elseif (lock_timer == 90) then
            sfx(17)
        elseif (lock_timer > 119) then

            -- blob setup
            blob1_x = 10
            blob2_x = 10
            blob1_y = 66
            blob2_y = 96

            boost_balance(blob1_speed, blob2_speed)

            -- player boost setup
            player_boost.active = false
            player_boost.overheating = false
            player_boost.overheating_timer = 0
            player_boost.amount = 0

            -- opponent boost setup
            opponent_boost.active = false
            opponent_boost.overheating = false
            opponent_boost.overheating_timer = 0
            opponent_boost.amount = 0
            opponent_boost.timer = 0
            opponent_boost.cooldown = 0
            opponent_boost.did_breakdown = false

            race_winner = 0

            state = "racing"
        end

        -- log_msg = "countdown timer: " .. lock_timer
    elseif (state == "racing") then

        update_player_overheat()
        update_opponent_overheat()
        player_boost_check()
        opponent_boost_check()
        opponent_boost_cooldown_check()
        update_blobs_speed()
        win_condition_check()

        -- log_msg = "pb: " .. player_boost.meter .. " ob: " .. opponent_boost.meter
        -- log_msg = "pb: " .. player_boost.meter .. "pb_mod: " .. player_boost.amount_modified
        -- log_msg = "ob: " .. opponent_boost.meter .. "ob_mod: " .. opponent_boost.amount_modified
        -- log_msg = "pb_mod: " .. player_boost.amount_modified .. "ob_mod: " .. opponent_boost.amount_modified
        log_msg = "pb: " .. player_boost.meter .. "/" .. player_boost.amount_modified .. " ob: " .. opponent_boost.meter .. "/" .. opponent_boost.amount_modified

    elseif (state == "result") then
        if (btnp(4) and game_over) then
            state = "game-start"
        elseif (btnp(4) and not game_over) then
            state = "race-init"
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

    if (state == "game-start") then
        -- Pulsing welcome text
        local t = sin(time() * 2)
        local c = 7 + flr((t + 1) * 2)
        print("welcome to blob race!", 20, 20, c)
        print("version 0.1.0", 20, 30, 12)

        local base_y = 60
        local scroll_x = (time() * 30)
        local parade_length = #parade_blobs * 32

        -- Draw blob parade (seamless loop)
        for blob in all(parade_blobs) do
            local x = blob.offset - scroll_x % parade_length
            local y = base_y + sin(time() * 2 + blob.offset) * 2
            draw_sprite(blob.sprite, x, y, 16, 16, blob.flip_x, blob.flip_y)
            -- draw a second copy to the right for seamless looping
            if x < 128 then
                draw_sprite(blob.sprite, x + parade_length, y, 16, 16, blob.flip_x, blob.flip_y)
            end
        end

        print("press 🅾️ or z to start", 20, 100, 10)
        -- print("press ⬇️ down arrow to mute", 20, 110, 9)

        print_log_msg(log_msg)
    elseif (state == "race-init") then
        -- nothing to display right now
    elseif (state == "choose") then
        -- print score
        print("your score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)
        print("comp score: " .. score.opponent .. " (" .. score.opponent_wins .. "-" .. score.opponent_losses .. ")", 0, 10, 7)

        print("choose your blob!", 30, 25, 7)

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
        print("risk | reward", 8, 82, 11)

        if (win_probability.blob1_moneyline < 0) then
            print(abs(win_probability.blob1_moneyline) .. " | 100", 12, 92, 11)
        else
            print("100 | " .. abs(win_probability.blob1_moneyline), 12, 92, 11)
        end

        print("blob 02", 77, 72, 12)
        print("risk | reward", 68, 82, 12)

        if (win_probability.blob2_moneyline < 0) then
            print(abs(win_probability.blob2_moneyline) .. " | 100", 72, 92, 12)
        else
            print("100 | " .. abs(win_probability.blob2_moneyline), 72, 92, 12)
        end

        print("use ⬅️ or ➡️ to choose", 20, 105, 9)
        print("press 🅾️ or z to select!", 15, 115, 10)

        -- print log message
        print_log_msg(log_msg)
    elseif (state == "locked_in") then
        print("current score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)
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

        local pre_race_x = 10
        local blob1_y_countdown = 66
        local blob2_y_countdown = 96

        -- run animation and bobbing
        local run_anim_1 = blob1_sprite + flr(time() * 4) % 2
        local run_anim_2 = blob2_sprite + flr(time() * 3.5) % 2
        local bob = sin(time() * 6) * 1.5

        draw_track()

        -- draw with both bobbing and false start offset
        sspr(run_anim_1 * 8, 0, 8, 8, pre_race_x - 12 + false_start.blob1.current, blob1_y_countdown - 12 + bob, 24, 24, false, false)
        sspr(run_anim_2 * 8, 0, 8, 8, pre_race_x - 12 + false_start.blob2.current, blob2_y_countdown - 12 + bob, 24, 24, false, false)

        if (lock_timer < 30) then
            announcer_opt = {string = "racers on the ready...", x = 22, y = 10, color = 14}
            spr(48, 43, 20) -- red light
            spr(51, 51, 20)
            spr(51, 59, 20)
            spr(51, 67, 20)
            countdown_opt = {string = "3", x = 58, y = 32, color = 7}
        elseif (lock_timer < 60) then
            announcer_opt = {string = "on your marks...", x = 33, y = 10, color = 13}
            spr(48, 43, 20) -- red light
            spr(48, 51, 20)
            spr(51, 59, 20)
            spr(51, 67, 20)
            countdown_opt = {string = "2", x = 58, y = 32, color = 10}
        elseif (lock_timer < 90) then
            announcer_opt = {string = "get set...", x = 45, y = 10, color = 12}
            spr(48, 43, 20)
            spr(48, 51, 20)
            spr(49, 59, 20) -- orange light
            spr(51, 67, 20)
            countdown_opt = {string = "1", x = 58, y = 32, color = 9}
        elseif (lock_timer < 120) then
            announcer_opt = {string = "and they're off!", x = 30, y = 10, color = 11}
            spr(48, 43, 20)
            spr(48, 51, 20)
            spr(49, 59, 20)
            spr(50, 67, 20) -- green light!
            countdown_opt = {string = "go!", x = 55, y = 32, color = 8}
        else
            announcer_opt = {string = "there's a problem on the track!", x = 20, y = 30, color = 14}
            countdown_opt = {string = "false start!", x = 60, y = 50, color = 14}
        end

        countdown_msg(announcer_opt, countdown_opt)

        print_log_msg(log_msg)
    elseif (state == "racing") then
        print("your score: " .. score.player .. " ", 0, 0, 7)
        print("comp score: " .. score.opponent, 64, 0, 7)
        print("the race is on!", 35, 10, 11)

        if (player_boost.overheating) then
            print("boost overheat!", 35, 20, 8)
        else
            print("press ❎ or x to boost!", 20, 20, 9)
        end

        draw_track()

        sspr(blob1_sprite_frame * 8, 0, 8, 8, blob1_x - 12, blob1_y - 12, 24, 24, false, false)
        sspr(blob2_sprite_frame * 8, 0, 8, 8, blob2_x - 12, blob2_y - 12, 24, 24, false, false)

        -- if (logging) then
        --     print("blob1_x: " .. blob1_x .. " speed: " .. blob1_speed, 0, 90, 6)
        --     print("blob2_x: " .. blob2_x .. " speed: " .. blob2_speed, 0, 100, 6)
        -- end

        print_log_msg(log_msg)
    elseif (state == "result") then
        print("your score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)
        print("comp score: " .. score.opponent .. " (" .. score.opponent_wins .. "-" .. score.opponent_losses .. ")", 0, 10, 7)

        if (game_over) then
            print("the match is over!", 30, 30, 11)
        else
            print("this race is over!!", 30, 30, 11)
        end

        print("the race winner is blob " .. race_winner .. "!", 15, 40, 14)

        if (race_winner == selected_blob and game_over) then
            print("you won the match!", 30, 60, 11)
            print("congratulations!", 31, 70, 12)
            print("press 🅾️ or z to play again", 11, 90, 10)
        elseif (race_winner == selected_blob and not game_over) then
            print("you won!", 48, 60, 12)
            print("congratulations!", 31, 70, 12)
            print("press 🅾️ or z to race again", 11, 90, 10)
        elseif (race_winner != selected_blob and game_over) then
            print("you lost the match!", 27, 60, 11)
            print("better luck next time!", 22, 70, 9)
            print("press 🅾️ or z to play again", 11, 90, 10)
        elseif (race_winner != selected_blob and not game_over) then
            print("you didn't win the race", 19, 60, 9)
            print("better luck next time!", 22, 70, 9)
            print("press 🅾️ or z to race again", 11, 90, 10)
        end

        print_log_msg(log_msg)
    end
end

-->8
-- helper functions

function draw_sprite(sprite_id, x, y, w, h, flip_x, flip_y)
    local sx = (sprite_id % 16) * 8
    local sy = flr(sprite_id / 16) * 8
    sspr(sx, sy, 8, 8, x, y, w, h, flip_x or false, flip_y or false)
end

function game_score_init()
    score.player = 500
    score.opponent = 500
    score.player_wins = 0
    score.opponent_wins = 0
    score.player_losses = 0
    score.opponent_losses = 0
    game_over = false
end

function set_win_probability()
    win_probability.track_length = win_probability.finish_line - win_probability.start_line
    win_probability.blob1_expected_time = (win_probability.track_length/blob1_speed)/30
    win_probability.blob2_expected_time = (win_probability.track_length/blob2_speed)/30
    win_probability.blob1 = blob1_speed/win_probability.total_speed
    win_probability.blob2 = blob2_speed/win_probability.total_speed
end

-- Converts a win probability (wp) into a moneyline value, a common concept in sports betting.
-- The formula differs based on whether wp is greater than or less than 0.5:
--   - For wp >= 0.5, the moneyline is negative, indicating a favored outcome.
--   - For wp < 0.5, the moneyline is positive, indicating an underdog outcome.
-- The `+0.5` adjustment ensures proper rounding to the nearest integer when using the `flr` function.

function win_probability_to_moneyline(wp)
    local moneyline = 0
    if (wp >= 0.5) then
        moneyline = -1 * (wp / (1 - wp)) * 100 + 0.5
    elseif (wp < 0.5) then
        moneyline = ((1 - wp) / wp) * 100 + 0.5
    end
    return flr(moneyline)
end

function set_racer_moneyline()
    win_probability.blob1_moneyline = win_probability_to_moneyline(win_probability.blob1)
    win_probability.blob2_moneyline = win_probability_to_moneyline(win_probability.blob2)
end

function set_fastest_blob(blob1_speed, blob2_speed)
    if (blob1_speed > blob2_speed) then
        boost_meter.fastest_blob = 1
    else
        boost_meter.fastest_blob = 2
    end
end

function calculate_speed_gap_percent(blob1_speed, blob2_speed)
    local average = (blob1_speed + blob2_speed) / 2
    local gap = abs(blob1_speed - blob2_speed)
    local percent_speed_gap_difference = gap / average

    return percent_speed_gap_difference
end

function calculate_boost_bonus(blob1_speed, blob2_speed)
    local speed_gap_percent = calculate_speed_gap_percent(blob1_speed, blob2_speed)

    boost_meter.bonus = speed_gap_percent * 70
    quick_log.boost_bonus = boost_meter.bonus
end

function calculate_boost_strength(blob1_speed, blob2_speed)
    local speed_gap_percent = calculate_speed_gap_percent(blob1_speed, blob2_speed)
    local scale = 1 + (speed_gap_percent * 0.5) -- Scale the strength based on speed gap

    quick_log.scale = scale

    boost_meter.strength_balance = boost_meter.strength_base * scale
end

function boost_balance(blob1_speed, blob2_speed)
    local boost_base = 100
    if (selected_blob == 1) then
        if (boost_meter.fastest_blob == 1) then
            player_boost.meter = boost_base
            player_boost.amount_modified = boost_meter.strength_base

            opponent_boost.meter = boost_base + boost_meter.bonus
            opponent_boost.amount_modified = boost_meter.strength_balance
        else
            player_boost.meter = boost_base + boost_meter.bonus
            player_boost.amount_modified = boost_meter.strength_balance

            opponent_boost.meter = boost_base
            opponent_boost.amount_modified = boost_meter.strength_base
        end
    elseif (selected_blob == 2) then
        if (boost_meter.fastest_blob == 2) then
            player_boost.meter = boost_base
            player_boost.amount_modified = boost_meter.strength_base

            opponent_boost.meter = boost_base + boost_meter.bonus
            opponent_boost.amount_modified = boost_meter.strength_balance
        else
            player_boost.meter = boost_base + boost_meter.bonus
            player_boost.amount_modified = boost_meter.strength_balance

            opponent_boost.meter = boost_base
            opponent_boost.amount_modified = boost_meter.strength_base
        end
    end
end

function countdown_msg(announcer_opt, countdown_opt)
    print(announcer_opt.string, announcer_opt.x, announcer_opt.y, announcer_opt.color)
    print(countdown_opt.string, countdown_opt.x, countdown_opt.y, countdown_opt.color)
end

function draw_track()
    map(0, 0, 0, 45, 16, 16)
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
            player_boost.amount = player_boost.amount_modified
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
            opponent_boost.amount = opponent_boost.amount_modified
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
            update_scoring()
        elseif (blob2_x >= 120) then
            race_winner = 2
            state = "result"
            update_scoring()
        end
    end
end

function update_scoring()
    -- Determine the player's chosen blob's moneyline
    local player_moneyline

    if (selected_blob == 1) then
        player_moneyline = win_probability.blob1_moneyline
    else
        player_moneyline = win_probability.blob2_moneyline
    end

    local abs_moneyline = abs(player_moneyline)

    if (race_winner == selected_blob) then
        -- Player wins
        if (player_moneyline > 0) then
            -- Underdog: risk 100 to win moneyline
            score.player += player_moneyline
            score.opponent -= player_moneyline
        else
            -- Favorite: risk abs(moneyline) to win 100
            score.player += 100
            score.opponent -= 100
        end
        score.player_wins += 1
        score.opponent_losses += 1
    else
        -- Player loses
        if (player_moneyline > 0) then
            -- Underdog: lose 100
            score.player -= 100
            score.opponent += 100
        else
            -- Favorite: lose abs(moneyline)
            score.player -= abs_moneyline
            score.opponent += abs_moneyline
        end
        score.player_losses += 1
        score.opponent_wins += 1
    end

    is_game_over()
end

function is_game_over()
    if (score.player >= 1000 or score.opponent >= 1000) then
        game_over = true
    end
end

function music_player()
    local desired_music = -1

    if state == "game-start" then
        desired_music = 0
    elseif state == "choose" then
        desired_music = 10
    end

    -- only change music if it's different than current

    if (is_muted) then
        if current_music != -1 then
            music(-1) -- stop music if muted
            current_music = -1 -- stop music if muted
        end
    elseif desired_music != current_music then
        if desired_music == -1 then
            music(-1) -- stop music
        else
            music(desired_music)
        end
        current_music = desired_music
    end
end

function print_log_msg()
    if logging then
        if (log_msg != "") then
            print(log_msg, 0, 120, 5)
        else
            print("log: na", 0, 120, 5)
        end
    end
end

__gfx__
000000000088880000bbbb0000000000000000000000000000000000000000000000000033333333000000000000000000000000000000000000000000000000
00000000080cc0800ba00ab000cccc0000cccc0000eeee0000eeee00000000000000000033333333000000000000000000000000000000000020000000000200
00700700088888800b0bb0b00ccacac00ccacac00eedede00eedede0000000000000000068686868000000000000000000110000000000000000000000000220
00077000080cc0800b0000b00cccccc00cccccc00eeeeee00eeeeee0000000000000000086868686077777700999999000010000000000000002000000000000
00077000088888800babbab00ccbabc00ccbabc00ee232e00ee232e0000000000000000068686868077777700999999000000000000001000000000000000000
0070070008c88c800bbbbbb00cccccc00cccacc00eee3ee00eee3ee0000000000000000086868686000000000000000000000000000010000000000000020000
0000000008cccc800babbab000cccc0000cccc0000eeee0000e33e00000000000000000068686868000000000000000000000000000000000000000000000000
000000000088880000bbbb0000000000000000000000000000000000000000000000000086868686000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000006a6a6a6a70707070333333337a7a7a7a000000000000000000000000
0077770000bbbb00009999000088880000aaaa0000000000000000000000000000000000a6a6a6a60707070733333333a7a7a7a7000000000000000000000000
077070700bbebeb009909090088989800aaeaea0000000000000000000000000000000006a6a6a6a70707070787878787a7a7a7a000000000000000000000200
077777700bbbbbb009999990088888800aaaaaa000000000000000000000000000000000a6a6a6a60707070787878787a7a7a7a7000000000000000000000002
077656700bba9ab0099c2c90088aca800aaebea0000000000000000000000000000000006a6a6a6a70707070787878787a7a7a7a000000000000000000000000
077777700bbbbbb009999990088888800aaaaaa000000000000000000000000000000000a6a6a6a60707070787878787a7a7a7a7000000000000000000220000
0077770000bbbb00009999000088880000aaaa000000000000000000000000000000000033333333707070707878787833333333000000000000000000020000
00000000000000000000000000000000000000000000000000000000000000000000000033333333070707078787878733333333000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68888886699999966bbbbbb667777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68788786697997966b7bb7b667766776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68877886699779966bb77bb667677676000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68877886699779966bb77bb667677676000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68788786697997966b7bb7b667766776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
68888886699999966bbbbbb667777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0909090909090909090909090909091b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
150f1515150d150e15150c151515151a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515150c0e15151515150f150d15151a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
150d1515151f15150c1515150c0e151a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0b0a0a0b0a0a0b0a0a0b0a0a0b1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151f1515150d0c151515150c0f0d0c1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0c0d000000000c0e0d000c0e001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515150f15150e1515290e2b2c2a1f1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1919191919191919191919191919191c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
460100001035011350103501135010350113501035011350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
370100002a7502b7502c7502d7502e7502f7502475025750267502775028750297503675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490800000c6501865024650306503c650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
270500001803226032180322603218032260321803226032000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
57080000376462b6561f6463762611616296561d65600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
270800000c5370e537115371353715537175371853700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507005070050700507
b51000000c302003020c352003020c302003020c352003020c302003020c352003020c302003020c352003020c302003020c352003020c302003020c352003020c302003020c352003020c3020c3520c3020c352
0110000018050000001c05000000000000000000000000001c0500000018050000000000000000000000000024050000002805000000000000000000000000003405000000240500000000000000000000000000
bf10000013150001001315000100171500010017150001001515000100151500010018150001001115000100001000010000100001000010000100001000010000100001000010000100001000c1501015013150
371000200c33300000000000000024133000000c100000000c333000000000000000241330000000000000000c333000000000000000241330000000000000000c33300000000000000024133000000c33300000
b51000000c3020030211352003020c3020030211352003020c3020030211352003020c3020030211352003020c3020030211352003020c3020030211352003020c3020030211352003020c302113520c30211352
011000001d050000001f05000000000000000000000000001f050000001d050000000000000000000000000029050000002b05000000000000000000000000002b05000000290500000000000000000000000000
d7100000171500010017150001000e150001000e150001000c150001000c150001001015000100151500010000100001000010000100001000010000100001000010000100001000010000100101501315017150
b71000000c35200302003020e3020e352003020030200302103520030200302003020e3520030200302003020e352003020030200302103520030200302003020c35200302003020c3520c3020c352003020c352
bf100000131500010013150001001715000100171500010015150001001515000100181500010011150001000010018150001001c15000100001001f150001000c10018150101001c15013100131001f15000000
01100000171500010017150001000e150001000e150001000c150001000c150001001015000100151500010000100001001c150001001f150001002315000100001000010028150001002b150101002f15017100
350200001e3501e3501e3501e3501e3501e3501e3501e350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
350200002225022250222502225022250222502225022250222502225022250222502225022250222502225000200002000020000200002000020000200002000020000200002000020000200002000020000200
__music__
01 06404109
00 06070809
00 06070e09
00 06474809
00 0a4b4c09
00 0a0b0c09
00 0a0b0f09
00 0a0b4c09
00 0a4b4c09
02 0d424309
01 06474809
02 0a4b4c09

