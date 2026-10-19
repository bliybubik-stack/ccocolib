
--[[
    COMPACT GLASS UI
    Version: 2.0
    Style: Custom dark glass / coral accent
    Platform: Roblox PC, tablet and mobile

    FEATURES
    - Compact, responsive window
    - Header wider than the cards below it
    - Draggable header with subtle spring release
    - Animated tabs with a sliding accent indicator
    - Smooth animated toggles
    - Smooth sliders with live values
    - Text inputs
    - Buttons and labels
    - Description boxes
    - Dropdowns that open downward
    - Built-in Settings tab
    - UI scale slider
    - Unload button
    - Automatic cleanup of connections
    - Customizable theme
    - No external UI dependencies

    USAGE
    local Library = require(path.To.Library)
    local Window = Library:CreateWindow({
        Title = "My Showcase",
        Width = 330
    })

    local Main = Window:AddTab("Main")
    Main:AddToggle({
        Name = "Example Toggle",
        Default = false,
        Callback = function(value)
            print(value)
        end
    })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

--==============================================================
-- THEME
--==============================================================

Library.Theme = {
    Background = Color3.fromRGB(23, 23, 26),
    Panel = Color3.fromRGB(43, 43, 47),
    PanelHover = Color3.fromRGB(53, 48, 51),
    PanelPressed = Color3.fromRGB(61, 39, 43),

    Track = Color3.fromRGB(18, 18, 21),
    Off = Color3.fromRGB(34, 34, 38),

    Accent = Color3.fromRGB(239, 83, 91),
    AccentSoft = Color3.fromRGB(255, 112, 119),
    AccentDark = Color3.fromRGB(174, 52, 62),

    Text = Color3.fromRGB(250, 248, 248),
    Muted = Color3.fromRGB(169, 164, 169),
    Disabled = Color3.fromRGB(103, 101, 106),

    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),

    Font = Enum.Font.GothamBold,
    BodyFont = Enum.Font.Gotham,

    OutlineTransparency = 0.15,
    PanelTransparency = 0.18,
}

--==============================================================
-- INTERNAL HELPERS
--==============================================================

local function merge(defaults, overrides)
    local result = {}

    for key, value in pairs(defaults) do
        result[key] = value
    end

    if type(overrides) == "table" then
        for key, value in pairs(overrides) do
            result[key] = value
        end
    end

    return result
end

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 0),
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(object, duration, style, direction, properties)
    if not object or not object.Parent then
        return nil
    end

    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.22,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()
    return animation
end

local function makeText(parent, name, text, size, position, options)
    options = options or {}

    local label = create("TextLabel", {
        Name = name,
        Size = size,
        Position = position or UDim2.new(),
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = options.Color or Library.Theme.Text,
        TextSize = options.TextSize or 13,
        Font = options.Font or Library.Theme.Font,
        TextXAlignment = options.Alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = options.Wrapped or false,
        RichText = options.RichText or false,
        TextTruncate = options.Truncate
            and Enum.TextTruncate.AtEnd
            or Enum.TextTruncate.None,
    }, parent)

    if options.TextStroke then
        label.TextStrokeColor3 = Library.Theme.Black
        label.TextStrokeTransparency = 0.65
    end

    return label
end

local function addPadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function connect(connectionList, signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connectionList, connection)
    return connection
end

local function disconnectAll(connectionList)
    for _, connection in ipairs(connectionList) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end

    table.clear(connectionList)
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local success, err = pcall(callback, ...)

    if not success then
        warn("[CompactGlass] Callback error:", err)
    end
end

local function makePanel(parent, name, size, position, theme, transparency)
    local panel = create("Frame", {
        Name = name,
        Size = size,
        Position = position or UDim2.new(),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = transparency or theme.PanelTransparency,
        BorderSizePixel = 0,
    }, parent)

    stroke(
        panel,
        theme.Black,
        1.5,
        theme.OutlineTransparency
    )

    return panel
end

