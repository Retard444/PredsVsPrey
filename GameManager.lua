-- GameManager.lua
-- Controls the main game flow, teams, and round timing

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Constants
local ROUND_DURATION = 300 -- 5 minutes per round
local INTERMISSION_DURATION = 15 -- 15 seconds between rounds

-- Game state
local gameState = {
	isRoundActive = false,
	roundTimer = 0,
	intermissionTimer = 0,
	nextRoundSpawnPoints = {}
}

-- Try to load SimpleMap module
local mapGenerator = nil
spawn(function()
	-- Wait a moment to ensure scripts are loaded
	wait(1)

	-- Try to find SimpleMap script
	local mapGeneratorScript = script.Parent:FindFirstChild("SimpleMap")

	if not mapGeneratorScript then
		-- Look in all script descendants
		for _, obj in pairs(ServerScriptService:GetDescendants()) do
			if obj.Name == "SimpleMap" and (obj:IsA("ModuleScript") or obj:IsA("Script")) then
				mapGeneratorScript = obj
				break
			end
		end
	end

	if mapGeneratorScript then
		local success, result = pcall(function()
			return require(mapGeneratorScript)
		end)

		if success then
			mapGenerator = result
			print("SimpleMap module loaded successfully")

			-- Cleanup any existing map
			mapGenerator.CleanupMap()

			-- Generate initial map
			local success, result = pcall(function()
				return {mapGenerator.CreateMap()}
			end)

			if success then
				local mapParent = result[1]
				local spawnPoints = result[2]

				if spawnPoints then
					gameState.nextRoundSpawnPoints = {
						apex = spawnPoints.apex,
						predator = spawnPoints.predator,
						prey = spawnPoints.prey
					}
					print("Initial map generated with spawn points")
				end
			else
				warn("Error during initial map generation: " .. tostring(result))
			end
		else
			warn("Failed to load SimpleMap module: " .. tostring(result))
		end
	else
		warn("SimpleMap module not found, maps will not be generated")
	end
end)

