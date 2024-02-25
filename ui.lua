local Services = {}
setmetatable(Services, {
    __index = function(self, index)
        return game:GetService(index)
    end
})

local wait = task.wait
repeat wait() until game:IsLoaded()

local TweenService = Services.TweenService
local UserInputService = Services.UserInputService

local Creator = {
    Registry = {},
    Signals = {},
    TransparencyMotors = {},
    DefaultProperties = {
        ScreenGui = {
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        },
        Frame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0
        },
        ScrollingFrame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ScrollBarImageColor3 = Color3.new(0, 0, 0)
        },
        TextLabel = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            TextSize = 14
        },
        TextButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14
        },
        TextBox = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ClearTextOnFocus = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14
        },
        ImageLabel = {
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0
        },
        ImageButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false
        },
        CanvasGroup = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0
        }
    }
}

local function ApplyCustomProps(Object, Props)
    if Props.ThemeTag then
        Creator.AddThemeObject(Object, Props.ThemeTag)
    end
end

function Creator.AddSignal(Signal, Function)
    table.insert(Creator.Signals, Signal:Connect(Function))
end

function Creator.Disconnect()
    for Idx = #Creator.Signals, 1, -1 do
        local Connection = table.remove(Creator.Signals, Idx)
        Connection:Disconnect()
    end
end

function Creator.AddThemeObject(Object, Properties)
    local Idx = #Creator.Registry + 1
    local Data = {
        Object = Object,
        Properties = Properties,
        Idx = Idx
    }

    Creator.Registry[Object] = Data
    Creator.UpdateTheme()
    return Object
end

function Creator.OverrideTag(Object, Properties)
    Creator.Registry[Object].Properties = Properties
    Creator.UpdateTheme()
end

function Creator.New(Name, Properties, Children)
    Properties = Properties or {}
    Children = Children or {}
    local Object = Instance.new(Name)

    -- Default properties
    for Name, Value in next, Creator.DefaultProperties[Name] or {} do
        Object[Name] = Value
    end

    -- Properties
    for Name, Value in next, Properties or {} do
        if Name ~= "ThemeTag" then
            Object[Name] = Value
        end
    end

    -- Children
    for _, Child in next, Children or {} do
        Child.Parent = Object
    end

    ApplyCustomProps(Object, Properties)
    return Object
end

local function createAcrylic()
    local Part = Creator.New("Part", {
        Name = "Body",
        Color = Color3.new(0, 0, 0),
        Material = Enum.Material.Glass,
        Size = Vector3.new(1, 1, 0),
        Anchored = true,
        CanCollide = false,
        Locked = true,
        CastShadow = false,
        Transparency = 0.98
    }, { Creator.New("SpecialMesh", {
        MeshType = Enum.MeshType.Brick,
        Offset = Vector3.new(0, 0, -0.000001)
    }) })

    return Part
end

local function map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
    local unitRay = game:GetService("Workspace").CurrentCamera:ScreenPointToRay(location.X, location.Y)
    return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
    local viewportSizeY = game:GetService("Workspace").CurrentCamera.ViewportSize.Y
    return map(viewportSizeY, 0, 2560, 8, 56)
end

