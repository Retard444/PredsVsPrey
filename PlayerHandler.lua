-- PlayerHandler.lua
-- Manages player interactions, like eating other players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local TOUCH_COOLDOWN = 1 -- Seconds between touch checks
local EAT_RANGE = 5 -- Studs for touch detection
local RESPAWN_TIME = 3 -- Seconds before a player respawns after being eaten

-- Local variables
local touchCooldowns = {} -- Store cooldowns for player interactions

-- Handle player elimination
local function EliminatePlayer(prey, predator)
	-- Check if the prey is already eliminated
	if not prey.Character or prey.Character:FindFirstChild("Humanoid").Health <= 0 then
		return
	end

	-- Award points to the predator
	local points = 1
	if predator:FindFirstChild("leaderstats") and predator.leaderstats:FindFirstChild("Points") then
		predator.leaderstats.Points.Value = predator.leaderstats.Points.Value + points
	end

	-- Create elimination effect
	local eliminationEffect = Instance.new("Part")
	eliminationEffect.Shape = Enum.PartType.Ball
	eliminationEffect.Size = Vector3.new(3, 3, 3)
	eliminationEffect.Position = prey.Character.HumanoidRootPart.Position
	eliminationEffect.Anchored = true
	eliminationEffect.CanCollide = false
	eliminationEffect.BrickColor = prey.Team.TeamColor
	eliminationEffect.Material = Enum.Material.Neon
	eliminationEffect.Transparency = 0.3
	eliminationEffect.Parent = workspace

	-- Animate the effect
	spawn(function()
		for i = 1, 10 do
			eliminationEffect.Size = eliminationEffect.Size + Vector3.new(0.5, 0.5, 0.5)
			eliminationEffect.Transparency = eliminationEffect.Transparency + 0.07
			wait(0.05)
		end
		eliminationEffect:Destroy()
	end)

	-- "Eat" the player (they'll be respawned by Roblox automatically)
	prey.Character.Humanoid.Health = 0

	-- Notify all clients about the elimination
	if ReplicatedStorage:FindFirstChild("GameEvents") and 
		ReplicatedStorage.GameEvents:FindFirstChild("PlayerEliminated") then
		ReplicatedStorage.GameEvents.PlayerEliminated:FireAllClients(prey.Name, predator.Name, predator.Team.Name)
	end
end

-- Check if a player can eat another player
local function CanEatPlayer(predator, prey)
	-- Check teams
	if prey.Team.Name == "Spectator" then
		-- Can't eat spectators
		return false
	elseif predator.Team.Name == "Apex" then
		-- Apex can eat both Predator and Prey
		return prey.Team.Name == "Predator" or prey.Team.Name == "Prey"
	elseif predator.Team.Name == "Predator" then
		-- Predator can only eat Prey
		return prey.Team.Name == "Prey"
	end

	-- Prey can't eat anyone
	return false
end

-- Set up touch detection for a player
local function SetupTouchDetection(player)
	-- Skip for spectators
	if player.Team.Name == "Spectator" then
		return
	end

	-- Wait for character to load
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Create hitbox for eating other players
	local hitbox = Instance.new("Part")
	hitbox.Name = "EatHitbox"
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Anchored = false
	hitbox.Size = Vector3.new(EAT_RANGE, EAT_RANGE, EAT_RANGE)

	-- Create weld to attach hitbox to the player
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox

	hitbox.Parent = character
	hitbox.Position = rootPart.Position

	-- Set up touch detection
	hitbox.Touched:Connect(function(part)
		-- Check cooldown
		local now = tick()
		if touchCooldowns[player.UserId] and now - touchCooldowns[player.UserId] < TOUCH_COOLDOWN then
			return
		end
		touchCooldowns[player.UserId] = now

		-- Find the character this part belongs to
		local touchedCharacter = part:FindFirstAncestorOfClass("Model")
		if not touchedCharacter or not Players:GetPlayerFromCharacter(touchedCharacter) then
			return
		end

		local touchedPlayer = Players:GetPlayerFromCharacter(touchedCharacter)

		-- Check if we can eat this player
		if CanEatPlayer(player, touchedPlayer) then
			EliminatePlayer(touchedPlayer, player)
		end
	end)

	-- Clean up when the character dies
	humanoid.Died:Connect(function()
		if hitbox then
			hitbox:Destroy()
		end
	end)
end

-- Initialize for a player
local function InitializePlayer(player)
	-- Create leaderstats if they don't exist
	if not player:FindFirstChild("leaderstats") then
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player

		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Value = 0
		points.Parent = stats
	end

	-- Skip touch detection for spectators
	if player.Team.Name ~= "Spectator" then
		-- Set up character handling
		SetupTouchDetection(player)
	end

	-- Handle character respawning and team changes
	player.CharacterAdded:Connect(function(character)
		if player.Team.Name ~= "Spectator" then
			SetupTouchDetection(player)
		end
	end)

	-- Handle team changes
	player:GetPropertyChangedSignal("Team"):Connect(function()
		-- If the player has a character and isn't a spectator, set up touch detection
		if player.Character and player.Team.Name ~= "Spectator" then
			SetupTouchDetection(player)
		end
	end)
end

-- Initialize for all existing players
for _, player in pairs(Players:GetPlayers()) do
	InitializePlayer(player)
end

-- Initialize for new players
Players.PlayerAdded:Connect(InitializePlayer)

-- Clean up for leaving players
Players.PlayerRemoving:Connect(function(player)
	touchCooldowns[player.UserId] = nil
end) 
