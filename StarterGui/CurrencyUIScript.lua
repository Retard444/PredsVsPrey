local CoinsButton = script.Parent:WaitForChild('CurrencyUI'):WaitForChild('Coins UI'):WaitForChild('CoinsPlus')
local GemsButton = script.Parent:WaitForChild('CurrencyUI'):WaitForChild('Gems UI'):WaitForChild('GemsPlus')
local CoinsFrame = script.Parent:WaitForChild('CurrencyUI'):WaitForChild('CoinsFrame')
local GemsFrame = script.Parent:WaitForChild('CurrencyUI'):WaitForChild('GemsFrame')

CoinsButton.MouseButton1Click:Connect(function()
	CoinsFrame.Visible = not CoinsFrame.Visible
	print('Coins button has been clicked')
end)

GemsButton.MouseButton1Click:Connect(function()
	GemsFrame.Visible = not GemsFrame.Visible
	print('Gems button has been click')
end)