local function createAcrylicBlur(distance)
    local cleanups = {}

    distance = distance or 0.001
    local positions = {
        topLeft = Vector2.new(),
        topRight = Vector2.new(),
        bottomRight = Vector2.new()
    }
    local model = createAcrylic()
    model.Parent = workspace

    local function updatePositions(size, position)
        positions.topLeft = position
        positions.topRight = position + Vector2.new(size.X, 0)
        positions.bottomRight = position + size
    end

    local render = function()
        local res = game:GetService("Workspace").CurrentCamera
        if res then
            res = res.CFrame
        end
        local cond = res
        if not cond then
            cond = CFrame.new()
        end

        local camera = cond
        local topLeft = positions.topLeft
        local topRight = positions.topRight
        local bottomRight = positions.bottomRight

        local topLeft3D = viewportPointToWorld(topLeft, distance)
        local topRight3D = viewportPointToWorld(topRight, distance)
        local bottomRight3D = viewportPointToWorld(bottomRight, distance)

        local width = (topRight3D - topLeft3D).Magnitude
        local height = (topRight3D - bottomRight3D).Magnitude

        model.CFrame =
            CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, camera.XVector, camera.YVector, camera.ZVector)
        model.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function onChange(rbx)
        local offset = getOffset()
        local size = rbx.AbsoluteSize - Vector2.new(offset, offset)
        local position = rbx.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        updatePositions(size, position)
        task.spawn(render)
    end

    local function renderOnChange()
        local camera = game:GetService("Workspace").CurrentCamera
        if not camera then
            return
        end

        table.insert(cleanups, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
        table.insert(cleanups, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
        table.insert(cleanups, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
        task.spawn(render)
    end

    model.Destroying:Connect(function()
        for _, item in cleanups do
            pcall(function()
                item:Disconnect()
            end)
        end
    end)

    renderOnChange()

    return onChange, model
end

local function AcrylicBlur(distance)
    local Blur = {}
    local onChange, model = createAcrylicBlur(distance)

    local comp = Creator.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1)
    })

    Creator.AddSignal(comp:GetPropertyChangedSignal("AbsolutePosition"), function()
        onChange(comp)
    end)

    Creator.AddSignal(comp:GetPropertyChangedSignal("AbsoluteSize"), function()
        onChange(comp)
    end)

    Blur.AddParent = function(Parent)
        Creator.AddSignal(Parent:GetPropertyChangedSignal("Visible"), function()
            Blur.SetVisibility(Parent.Visible)
        end)
    end

    Blur.SetVisibility = function(Value)
        model.Transparency = Value and 0.98 or 1
    end

    Blur.Frame = comp
    Blur.Model = model

    return Blur
end

local New = Creator.New

local function AcrylicPaint(props)
    local AcrylicPaint = {}

    AcrylicPaint.Frame = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.9,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, { New("ImageLabel", {
        Image = "rbxassetid://8992230677",
        ScaleType = "Slice",
        SliceCenter = Rect.new(Vector2.new(99, 99), Vector2.new(99, 99)),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 120, 1, 116),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.7
    }), New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }), New("Frame", {
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
        Name = "Background",
        ThemeTag = {
            BackgroundColor3 = "AcrylicMain"
        }
    }, { New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }) }), New("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.4,
        Size = UDim2.fromScale(1, 1)
    }, { New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }), New("UIGradient", {
        Rotation = 90,
        ThemeTag = {
            Color = "AcrylicGradient"
        }
    }) }), New("ImageLabel", {
        Image = "rbxassetid://9968344105",
        ImageTransparency = 0.98,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 128, 0, 128),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1
    }, { New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }) }), New("ImageLabel", {
        Image = "rbxassetid://9968344227",
        ImageTransparency = 0.9,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 128, 0, 128),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ThemeTag = {
            ImageTransparency = "AcrylicNoise"
        }
    }, { New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }) }), New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    }, { New("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }), New("UIStroke", {
        Transparency = 0.5,
        Thickness = 1,
        ThemeTag = {
            Color = "AcrylicBorder"
        }
    }) }) })

    return AcrylicPaint
end

local Acrylic = {
    AcrylicBlur = AcrylicBlur,
    CreateAcrylic = createAcrylic,
    AcrylicPaint = AcrylicPaint
}

