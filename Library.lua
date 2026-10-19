--[[
    Compact Glass UI Library
    File: Library.lua
    Client-side Roblox UI library. No external dependencies.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library


Library.Theme = {
    Panel = Color3.fromRGB(31, 33, 38),
    PanelAlt = Color3.fromRGB(23, 25, 30),
    Track = Color3.fromRGB(13, 15, 19),
    Text = Color3.fromRGB(245, 247, 250),
    Muted = Color3.fromRGB(160, 166, 177),
    Accent = Color3.fromRGB(239, 82, 91),
    Border = Color3.fromRGB(70, 73, 82),
    White = Color3.fromRGB(255, 255, 255),
}

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function outline(object, thickness, color, transparency)
    return make("UIStroke", {
        Color = color or Library.Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.12,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end

local function round(object, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 7)}, object)
    return object
end

local function baseFrame(parent, name, size, position, transparency)
    local frame = make("Frame", {
        Name = name,
        Size = size,
        Position = position or UDim2.new(),
        BackgroundColor3 = Library.Theme.Panel,
        BackgroundTransparency = transparency == nil and 0.17 or transparency,
        BorderSizePixel = 0,
    }, parent)
    round(frame, 8)
    outline(frame, 1)
    return frame
end

local function label(parent, text, size, position, textSize, color)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Size = size,
        Position = position or UDim2.new(),
        Font = Enum.Font.GothamBold,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = textSize or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = 0.72,
        TextWrapped = false,
    }, parent)
end

local function connectPress(guiObject, callback)
    guiObject.Active = true
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            callback(input)
        end
    end)
end

