--[[
    Example.lua
    Put Library.lua in your GitHub repository next to this file.
    Replace USERNAME/REPO with your GitHub account and repository.
]]

local REPO = "https://raw.githubusercontent.com/USERNAME/REPO/main/"

local Library = loadstring(game:HttpGet(REPO .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "My compact UI",
    Scale = 0.82,
    Size = UDim2.fromOffset(330, 255),
    AutoShow = true,
})

local Main = Window:AddTab("Main")
local Visuals = Window:AddTab("Visuals")

Main:AddToggle("ExampleToggle", {
    Text = "Example toggle",
    Default = false,
    Callback = function(enabled)
        print("Example toggle:", enabled)
    end,
})

Main:AddSlider("Power", {
    Text = "Power",
    Min = 0,
    Max = 100,
    Default = 35,
    Suffix = "%",
    Rounding = 0,
    Callback = function(value)
        print("Power:", value)
    end,
})

Main:AddInput("Message", {
    Text = "Message",
    Placeholder = "Type something...",
    Default = "",
    Finished = true,
    Callback = function(text)
        print("Message:", text)
    end,
})

Main:AddButton({
    Text = "Press me",
    Callback = function()
        print("Button pressed!")
    end,
})

Visuals:AddToggle("ExtraToggle", {
    Text = "Extra toggle",
    Default = true,
    Callback = function(enabled)
        print("Extra toggle:", enabled)
    end,
})

Visuals:AddButton("Print hello", function()
    print("Hello from the Visuals tab!")
end)

-- Settings is created automatically by the library.
-- It includes a GUI size slider and an unload button.