function Acrylic.init()
    local baseEffect = Instance.new("DepthOfFieldEffect")
    baseEffect.FarIntensity = 0
    baseEffect.InFocusRadius = 0.1
    baseEffect.NearIntensity = 1

    local depthOfFieldDefaults = {}

    function Acrylic.Enable()
        for _, effect in pairs(depthOfFieldDefaults) do
            effect.Enabled = false
        end
        baseEffect.Parent = game:GetService("Lighting")
    end

    function Acrylic.Disable()
        for _, effect in pairs(depthOfFieldDefaults) do
            effect.Enabled = effect.enabled
        end
        baseEffect.Parent = nil
    end

    local function registerDefaults()
        local function register(object)
            if object:IsA("DepthOfFieldEffect") then
                depthOfFieldDefaults[object] = {
                    enabled = object.Enabled
                }
            end
        end

        for _, child in pairs(game:GetService("Lighting"):GetChildren()) do
            register(child)
        end

        if game:GetService("Workspace").CurrentCamera then
            for _, child in pairs(game:GetService("Workspace").CurrentCamera:GetChildren()) do
                register(child)
            end
        end
    end

    registerDefaults()
    Acrylic.Enable()
end

local UDim2 = {
    new = UDim2.new,
    fromScale = UDim2.fromScale,
    fromOffset = UDim2.fromOffset,
    center = UDim2.new(0.5, 0,
        0.5, 0)
}
local anchor = Vector2.new(0.5, 0.5)
local gotham = Enum.Font.Gotham

local function CreateTopbarIcon(name, image, pos)
    return New("ImageButton", {
            Name = name,
            Image = image,
            ImageColor3 = Color3.fromRGB(206, 206, 206),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(1, 1, 15, 15),
            AnchorPoint = anchor,
            BackgroundColor3 = Color3.fromRGB(255, 12, 50),
            BackgroundTransparency = 1,
            Position = pos,
            ZIndex = 2
        },
        {
            New("UICorner", {
                CornerRadius = UDim.new(0, 3)
            })
        }
    )
end

local function CreateTween(object, time, style, property, value)
    local tween = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle[style]), {[property] = value})
    tween.Completed:Connect(function()
        tween:Destroy()
    end)

    return tween
end

local function HasProperty(object, property) -- this probably isnt the best way of doing it, but i couldnt find any object methods for doing this
    local s, r = pcall(function()
        object:GetPropertyChangedSignal(property):Connect(function ()
            
        end):Disconnect()
    end)

    return s
end

