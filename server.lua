local QBCore = exports['qb-core']:GetCoreObject()
local previousDutyStatus = {}
local dutyStartTimes = {}

local function sendToDiscord(webhookURL, title, description, color, timestamp)
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "Duty Logger by CDocc"
            },
            ["timestamp"] = timestamp
        }
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({username = "Duty Logger", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

local function getFrameworkPlayer(src)
    if config.framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    elseif config.framework == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    else
        print("Unsupported framework: " .. config.framework)
        return nil
    end
end

RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(playerData)
    local src = source
    local player = getFrameworkPlayer(src)
    local job = playerData.job.name
    local duty = playerData.job.onduty
    local webhookURL = config.jobWebhooks[job]

    if previousDutyStatus[src] ~= duty then
        previousDutyStatus[src] = duty

        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

        if webhookURL then
            if duty then
                dutyStartTimes[src] = os.time()
                sendToDiscord(webhookURL, "Player On Duty", playerData.name .. " | **" ..playerData.charinfo.firstname.. " " ..playerData.charinfo.lastname.. "** is now on duty as " .. job, 3066993, timestamp) -- Green color
            else
                local dutyEndTime = os.time()
                local dutyStartTime = dutyStartTimes[src] or dutyEndTime
                local duration = os.difftime(dutyEndTime, dutyStartTime)
                
                local hours = math.floor(duration / 3600)
                local minutes = math.floor((duration % 3600) / 60)
                local seconds = duration % 60

                local durationString = string.format("%02d hours, %02d minutes, %02d seconds", hours, minutes, seconds)

                sendToDiscord(webhookURL, "Player Off Duty", playerData.name .. " | **" ..playerData.charinfo.firstname.. " " ..playerData.charinfo.lastname.. "** is now off duty as " .. job .. ". Duration: " .. durationString, 15158332, timestamp) -- Red color
            
                dutyStartTimes[src] = nil
            end
        else
            print("No webhook URL configured for job: " .. job)
        end
    end
end)