-- Create teams if they don't exist
local function SetupTeams()
	print("Setting up teams...")

	-- Create Apex team
	local apexTeam = Teams:FindFirstChild("Apex") or Instance.new("Team")
	apexTeam.Name = "Apex"
	apexTeam.TeamColor = BrickColor.new("Really red")
	apexTeam.AutoAssignable = false
	apexTeam.Parent = Teams

	-- Create Predator team
	local predatorTeam = Teams:FindFirstChild("Predator") or Instance.new("Team")
	predatorTeam.Name = "Predator"
	predatorTeam.TeamColor = BrickColor.new("Really blue")
	predatorTeam.AutoAssignable = false
	predatorTeam.Parent = Teams

	-- Create Prey team
	local preyTeam = Teams:FindFirstChild("Prey") or Instance.new("Team")
	preyTeam.Name = "Prey"
	preyTeam.TeamColor = BrickColor.new("Bright green")
	preyTeam.AutoAssignable = false
	preyTeam.Parent = Teams

	-- Create Spectator team
	local spectatorTeam = Teams:FindFirstChild("Spectator") or Instance.new("Team")
	spectatorTeam.Name = "Spectator"
	spectatorTeam.TeamColor = BrickColor.new("Institutional white")
	spectatorTeam.AutoAssignable = true
	spectatorTeam.Parent = Teams

	print("Teams created: " .. #Teams:GetChildren())
	return true
end

-- Assign players to teams
local function AssignTeams()
	print("Assigning players to teams...")
	local players = Players:GetPlayers()
	local playerCount = #players

	if playerCount < 2 then
		-- Not enough players to start
		print("Not enough players to start a round")
		return false
	end

	-- Make sure teams exist
	if #Teams:GetChildren() < 4 then
		print("Teams not found, setting up teams again")
		SetupTeams()
	end

	-- Verify teams were created
	if not Teams:FindFirstChild("Apex") or 
		not Teams:FindFirstChild("Predator") or 
		not Teams:FindFirstChild("Prey") or 
		not Teams:FindFirstChild("Spectator") then
		warn("Failed to create all required teams")
		return false
	end

	-- Shuffle players
	for i = #players, 2, -1 do
		local j = math.random(i)
		players[i], players[j] = players[j], players[i]
	end

	-- Assign Apex (10% of players, at least 1)
	local apexCount = math.max(1, math.floor(playerCount * 0.1))
	local predatorCount = math.max(1, math.floor(playerCount * 0.3))
	local preyCount = playerCount - apexCount - predatorCount

	local currentIndex = 1

	-- Assign Apex players
	for i = 1, apexCount do
		if currentIndex <= playerCount then
			players[currentIndex].Team = Teams.Apex
			print("Assigned player " .. players[currentIndex].Name .. " to Apex team")
			currentIndex = currentIndex + 1
		end
	end

	-- Assign Predator players
	for i = 1, predatorCount do
		if currentIndex <= playerCount then
			players[currentIndex].Team = Teams.Predator
			print("Assigned player " .. players[currentIndex].Name .. " to Predator team")
			currentIndex = currentIndex + 1
		end
	end

	-- Assign remaining players to Prey
	for i = currentIndex, playerCount do
		players[i].Team = Teams.Prey
		print("Assigned player " .. players[i].Name .. " to Prey team")
	end

	return true
end

-- Set up necessary tools
local function SetupTools()
	-- Try to load ToolManager module
	local toolManager = script.Parent:FindFirstChild("ToolManager")
	if toolManager then
		print("Loading ToolManager...")
		local ToolManager = require(toolManager)
		ToolManager.Initialize()
		print("Tools created successfully")
		return true
	else
		warn("ToolManager not found, tools will not be available")
		return false
	end
end

-- Apply team abilities and properties
local function SetupPlayerForTeam(player)
	local character = player.Character or player.CharacterAdded:Wait()

	-- Reset any previous settings
	for _, item in pairs(character:GetChildren()) do
		if item:IsA("Tool") then
			item:Destroy()
		end
	end

	local teamToolsFolder = ServerStorage:FindFirstChild("TeamTools")
	if not teamToolsFolder then
		-- Try to set up tools if they don't exist
		SetupTools()
		teamToolsFolder = ServerStorage:FindFirstChild("TeamTools")
	end

	-- Set speed and abilities based on team
	if player.Team.Name == "Apex" then
		-- Apex is powerful but slower
		character.Humanoid.WalkSpeed = 20
		-- Give apex abilities/tools
		if teamToolsFolder and teamToolsFolder:FindFirstChild("ApexTool") then
			local apexTool = teamToolsFolder:FindFirstChild("ApexTool"):Clone()
			apexTool.Parent = character
			print("Gave ApexTool to " .. player.Name)
		else
			warn("ApexTool not found for player " .. player.Name)
		end

	elseif player.Team.Name == "Predator" then
		-- Predator is balanced
		character.Humanoid.WalkSpeed = 24
		-- Give predator abilities/tools
		if teamToolsFolder and teamToolsFolder:FindFirstChild("PredatorTool") then
			local predatorTool = teamToolsFolder:FindFirstChild("PredatorTool"):Clone()
			predatorTool.Parent = character
			print("Gave PredatorTool to " .. player.Name)
		else
			warn("PredatorTool not found for player " .. player.Name)
		end

	elseif player.Team.Name == "Prey" then
		-- Prey is fastest but weakest
		character.Humanoid.WalkSpeed = 28
		-- Give prey abilities/tools
		if teamToolsFolder and teamToolsFolder:FindFirstChild("PreyTool") then
			local preyTool = teamToolsFolder:FindFirstChild("PreyTool"):Clone()
			preyTool.Parent = character
			print("Gave PreyTool to " .. player.Name)
		else
			warn("PreyTool not found for player " .. player.Name)
		end

	elseif player.Team.Name == "Spectator" then
		-- Spectator settings
		character.Humanoid.WalkSpeed = 16

		-- Make spectators slightly transparent
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
				part.CanCollide = false
			end
		end

		-- Allow spectators to fly
		character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
	end

	-- Set team-colored parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "TeamIndicator" then
			part.BrickColor = player.Team.TeamColor
		end
	end

	-- Set up death handling for player
	if player.Team.Name ~= "Spectator" then
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- When player dies, move to spectator team
			player.Team = Teams.Spectator

			-- Let them know they're now a spectator
			ReplicatedStorage.GameEvents.PlayerBecameSpectator:FireClient(player)

			-- Apply spectator settings when they respawn
			player.CharacterAdded:Wait()
			SetupPlayerForTeam(player)
		end)
	end
