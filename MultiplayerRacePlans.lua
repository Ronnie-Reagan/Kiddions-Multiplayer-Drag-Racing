--[[Multiplayer Race Plans - Reformatted for discord viewing
--------------------------------------------------------------------------------------------------------------------------


Note:
The "Flag", is the speed value. there are a total of 500 unique flags (0.00-5.00) in all.
However: While some may not be used or set yet, others may be used twice (car group and car in group) 


Post Race Records to Include:

Race Distance
Race Location                                                                       -- preset location name else x, y, z
winner                                                                              -- winner's name
time difference between players: x seconds

local player's name
local player's vehicle model
local player's final speed
local player's 60 foot time
local player's reaction time

opponent's name
opponent's vehicle model
opponent's final speed
opponent's 60 foot time
opponent's reaction time
]]

--                                              Planned Data Stucture:

--[[
local Flags = {
    Utility = {                                                                     -- Default / unused for flags / non message
        Default = 1.00,
    },
    Distance = {
        EighthMile = 2.01,
        QuarterMile = 2.02,
        HalfMile = 2.03,
        ThousandFoot = 2.04,
        FullMile = 2.05
    },
    Locations = {
        FortZancudoAirstrip = 2.11,
        LosSantosInternationalAirport = 2.12,
        SandyShoresAirfield = 2.13,
        NorthSenoraFreeway = 2.14,
        PaletoBayFreeway = 2.15,
        LaPuertaBridge = 2.16,
        CurrentPlayerLocation = 2.17
    },
    CarGroups = {
        GroupStart = 3.50,
        GroupEnd = 3.59,
        IndividualStart = 3.50,
        IndividualEnd = 3.99
    },
    HosterFlags = {
        HostAccepts = 1.02,
        HostFinished = 1.50,
        HostingOpen = 1.01,
        HostReady = 1.03,
        HostWaiting = 1.04,
        HostYes = 1.05,
	    HostNo = 1.06,
        RaceStart = 1.49
        -- Add other flags as needed
    },
    JoinerFlags = {
        JoinerBusy = 1.51,
        JoinerFinished = 1.52,
        JoinerJoined = 1.53,
        JoinerReady = 1.54,
        JoinerSearching = 1.55,
        JoinerYes = 1.56,
        JoinerNo = 1.57
        -- Add other flags as needed
    }
}


--                                          Order of Actions/Functions
        Host Actions                                                                        Joiner Actions

1. Initialize Race	
    - Open drag race menu	
    - Set default distance and location	
2. Host Race                                                                    1. Search for Race
    - Set RaceAvailable to false                                                    - Set joiner flag to Joiner Searching
    - Set host flag to "Hosting Open"                                               - Look for Host Accepts flag
    - Wait for a joiner	
3. Monitor for Joiner	
    - Check for Joiner Searching flag	
4. Host Accepts (Once Joiner Found)                                             2. Join Race (Once Host Accepts)
    - Set host flag to Host Accepts                                                 - Set joiner flag to Joiner Joined
    - Monitor for Joiner Joined flag                                                - Wait for HostReady to be true
5. Wait for Joiner to be Ready                                                  3. Prepare for Race
    - Monitor for "Joiner Ready" flag                                               - Set joiner flag to Joiner Ready
    - Once Joiner Ready detected,                                                   - Wait for race start signal
    - Set RaceAvailable to true	
6. Start Race	                                                                4. Start Race (Upon Host's Signal)
    - Set host flag to Race Started                                                 - Begin race loop upon host's start
    - Begin race loop after delay to sync
7. Race Loop                                                                    5. Race Loop
    - Monitor race progress                                                         - Monitor race progress
    - Handle in-race events                                                         - Handle in-race events
8. Post-Race                                                                    6. Post-Race
    - Receive Joiner results                                                        - Send results inc. all player info
    - compile, save and send race results                                           - Receive compiled race results
    - Offer rematch option                                                          - Decide on rematch option
    - if rematch = true go to 5                                                     - if rematch = true go to 2
    - if rematch = false go to 1
]]

--[[                                                Pseudocode: 


Notes:
tbd = to be determined




]]
-- Start of the script
--                                                Initialization
-- Initialization and Menu Setup
mainmenu = menu.add_submenu("MULTIPLAYER RACE")
local systemdelay = 0.25
local raceavailable = false
local racerunning = false
local racestarted = false
local racefinished = false
local playerishost = false
local playerisjoiner = false
local MYPED = localplayer:get_player_ped()
local HostInfo = {}
local JoinerInfo = {}
local raceDataFilename = "race_data.json"
local raceData = {}

-- Importing the Vehicle Groups
local CarGroups = require("scripts/vehicle_Groups")

-- Host and Joiner Flags
local HostAccepts = 1.02
local HostFinished = 1.50
local HostingOpen = 1.01
local HostReady = 1.03
local HostWaiting = 1.04
local HostYes = 1.05
local HostNo = 1.06
local RaceStart = 1.49

local JoinerBusy = 1.51
local JoinerFinished = 1.52
local JoinerJoined = 1.53
local JoinerReady = 1.54
local JoinerSearching = 1.55
local JoinerYes = 1.56
local JoinerNo = 1.57

-- Car Groups and Distance Flags (Range Information)
local GroupStart = 3.50
local GroupEnd = 3.59
local IndividualStart = 3.50
local IndividualEnd = 3.99

local EighthMile = 2.01
local QuarterMile = 2.02
local HalfMile = 2.03
local ThousandFoot = 2.04
local FullMile = 2.05

-- Host Functionality
function HostRace()
    playerisjoiner = false
    playerishost = true
    MYPED:set_swim_speed(HostingOpen)  -- Set the host flag to "Hosting Open"
    raceavailable = false
    MonitorForJoiner()  -- Search for player
end

function MonitorForJoiner()
    while true do
        local numberOfPlayers = player.get_number_of_players()
        for i = 1, numberOfPlayers do
            local playerPed = player.get_player_ped(i)
            local playerSwimSpeed = playerPed:get_swim_speed()

            if playerPed ~= nil and playerSwimSpeed == JoinerSearching then
                -- Store the joiner's ped and other information in the global JoinerInfo table
                JoinerInfo = {
                    ped = playerPed,
                    name = player.get_player_name(i),
                    vehicle = playerPed:get_current_vehicle()  -- Get the joiner's vehicle
                }

                local joinerId = playerPed:get_player_id()
                HostAccepts(joinerId, playerPed)  -- Accept joiner and proceed
                return  -- Exit the function after finding the joiner
            end
        end
        sleep(systemdelay)
    end
end


function HostAccept(joinerId, joinerPed)
    local carName, carGroup = getVehicleInfoFromPed(joinerPed)
    -- Additional logic using carName and carGroup

    MYPED:set_swim_speed(HostAccepts)
    WaitForJoinerReady(joinerId)
end

function WaitForJoinerReady(joinerId)
    local joinerPed = player.get_player_ped(joinerId)
    while true do
        if joinerPed:get_swim_speed() == JoinerReady then
            WaitForRaceStart()  -- Wait for the host to start the race
            break
        end
        sleep(systemdelay)
    end
end

function WaitForRaceStart()
    while not racestarted do
        sleep(systemdelay)  -- Loop until racestarted is set to true
    end
    StartRace()  -- Start the race
end

function StartRace()
    MYPED:set_swim_speed(RaceStart)  -- Set the flag to "Race Started"
    -- Synchronize the start between host and joiner
end

-- Joiner Functionality
function SearchForRace()
    playerishost = false
    playerisjoiner = true
    MYPED:set_swim_speed(JoinerSearching)  -- Indicate that the joiner is searching for a race
    FindRaceHost()
end

function FindRaceHost()
    while playerisjoiner do
        local numberOfPlayers = player.get_number_of_players()
        for i = 1, numberOfPlayers do
            local playerPed = player.get_player_ped(i)
            if playerPed and playerPed:get_swim_speed() == HostingOpen then
                -- Found the host, store their information
                HostInfo = {
                    ped = playerPed,
                    name = player.get_player_name(i),
                    vehicle = playerPed:get_current_vehicle()  -- Assuming you can get vehicle from the ped
                }

                JoinRace()  -- Join the race
                return  -- Exit the function after finding the host
            end
        end
        sleep(systemdelay)
    end
end



function JoinRace()
    MYPED:set_swim_speed(JoinerJoined)  -- Indicate that the joiner has joined the race
    PrepareForRace()
end

function PrepareForRace()
    MYPED:set_swim_speed(JoinerBusy)  -- Indicate that the joiner is preparing for the race
    -- Final preparations for joiner
    -- Synchronize with host's start
end

function Readyup()
    MYPED:set_swim_speed(JoinerReady)  -- Indicate that the joiner is ready
end

-- Main Race Loop
function RaceLoop()
    while racestarted do
        if racerunning == true then
            -- Main race loop
            elseif racefinished == true then -- break after race complete, proceed to data transfer
                if playerishost then
                -- set flag to "ready to recieve data"
                -- set flags for data transmission
                elseif playerisjoiner then
                -- set flag to "sending data next"
                -- set flags in sequence for data transmission
                break
            end
        end
    end
end

-- Vehicle Information Retrieval Functions
function getVehicleInfoFromPed(potentialHostPed)
    local vehicle = ped:get_current_vehicle()
    if vehicle then
        local modelHash = vehicle:get_model_hash()
        return findCarInGroups(modelHash)
    else
        return nil, nil
    end
end

function findCarInGroups(modelHash)
    for _, group in pairs(CarGroups) do
        for hash, name in pairs(group) do
            if hash == modelHash then
                return name, _  -- Return car name and group identifier
            end
        end
    end
    return nil, nil  -- Car not found in groups
end

-- Function to update race data with new race details
function updateRaceDetails(newRaceDetails)
    table.insert(raceData, newRaceDetails)
    saveRaceData()  -- Save the updated race data to file
end

-- Example usage of updateRaceDetails after a race
function onRaceEnd()
    local newRaceDetails = {
        raceDistance = "your_race_distance",
        raceLocation = "your_race_location",
        winner = "winner's name",
        timeDifference = "x seconds",
        localPlayer = {
            name = "local player's name",
            vehicleModel = getVehicleNameFromHash(localPlayerVehicleHash),
            finalSpeed = "local player's final speed",
            time60Foot = "local player's 60 foot time",
            reactionTime = "local player's reaction time"
        },
        opponent = {
            name = "opponent's name",
            vehicleModel = getVehicleNameFromHash(opponentVehicleHash),
            finalSpeed = "opponent's final speed",
            time60Foot = "opponent's 60 foot time",
            reactionTime = "opponent's reaction time"
        }
    }

    updateRaceDetails(newRaceDetails)
end

function offerRematch()                                         -- tbd
    -- Provide option for rematch
    -- Reset race conditions if both players agree
end

-- Save File Management

function loadRaceData()
    local success, content = pcall(json.loadfile, raceDataFilename)
    if success then
        raceData = content
    else
        raceData = {}  -- Initialize an empty table if file doesn't exist or can't be read
    end
end

function saveRaceData()
    json.savefile(raceDataFilename, raceData)
    print("Race data saved.")
end

function updateRaceDetails(newRaceDetails)
    table.insert(raceData, newRaceDetails)  -- Append new details to the race data table
    saveRaceData()  -- Save the updated race data to the file
end


--Initialization
loadRaceData()