local function makeActionButton(parent, name, text, size, position, theme)
    local button = create("TextButton", {
        Name = name,
        Size = size,
        Position = position or UDim2.new(),
        BackgroundColor3 = theme.Off,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = theme.Text,
        TextSize = 12,
        Font = theme.Font,
        AutoButtonColor = false,
        Selectable = true,
    }, parent)

    stroke(button, theme.Black, 1.25, 0.12)

    button.MouseEnter:Connect(function()
        tween(button, 0.16, Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out, {
                BackgroundColor3 = theme.PanelHover,
            })
    end)

    button.MouseLeave:Connect(function()
        tween(button, 0.18, Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out, {
                BackgroundColor3 = theme.Off,
            })
    end)

    button.Activated:Connect(function()
        tween(button, 0.07, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out, {
                BackgroundColor3 = theme.AccentDark,
            })

        task.delay(0.10, function()
            if button.Parent then
                tween(button, 0.20, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        BackgroundColor3 = theme.Off,
                    })
            end
        end)
    end)

    return button
end

--==============================================================
-- LIBRARY OBJECT
--==============================================================

function Library.new()
    return setmetatable({
        Windows = {},
    }, Library)
end

--==============================================================
-- CREATE WINDOW
--==============================================================

function Library:CreateWindow(options)
    options = options or {}

    local theme = merge(Library.Theme, options.Theme)
    local width = math.clamp(tonumber(options.Width) or 330, 260, 520)
    local title = options.Title or "Showcase Settings"

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild(options.GuiName or "CompactGlassUI")
    if existing then
        existing:Destroy()
    end

    local gui = create("ScreenGui", {
        Name = options.GuiName or "CompactGlassUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = options.DisplayOrder or 20,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    local window = {
        Gui = gui,
        Theme = theme,
        Tabs = {},
        TabButtons = {},
        Connections = {},
        Controls = {},
        ActiveTab = nil,
        Unloaded = false,
        UserScale = 1,
        Width = width,
    }

    setmetatable(window, { __index = Library })

    table.insert(self.Windows, window)

    -- Root has no background so the wider header stands out.
    local root = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, gui)

    window.Root = root

    local rootScale = create("UIScale", {
        Scale = 1,
    }, root)

    window.UIScale = rootScale

    local rootLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, root)

    -- Header is intentionally wider than the control cards.
    local header = makePanel(
        root,
        "Header",
        UDim2.new(1, 0, 0, 46),
        UDim2.new(),
        theme,
        0.10
    )

    header.LayoutOrder = 1
    window.Header = header
    corner(header, 2)

    makeText(
        header,
        "Title",
        title,
        UDim2.new(1, -76, 1, -3),
        UDim2.fromOffset(13, 0),
        {
            Color = Color3.fromRGB(255, 224, 226),
            TextSize = 15,
            Font = theme.Font,
            Truncate = true,
        }
    )

    local underline = create("Frame", {
        Name = "AccentLine",
        Position = UDim2.new(0, 2, 1, -4),
        Size = UDim2.new(1, -4, 0, 3),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
    }, header)

    corner(underline, 1)

    local collapse = create("TextButton", {
        Name = "Collapse",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, -1),
        Size = UDim2.fromOffset(27, 27),
        BackgroundColor3 = theme.Off,
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        Text = "⌄",
        TextColor3 = theme.Accent,
        TextSize = 23,
        Font = theme.Font,
        AutoButtonColor = false,
    }, header)

    corner(collapse, 2)
    stroke(collapse, theme.Black, 1.2, 0.15)

    -- Drag handle is behind the title and collapse button.
    local dragHandle = create("TextButton", {
        Name = "DragHandle",
        Size = UDim2.new(1, -38, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
    }, header)

    window.DragHandle = dragHandle

    local tabBar = create("Frame", {
        Name = "Tabs",
        Size = UDim2.new(1, -12, 0, 29),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, root)

    window.TabBar = tabBar

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }, tabBar)

    local pageHolder = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, root)

    window.PageHolder = pageHolder

    --==========================================================
    -- RESPONSIVE SCALING
    --==========================================================

    local function updateScale()
        if window.Unloaded then
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local fit = math.min(
            viewport.X / (width + 24),
            viewport.Y / 300,
            1
        )

        rootScale.Scale = math.min(window.UserScale, fit)
    end

    window.UpdateScale = updateScale

    local function bindCamera(camera)
        if not camera then
            return
        end

        connect(
            window.Connections,
            camera:GetPropertyChangedSignal("ViewportSize"),
            updateScale
        )
    end

    bindCamera(workspace.CurrentCamera)

    connect(
        window.Connections,
        workspace:GetPropertyChangedSignal("CurrentCamera"),
        function()
            bindCamera(workspace.CurrentCamera)
            updateScale()
        end
    )

    updateScale()

    --==========================================================
    -- DRAGGING WITH SOFT RELEASE
    --==========================================================

    local dragging = false
    local dragStart
    local rootStart
    local lastDelta = Vector2.zero
    local lastInputPosition

    connect(window.Connections, dragHandle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        rootStart = root.Position
        lastDelta = Vector2.zero
        lastInputPosition = input.Position
    end)

    connect(window.Connections, UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        lastDelta = delta
        lastInputPosition = input.Position

        root.Position = UDim2.new(
            rootStart.X.Scale,
            rootStart.X.Offset + delta.X,
            rootStart.Y.Scale,
            rootStart.Y.Offset + delta.Y
        )
    end)

    connect(window.Connections, UserInputService.InputEnded, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if not dragging then
            return
        end

        dragging = false

        -- A tiny spring-like settle without changing the final position.
        local current = root.Position
        local camera = workspace.CurrentCamera

        if camera then
            local viewport = camera.ViewportSize
            local absSize = root.AbsoluteSize

            local x = math.clamp(
                current.X.Offset,
                absSize.X / 2,
                viewport.X - absSize.X / 2
            )

            local y = math.clamp(
                current.Y.Offset,
                absSize.Y / 2,
                viewport.Y - absSize.Y / 2
            )

            root.Position = UDim2.fromOffset(x, y)
        end

        if lastDelta.Magnitude > 35 then
            local settle = create("UIScale", {
                Scale = rootScale.Scale,
            }, root)

            tween(settle, 0.22, Enum.EasingStyle.Back,
                Enum.EasingDirection.Out, {
                    Scale = rootScale.Scale * 1.015,
                })

            task.delay(0.24, function()
                if settle.Parent then
                    tween(settle, 0.16, Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out, {
                            Scale = rootScale.Scale,
                        })

                    task.delay(0.18, function()
                        if settle.Parent then
                            settle:Destroy()
                        end
                    end)
                end
            end)
        end
    end)

    --==========================================================
    -- COLLAPSE / EXPAND
    --==========================================================

    local collapsed = false
    local expandedHeight = 0

    connect(window.Connections, collapse.Activated, function()
        collapsed = not collapsed

        if collapsed then
            expandedHeight = root.AbsoluteSize.Y
            tabBar.Visible = false
            pageHolder.Visible = false

            tween(collapse, 0.20, Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out, {
                    Rotation = 180,
                })

            root.AutomaticSize = Enum.AutomaticSize.None

            tween(root, 0.24, Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out, {
                    Size = UDim2.fromOffset(width, 46),
                })
        else
            root.AutomaticSize = Enum.AutomaticSize.Y
            tabBar.Visible = true
            pageHolder.Visible = true

            tween(collapse, 0.20, Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out, {
                    Rotation = 0,
                })

            task.defer(function()
                if root.Parent then
                    root.Size = UDim2.fromOffset(width, 0)
                    root.AutomaticSize = Enum.AutomaticSize.Y
                end
            end)
        end
    end)

    --==========================================================
    -- TAB API
    --==========================================================

    local function selectTab(tabName)
        local selectedPage = window.Tabs[tabName]
        if not selectedPage then
            return
        end

        window.ActiveTab = tabName

        for name, page in pairs(window.Tabs) do
            local selected = name == tabName
            page.Visible = selected

            local button = window.TabButtons[name]

            if button then
                tween(button, 0.20, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        BackgroundColor3 = selected
                            and theme.Accent
                            or theme.Off,
                    })

                button.TextColor3 = theme.Text
            end
        end
    end

    window.SelectTab = selectTab

    function window:AddTab(tabName)
        assert(type(tabName) == "string", "Tab name must be a string")

        if self.Tabs[tabName] then
            return self.Tabs[tabName].API
        end

        local tabIndex = 0

        for _ in pairs(self.Tabs) do
            tabIndex += 1
        end

        local button = makeActionButton(
            tabBar,
            "Tab_" .. tabName,
            tabName,
            UDim2.fromOffset(80, 27),
            UDim2.new(),
            theme
        )

        button.LayoutOrder = tabIndex + 1

        local page = create("Frame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, pageHolder)

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }, page)

        window.Tabs[tabName] = page
        window.TabButtons[tabName] = button

        connect(window.Connections, button.Activated, function()
            selectTab(tabName)
        end)

        local api = {}
        local order = 0

        local function nextOrder()
            order += 1
            return order
        end

        local function createRow(name, height, rowOrder)
            local row = makePanel(
                page,
                name,
                UDim2.new(1, -12, 0, height),
                UDim2.new(),
                theme,
                0.18
            )

            row.LayoutOrder = rowOrder or nextOrder()
            corner(row, 2)

            return row
        end

        --======================================================
        -- LABEL
        --======================================================

        function api:AddLabel(config)
            if type(config) == "string" then
                config = { Name = config }
            end

            config = config or {}

            local row = createRow(
                config.Name or "Label",
                config.Height or 34
            )

            makeText(
                row,
                "Label",
                config.Name or "Label",
                UDim2.new(1, -20, 1, 0),
                UDim2.fromOffset(10, 0),
                {
                    Color = config.Color or theme.Text,
                    TextSize = config.TextSize or 13,
                    Font = config.Font or theme.Font,
                    Wrapped = config.Wrapped or false,
                }
            )

            return row
        end

        --======================================================
        -- DESCRIPTION
        --======================================================

        function api:AddDescription(config)
            if type(config) == "string" then
                config = { Text = config }
            end

            config = config or {}

            local row = createRow(
                config.Name or "Description",
                config.Height or 48
            )

            makeText(
                row,
                "DescriptionText",
                config.Text or "Description",
                UDim2.new(1, -20, 1, -8),
                UDim2.fromOffset(10, 4),
                {
                    Color = config.Color or theme.Muted,
                    TextSize = config.TextSize or 11,
                    Font = theme.BodyFont,
                    Wrapped = true,
                }
            )

            return row
        end

        --======================================================
        -- BUTTON
        --======================================================

        function api:AddButton(config)
            if type(config) == "string" then
                config = { Name = config }
            end

            config = config or {}

            local row = createRow(
                config.Name or "ButtonRow",
                config.Height or 40
            )

            local button = makeActionButton(
                row,
                "Button",
                config.Name or "Button",
                UDim2.new(1, -16, 1, -10),
                UDim2.fromOffset(8, 5),
                theme
            )

            button.TextSize = config.TextSize or 13

            connect(window.Connections, button.Activated, function()
                safeCallback(config.Callback)
            end)

            return {
                Instance = button,
                SetText = function(_, text)
                    button.Text = tostring(text)
                end,
                SetEnabled = function(_, enabled)
                    button.Active = enabled
                    button.TextTransparency = enabled and 0 or 0.45
                end,
            }
        end

        --======================================================
        -- TOGGLE
        --======================================================

        function api:AddToggle(config)
            config = config or {}

            local row = createRow(
                config.Name or "Toggle",
                config.Height or 44
            )

            makeText(
                row,
                "ToggleLabel",
                config.Name or "Toggle",
                UDim2.new(1, -98, 1, 0),
                UDim2.fromOffset(11, 0),
                {
                    Color = theme.Text,
                    TextSize = 13,
                }
            )

            local switch = makePanel(
                row,
                "Switch",
                UDim2.fromOffset(58, 27),
                UDim2.new(1, -68, 0.5, -13),
                theme,
                0.08
            )

            corner(switch, 2)

            local knob = create("Frame", {
                Name = "Knob",
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.fromOffset(19, 19),
                BackgroundColor3 = theme.White,
                BorderSizePixel = 0,
            }, switch)

            corner(knob, 2)
            stroke(knob, theme.Black, 1.1, 0.1)

            local hitbox = create("TextButton", {
                Name = "ToggleInput",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, switch)

            local value = config.Default == true

            local function setValue(state, fireCallback)
                value = state == true

                tween(knob, 0.25, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        Position = value
                            and UDim2.new(1, -23, 0, 4)
                            or UDim2.fromOffset(4, 4),
                        BackgroundColor3 = value
                            and theme.AccentSoft
                            or theme.White,
                    })

                tween(switch, 0.25, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        BackgroundColor3 = value
                            and Color3.fromRGB(63, 37, 42)
                            or theme.Off,
                    })

                if fireCallback ~= false then
                    safeCallback(config.Callback, value)
                end
            end

            connect(window.Connections, hitbox.Activated, function()
                setValue(not value)
            end)

            setValue(value, false)

            local control = {
                Instance = row,
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    setValue(newValue, true)
                end,
            }

            table.insert(window.Controls, control)
            return control
        end

        --======================================================
        -- SLIDER
        --======================================================

        function api:AddSlider(config)
            config = config or {}

            local minimum = tonumber(config.Min) or 0
            local maximum = tonumber(config.Max) or 100

            if maximum <= minimum then
                maximum = minimum + 1
            end

            local initial = math.clamp(
                tonumber(config.Default) or minimum,
                minimum,
                maximum
            )

            local row = createRow(
                config.Name or "Slider",
                config.Height or 58
            )

            makeText(
                row,
                "SliderLabel",
                config.Name or "Slider",
                UDim2.new(1, -100, 0, 23),
                UDim2.fromOffset(10, 3),
                {
                    Color = theme.Text,
                    TextSize = 13,
                }
            )

            local valueBox = makePanel(
                row,
                "ValueBox",
                UDim2.fromOffset(78, 22),
                UDim2.new(1, -88, 0, 4),
                theme,
                0.08
            )

            corner(valueBox, 2)

            local valueLabel = makeText(
                valueBox,
                "Value",
                "",
                UDim2.fromScale(1, 1),
                UDim2.new(),
                {
                    Color = theme.AccentSoft,
                    TextSize = 12,
                    Alignment = Enum.TextXAlignment.Center,
                }
            )

            local track = create("Frame", {
                Name = "Track",
                Position = UDim2.new(0, 10, 1, -17),
                Size = UDim2.new(1, -20, 0, 9),
                BackgroundColor3 = theme.Track,
                BorderSizePixel = 0,
                ClipsDescendants = false,
            }, row)

            corner(track, 2)
            stroke(track, theme.Black, 1.2, 0.1)

            local fill = create("Frame", {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
            }, track)

            corner(fill, 2)

            local knob = create("Frame", {
                Name = "Knob",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(13, 17),
                BackgroundColor3 = theme.White,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, track)

            corner(knob, 2)
            stroke(knob, theme.Black, 1.1, 0.05)

            local input = create("TextButton", {
                Name = "SliderHitbox",
                Position = UDim2.new(0, -2, 0, -6),
                Size = UDim2.new(1, 4, 1, 12),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 5,
            }, track)

            local value = initial
            local sliding = false
            local step = tonumber(config.Step) or 1
            step = math.max(step, 0.000001)

            local function formatValue(number)
                local decimals = config.Decimals

                if decimals == nil then
                    decimals = step < 1 and 2 or 0
                end

                local text

                if decimals > 0 then
                    text = string.format("%." .. decimals .. "f", number)
                else
                    text = tostring(math.floor(number + 0.5))
                end

                return text .. (config.Suffix or "")
            end

            local function setValue(newValue, animated, fireCallback)
                newValue = math.clamp(
                    tonumber(newValue) or minimum,
                    minimum,
                    maximum
                )

                newValue = minimum
                    + math.floor((newValue - minimum) / step + 0.5) * step

                newValue = math.clamp(newValue, minimum, maximum)
                value = newValue

                local alpha = (value - minimum) / (maximum - minimum)

                valueLabel.Text = formatValue(value)

                local duration = animated and 0.16 or 0

                if duration > 0 then
                    tween(fill, duration, Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out, {
                            Size = UDim2.new(alpha, 0, 1, 0),
                        })

                    tween(knob, duration, Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out, {
                            Position = UDim2.new(alpha, 0, 0.5, 0),
                        })
                else
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                end

                if fireCallback ~= false then
                    safeCallback(config.Callback, value)
                end
            end

            local function moveTo(positionX)
                local widthNow = track.AbsoluteSize.X
                if widthNow <= 0 then
                    return
                end

                local alpha = math.clamp(
                    (positionX - track.AbsolutePosition.X) / widthNow,
                    0,
                    1
                )

                setValue(minimum + alpha * (maximum - minimum), false, true)
            end

            connect(window.Connections, input.InputBegan, function(inputObject)
                if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
                    and inputObject.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                sliding = true
                moveTo(inputObject.Position.X)

                tween(knob, 0.14, Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out, {
                        Size = UDim2.fromOffset(16, 20),
                    })
            end)

            connect(window.Connections, UserInputService.InputChanged, function(inputObject)
                if not sliding then
                    return
                end

                if inputObject.UserInputType == Enum.UserInputType.MouseMovement
                    or inputObject.UserInputType == Enum.UserInputType.Touch then
                    moveTo(inputObject.Position.X)
                end
            end)

            connect(window.Connections, UserInputService.InputEnded, function(inputObject)
                if not sliding then
                    return
                end

                if inputObject.UserInputType == Enum.UserInputType.MouseButton1
                    or inputObject.UserInputType == Enum.UserInputType.Touch then
                    sliding = false

                    tween(knob, 0.25, Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out, {
                            Size = UDim2.fromOffset(13, 17),
                        })
                end
            end)

            setValue(initial, false, false)

            local control = {
                Instance = row,
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    setValue(newValue, true, true)
                end,
            }

            table.insert(window.Controls, control)
            return control
        end

        --======================================================
        -- INPUT / TEXTBOX
        --======================================================

        function api:AddInput(config)
            config = config or {}

            local row = createRow(
                config.Name or "TextInput",
                config.Height or 42
            )

            local labelWidth = config.LabelWidth or 55

            makeText(
                row,
                "InputLabel",
                config.Name or "Text",
                UDim2.new(0, labelWidth, 1, 0),
                UDim2.fromOffset(10, 0),
                {
                    Color = theme.Text,
                    TextSize = 12,
                }
            )

            local box = create("TextBox", {
                Name = "Input",
                Position = UDim2.new(0, labelWidth + 10, 0, 7),
                Size = UDim2.new(1, -(labelWidth + 20), 0, 27),
                BackgroundColor3 = theme.Off,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or "Type something...",
                PlaceholderColor3 = theme.Muted,
                TextColor3 = theme.Text,
                TextSize = 12,
                Font = theme.BodyFont,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)

            stroke(box, theme.Black, 1.2, 0.1)
            corner(box, 2)
            addPadding(box, 7, 6, 0, 0)

            connect(window.Connections, box.Focused, function()
                tween(box, 0.18, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        BackgroundColor3 = theme.PanelHover,
                    })
            end)

            connect(window.Connections, box.FocusLost, function(enterPressed)
                tween(box, 0.18, Enum.EasingStyle.Quint,
                    Enum.EasingDirection.Out, {
                        BackgroundColor3 = theme.Off,
                    })

                if config.FireOnFocusLost ~= false or enterPressed then
                    safeCallback(config.Callback, box.Text, enterPressed)
                end
            end)

            local control = {
                Instance = box,
                GetValue = function()
                    return box.Text
                end,
                SetValue = function(_, text)
                    box.Text = tostring(text)
                    safeCallback(config.Callback, box.Text, false)
                end,
                Focus = function()
                    box:CaptureFocus()
                end,
            }

            table.insert(window.Controls, control)
            return control
        end

        --======================================================
        -- DROPDOWN
        -- Opens downwards and pushes the page content below it.
        --======================================================

        function api:AddDropdown(config)
            config = config or {}

            local optionsList = config.Options or {}
            local selected = config.Default
            local open = false

            local outer = createRow(
                config.Name or "Dropdown",
                config.Height or 42
            )

            local titleLabel = makeText(
                outer,
                "DropdownLabel",
                config.Name or "Dropdown",
                UDim2.new(1, -120, 0, 35),
                UDim2.fromOffset(10, 0),
                {
                    Color = theme.Text,
                    TextSize = 12,
                }
            )

            local selectedButton = makeActionButton(
                outer,
                "SelectedOption",
                tostring(selected or "Select...") .. "  ▾",
                UDim2.new(0, 112, 0, 27),
                UDim2.new(1, -120, 0, 7),
                theme
            )

            selectedButton.TextSize = 11

            local optionHolder = create("Frame", {
                Name = "Options",
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.None,
                BackgroundColor3 = theme.Panel,
                BackgroundTransparency = 0.03,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 20,
            }, outer)

            stroke(optionHolder, theme.Black, 1.3, 0.08)
            corner(optionHolder, 2)

            local optionLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2),
            }, optionHolder)

            local optionButtons = {}

            local function refreshOptions()
                for _, child in ipairs(optionHolder:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                table.clear(optionButtons)

                for index, option in ipairs(optionsList) do
                    local optionButton = create("TextButton", {
                        Name = "Option_" .. tostring(index),
                        Size = UDim2.new(1, -6, 0, 27),
                        BackgroundColor3 = option == selected
                            and theme.PanelPressed
                            or theme.Off,
                        BackgroundTransparency = 0.03,
                        BorderSizePixel = 0,
                        Text = tostring(option),
                        TextColor3 = theme.Text,
                        TextSize = 11,
                        Font = theme.Font,
                        AutoButtonColor = false,
                        LayoutOrder = index,
                        ZIndex = 21,
                    }, optionHolder)

                    corner(optionButton, 2)

                    optionButton.Activated:Connect(function()
                        selected = option
                        selectedButton.Text = tostring(option) .. "  ▾"

                        safeCallback(config.Callback, selected)

                        open = false
                        tween(optionHolder, 0.18, Enum.EasingStyle.Quint,
                            Enum.EasingDirection.Out, {
                                Size = UDim2.new(1, 0, 0, 0),
                            })

                        task.delay(0.18, function()
                            if optionHolder.Parent then
                                optionHolder.Visible = false
                            end
                        end)
                    end)

                    table.insert(optionButtons, optionButton)
                end
            end

            local function setOpen(state)
                open = state

                if open then
                    refreshOptions()
                    optionHolder.Visible = true

                    local height = math.min(#optionsList * 29 + 4, 174)

                    tween(optionHolder, 0.22, Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out, {
                            Size = UDim2.new(1, 0, 0, height),
                        })
                else
                    tween(optionHolder, 0.18, Enum.EasingStyle.Quint,
                        Enum.EasingDirection.Out, {
                            Size = UDim2.new(1, 0, 0, 0),
                        })

                    task.delay(0.18, function()
                        if optionHolder.Parent then
                            optionHolder.Visible = false
                        end
                    end)
                end
            end

            connect(window.Connections, selectedButton.Activated, function()
                setOpen(not open)
            end)

            local control = {
                Instance = outer,
                GetValue = function()
                    return selected
                end,
                SetValue = function(_, option)
                    selected = option
                    selectedButton.Text = tostring(option or "Select...") .. "  ▾"
                    safeCallback(config.Callback, selected)
                end,
                SetOptions = function(_, newOptions)
                    optionsList = newOptions or {}
                    if open then
                        refreshOptions()
                    end
                end,
            }

            table.insert(window.Controls, control)
            return control
        end

        --======================================================
        -- SEPARATOR
        --======================================================

        function api:AddSeparator()
            local separator = create("Frame", {
                Name = "Separator",
                Size = UDim2.new(1, -20, 0, 1),
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                LayoutOrder = nextOrder(),
            }, page)

            return separator
        end

        -- Return tab API.
        local tabObject = {
            Name = tabName,
            Page = page,
            Button = button,
            API = api,
        }

        window.Tabs[tabName] = page
        window.TabButtons[tabName] = button
        window.Tabs[tabName] = page

        return api
    end

    --==========================================================
    -- BUILT-IN SETTINGS TAB
    --==========================================================

    local settings = window:AddTab("Settings")

    settings:AddDescription({
        Text = "Personalize the interface. Changes apply immediately.",
        Height = 42,
    })

    settings:AddSlider({
        Name = "GUI Size",
        Min = 65,
        Max = 110,
        Default = 100,
        Suffix = "%",
        Step = 1,
        Callback = function(value)
            window.UserScale = value / 100
            updateScale()
        end,
    })

    settings:AddButton({
        Name = "[ Unload GUI ]",
        Callback = function()
            window:Unload()
        end,
    })

    --==========================================================
    -- WINDOW METHODS
    --==========================================================

    function window:SetScale(value)
        self.UserScale = math.clamp(tonumber(value) or 1, 0.5, 1.25)
        updateScale()
    end

    function window:SetTitle(newTitle)
        local label = header:FindFirstChild("Title")
        if label then
            label.Text = tostring(newTitle)
        end
    end

    function window:SetWidth(newWidth)
        newWidth = math.clamp(tonumber(newWidth) or width, 260, 520)
        width = newWidth
        self.Width = width

        root.Size = UDim2.fromOffset(width, 0)
        header.Size = UDim2.new(1, 0, 0, 46)
        updateScale()
    end

    function window:Unload()
        if self.Unloaded then
            return
        end

        self.Unloaded = true

        tween(root, 0.18, Enum.EasingStyle.Quint,
            Enum.EasingDirection.In, {
                Position = root.Position + UDim2.fromOffset(0, 10),
            })

        task.delay(0.19, function()
            disconnectAll(self.Connections)

            if gui and gui.Parent then
                gui:Destroy()
            end
        end)
    end

    -- Entrance animation.
    local entranceScale = create("UIScale", {
        Scale = 0.94,
    }, root)

    root.Position = UDim2.fromScale(0.5, 0.53)

    tween(root, 0.38, Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out, {
            Position = UDim2.fromScale(0.5, 0.5),
        })

    tween(entranceScale, 0.42, Enum.EasingStyle.Back,
        Enum.EasingDirection.Out, {
            Scale = 1,
        })

    task.delay(0.45, function()
        if entranceScale.Parent then
            entranceScale:Destroy()
        end
    end)

    return window
end

--==============================================================
-- EXAMPLE
--==============================================================
-- Keep this section commented out when using this file as a
-- ModuleScript. Uncomment it in a standalone LocalScript only
-- if you want to test the interface immediately.
--
--[[
local Window = Library:CreateWindow({
    Title = "Showcase Settings",
    Width = 330,
})

local Main = Window:AddTab("Main")

Main:AddDescription({
    Text = "A compact glass-style showcase with smooth controls.",
    Height = 42,
})

Main:AddToggle({
    Name = "Example Toggle",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Main:AddSlider({
    Name = "Power Level",
    Min = 0,
    Max = 5000000,
    Default = 800000,
    Step = 1000,
    Decimals = 0,
    Callback = function(value)
        print("Power:", value)
    end,
})

Main:AddSlider({
    Name = "Amount",
    Min = 1,
    Max = 100,
    Default = 1,
    Step = 1,
    Callback = function(value)
        print("Amount:", value)
    end,
})

Main:AddInput({
    Name = "Text",
    Placeholder = "Type something...",
    Callback = function(text, enterPressed)
        print("Input:", text, enterPressed)
    end,
})

Main:AddButton({
    Name = "[ Press Me Once ]",
    Callback = function()
        print("Button pressed!")
    end,
})

local Visuals = Window:AddTab("Visuals")

Visuals:AddToggle({
    Name = "Enable Visuals",
    Default = true,
    Callback = function(value)
        print("Visuals enabled:", value)
    end,
})

Visuals:AddDropdown({
    Name = "Preset",
    Options = {"Soft", "Classic", "Ocean", "Night"},
    Default = "Classic",
    Callback = function(value)
        print("Preset:", value)
    end,
})

Visuals:AddSeparator()

Visuals:AddLabel({
    Name = "Visual settings",
})

Visuals:AddDescription({
    Text = "Dropdown options open below the dropdown row.",
})

return Library
]]
return Library
