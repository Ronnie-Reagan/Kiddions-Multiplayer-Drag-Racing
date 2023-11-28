-- Import vehicle groups
local vehicleGroups = require("scripts/vehicle_Groups")

-- Flag Table
local flagTable = {
    ["Hosting Open"] = 1.01,
    ["Joiner Searching"] = 1.02,
    ["Host Accepts"] = 1.03,
    ["Joiner Joined"] = 1.04,
    ["Host Ready"] = 1.05,
    ["Joiner Ready"] = 1.06,
    ["Race Started"] = 1.07,
    ["Host Finished"] = 1.08,
    ["Joiner Finished"] = 1.09,
    ["Post Race Data Exchange"] = 1.10,
    -- Additional flags as needed
}

-- Semaphore Communication Functions
-- Set a flag
function setFlag(flagName)
    local swimSpeed = flagTable[flagName]
    myped:set_swim_speed(swimSpeed)
end

-- Interpret a flag
function interpretFlag(swimSpeed)
    for name, speed in pairs(flagTable) do
        if speed == swimSpeed then
            return name
        end
    end
    return nil
end

-- Assign swim speeds to each group and car
function assignCarSpeeds()
    local baseGroupSpeed = 3.00
    local groupSpeedIncrement = 0.10
    local carSpeedStart = 3.50
    local carSpeedIncrement = 0.01

    for groupIndex, group in ipairs(vehicleGroups) do
        local groupSpeed = baseGroupSpeed + (groupIndex - 1) * groupSpeedIncrement

        for carIndex, carHash in ipairs(group) do
            local carSpeed = carSpeedStart + (carIndex - 1) * carSpeedIncrement
            local carKey = groupIndex .. "_" .. carIndex

            flagTable[carKey] = {groupSpeed = groupSpeed, carSpeed = carSpeed}
        end
    end
end

assignCarSpeeds()

-- Global Variables for Race Control
local selectedDistance = "1/8 Mile"
local raceDistances = {
    ["1/8 Mile"] = 1609.34 / 8,
    ["1/4 Mile"] = 1609.34 / 4,
    ["1/2 Mile"] = 1609.34 / 2,
    ["Full Mile"] = 1609.34
}
local raceDistance = raceDistances[selectedDistance]
local raceFinished = false
local racerunning = false
local startPosition
local currentOpponentIndex = nil

-- Function to start hosting a race
function hostRace()
    setFlag("Hosting Open")
    print("Hosting a race. Waiting for a joiner...")

    local joinerFound = false
    while not joinerFound do
        for i = 0, 31 do
            if i ~= localplayer.player_id() then
                local joinerFlag = interpretFlag(i)
                if joinerFlag == flagTable["Joiner Searching"] then
                    currentOpponentIndex = i
                    joinerFound = true
                    print("Joiner found: Player ID " .. i)
                    setFlag("Host Accepts")
                    break
                end
            end
        end
        sleep(1)  -- Check every second
    end

    synchronizeRaceStart()
end

-- Function to join a race
function joinRace()
    setFlag("Joiner Searching")
    print("Searching for a race to join...")

    local hostFound = false
    while not hostFound do
        for i = 0, 31 do
            if i ~= localplayer.player_id() then
                local hostFlag = interpretFlag(i)
                if hostFlag == flagTable["Host Accepts"] then
                    currentOpponentIndex = i
                    hostFound = true
                    print("Joined a race hosted by Player ID " .. i)
                    setFlag("Joiner Ready")
                    break
                end
            end
        end
        sleep(1)  -- Check every second
    end

    waitForRaceStart()
end

-- Function to synchronize the race start
function synchronizeRaceStart()
    print("Synchronizing race start...")
    setFlag("Host Ready")

    local raceStartConfirmed = false
    while not raceStartConfirmed do
        local joinerFlag = interpretFlag(currentOpponentIndex)
        if joinerFlag == flagTable["Joiner Ready"] then
            raceStartConfirmed = true
            setFlag("Race Started")
            print("Race is starting!")
        end
        sleep(0.5)  -- Check every half second
    end

    startDragRace()