end

-- Start a new round
local function StartRound()
	if not AssignTeams() then
		-- Not enough players
		return false
	end

	gameState.isRoundActive = true
	gameState.roundTimer = ROUND_DURATION

	-- Update round status value
	if ReplicatedStorage:FindFirstChild("GameEvents") and 
		ReplicatedStorage.GameEvents:FindFirstChild("RoundStatus") then
		ReplicatedStorage.GameEvents.RoundStatus.Value = true
	end

	-- Setup all players
	for _, player in pairs(Players:GetPlayers()) do
		SetupPlayerForTeam(player)

		-- Teleport to team spawn points if available
		if gameState.nextRoundSpawnPoints and player.Character then
			spawn(function()
				local spawnCategory = string.lower(player.Team.Name)
				-- For spectators, use any spawn point
				if spawnCategory == "spectator" then
					spawnCategory = "prey" -- Use prey spawn points for spectators
				end

				if gameState.nextRoundSpawnPoints[spawnCategory] and #gameState.nextRoundSpawnPoints[spawnCategory] > 0 then
					-- Pick a random spawn point for this team
					local spawnIndex = math.random(1, #gameState.nextRoundSpawnPoints[spawnCategory])
					local spawnPoint = gameState.nextRoundSpawnPoints[spawnCategory][spawnIndex]

					-- Teleport player
					player.Character:SetPrimaryPartCFrame(CFrame.new(spawnPoint.Position + Vector3.new(0, 5, 0)))
					print("Teleported " .. player.Name .. " to " .. spawnCategory .. " spawn point")
				else
					warn("No spawn points found for team: " .. spawnCategory)
				end
			end)
		else
			warn("No spawn points available for teleportation")
		end
	end

	-- Broadcast round start
	ReplicatedStorage.GameEvents.RoundStarted:FireAllClients(gameState.roundTimer)

	return true
end

-- End the current round
local function EndRound()
	gameState.isRoundActive = false
	gameState.intermissionTimer = INTERMISSION_DURATION

	-- Update round status value
	if ReplicatedStorage:FindFirstChild("GameEvents") and 
		ReplicatedStorage.GameEvents:FindFirstChild("RoundStatus") then
		ReplicatedStorage.GameEvents.RoundStatus.Value = false
	end

	-- Count surviving prey
	local survivingPrey = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team.Name == "Prey" and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			survivingPrey = survivingPrey + 1
		end
	end

	-- Broadcast round end with results
	ReplicatedStorage.GameEvents.RoundEnded:FireAllClients(survivingPrey)

	-- Move all players to Spectator team until next round starts
	for _, player in pairs(Players:GetPlayers()) do
		player.Team = Teams.Spectator
	end

	-- Generate a new map for the next round
	spawn(function()
		if mapGenerator then
			print("Generating new map using SimpleMap...")

			-- Clean up existing map
			mapGenerator.CleanupMap()

			-- Generate new map
			local success, result = pcall(function()
				return {mapGenerator.CreateMap()}
			end)

			if success then
				local mapParent = result[1]
				local spawnPoints = result[2]

				if spawnPoints then
					gameState.nextRoundSpawnPoints = {
						apex = spawnPoints.apex,
						predator = spawnPoints.predator,
						prey = spawnPoints.prey
					}
					print("New map generated with " .. 
						#gameState.nextRoundSpawnPoints.apex .. " apex, " ..
						#gameState.nextRoundSpawnPoints.predator .. " predator, " ..
						#gameState.nextRoundSpawnPoints.prey .. " prey spawn points")
				else
					warn("No spawn points returned from map generation")
				end
			else
				warn("Error during map generation: " .. tostring(result))
			end
		else
			warn("Cannot generate new map: SimpleMap not loaded")
		end
	end)
end

-- Game loop
local function GameLoop()
	print("Starting game loop")

	-- Wait a short time for map generation
	wait(5)

	-- Make sure we have a valid map
	if not workspace:FindFirstChild("SimpleMap") and mapGenerator then
		-- Try to generate a map if one doesn't exist
		print("No map found. Generating initial map...")
		local success, result = pcall(function()
			return {mapGenerator.CreateMap()}
		end)

		if success then
			local mapParent = result[1]
			local spawnPoints = result[2]

			if spawnPoints then
				gameState.nextRoundSpawnPoints = {
					apex = spawnPoints.apex,
					predator = spawnPoints.predator,
					prey = spawnPoints.prey
				}
				print("Generated initial map with spawn points")
			else
				warn("No spawn points returned from initial map generation")
			end
		else
			warn("Error during initial map generation: " .. tostring(result))
		end
	end

	while true do
		if gameState.isRoundActive then
			-- Round in progress
			gameState.roundTimer = gameState.roundTimer - 1

			-- Check if round should end
			if gameState.roundTimer <= 0 then
				print("Round timer expired, ending round")
				EndRound()
			end

			-- Check if all prey are gone
			local preyRemaining = false
			for _, player in pairs(Players:GetPlayers()) do
				if player.Team.Name == "Prey" and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
					preyRemaining = true
					break
				end
			end

			if not preyRemaining then
				print("No prey remaining, ending round")
				EndRound()
			end
		else
			-- Intermission
			gameState.intermissionTimer = gameState.intermissionTimer - 1

			if gameState.intermissionTimer <= 0 then
				print("Intermission over, starting new round")
				StartRound()
			end
		end

		wait(1) -- Wait 1 second between loop iterations
	end
end

-- Initialize the game
local function Initialize()
	-- Create events folder in ReplicatedStorage if it doesn't exist
	if not ReplicatedStorage:FindFirstChild("GameEvents") then
		local eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "GameEvents"
		eventsFolder.Parent = ReplicatedStorage

		-- Create necessary remote events
		local events = {
			"RoundStarted",
			"RoundEnded",
			"PlayerEliminated",
			"PlayerBecameSpectator"
		}

		for _, eventName in ipairs(events) do
			local event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = eventsFolder
		end

		-- Create a RoundStatus value object for debugging
		local roundStatus = Instance.new("BoolValue")
		roundStatus.Name = "RoundStatus"
		roundStatus.Value = false -- initially not active
		roundStatus.Parent = eventsFolder
	end

	-- Set up teams first
	local teamsCreated = SetupTeams()
	print("Teams setup completed: " .. tostring(teamsCreated))

	-- Set up tools
	SetupTools()

	-- Handle new players joining
	Players.PlayerAdded:Connect(function(player)
		print("Player joined: " .. player.Name)
		if gameState.isRoundActive then
			-- Assign them to spectator if joining mid-round
			player.Team = Teams.Spectator
			print("Assigned joining player to Spectator team (mid-round)")

			-- Let them know they're a spectator until next round
			player.CharacterAdded:Connect(function(character)
				if player.Team.Name == "Spectator" then
					SetupPlayerForTeam(player)
					ReplicatedStorage.GameEvents.PlayerBecameSpectator:FireClient(player)
				end
			end)
		else
			-- During intermission, players join as spectator but will be assigned when round starts
			player.Team = Teams.Spectator
			print("Assigned joining player to Spectator team (intermission)")
		end
	end)

	-- Start the game loop
	spawn(GameLoop)

	-- Start the first intermission
	gameState.intermissionTimer = INTERMISSION_DURATION
	print("Game initialized, starting first intermission")

	-- Add a debug indicator to show the game is running with SimpleMap
	local part = Instance.new("Part")
	part.Name = "SimpleMapIndicator"
	part.Size = Vector3.new(4, 4, 4)
	part.Position = Vector3.new(0, 40, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Bright yellow")
	part.Transparency = 0.5

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.Adornee = part
	billboardGui.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextSize = 16
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Text = "Game Running w/ SimpleMap"
	textLabel.Parent = billboardGui

	part.Parent = workspace
end

-- Run the game
Initialize() 
