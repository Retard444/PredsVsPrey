local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- IMPORTANT: Replace these placeholder IDs and amounts with your actual Developer Product IDs
-- and the amount of in-game currency they should grant.
-- You create Developer Products on the Roblox website (Creator Dashboard -> Your Game -> Monetization -> Developer Products).
local currencyProducts = {
    [0] = 0, -- Replace 0 with your actual Product ID for 100 Cash
    -- [YOUR_PRODUCT_ID_FOR_100_CASH] = 100,
    -- [YOUR_PRODUCT_ID_FOR_500_CASH] = 500,
    -- Example:
    -- [123456789] = 100,  -- Product ID 123456789 grants 100 Cash
    -- [987654321] = 500,  -- Product ID 987654321 grants 500 Cash
}

-- This function will be called by Roblox when a player completes a purchase of a Developer Product.
local function processReceipt(receiptInfo)
    local userId = receiptInfo.PlayerId
    local productId = receiptInfo.ProductId

    local player = Players:GetPlayerByUserId(userId)

    -- Check if the player is in the game
    if not player then
        -- Player might have left, or this could be a test purchase from Studio without a player.
        -- Roblox will retry if NotProcessedYet is returned.
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Check if the productId is one of our currency products
    local currencyAmount = currencyProducts[productId]
    if not currencyAmount then
        -- This product ID is not in our list of currency products.
        warn("CurrencyPurchaseHandler: Unrecognized product ID purchased:", productId, "by player:", player.Name)
        -- Do not grant anything, but acknowledge the purchase if it's a legitimate product you might sell elsewhere.
        -- Or, if it's definitely not one of yours, you might still grant it to avoid issues,
        -- but for currency, it's better to be strict.
        return Enum.ProductPurchaseDecision.NotProcessedYet -- Or PurchaseGranted if you want to accept any product but not give currency
    end

    -- Grant the currency
    -- This assumes you have a leaderstats setup with an IntValue or NumberValue named "Cash" (or your currency name)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        warn("CurrencyPurchaseHandler: Player", player.Name, "does not have leaderstats for currency purchase.")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local currencyStat = leaderstats:FindFirstChild("Cash") -- IMPORTANT: Change "Cash" to your currency's name if different
    if not currencyStat or not (currencyStat:IsA("IntValue") or currencyStat:IsA("NumberValue")) then
        warn("CurrencyPurchaseHandler: Player", player.Name, "does not have a 'Cash' IntValue/NumberValue in leaderstats.")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Add the currency
    currencyStat.Value = currencyStat.Value + currencyAmount
    print("CurrencyPurchaseHandler: Awarded", currencyAmount, "Cash to", player.Name, "for product", productId)

    -- IMPORTANT: You MUST return PurchaseGranted for the transaction to be considered successful by Roblox.
    -- If you return NotProcessedYet, Roblox will retry, and the player might not get their item but still be charged.
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Connect the ProcessReceipt function to MarketplaceService
MarketplaceService.ProcessReceipt = processReceipt