end

-- Function to wait for the race to start (for Joiner)
function waitForRaceStart()
    print("Waiting for the race to start...")
    local raceStarted = false
    while not raceStarted do
        local hostFlag = interpretFlag(currentOpponentIndex)
        if hostFlag == flagTable["Race Started"] then
            raceStarted = true
            print("Race is starting!")
        end
        sleep(0.5)  -- Check every half second
    end

    startDragRace()
end

-- Function to start the actual drag race
function startDragRace()
    local vehicle = localplayer:get_current_vehicle()
    if not vehicle then
        print("No vehicle detected. Race cannot start.")
        return
    end

    raceFinished = false
    racerunning = true
    startPosition = vehicle:get_position()
    Timer:start()

    print("Race has started! Good luck!")

    while racerunning and not raceFinished do
        local currentPosition = vehicle:get_position()
        local distanceTravelled = calculateDistance(startPosition, currentPosition)
        
        if distanceTravelled >= raceDistance then
            raceFinished = true
            racerunning = false
            local finalTime = Timer:elapsedTime()
            print("Race finished! Time: " .. formatTime(finalTime))
            setFlag("Host Finished")  -- Or "Joiner Finished" depending on role
            exchangeRaceResults(finalTime)
        else
            sleep(0.025)  -- Small delay for loop iteration
        end
    end
end

-- Function for Post-Race Data Exchange
function exchangeRaceResults(finalTime)
    -- Logic to send your race time
    setFlag("Post Race Data Exchange")
    -- Further logic to encode and send the time is needed here

    -- Logic to receive opponent's race time
    local opponentTimeReceived = false
    local opponentFinalTime

    while not opponentTimeReceived do
        local opponentFlag = interpretFlag(currentOpponentIndex)
        if opponentFlag == flagTable["Post Race Data Exchange"] then
            opponentFinalTime = decodeOpponentTime(currentOpponentIndex)
            opponentTimeReceived = true
        end
        sleep(0.5)
    end

    compareRaceTimes(finalTime, opponentFinalTime)
end

-- Function to compare your and your opponent's race times
function compareRaceTimes(yourTime, opponentTime)
    if yourTime < opponentTime then
        print("Congratulations, you won the race!")
    else
        print("You finished second. Better luck next time!")
    end
end

-- Placeholder function for decoding opponent's time
function decodeOpponentTime(opponentIndex)
    -- Implement the logic based on how the time is encoded in swim speeds
    return 0  -- Placeholder return value
end

-- Timer utility
local Timer = {
    startTime = 0,
    start = function(self)
        self.startTime = getTimeInCar()
    end,
    elapsedTime = function(self)
        return getTimeInCar() - self.startTime
    end
}
function getTimeInCar()
    return stats.get_int("MP" .. stats.get_int("MPPLY_LAST_MP_CHAR") .. "_TIME_IN_CAR")
end

function formatTime(milliseconds)
    local seconds = math.floor(milliseconds / 1000)
    local remainingMilliseconds = milliseconds % 1000
    return string.format("%d.%03d", seconds, remainingMilliseconds)
end

-- Function to calculate distance
function calculateDistance(pos1, pos2)
    if pos1 and pos2 then
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        local dz = pos1.z - pos2.z
        return math.sqrt(dx^2 + dy^2 + dz^2)
    end
    return nil
end

-- Function to handle race abortion or cancellation
function abortRace()
    if racerunning then
        racerunning = false
        raceFinished = true
        setFlag("Race Aborted")
        print("Race has been aborted.")
    end
end

-- Adding race control options to the menu
DragMenu = menu.add_submenu("DragMenu")
DragMenu:add_action("Host Race", hostRace)
DragMenu:add_action("Join Race", joinRace)
DragMenu:add_action("Start Race", startDragRace)
DragMenu:add_action("Abort Race", abortRace)
-- Add any other necessary menu actions for complete race control