function Library:CreateWindow(options)
    options = options or {}
    local self = setmetatable({}, Library)
    self.Unloaded = false
    self.Tabs = {}
    self.TabOrder = {}
    self.Connections = {}
    self.Scale = math.clamp(tonumber(options.Scale) or 0.82, 0.5, 1.5)

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild(options.GuiName or "CompactGlassLibrary")
    if existing then existing:Destroy() end

    self.Gui = make("ScreenGui", {
        Name = options.GuiName or "CompactGlassLibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 40,
    }, playerGui)

    self.ScaleObject = make("UIScale", { Scale = self.Scale }, self.Gui)

    self.Root = make("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Size = options.Size or UDim2.fromOffset(330, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, self.Gui)

    self.Header = baseFrame(self.Root, "Header", UDim2.new(1, 0, 0, 43), UDim2.new(), 0.12)
    self.Header.BackgroundColor3 = Color3.fromRGB(37, 39, 45)
    self.HeaderTitle = label(self.Header, options.Title or "Glass Library", UDim2.new(1, -58, 1, -4), UDim2.new(0, 14, 0, 0), 15)
    self.HeaderTitle.TextTruncate = Enum.TextTruncate.AtEnd
    self.Chevron = label(self.Header, "⌄", UDim2.new(0, 30, 1, 0), UDim2.new(1, -39, 0, -1), 27, Library.Theme.Accent)
    self.Chevron.TextXAlignment = Enum.TextXAlignment.Center
    local redLine = make("Frame", {
        Name = "AccentLine",
        Position = UDim2.new(0, 9, 1, -3),
        Size = UDim2.new(1, -18, 0, 2),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
    }, self.Header)

    self.Body = baseFrame(self.Root, "Body", UDim2.new(1, 0, 1, -51), UDim2.new(0, 0, 0, 49), 0.17)
    self.Body.BackgroundColor3 = Color3.fromRGB(27, 29, 34)

    self.TabBar = make("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.new(0, 9, 0, 9),
        Size = UDim2.new(1, -18, 0, 29),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, self.Body)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.TabBar)

    self.PageHolder = make("Frame", {
        Name = "PageHolder",
        Position = UDim2.new(0, 9, 0, 45),
        Size = UDim2.new(1, -18, 1, -54),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, self.Body)

    -- Normal drag: preserve the exact pointer offset, and only move while held.
    local dragging, dragStart, startPosition, activeInput
    self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = self.Root.Position
            activeInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeInput = nil
                end
            end)
        end
    end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            self.Root.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end))

    local collapsed = false
    connectPress(self.Header, function()
        -- Header remains a drag surface; collapse is done with the arrow's own button.
    end)
    self.CollapseButton = make("TextButton", {
        Name = "Collapse",
        Position = UDim2.new(1, -42, 0, 0),
        Size = UDim2.new(0, 40, 1, -4),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, self.Header)
    self.CollapseButton.Activated:Connect(function()
        collapsed = not collapsed
        tween(self.Body, 0.2, {BackgroundTransparency = collapsed and 1 or 0.17})
        self.Body.Visible = true
        self.Body.ClipsDescendants = true
        tween(self.Root, 0.22, {
            Size = collapsed and UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, 43)
                or (options.Size or UDim2.fromOffset(330, 255))
        })
        self.Body.Visible = not collapsed
        self.Chevron.Text = collapsed and "›" or "⌄"
    end)

    function self:SetScale(value)
        self.Scale = math.clamp(tonumber(value) or 1, 0.5, 1.5)
        tween(self.ScaleObject, 0.2, {Scale = self.Scale})
    end

    function self:Unload()
        if self.Unloaded then return end
        self.Unloaded = true
        for _, connection in ipairs(self.Connections) do
            pcall(function() connection:Disconnect() end)
        end
        tween(self.Root, 0.15, {Position = self.Root.Position + UDim2.fromOffset(0, 8)})
        task.delay(0.16, function()
            if self.Gui then self.Gui:Destroy() end
        end)
    end

    local window = self

    function self:AddTab(name)
        assert(type(name) == "string", "Tab name must be a string")
        local tab = {Name = name, Controls = {}}
        tab.Button = make("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(0, math.max(52, #name * 7 + 18), 1, 0),
            BackgroundColor3 = Library.Theme.PanelAlt,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Text = name,
            TextColor3 = Library.Theme.Muted,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, self.TabBar)
        round(tab.Button, 6)
        outline(tab.Button, 1, Library.Theme.Border, 0.25)

        tab.Page = make("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, self.PageHolder)
        tab.Layout = make("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, tab.Page)
        make("UIPadding", {
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 3),
        }, tab.Page)

        function tab:_AddRow(name, height)
            local row = baseFrame(tab.Page, name or "Control", UDim2.new(1, -3, 0, height or 39), UDim2.new(), 0.13)
            row.BackgroundColor3 = Color3.fromRGB(36, 38, 44)
            return row
        end

        function tab:AddLabel(text)
            local row = self:_AddRow("Label", 30)
            label(row, text, UDim2.new(1, -16, 1, 0), UDim2.new(0, 9, 0, 0), 12)
            return row
        end

        function tab:AddButton(config, callback)
            if type(config) == "string" then config = {Text = config, Callback = callback} end
            config = config or {}
            local row = self:_AddRow("Button", 36)
            local button = make("TextButton", {
                Position = UDim2.new(0, 6, 0, 4),
                Size = UDim2.new(1, -12, 1, -8),
                BackgroundColor3 = Library.Theme.PanelAlt,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = config.Text or "Press me",
                TextColor3 = Library.Theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, row)
            round(button, 5)
            outline(button, 1, Library.Theme.Border, 0.18)
            button.Activated:Connect(function()
                tween(button, 0.08, {BackgroundColor3 = Library.Theme.Accent})
                task.delay(0.09, function()
                    if button.Parent then tween(button, 0.16, {BackgroundColor3 = Library.Theme.PanelAlt}) end
                end)
                if config.Callback then task.spawn(config.Callback) end
            end)
            return button
        end

        function tab:AddToggle(id, config)
            if type(id) == "table" then config = id; id = config.Name end
            config = config or {}
            local value = config.Default == true
            local row = self:_AddRow(config.Text or id or "Toggle", 39)
            label(row, config.Text or id or "Toggle", UDim2.new(1, -78, 1, 0), UDim2.new(0, 10, 0, 0), 13)
            local box = make("Frame", {
                Position = UDim2.new(1, -58, 0.5, -12),
                Size = UDim2.new(0, 48, 0, 24),
                BackgroundColor3 = Library.Theme.PanelAlt,
                BorderSizePixel = 0,
            }, row)
            round(box, 6)
            outline(box, 1, Library.Theme.Border, 0.1)
            local knob = make("Frame", {
                Position = value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3),
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundColor3 = value and Library.Theme.Accent or Library.Theme.White,
                BorderSizePixel = 0,
            }, box)
            round(knob, 4)
            outline(knob, 1, Library.Theme.Border, 0.2)
            local toggleButton = make("TextButton", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, box)
            local object = {Value = value}
            function object:SetValue(nextValue)
                value = nextValue == true
                self.Value = value
                tween(knob, 0.2, {
                    Position = value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3),
                    BackgroundColor3 = value and Library.Theme.Accent or Library.Theme.White,
                })
                if config.Callback then task.spawn(config.Callback, value) end
            end
            toggleButton.Activated:Connect(function() object:SetValue(not value) end)
            if config.Callback then task.spawn(config.Callback, value) end
            self.Controls[id or config.Text or tostring(#self.Controls + 1)] = object
            return object
        end

        function tab:AddSlider(id, config)
            if type(id) == "table" then config = id; id = config.Name end
            config = config or {}
            local minimum, maximum = tonumber(config.Min) or 0, tonumber(config.Max) or 100
            if maximum <= minimum then maximum = minimum + 1 end
            local value = math.clamp(tonumber(config.Default) or minimum, minimum, maximum)
            local row = self:_AddRow(config.Text or id or "Slider", 54)
            label(row, config.Text or id or "Slider", UDim2.new(0.65, -8, 0, 23), UDim2.new(0, 9, 0, 2), 12)
            local valueBox = make("Frame", {
                Position = UDim2.new(1, -82, 0, 5),
                Size = UDim2.new(0, 72, 0, 21),
                BackgroundColor3 = Library.Theme.PanelAlt,
                BorderSizePixel = 0,
            }, row)
            round(valueBox, 5)
            outline(valueBox, 1, Library.Theme.Border, 0.2)
            local valueText = label(valueBox, tostring(value) .. (config.Suffix or ""), UDim2.fromScale(1, 1), UDim2.new(), 12, Library.Theme.Accent)
            valueText.TextXAlignment = Enum.TextXAlignment.Center
            local track = make("Frame", {
                Position = UDim2.new(0, 8, 0, 32),
                Size = UDim2.new(1, -16, 0, 13),
                BackgroundColor3 = Library.Theme.Track,
                BorderSizePixel = 0,
                ClipsDescendants = false,
            }, row)
            round(track, 5)
            outline(track, 1, Library.Theme.Border, 0.1)
            local fill = make("Frame", {
                Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
            }, track)
            round(fill, 5)
            local knob = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((value - minimum) / (maximum - minimum), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 22),
                BackgroundColor3 = Library.Theme.White,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, track)
            round(knob, 4)
            outline(knob, 1, Library.Theme.Border, 0.1)
            local hit = make("TextButton", {
                Size = UDim2.new(1, 12, 1, 18),
                Position = UDim2.new(0, -6, 0, -9),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 4,
            }, track)
            local object = {Value = value, Min = minimum, Max = maximum}
            local function setFromX(x)
                local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                local nextValue = minimum + (maximum - minimum) * ratio
                local rounding = config.Rounding
                if rounding == nil then rounding = 0 end
                local factor = 10 ^ rounding
                nextValue = math.floor(nextValue * factor + 0.5) / factor
                value, object.Value = nextValue, nextValue
                local p = (value - minimum) / (maximum - minimum)
                tween(fill, 0.08, {Size = UDim2.new(p, 0, 1, 0)})
                tween(knob, 0.08, {Position = UDim2.new(p, 0, 0.5, 0)})
                valueText.Text = tostring(value) .. (config.Suffix or "")
                if config.Callback then task.spawn(config.Callback, value) end
            end
            function object:SetValue(nextValue)
                nextValue = math.clamp(tonumber(nextValue) or minimum, minimum, maximum)
                local rounding = 10 ^ (config.Rounding or 0)
                value = math.floor(nextValue * rounding + 0.5) / rounding
                object.Value = value
                local p = (value - minimum) / (maximum - minimum)
                tween(fill, 0.18, {Size = UDim2.new(p, 0, 1, 0)})
                tween(knob, 0.18, {Position = UDim2.new(p, 0, 0.5, 0)})
                valueText.Text = tostring(value) .. (config.Suffix or "")
                if config.Callback then task.spawn(config.Callback, value) end
            end
            local sliding = false
            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    setFromX(input.Position.X)
                end
            end)
            local moveConnection = UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)
            local endConnection = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
            end)
            table.insert(window.Connections, moveConnection)
            table.insert(window.Connections, endConnection)
            if config.Callback then task.spawn(config.Callback, value) end
            self.Controls[id or config.Text or tostring(#self.Controls + 1)] = object
            return object
        end

        function tab:AddInput(id, config)
            if type(id) == "table" then config = id; id = config.Name end
            config = config or {}
            local row = self:_AddRow(config.Text or id or "Textbox", 42)
            label(row, config.Text or id or "Textbox", UDim2.new(0.42, -8, 1, 0), UDim2.new(0, 9, 0, 0), 12)
            local input = make("TextBox", {
                Position = UDim2.new(0.42, 0, 0, 7),
                Size = UDim2.new(0.58, -9, 1, -14),
                BackgroundColor3 = Library.Theme.PanelAlt,
                BorderSizePixel = 0,
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or "Type here...",
                PlaceholderColor3 = Library.Theme.Muted,
                TextColor3 = Library.Theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = config.ClearTextOnFocus == true,
            }, row)
            round(input, 5)
            outline(input, 1, Library.Theme.Border, 0.18)
            input.TextXAlignment = Enum.TextXAlignment.Left
            local inputPadding = make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6)}, input)
            local object = {Value = input.Text, Instance = input}
            input:GetPropertyChangedSignal("Text"):Connect(function()
                object.Value = input.Text
                if not config.Finished and config.Callback then task.spawn(config.Callback, input.Text) end
            end)
            input.FocusLost:Connect(function(enterPressed)
                object.Value = input.Text
                if (config.Finished == true or enterPressed) and config.Callback then
                    task.spawn(config.Callback, input.Text)
                end
            end)
            function object:SetValue(value)
                input.Text = tostring(value or "")
                object.Value = input.Text
            end
            self.Controls[id or config.Text or tostring(#self.Controls + 1)] = object
            return object
        end

        tab.Button.Activated:Connect(function()
            self:SelectTab(name)
        end)

        self.Tabs[name] = tab
        if name == "Settings" then
            table.insert(self.TabOrder, name)
        else
            local settingsIndex = table.find(self.TabOrder, "Settings")
            if settingsIndex then
                table.insert(self.TabOrder, settingsIndex, name)
            else
                table.insert(self.TabOrder, name)
            end
        end
        -- Keep visual order in sync with TabOrder; Settings is always the final tab.
        for index, tabName in ipairs(self.TabOrder) do
            local orderedTab = self.Tabs[tabName]
            if orderedTab and orderedTab.Button then
                orderedTab.Button.LayoutOrder = index
            end
        end
        if not self.SelectedTab or (self.SelectedTab == "Settings" and name ~= "Settings") then
            self:SelectTab(name)
        end
        return tab
    end

    function self:SelectTab(name)
        local chosen = self.Tabs[name]
        if not chosen then return end
        self.SelectedTab = name
        for tabName, tab in pairs(self.Tabs) do
            local selected = tabName == name
            tab.Page.Visible = selected
            tween(tab.Button, 0.2, {
                BackgroundColor3 = selected and Library.Theme.Accent or Library.Theme.PanelAlt,
                BackgroundTransparency = selected and 0 or 0.04,
            })
            tab.Button.TextColor3 = selected and Library.Theme.White or Library.Theme.Muted
            local stroke = tab.Button:FindFirstChildOfClass("UIStroke")
            if stroke then tween(stroke, 0.18, {Transparency = selected and 0.02 or 0.25, Color = selected and Library.Theme.Accent or Library.Theme.Border}) end
        end
    end

    -- Create the permanent settings tab automatically.
    local settings = self:AddTab("Settings")
    settings:AddLabel("Interface settings")
    settings:AddSlider("UIScale", {
        Text = "GUI size", Min = 50, Max = 125, Default = math.floor(self.Scale * 100),
        Suffix = "%", Rounding = 0,
        Callback = function(value) self:SetScale(value / 100) end,
    })
    settings:AddButton({
        Text = "Unload library",
        Callback = function() self:Unload() end,
    })

    -- Keep references for slider connections created by tab methods.
    if options.AutoShow ~= false then
        self.Gui.Enabled = true
    end
    return self
end

return Library