local Library = {}
Library.BuildUI = function(icon, title)
    local ScreenGui = Creator.New("ScreenGui", {
        Parent = Services.CoreGui
    }, {
        New("Frame", {
            ZIndex = 2,
            Size = UDim2.new(0, 700, 0, 500),
            Position = UDim2.center,
            BackgroundTransparency = 0.2,
            BackgroundColor3 = Color3.fromRGB(24, 26, 27),
            AnchorPoint = anchor
        }, {
            New("UICorner"),
            New("UIStroke", {
                Color = Color3.fromRGB(72, 72, 72),
                Thickness = 2
            }),
            New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 0,
                Active = true,
                AnchorPoint = anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0.5, 0, 0.55, 0),
                Size = UDim2.new(0, 670, 0, 400),
                ZIndex = 3,
                Name = "content"
            }),
            New("UIListLayout", {
                Padding = UDim2.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            New("ImageLabel", {
                Image = "rbxassetid://9886919127",
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(60, 60, 166, 166),
                AnchorPoint = anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.center,
                Size = UDim2.new(1, 110, 1, 110),
                Name = "dropshadow"
            }),
            New("ImageLabel", {
                Image = icon,
                AnchorPoint = anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0.05, 0, 0.05),
                Size = UDim2.new(0, 40, 0, 40),
                ZIndex = 2,
                Name = "logo"
            }),
            New("TextLabel", {
                Font = gotham,
                Text = title,
                TextColor3 = Color3.fromRGB(206, 206, 206),
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Left,
                AnchorPoint = center,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0.23, 0, 0.05, 0),
                Size = UDim2.new(0, 200, 0, 26),
                ZIndex = 2,
                Name = "title"
            }),
            New("TextLabel", {
                Font = gotham,
                TextColor3 = Color3.fromRGB(216, 216, 216),
                TextDirection = Enum.TextDirection.LeftToRight,
                TextSize = 16,
                TextTransparency = 1,
                AnchorPoint = anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.center,
                Size = UDim2.new(0, 200, 0, 30),
                ZIndex = 2,
                Name = "clock"
            })
        })
    })

    local Frame = ScreenGui.Frame

    local icons = {
        ['close'] = CreateTopbarIcon("close", "rbxassetid://14964754255", UDim2.new(0.97, 0, 0.05, 0)),
        ['collapse'] = CreateTopbarIcon("collapse", "rbxassetid://9886659001", UDim2.new(0.92, 0, 0.05, 0)),
        ['minimize'] = CreateTopbarIcon("minimize", "rbxassetid://9886659276", UDim2.new(0.87, 0, 0.05, 0))
    }

    for i,v in pairs(icons) do
        v.Parent = Frame
    end

    local blureffect = AcrylicBlur()
    blureffect.Parent = Frame

    local CanBeDragged = true -- <-- got this from a roblox extension
    local Delta = nil
    local Position = nil

    local dragToggle = nil
    local dragInput = nil
    local dragStart = nil
    local dragPos = nil

    local function updateInput(input)
        Delta = input.Position - dragStart
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        TweenService:Create(frame, TweenInfo.new(.025), { Position = Position }):Play()
    end
    
    Frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and CanBeDragged then
            dragToggle = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if (input.UserInputState == Enum.UserInputState.End) then
                    dragToggle = false
                end
            end)
        end
    end)
    
    Frame.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if (input == dragInput and dragToggle) then
            updateInput(input)
        end
    end)

    -- animations

    local Collapsed = false
    local Minimized = false
    local Debounce = false

    local Content = Frame.content

    local Clock = Frame.clock
    local Title = Frame.title
    local Logo = Frame.logo
    local Minimize = Frame.minimize
    local Collapse = Frame.collapse
    local Close = Frame.close

    local TopbarContents = {Logo, Title, Clock, Minimize, Collapse, Close}
    local TopbarButtons = {Minimize, Collapse, Close}

    local function RenderFrames()
        for i,v in pairs(content:GetChildren()) do
            if v:IsA("Frame") then
                task.spawn(function()
                    CreateTween(v, 0.3, 'Quart', 'BackgroundTransparency', 0):Play()

                    for _, object in pairs(v:GetDescendants()) do
                        if HasProperty(object, 'BackgroundTransparency') and v.Name == 'copy' then
                            CreateTween(object, 0.2, 'Quart', 'BackgroundTransparency', 0.5):Play()
                        end

                        if object:IsA("UIStroke") then
                            object.Enabled = true
                            object.Transparency = 0
                        elseif object:IsA("UIGradient") then
                            object.Enabled = true
                        end

                        if HasProperty(object, 'TextTransparency') then
                            CreateTween(object, 0.2, 'Quart', 'TextTransparency', 0)
                        end

                        if HasProperty(object, 'ImageTransparency') then
                            CreateTween(object, 0.2, 'Quart', 'ImageTransparency', 0)
                        end
                    end
                end)
            end
        end
    end

    local function DerenderFrames()
        for i,v in pairs(content:GetChildren()) do
            if v:IsA("Frame") then
                task.spawn(function()
                    for _, object in pairs(v:GetDescendants()) do
                        if HasProperty(object, 'ImageTransparency') then
                            CreateTween(object, 0.2, 'Quart', 'ImageTransparency', 1)
                        end

                        if HasProperty(object, 'TextTransparency') then
                            CreateTween(object, 0.2, 'Quart', 'TextTransparency', 1)
                        end

                        if object:IsA("UIStroke") then
                            object.Enabled = false
                            object.Transparency = 1
                        elseif object:IsA("UIGradient") then
                            object.Enabled = false
                        end

                        if HasProperty(object, 'BackgroundTransparency') and v.Name == 'copy' then
                            CreateTween(object, 0.2, 'Quart', 'BackgroundTransparency', 1):Play()
                        end
                    end
                    
                    wait(0.1)
                    CreateTween(v, 0.3, 'Quart', 'BackgroundTransparency', 1):Play()
                end)
            end
        end
    end

    local function RenderWindow()
        ScreenGui.Enabled = true

        blureffect:SetVisibility(1)
        CreateTween(Frame.UIStroke, 0.4, 'Quart', 'Transparency', 0):Play()
        CreateTween(Frame.dropshadow, 0.4, 'Quart', 'ImageTransparency', 0):Play()

        wait(0.2)
        CreateTween(Frame, 0.2, 'Quart', 'BackgroundTransparency', 0):Play()
        CreateTween(Frame, 0.2, 'Quart', 'Size', Frame.Size + UDim2.new(0, 10, 0, 10)):Play()

        for i,v in pairs(TopbarContents) do
            if HasProperty(v, 'TextTransparency') then
                CreateTween(v, 0.2, 'Quart', 'TextTransparency', 0):Play()
            else -- everything either has texttransparency or imagetransparency
                CreateTween(v, 0.2, 'Quart', 'ImageTransparency', 0):Play()
            end

            CreateTween(v, 0.2, 'Quart', 'BackgroundTransparency', 0)
        end

        if not Collapsed then
            RenderFrames()
        else
            CreateTween(Clock, 0.3, 'Quart', 'TextTransparency', 0)
        end
    end

    local function DerenderWindow(fullclose)
        if fullclose then
            Creator.Disconnect()
            Library.ClockLoop.close()
        end

        CreateTween(Clock, 0.3, 'Quart', 'TextTransparency', 1)

        DerenderFrames()
        CreateTween(Frame, 0.2, 'Quart', 'Size', Frame.Size - UDim2.new(0, 10, 0, 10)):Play()

        for i,v in pairs(TopbarContents) do
            if HasProperty(v, 'TextTransparency') then
                CreateTween(v, 0.2, 'Quart', 'TextTransparency', 1):Play()
            else -- everything either has texttransparency or imagetransparency
                CreateTween(v, 0.2, 'Quart', 'ImageTransparency', 1):Play()
            end

            CreateTween(v, 0.2, 'Quart', 'BackgroundTransparency', 1)
        end

        wait(0.4)
        CreateTween(Frame, 0.2, 'Quart', 'BackgroundTransparency', 1):Play()
        wait(0.2)

        blureffect:SetVisibility()
        CreateTween(Frame.dropshadow, 0.4, 'Quart', 'ImageTransparency', 1):Play()
        CreateTween(Frame.UIStroke, 0.4, 'Quart', 'Transparency', 1):Play()

        wait(0.3)
        ScreenGui.Enabled = false
    end

    local ReturnTo = nil
    local function CollapseCallback()
        Library.Interaction()

        if not Collapsed then
            ReturnTo = Frame.Position
            CanBeDragged = false

            DerenderFrames()
            wait(0.3)

            for i,v in pairs({Title, Minimize, Collapse, Close, Logo}) do
                CreateTween(v, 0.4, 'Quart', 'Position', v.Position + UDim2.new(0, 0, 0.45, 0)):Play()
            end

            CreateTween(Frame, 0.4, 'Linear', 'Position', UDim2.new(0.5, 0, 0.95, 0)):Play()
            CreateTween(Frame, 0.3, 'Quart', 'Size', UDim2.new(0, 700, 0, 50)):Play()

            wait(0.3)
            CreateTween(Frame, 0.3, 'Quart', 'Size', UDim2.new(0.5, 0, 0, 50)):Play()

            wait(0.3)

            CreateTween(Title, 0.4, 'Quart', 'Position', Title.Position + UDim2.new(0.071, 0, 0, 0)):Play()
            CreateTween(Logo, 0.4, 'Quart', 'Position', Logo.Position + UDim2.new(0.02, 0, 0, 0)):Play()

            for i,v in pairs(TopbarButtons) do
                CreateTween(v, 0.4, 'Quart', 'Position', v.Position + UDim2.new(0.015, 0, 0, 0)):Play()
            end

            CreateTween(Clock, 0.3, 'Quart', 'TextTransparency', 0):Play()
        else
            CreateTween(Clock, 0.3, 'Quart', 'TextTransparency', 1):Play()

            for i,v in pairs(TopbarButtons) do
                CreateTween(v, 0.4, 'Quart', 'Position', v.Position - UDim2.new(0.015, 0, 0, 0)):Play()
            end

            CreateTween(Title, 0.4, 'Quart', 'Position', Title.Position - UDim2.new(0.071, 0, 0, 0)):Play()
            CreateTween(Logo, 0.4, 'Quart', 'Position', Logo.Position - UDim2.new(0.02, 0, 0, 0)):Play()

            wait(0.3)
            CreateTween(Frame, 0.3, 'Quart', 'Size', UDim2.new(0, 700, 0, 500)):Play()
            CreateTween(Frame, 0.4, 'Quart', 'Position', ReturnTo):Play()

            for i,v in pairs({Title, Minimize, Collapse, Close, Logo}) do
                CreateTween(v, 0.4, 'Quart', 'Position', v.Position - UDim2.new(0, 0, 0.45, 0)):Play()
            end

            wait(0.3)
            RenderFrames()

            CanBeDragged = true
        end
    end

    local function MinimizeCallback()
        Library.Interaction()

        DerenderWindow()
        Library.BuildNotif('UI Toggled', 'Press right control to re-open the UI.')
    end

    Creator.AddSignal(Close.MouseButton1Click, function()
        if Debounce then return end
        Debounce = true

        DerenderWindow(true)
        Debounce = false
    end)

    Creator.AddSignal(Minimize.MouseButton1Click, function()
        if Debounce then return end
        Debounce = true

        MinimizeCallback()
        Debounce = false
    end)

    Creator.AddSignal(Collapse.MouseButton1Click, function()
        if Debounce then return end
        Debounce = true

        CollapseCallback()
        Debounce = false
    end)

    Creator.AddSignal(UserInputService.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            if Minimized then
                if Debounce then return end
                Debounce = true

                RenderWindow()
                Minimized = false
                Debounce = false
            end
        end
    end)

    for i,v in pairs(TopbarButtons) do
        Creator.AddSignal(v.MouseEnter, function()
            CreateTween(v, 0.2, 'Quart', 'ImageColor3', Color3.fromRGB(255, 255, 255)):Play()
            CreateTween(v, 0.2, 'Quart', 'BackgroundTransparency', 0.5):Play()
        end)

        Creator.AddSignal(v.MouseLeave, function()
            CreateTween(v, 0.2, 'Quart', 'ImageColor3', Color3.fromRGB(206, 206, 206)):Play()
            CreateTween(v, 0.2, 'Quart', 'BackgroundTransparency', 1):Play()
        end)
    end

    return ScreenGui
