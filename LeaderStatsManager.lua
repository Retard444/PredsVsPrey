local Players = game:GetService("Players")

local function onPlayerAdded(player)
    -- Create a folder for leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    -- Create the currency stat (e.g., "Cash")
    local cash = Instance.new("IntValue")
    cash.Name = "Cash" -- Make sure this matches the name in CurrencyPurchaseHandler and CurrencyUIScript
    cash.Value = 0 -- Starting cash amount
    cash.Parent = leaderstats

    print("Leaderstats created for player:", player.Name)
end

-- Connect the function to the PlayerAdded event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players who might already be in the game when the script runs (e.g., during hot-swapping)
for _, player in Players:GetPlayers() do
    if not player:FindFirstChild("leaderstats") then
        task.spawn(onPlayerAdded, player)
    end
end

