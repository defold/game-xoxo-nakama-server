local tictactoe = require("tictactoe_state")
local nk = require("nakama")

local M = {}

local OP_CODE_MOVE = 1
local OP_CODE_STATE = 2


local function pprint(t)
    if type(t) ~= "table" then
        nk.logger_info(tostring(t))
    else
        for k,v in pairs(t) do
            nk.logger_info(string.format("%s = %s", tostring(k), tostring(v)))
        end
    end
end

local function broadcast_gamestate_to_recipient(dispatcher, gamestate, recipient)
    nk.logger_info("broadcast_gamestate")
    local active_player = tictactoe.get_active_player(gamestate)
    local other_player = tictactoe.get_other_player(gamestate)
    local your_turn = active_player.user_id == recipient.user_id
    local message = {
        state = gamestate,
        active_player = active_player,
        other_player = other_player,
        your_turn = your_turn,
    }
    local encoded_message = nk.json_encode(message)
    dispatcher.broadcast_message(OP_CODE_STATE, encoded_message, { recipient })
end

local function broadcast_gamestate(dispatcher, gamestate)
    local player = tictactoe.get_active_player(gamestate)
    local opponent = tictactoe.get_other_player(gamestate)
    broadcast_gamestate_to_recipient(dispatcher, gamestate, player)
    broadcast_gamestate_to_recipient(dispatcher, gamestate, opponent)
end

function M.match_init(context, setupstate)
    nk.logger_info("match_init")
    local gamestate = tictactoe.new_game()
    local tickrate = 1 -- per sec
    local label = ""
    return gamestate, tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, gamestate, presence, metadata)
    nk.logger_info("match_join_attempt")
    local acceptuser = true
    return gamestate, acceptuser
end

function M.match_join(context, dispatcher, tick, gamestate, presences)
    nk.logger_info("match_join")
    for _, presence in ipairs(presences) do
        tictactoe.add_player(gamestate, presence)
    end
    if tictactoe.player_count(gamestate) == 2 then
        broadcast_gamestate(dispatcher, gamestate)
    end
    return gamestate
end

function M.match_leave(context, dispatcher, tick, gamestate, presences)
    nk.logger_info("match_leave")
    -- end match if someone leaves
    return nil
end

function M.match_loop(context, dispatcher, tick, gamestate, messages)
    nk.logger_info("match_loop")

    for _, message in ipairs(messages) do
        nk.logger_info(string.format("Received %s from %s", message.data, message.sender.username))
        pprint(message)

        if message.op_code == OP_CODE_MOVE then
            local decoded = nk.json_decode(message.data)
            local row = decoded.row
            local col = decoded.col
            gamestate = tictactoe.player_move(gamestate, row, col)
            if gamestate.winner or gamestate.draw then
                gamestate.rematch_countdown = 10
            end

            broadcast_gamestate(dispatcher, gamestate)
        end
    end
    if gamestate.rematch_countdown then
        gamestate.rematch_countdown = gamestate.rematch_countdown - 1
        if gamestate.rematch_countdown == 0 then
            gamestate = tictactoe.rematch(gamestate)
        end
        broadcast_gamestate(dispatcher, gamestate)
    end

    return gamestate
end

function M.match_terminate(context, dispatcher, tick, gamestate, grace_seconds)
    nk.logger_info("match_terminate")
    local message = "Server shutting down in " .. grace_seconds .. " seconds"
    dispatcher.broadcast_message(2, message)
    return nil
end

return M
