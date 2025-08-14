--[[
  Copyright 2020 The Defold Foundation Authors & Contributors

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]--

local M = {}

local function index_to_row_column(index)
	local row = math.ceil(index / 3)
	local column = 1 + ((index - 1) % 3)
	return row, column
end

local function check_match(cells)
	local match = cells[1] ~= -1 and cells[1] == cells[2] and cells[1] == cells[3]
	if match then
		return cells[1]
	end
end

local function check_winner(state)
	local cells = state.cells
	local match_row =
	check_match(cells[1]
	or check_match(cells[2])
	or check_match(cells[3]))

	local match_column =
	-- down
	check_match({ cells[1][1], cells[2][1], cells[3][1] })
	or check_match({ cells[1][2], cells[2][2], cells[3][2] })
	or check_match({ cells[1][3], cells[2][3], cells[3][3] })
	-- across
	or check_match({ cells[1][1], cells[1][2], cells[1][3] })
	or check_match({ cells[2][1], cells[2][2], cells[2][3] })
	or check_match({ cells[3][1], cells[3][2], cells[3][3] })

	local match_cross =
	check_match({ cells[1][1], cells[2][2], cells[3][3] })
	or check_match({ cells[3][1], cells[2][2], cells[1][3] })

	local won = match_row or match_column or match_cross
	return won
end

local function check_draw(state)
	local cells = state.cells
	for i=1,9 do
		local row, column = index_to_row_column(i)
		if cells[row][column] == -1 then
			return false
		end
	end
	return true
end

local function create_state(players)
	return {
		cells = {
			{ -1, -1, -1 },
			{ -1, -1, -1 },
			{ -1, -1, -1 },
		},
		players = players or {},
		player_turn = 1,
	}
end

function M.new_game()
	return create_state()
end

function M.rematch(state)
	assert(state)
	assert(#state.players == 2, "Game must have two players")
	return create_state(state.players)
end

function M.add_player(state, player_id)
	assert(state)
	assert(#state.players < 2, "Game already has two players")
	assert(player_id)
	if #state.players == 1 then
		assert(state.players[1] ~= player_id, "The player has already been added to the match")
	end
	state.players[#state.players + 1] = player_id
	return state
end

function M.player_count(state)
	assert(state)
	return #state.players
end

function M.player_move(state, row, column)
	assert(state)
	assert(#state.players == 2, "Game must have two players before a move can be made")
	if state.cells[row][column] == -1 then
		local player_index = state.player_turn
		state.cells[row][column] = state.player_turn
		state.player_turn = (state.player_turn == 1) and 2 or 1
		state.draw = check_draw(state)
		if check_winner(state) then
			state.winner = player_index
		else
			state.winner = false
		end
		return state, true
	else
		return state, false
	end
end

function M.get_active_player(state)
	assert(state)
	assert(#state.players == 2, "Game must have two players!")
	return state.players[state.player_turn]
end

function M.get_other_player(state)
	assert(state)
	assert(#state.players == 2, "Game must have two players!")
	return state.players[(state.player_turn == 1) and 2 or 1]
end

function M.dump(state)
	for r=1,3 do
		local c1 = state.cells[r][1]
		local c2 = state.cells[r][2]
		local c3 = state.cells[r][3]
		print(("[%02d][%02d][%02d]"):format(c1, c2, c3))
	end
end

return M