end

Library.Interaction = function()
    CreateTween(Library.Main.Frame, 0.2, 'Quart', 'Size', Library.Main.Frame.Size + UDim2.new(0, 10, 0, 10)):Play()
    wait(0.2)
    CreateTween(Library.Main.Frame, 0.2, 'Quart', 'Size', Library.Main.Frame.Size - UDim2.new(0, 10, 0, 10)):Play()
end

local format = string.format
local copy = setclipboard or copyclipboard or print

local NumLogs = 0 -- for the slight transparency at the top of the first log
Library.BuildLog = function(url, method, flagged, sent, received)
    local log = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 48),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.center,
        Size = UDim2.new(0, 658, 0, 98),
        Visible = true,
        ZIndex = 2,
        Name = "logframe"
    }, {
        New("UICorner"),
        New("UIGradient", {
            Enabled = false,
            Rotation = -90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.9, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Name = "UIGradientTop"
        }),
        New("UIStroke", {
            Color = Color3.fromRGB(84, 86, 90)
        }, {
            New("UIGradient", {
                Enabled = false,
                Rotation = -90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.9, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Name = "UIGradientTop"
            })
        }),
        New("TextLabel", {
            Font = gotham,
            Text = url,
            TextColor3 = Color3.fromRGB(206, 207, 207),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.01, 0, 0.09, 0),
            Size = UDim2.new(0, 400, 0, 24),
            ZIndex = 2,
            Name = "url",
            TextTruncate = 1
        }),
        New("TextLabel", {
            Font = gotham,
            Text = format("Method: %s", method),
            TextColor3 = Color3.fromRGB(177, 177, 177),
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.01, 0, 0.3, 0),
            Size = UDim2.new(0, 611, 0, 19),
            ZIndex = 2,
            Name = "method"
        }),
        New("TextLabel", {
            Font = gotham,
            Text = format("Flagged: %s", flagged),
            TextColor3 = Color3.fromRGB(177, 177, 177),
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.01, 0, 0.3, 0),
            Size = UDim2.new(0, 611, 0, 19),
            ZIndex = 2,
            Name = "flagged"
        }),
        New("TextLabel", {
            Font = gotham,
            Text = "Received",
            TextColor3 = Color.fromRGB(206, 207, 207),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.86, 0, 0.12, 0),
            Size = UDim2.new(0, 80, 0, 20),
            ZIndex = 2,
            Name = "received"
        },{
            New("ImageButton", {
                Image = "rbxassetid://13739190982",
                ImageColor3 = Color3.fromRGB(224, 224, 225),
                BackgroundColor3 = Color3.fromRGB(49, 52, 59),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(-0.47, 0, -0.34, 0),
                Size = UDim2.new(0, 30, 0, 30),
                ZIndex = 2,
                Name = "copy"
            }),
            New("UICorner", {
                CornerRadius = UDim.new(0, 3)
            }),
            New("UIStroke", {
                Color = Color3.fromRGB(84, 86, 90)
            })
        }),
        New("TextLabel", {
            Font = gotham,
            Text = "Sent",
            TextColor3 = Color.fromRGB(206, 207, 207),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.86, 0, 0.5, 0),
            Size = UDim2.new(0, 80, 0, 20),
            ZIndex = 2,
            Name = "sent"
        },{
            New("ImageButton", {
                Image = "rbxassetid://13739190982",
                ImageColor3 = Color3.fromRGB(224, 224, 225),
                BackgroundColor3 = Color3.fromRGB(49, 52, 59),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(-0.47, 0, -0.34, 0),
                Size = UDim2.new(0, 30, 0, 30),
                ZIndex = 2,
                Name = "copy"
            }),
            New("UICorner", {
                CornerRadius = UDim.new(0, 3)
            }),
            New("UIStroke", {
                Color = Color3.fromRGB(84, 86, 90)
            })
        })
    })

    Creator.AddSignal(log.sent.copy.MouseButton1Click, function()
        copy(sent)
    end)

    Creator.AddSignal(log.received.copy.MouseButton1Click, function()
        copy(received)
    end)

    NumLogs = NumLogs + 1

    if NumLogs == 1 then -- i know this is a really shitty way of doing it, but i cant be bothered to do it properly
        local Gradient1, Gradient2 = log.UIGradientTop, log.UIStroke.UIGradientTop
        Gradient1.Enabled = true
        Gradient2.Enabled = true
    else
        log.UIGradientTop:Destroy()
        log.UIStroke.UIGradientTop:Destroy()
    end

    for _, object in pairs(log:GetDescendants()) do
        if HasProperty(object, 'ImageTransparency') then
            object.ImageTransparency = 1
        end

        if HasProperty(object, 'TextTransparency') then
            object.TextTransparency = 1
        end
    end

    log.BackgroundTransparency = 1
    log.Parent = Library.Main.Frame.content

    CreateTween(log, 0.5, 'Qart', 'BackgroundTransparency', 0.2):Play()
    for _, object in pairs(log:GetDescendants()) do
        if HasProperty(object, 'ImageTransparency') then
            CreateTween(object, 0.3, 'Quart', 'ImageTransparency', 0):Play()
        end

        if HasProperty(object, 'TextTransparency') then
            CreateTween(object, 0.3, 'Quart', 'TextTransparency', 0):Play()
        end
    end

    return log
