--Multiplayer Race Plans - Reformatted for discord viewing
--------------------------------------------------------------------------------------------------------------------------
--[[Note:
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

--                                              Data Stucture:

local Flags = {
    Utility = {                                                                     -- Range: 1.01 - 2.00
        Default = 1.00,
        RaceStart = 1.01
    },
    Distance = {                                                                    -- Range: 2.01 - 2.10
        EighthMile = 2.01,
        QuarterMile = 2.02,
        HalfMile = 2.03,
        ThousandFoot = 2.04,
        FullMile = 2.05
    },
    Locations = {                                                                   -- Range: 2.11 - 2.20
        FortZancudoAirstrip = 2.11,
        LosSantosInternationalAirport = 2.12,
        SandyShoresAirfield = 2.13,
        NorthSenoraFreeway = 2.14,
        PaletoBayFreeway = 2.15,
        LaPuertaBridge = 2.16,
        CurrentPlayerLocation = 2.17
    },
    CarGroups = {                                                                   -- Range: 3.50 - 3.99 
        GroupStart = 3.50,
        GroupEnd = 3.59,
        IndividualStart = 3.50,
        IndividualEnd = 3.99
    },
    HosterFlags = {                                                                 -- Range: 1.01 - 1.50 
        HostAccepts = 1.02,
        HostFinished = 1.50,
        HostingOpen = 1.01,
        HostReady = 1.03,
        HostWaiting = 1.04,
        HostYes = 1.05
		HostNo = 1.06
        -- Add other flags as needed
    },
    JoinerFlags = {                                                                 -- Range: 1.51 - 2.00 
        JoinerBusy = 1.51,
        JoinerFinished = 1.52,
        JoinerJoined = 1.53,
        JoinerReady = 1.54,
        JoinerSearching = 1.55
		JoinerYes = 1.56
		JoinerNo = 1.57
        -- Add other flags as needed
    }
}

--[[                                              Order of Actions/Functions
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
    - Monitor for Joiner Joined flag                                                - Wait for RaceAvailable to be true
5. Wait for Joiner to be Ready                                                  3. Prepare for Race
    - Monitor for "Joiner Ready" flag                                               - Set joiner flag to Joiner Ready
    - Once Joiner Ready detected,                                                   - Wait for race start signal
    - Set RaceAvailable to true	
6. Start Race	                                                                4. Start Race (Upon Host's Signal)
    - Set host flag to Race Started                                                 - Begin race loop upon host's start
    - Begin race loop	
7. Race Loop                                                                    5. Race Loop
    - Monitor race progress                                                         - Monitor race progress
    - Handle in-race events                                                         - Handle in-race events
8. Post-Race                                                                    6. Post-Race
    - Handle race results                                                           - Receive race results
    - Offer rematch option                                                          - Decide on rematch option
    - Set RaceAvailable to false if no rematch	
]]

--                                          Pseudocode: 

--tbd = to be determined


--                                          Initialization

mainmenu = menu.add_submenu("MULTIPLAYER RACE")
--Initialize default settings
local systemdelay = 0.25
local raceavailable = false
local racerunning = false
local racestarted = false
local racefinished = false
local playerishost = false
local playerisjoiner = false
local MYPED = localplayer:get_player_ped()


--                                          Host Functionality

function HostRace()                                             -- To be attached to "Host Race" submenu's "on open action"
    playerisjoiner = false
	playerishost = true
    MYPED:set_swim_speed(HostingOpen)                           -- Set the host flag to "Hosting Open"
    raceavailable = false	                                    -- Disable race starting for host
	Monitorforjoiner()											-- Search for player
end

function MonitorForJoiner()
    while true do
        local numberOfPlayers = player.get_number_of_players()
        for i = 1, numberOfPlayers do
            local playerPed = player.get_player_ped(i)
            local playerSwimSpeed = playerPed:get_swim_speed()

            if playerPed ~= nil and playerSwimSpeed == JoinerSearching then
                local joinerId = playerPed:get_player_id()
                HostAccepts(joinerId)  							-- Accept joiner and proceed
                break
            end
        end
        sleep(systemdelay)
    end
end

function HostAccepts(joinerId)
    MYPED:set_swim_speed(HostAccepts) 							-- Set swim speed to indicate host acceptance
    WaitForJoinerReady(joinerId) 								-- Pass the joiner's ID to the WaitForJoinerReady function
end

function WaitForJoinerReady(joinerId)
    local joinerPed = player.get_player_ped(joinerId)
    while true do
        if joinerPed:get_swim_speed() == JoinerReady then
            WaitForRaceStart()  								-- Wait for the host to start the race
            break
        end
        sleep(systemdelay)
    end
end

function WaitForRaceStart()
    while not racestarted do
        sleep(systemdelay)  									-- Loop until racestarted is set to true
    end
    StartRace()  												-- Start the race
end

function UpdateRaceStatus()                                     -- to be used for when a player leaves
    -- Update race status flags based on host/joiner interactions
end

function StartRace()                                            -- Variable Checks before start Race
    MYPED:set_swim_speed(RaceStarted)                           -- Set the flag to "Race Started"
    -- Synchronize the start between host and joiner
end

--                                              Joiner Functionality

function SearchForRace()
	playerishost = false
	playerisjoiner = true
	MYPED:set_swim_speed(JoinerSearching)
    FindRaceHost()
end

function FindRaceHost()
    while playerisjoiner do  -- Ensure this runs only if the player is a joiner
        local numberOfPlayers = player.get_number_of_players()
        for i = 1, numberOfPlayers do
            local potentialHostPed = player.get_player_ped(i)
            if potentialHostPed and potentialHostPed:get_swim_speed() == HostingOpen then
                local hostId = potentialHostPed:get_player_id()
                -- Pass the host's ID to the joiner's functions
                JoinRace(hostId)
                break
            end
        end
        sleep(systemdelay)
    end
end

function JoinRace(hostId)
    -- Logic for joining an available race hosted by the player with hostId
    MYPED:set_swim_speed(JoinerJoined)
    PrepareForRace()
end

function Readyup()
	MYPED:set_swim_speed(JoinerReady)
end

function PrepareForRace()
	MYPED:set_swim_speed(JoinerBusy)
    -- Final preparations for joiner
    -- Synchronize with host's start
end

-- Race Loop and Event Handling

function RaceLoop()
    -- Main race loop
    -- Handle race events and checkpoints
end

function monitorRaceProgress()                                  -- tbd
    -- Monitor the race's progress
    -- Update flags and handle in-race events
end


-- Post-Race Handling and Rematch Options

function postRaceHandling()                                     -- Transmit post-race details consequtively (with delays)
    -- Handle post-race data exchange and recording
end

function offerRematch()                                         -- tbd
    -- Provide option for rematch
    -- Reset race conditions if both players agree
end