--[[
  Copyright 2020 The Nakama Authors

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

local nk = require("nakama")

local format = string.format
local function log(fmt, ...)
    nk.logger_info(string.format(fmt, ...))
end

local function pprint(value)
    if type(value) == "table" then
        for k,v in pairs(value) do
            log("'%s' = '%s'", tostring(k), tostring(v))
        end
    else
        log(tostring(value))
    end
end


local function makematch(context, matched_users)
    log("Creating TicTacToe match")
    -- print matched users
    for _, user in ipairs(matched_users) do
        local presence = user.presence
        log("Matched user '%s' named '%s'", presence.user_id, presence.username)
        for k, v in pairs(user.properties) do
            log("Matched on '%s' value '%s'", k, v)
        end
    end

    local modulename = "tictactoe_match"
    local setupstate = { invited = matched_users }
    local matchid = nk.match_create(modulename, setupstate)
    return matchid
end




nk.run_once(function(ctx)

  local now = os.time()
  nk.logger_info(("Backend loaded at %d"):format(now))

  nk.register_matchmaker_matched(makematch)

  create_tournament()
end)