end

Library.BuildNotif = function(title, contents)
    local notification = New("Frame", {
        AnchorPoint = anchor,
        BackgroundColor3 = Color3.fromRGB(32, 34, 36),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(0.9, 0, 0.9, 0),
        Size = UDim2.new(0, 250, 0, 90),
        Visible = true,
        Name = "notification"
    },{
        New("UICorner"),
        New("UIStroke", {
            Color = Color3.fromRGB(72, 72, 72),
            Thickness = 2
        }),
        New("ImageLabel", {
            Image = "rbxassetid://9886919127",
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(60, 60, 166, 166),
            AnchorPoint = anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.center,
            Size = UDim2.new(1, 110, 1, 110),
            Name = "dropshadow"
        }),
        New("TextLabel", {
            Font = gotham,
            Text = title,
            TextColor3 = Color3.fromRGB(206, 206, 206),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.43, 0, 0.21, 0),
            Size = UDim2.new(0, 200, 0, 26),
            ZIndex = 2,
            Name = "title"
        }),
        New("TextLabel", {
            Font = gotham,
            Text = contents,
            TextColor3 = Color3.fromRGB(177, 177, 177),
            TextSize = 14,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.03, 0, 0.35, 0),
            Size = UDim2.new(0, 235, 0, 50),
            ZIndex = 2,
            Name = "description"
        })
    })

    notification.BackgroundTransparency = 1
    for _, object in pairs(notification:GetDescendants()) do
        if HasProperty(object, 'ImageTransparency') then
            object.ImageTransparency = 1
        end

        if HasProperty(object, 'TextTransparency') then
            object.TextTransparency = 1
        end

        if HasProperty(object, 'Transparency') then
            object.Transparency = 1
        end
    end

    task.spawn(function()
        CreateTween(notification, 0.3, 'Quart', 'BackgroundTransparency', 0.2):Play()
        wait(0.1)

        for _, object in pairs(notification:GetDescendants()) do
            if HasProperty(object, 'ImageTransparency') then
                object.ImageTransparency = 0
            end
    
            if HasProperty(object, 'TextTransparency') then
                object.TextTransparency = 0
            end
    
            if HasProperty(object, 'Transparency') then
                object.Transparency = 0
            end
        end

        task.delay(4, function()
            for _, object in pairs(notification:GetDescendants()) do
                if HasProperty(object, 'ImageTransparency') then
                    object.ImageTransparency = 1
                end
        
                if HasProperty(object, 'TextTransparency') then
                    object.TextTransparency = 1
                end
        
                if HasProperty(object, 'Transparency') then
                    object.Transparency = 1
                end
            end

            wait(0.1)
            CreateTween(notification, 0.3, 'Quart', 'BackgroundTransparency', 1):Play()
        end)
    end)

    return notification
end

Library.init = function()
    Library.Main = Library.BuildUI()
    Library.ClockLoop = task.spawn(function()
        while wait(1) do
            Library.Main.Frame.clock.Text = os.date("%x, %I:%M %p")
        end
    end)

    return Library
end

return Library
