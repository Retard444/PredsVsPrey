-- ToolManager.lua
-- Creates and manages tools for different teams

local ServerStorage = game:GetService("ServerStorage")

-- Create tool storage folder if it doesn't exist
local function SetupToolStorage()
	if not ServerStorage:FindFirstChild("TeamTools") then
		local toolsFolder = Instance.new("Folder")
		toolsFolder.Name = "TeamTools"
		toolsFolder.Parent = ServerStorage

		print("Created TeamTools folder in ServerStorage")
	end

	return ServerStorage.TeamTools
end

-- Create a basic tool for a team
local function CreateBasicTool(name, teamName, teamColor)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = false

	-- Create handle
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 2)
	handle.Position = Vector3.new(0, 0, 0)
	handle.CanCollide = false
	handle.BrickColor = BrickColor.new(teamColor)
	handle.Material = Enum.Material.Neon
	handle.Parent = tool

	-- Add team data
	local teamValue = Instance.new("StringValue")
	teamValue.Name = "TeamName"
	teamValue.Value = teamName
	teamValue.Parent = tool

	return tool
end

-- Create all team tools
local function CreateTeamTools()
	local toolsFolder = SetupToolStorage()

	-- Make sure folder is empty
	for _, item in pairs(toolsFolder:GetChildren()) do
		item:Destroy()
	end

	-- Create Apex tool
	local apexTool = CreateBasicTool("ApexTool", "Apex", "Really red")
	apexTool.ToolTip = "Dash Attack (Click)"
	apexTool.Parent = toolsFolder

	-- Create Predator tool
	local predatorTool = CreateBasicTool("PredatorTool", "Predator", "Really blue")
	predatorTool.ToolTip = "Speed Boost (Click)"
	predatorTool.Parent = toolsFolder

	-- Create Prey tool
	local preyTool = CreateBasicTool("PreyTool", "Prey", "Bright green")
	preyTool.ToolTip = "Invisibility (Click)" 
	preyTool.Parent = toolsFolder

	print("Created all team tools")
	return toolsFolder
end

-- Initialize the tool manager
local function Initialize()
	CreateTeamTools()
end

-- Run initialization
Initialize()

-- Return module interface
local ToolManager = {}
ToolManager.Initialize = Initialize
ToolManager.CreateTeamTools = CreateTeamTools
return ToolManager 
