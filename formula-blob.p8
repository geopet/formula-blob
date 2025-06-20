pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- formula blob 1.0.0
-- by @geopet
-- https://github.com/geopet/formula-blob

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
    race_victory_sfx = false
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

    blobs = {
        blob1 = {
            base_sprite = { x = 3, y = 0 },
            boost_sprite = { x = 5, y = 8 },
            position = { x = nil, y = nil },
            speed = nil,
            name = nil,
            false_start = { target = 0, current = 0 },
            win_probability = { expected_time = nil, ratio = nil, moneyline = nil }
        },
        blob2 = {
            base_sprite = { x = 5, y = 0 },
            boost_sprite = { x = 1, y = 0 },
            position = { x = nil, y = nil },
            speed = nil,
            name = nil,
            false_start = { target = 0, current = 0 },
            win_probability = { expected_time = nil, ratio = nil, moneyline = nil }
        }
    }

    selected_blob = 0

    -- race variables
    race_results = {
        winner = nil,
        loser = nil,
        winner_id = 0,
        loser_id = 0
    }

    game_over = nil
    fireworks = {}

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
        total_speed = nil
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
        blobs.blob1.speed = (0.5 * rnd(1)) + 0.08
        blobs.blob2.speed = (0.5 * rnd(1)) + 0.08

        -- testing values
        -- blobs.blob1.speed = 0.1
        -- blobs.blob2.speed = 0.1

        win_probability.total_speed = blobs.blob1.speed + blobs.blob2.speed

        set_fastest_blob()
        calculate_boost_bonus()
        calculate_boost_strength()
        set_win_probability()
        set_racer_moneyline()
        set_blob_names()

        state = "choose"
    elseif (state == "choose") then
        if (log_msg == "start state") then
            log_msg = "b1 t: " .. blobs.blob1.win_probability.expected_time .. " b2 t: " .. blobs.blob2.win_probability.expected_time
        end
        if (btnp(0)) then -- left blob (1)
            selected_blob = 1
            sfx(0)
            -- log_msg = "b1 wp: " .. blobs.blob1.win_probability.ratio .. "b1 t: " .. blobs.blob1.win_probability.expected_time
            -- log_msg = "b1 wp: " .. blobs.blob1.win_probability.ratio .. " b1 ml: " .. blobs.blob1.win_probability.moneyline
            log_msg = quick_log.scale .. " " .. quick_log.boost_bonus .. " " .. (1.5 * quick_log.scale)
        elseif (btnp(1)) then -- right blob (2)
            selected_blob = 2
            sfx(0)
            -- log_msg = "b2 wp: " .. blobs.blob2.win_probability.ratio .. "b2 t: " .. blobs.blob2.win_probability.expected_time
            -- log_msg = "b2 wp: " .. blobs.blob2.win_probability.ratio .. " b2 ml: " .. blobs.blob2.win_probability.moneyline
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
        if (rnd(1) < 0.02 and blobs.blob1.false_start.target == 0 and blobs.blob1.false_start.current == 0) then
            blobs.blob1.false_start.target = flr(rnd(37)) + 4
            sfx(18)
        end
        if (rnd(1) < 0.02 and blobs.blob2.false_start.target == 0 and blobs.blob2.false_start.current == 0) then
            blobs.blob2.false_start.target = flr(rnd(37)) + 4
            sfx(18)
        end

        -- update blob false start positions
        for key, blob in pairs(blobs) do
            local fs = blob.false_start

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
            blobs.blob1.position.x = 10
            blobs.blob2.position.x = 10
            blobs.blob1.position.y = 66
            blobs.blob2.position.y = 96

            boost_balance(blobs.blob1.speed, blobs.blob2.speed)

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

            race_results.winner_id = 0

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

        for f in all(fireworks) do
            f.x += f.vx
            f.y += f.vy
            f.life -= 1
            if f.life <= 0 then
                del(fireworks, f)
            end
        end

        if (#fireworks == 0) then
            spawn_fireworks()
        end

        -- play victory sound effect
        if (not race_victory_sfx) then
            if (race_results.winner_id == selected_blob and not game_over) then
                sfx(21)
            elseif (race_results.winner_id == selected_blob and game_over) then
                sfx(23)
            else
                sfx(22)
            end
            race_victory_sfx = true
            spawn_fireworks()
        end

        if (btnp(4) and game_over) then
            race_victory_sfx = false
            state = "game-start"
        elseif (btnp(4) and not game_over) then
            race_victory_sfx = false
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
    local blob1_sprite_frame = blobs.blob1.base_sprite.x + flr(time() * 2.5) % 2
    local blob1_flip = flr(time() * 2) % 2 == 1
    local blob1_sprite_boost_frame = blobs.blob1.boost_sprite.x + flr(time() * 2.5) % 2
    local blob2_sprite_frame = blobs.blob2.base_sprite.x + flr(time() * 1.5) % 2
    local blob2_flip = flr(time()) % 2 == 1
    local blob2_sprite_boost_frame = blobs.blob2.boost_sprite.x + flr(time() * 1.5) % 2

    if (state == "game-start") then
        -- Pulsing welcome text
        local t = sin(time() * 2)
        local c = 7 + flr((t + 1) * 2)

        print_centered("welcome to formula blob!", 20, c)
        print_centered("version 1.0.0", 30, 12)
        print_centered("a fun time by @geopet", 40, 11)

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

        print_centered("press 🅾️ or z to start", 100, 10)
        -- print_centered("press ⬇️ down arrow to mute", 110, 9)

        print_log_msg(log_msg)
    elseif (state == "race-init") then
        -- nothing to display right now
    elseif (state == "choose") then
        -- calculate name layout
        local blob1_name_width = #blobs.blob1.name * 4
        local blob1_name_x = 30 - blob1_name_width / 2

        local blob2_name_width = #blobs.blob2.name * 4
        local blob2_name_x = 90 - blob2_name_width / 2

        -- print score
        print("your score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)
        print("comp score: " .. score.opponent .. " (" .. score.opponent_wins .. "-" .. score.opponent_losses .. ")", 0, 10, 7)

        print_centered("choose your blob!", 25, 7)

        -- draw blobs
        sspr(blob1_sprite_frame * 8, blobs.blob1.base_sprite.y, 8, 8, 30-12, 55-12 + blob_pulse, 24, 24, blob1_flip, false)
        sspr(blob2_sprite_frame * 8, blobs.blob2.base_sprite.y, 8, 8, 90-12, 55-12 + blob_pulse_2, 24, 24, blob2_flip, false)

        -- highlight selected blob
        if (selected_blob == 1) then
            print("⬇️", 27 + wiggle_offset, 35 + bobbing_offset, 7)
        elseif (selected_blob == 2) then
            print("⬇️", 87 + wiggle_offset, 35 + bobbing_offset, 7)
        end

        -- add labels
        print(blobs.blob1.name, blob1_name_x, 72, 11)
        print("risk | reward", 8, 82, 11)

        if (blobs.blob1.win_probability.moneyline < 0) then
            print(abs(blobs.blob1.win_probability.moneyline) .. " | 100", 12, 92, 11)
        else
            print("100 | " .. abs(blobs.blob1.win_probability.moneyline), 12, 92, 11)
        end

        print(blobs.blob2.name, blob2_name_x, 72, 12)
        print("risk | reward", 68, 82, 12)

        if (blobs.blob2.win_probability.moneyline < 0) then
            print(abs(blobs.blob2.win_probability.moneyline) .. " | 100", 72, 92, 12)
        else
            print("100 | " .. abs(blobs.blob2.win_probability.moneyline), 72, 92, 12)
        end

        print_centered("use ⬅️ or ➡️ to choose", 105, 9)
        print_centered("press 🅾️ or z to select!", 115, 10)

        -- print log message
        print_log_msg(log_msg)
    elseif (state == "locked_in") then
        print("current score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)

        -- prepare "is ready!" line
        local blob_name = (selected_blob == 1) and blobs.blob1.name or blobs.blob2.name
        local ready_text = blob_name .. " is ready!"
        print_centered(ready_text, 20, 12)

        if (selected_blob == 1) then
            sspr(blob1_sprite_frame * 8, blobs.blob1.base_sprite.y, 8, 8, 52, 42 + blob_pulse, 24, 24, blob1_flip, false)
        else
            sspr(blob2_sprite_frame * 8, blobs.blob2.base_sprite.y, 8, 8, 52, 42 + blob_pulse_2, 24, 24, blob2_flip, false)
        end

        print_centered("press 🅾️ or z to start race!", 90, 10)
        print_centered("press ❎ or x to boost!", 100, 14)

        print_log_msg(log_msg)
    elseif (state == "countdown") then

        local pre_race_x = 10
        local blob1_y_countdown = 66
        local blob2_y_countdown = 96

        -- run animation and bobbing
        local run_anim_1 = blobs.blob1.base_sprite.x + flr(time() * 4) % 2
        local run_anim_2 = blobs.blob2.base_sprite.x + flr(time() * 3.5) % 2
        local bob = sin(time() * 6) * 1.5

        draw_track()

        -- draw with both bobbing and false start offset
        sspr(run_anim_1 * 8, 0, 8, 8, pre_race_x - 12 + blobs.blob1.false_start.current, blob1_y_countdown - 12 + bob, 24, 24, false, false)
        sspr(run_anim_2 * 8, 0, 8, 8, pre_race_x - 12 + blobs.blob2.false_start.current, blob2_y_countdown - 12 + bob, 24, 24, false, false)

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
        print_centered("the race is on!", 10, 11)

        if (player_boost.overheating) then
            print_centered("boost overheat!", 20, 8)
        else
            print_centered("press ❎ or x to boost!", 20, 9)
        end

        draw_track()

        if selected_blob == 1 then
            draw_racer(blobs.blob1, player_boost.active, blob1_sprite_frame, blob1_sprite_boost_frame, 0)
            draw_racer(blobs.blob2, opponent_boost.active, blob2_sprite_frame, blob2_sprite_boost_frame, 0)
        else
            draw_racer(blobs.blob2, player_boost.active, blob2_sprite_frame, blob2_sprite_boost_frame, 0)
            draw_racer(blobs.blob1, opponent_boost.active, blob1_sprite_frame, blob1_sprite_boost_frame, 0)
        end

        if (logging) then
            print("blob1_x: " .. blobs.blob1.position.x .. " speed: " .. blobs.blob1.speed, 0, 90, 6)
            print("blob2_x: " .. blobs.blob2.position.x .. " speed: " .. blobs.blob2.speed, 0, 100, 6)
        end

        print_log_msg(log_msg)
    elseif (state == "result") then

        local winner_x, winner_y = 30, 50
        local winner_size = 32
        local dance_x = sin(time() * 4) * 2
        local winner_flip_x = flr(time() * 2 ) % 2 == 0
        local loser_flip_x = not winner_flip_x
        local flip_y = flr(time()) % 8 == 0

        print("your score: " .. score.player .. " (" .. score.player_wins .. "-" .. score.player_losses .. ")", 0, 0, 7)
        print("comp score: " .. score.opponent .. " (" .. score.opponent_wins .. "-" .. score.opponent_losses .. ")", 0, 10, 7)

        -- headline
        local headline = game_over and "the match is over!" or "this race is over!!"
        print_centered(headline, 20, 11)

        -- winner large
        sspr(
            race_results.winner.base_sprite.x * 8, race_results.winner.base_sprite.y,
            8, 8,
            winner_x + dance_x, winner_y,  -- position on screen
            winner_size, winner_size,  -- size (scale 4x)
            winner_flip_x, flip_y
        )

        if (race_results.winner_id == selected_blob) then
            -- crown sprite
            sspr(
                32 % 16 * 8, flr(32 / 16) * 8,
                8, 8,
                winner_x + dance_x, winner_y - 5,  -- position on screen
                32, 32, -- size (scale 4x)
                winner_flip_x, false
            )
            if (game_over) then
                -- launch fireworks
                for f in all(fireworks) do
                    pset(f.x, f.y, f.color)
                end
                print_centered("you are the match winner!", 30, 14)
            else
                print_centered("you are the race winner!", 30, 14)
            end
        else
            print_centered("you did not win the race :(", 30, 14)
        end

        -- loser small
        sspr(
            race_results.loser.base_sprite.x * 8, race_results.loser.base_sprite.y,
            8, 8,
            80, 72 + dance_x,  -- position on screen
            8, 8,    -- size (normal)
            loser_flip_x, false
        )

        local prompt = game_over and "press 🅾️ or z to play again" or "press 🅾️ or z to race again"
        print_centered(prompt, 90, 10)

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
    blobs.blob1.win_probability.expected_time = (win_probability.track_length/blobs.blob1.speed)/30
    blobs.blob2.win_probability.expected_time = (win_probability.track_length/blobs.blob2.speed)/30
    blobs.blob1.win_probability.ratio = blobs.blob1.speed/win_probability.total_speed
    blobs.blob2.win_probability.ratio = blobs.blob2.speed/win_probability.total_speed
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
    blobs.blob1.win_probability.moneyline = win_probability_to_moneyline(blobs.blob1.win_probability.ratio)
    blobs.blob2.win_probability.moneyline = win_probability_to_moneyline(blobs.blob2.win_probability.ratio)
end

function set_fastest_blob()
    if (blobs.blob1.speed > blobs.blob2.speed) then
        boost_meter.fastest_blob = 1
    else
        boost_meter.fastest_blob = 2
    end
end

function calculate_speed_gap_percent()
    local average = (blobs.blob1.speed + blobs.blob2.speed) / 2
    local gap = abs(blobs.blob1.speed - blobs.blob2.speed)
    local percent_speed_gap_difference = gap / average

    return percent_speed_gap_difference
end

function calculate_boost_bonus()
    local speed_gap_percent = calculate_speed_gap_percent()

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

function draw_racer(blob, is_boosting, standard_frame, boost_frame, pulse)
    local sprite_animation_frame = is_boosting and boost_frame or standard_frame
    local sprite_y = is_boosting and blob.boost_sprite.y or blob.base_sprite.y
    sspr(sprite_animation_frame * 8, sprite_y, 8, 8, blob.position.x - 12, blob.position.y - 12 + pulse, 24, 24, false, false)
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
        blobs.blob1.position.x += blobs.blob1.speed + player_boost.amount
        blobs.blob2.position.x += blobs.blob2.speed + opponent_boost.amount
    else
        blobs.blob2.position.x += blobs.blob2.speed + player_boost.amount
        blobs.blob1.position.x += blobs.blob1.speed + opponent_boost.amount
    end
end

function win_condition_check()
    if race_results.winner_id == 0 then
        if (blobs.blob1.position.x >= 120) then
            race_results.winner_id = 1
            race_results.winner = blobs.blob1
            race_results.loser = blobs.blob2
            state = "result"
            update_scoring()
        elseif (blobs.blob2.position.x >= 120) then
            race_results.winner_id = 2
            race_results.winner = blobs.blob2
            race_results.loser = blobs.blob1
            state = "result"
            update_scoring()
        end
    end
end

function update_scoring()
    -- Determine the player's chosen blob's moneyline
    local player_moneyline

    if (selected_blob == 1) then
        player_moneyline = blobs.blob1.win_probability.moneyline
    else
        player_moneyline = blobs.blob2.win_probability.moneyline
    end

    local abs_moneyline = abs(player_moneyline)

    if (race_results.winner_id == selected_blob) then
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

function spawn_fireworks()
    for i = 1, 20 do
        local f = {
            x = 64 + rnd(40) - 20,
            y = 32 + rnd(40) - 20,
            vx = rnd(2) - 1,
            vy = rnd(2) - 1,
            life = 30 + flr(rnd(20)),
            color = 8 + flr(rnd(7)) -- random color from 8 on (bright)
        }
        add(fireworks, f)
    end
end

function assign_name()
    local names = {
        "blobzilla", "blast", "skids", "mcblobface", "bouncy", "slimer", "wiggly", "blash",
        "mcblobberson", "blobster", "blobinator", "blobtastic", "blobby", "bloob",
        "max verblobben", "blobo norris", "charles leblob", "blewis hamiblob", "blobo perez", "fenando balobso",
        "blance bloll", "blierre basly", "blobos sainz", "baltteri blobas", "jeff"
    }

    return names[flr(rnd(#names)) + 1] -- pick a random name from the list
end

function set_blob_names()
    blobs.blob1.name = assign_name()
    blobs.blob2.name = assign_name()

    -- Ensure names are unique
    while (blobs.blob1.name == blobs.blob2.name) do
        blobs.blob2.name = assign_name()
    end
end

function print_centered(text, y, color)
    local text_width = #text * 4
    local x = 64 - text_width / 2
    print(text, x, y, color)
end

function music_player()
    local desired_music = -1

    if state == "game-start" then
        desired_music = 0
    elseif state == "choose" then
        desired_music = 10
    elseif state == "locked_in" then
        desired_music = 25
    elseif state == "countdown" or state == "racing" then
        desired_music = 24
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
0000000000000000bbbbbbb000000000000000000000000000000000000000000000000033333333000000000000000000000000000000000000000000000000
000000000beeee0000eeeeb000cccc0000cccc0000eeee0000eeee00000000000000000033333333000000000000000000000000000000000020000000000200
00700700beeaeae0beeaeae00ccacac00ccacac00eedede00eedede0000000000000000068686868000000000000000000110000000000000000000000000220
000770000eeeeee00eeaeae00cccccc00cccccc00eeeeee00eeeeee0000000000000000086868686077777700999999000010000000000000002000000000000
00077000be2232e0be2232e00ccbabc00ccbabc00ee232e00ee232e0000000000000000068686868077777700999999000000000000001000000000000000000
007007000e2222e00e2232e00cccccc00cccacc00eee3ee00eee3ee0000000000000000086868686000000000000000000000000000010000000000000020000
000000000beeee00bbe33e0000cccc0000cccc0000eeee0000e33e00000000000000000068686868000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000086868686000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000009999999000000000000000006a6a6a6a70707070333333337a7a7a7a000000000000000000000000
0077770000bbbb00009999000088880000aaaa0009cccc0000cccc900000000000000000a6a6a6a60707070733333333a7a7a7a7000000000000000000000000
077070700bbebeb009909090088989800aaeaea09cc8c8c09cc8c8c000000000000000006a6a6a6a70707070787878787a7a7a7a000000000000000000000200
077777700bbbbbb009999990088888800aaaaaa00cccccc00cc8c8c00000000000000000a6a6a6a60707070787878787a7a7a7a7000000000000000000000002
077656700bba9ab0099c2c90088aca800aaebea09caabac09caabac000000000000000006a6a6a6a70707070787878787a7a7a7a000000000000000000000000
077777700bbbbbb009999990088888800aaaaaa00caaaac00cababc00000000000000000a6a6a6a60707070787878787a7a7a7a7000000000000000000220000
0077770000bbbb00009999000088880000aaaa0009cccc0099cccc00000000000000000033333333707070707878787833333333000000000000000000020000
00000000000000000000000000000000000000000000000000000000000000000000000033333333070707078787878733333333000000000000000000000000
03900920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26299363000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
93999929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
340f3434340d340e34340c343434341a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3434340c0e34343434340f340d34341a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
340d3434341f34340c3434340c0e341a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0b0a0a0b0a0a0b0a0a0b0a0a0b1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
341f3434340d0c343434340c0f0d0c1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0c0d000000000c0e0d000c0e001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3434340f34340e3434290e2b2c2a1f1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
c10200002a2372823726237242372e2372b6370063728637006372363721637006371e6571c6071b607196071760717607166071360712607106070f6070f6070060700607006070060700607006070060700607
8f0900000961309613096130d6130d6132b6132b6132f613216132161321613256132561307613076130b6130961309613096130d6130d61307613076130b61321613216132d6130d6130d61307613076130b613
bd0900000961009610096100d6100d61007610076100b6100961009610096100d6100d61007610076100b610216102161021610196100d61007610076100b6100961009610096100d6100d6101f6101f61023610
551000000c352183520c3521835218302183520030224352003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302
0d100000210521f0521d0521c0521a052000021a052000020e0520000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
3d1000001c0521d052000021a0520000218052000021a052000021c052000021f052000021f052000021f05221052000021f052000021d052000021f0521c0521c052000021c052000021d05200002240522b052
47100000150550000511055000050e055000050000500005170550000513055000051005500005000050000518055000051505500005110550000500005000051c055000051a055000051f055000050000500005
__music__
01 06404109
00 06070809
00 06070e09
00 06074809
00 0a4b4c09
00 0a0b0c09
00 0a0b0f09
00 0a0b4c09
00 0a074c09
02 0d424309
01 06474809
02 0a4b4c09
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 13144344
03 18424344

