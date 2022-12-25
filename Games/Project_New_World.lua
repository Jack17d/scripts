--------------------------------------------------------------- BACK-END ---------------------------------------------------------------
local TTeleporter = loadstring(game:HttpGet("https://raw.githubusercontent.com/z4gs/scripts/master/TTeleporter.lua"))()(300)

local plr = game:GetService("Players").LocalPlayer
local plrData = plr.PlayerData
local serverStorage = game:GetService("ServerStorage")
local questRemote = plr.PlayerGui.QuestGui.QuestFunction
local questFolder = plr.Quest

local options = {
    Farm = false,
    BestQuest = false,
    HideName = false,
    InfDash = false,
    InfGeppo = false,
    TPFruit = false,
    QuestSelected = nil,
    QuestLevelSelected = nil,
    QuestOptions = nil,
    QuestGivers = {}
}

-- INITIALIZATION

for i,v in pairs(workspace.Npc_Workspace.QuestGivers:GetChildren()) do
    if v:FindFirstChild(v.Name) then
        table.insert(options.QuestGivers, {
            id = v.Name,
            npc = v:FindFirstChild(v.Name)
        })
    else 
        for i2,v2 in pairs(serverStorage.Npc_Workspace:GetChildren()) do
            if v2.Name == v.Name and v2:FindFirstChild("Configuration") then
                table.insert(options.QuestGivers, {
                    id = v2.Name,
                    npc = v2
                })
            end
        end
    end
end

do 
    local old

    old = hookmetamethod(game, "__namecall", function(obj, ...)
        local method = getnamecallmethod()

        if method == "InvokeServer" or method == "invokeServer" then
            if options.InfDash and obj.Name == "Dash" then
                return
            elseif options.InfGeppo and obj.Name == "Geppo" then
                return
            end
        end

        return old(obj, ...)
    end)
end

local function getQuest()
    if questFolder.NPCName.Value == "" and questFolder.Progress.Value == questFolder.Target.Value then
        questRemote:InvokeServer(options.QuestSelected, options.QuestLevelSelected.Name)
    end
end

local function setBestQuest()
    local oldlvl = -1

    for i,v in pairs(options.QuestGivers) do
        for i2,v2 in pairs(v.npc.Configuration.Quests:GetChildren()) do
            local questLvl = tonumber(v2.Name:split(" ")[2])
            
            if questLvl > oldlvl and plrData.Experience.Level.Value >= questLvl then
                oldlvl = questLvl
                options.QuestSelected = v.npc
                options.QuestLevelSelected = v2
            end
        end
    end

    print(options.QuestSelected, options.QuestLevelSelected)
end

local function getNpc()
    for i,v in pairs(workspace["NPC Zones"]:GetDescendants()) do
        if v.Name:gsub("%d*$", "") == questFolder.NPCName.Value and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end

    for i,v in pairs(serverStorage["NPC Zones"]:GetDescendants()) do
        if v.Name:gsub("%d*$", "") == questFolder.NPCName.Value and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end
end

local function autoFarm()
    while options.Farm do
        local npc = getNpc()
        
        if options.BestQuest then
            setBestQuest()
        end

        getQuest()

        if npc then
            while options.Farm and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and npc.Humanoid.Health > 0 do
                TTeleporter:Teleport(plr.Character.HumanoidRootPart, npc.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90),0,0) + Vector3.new(0,-6.5,0) , 200)
                
                if plr.Backpack:FindFirstChild("Combat") then
                    plr.Backpack.Combat.Parent = plr.Character
                    plr.Character:WaitForChild("Combat")
                end

                plr.Character.Combat.Punch:FireServer(math.random(1,4))
                
                task.wait()
            end
        end

        wait()
    end
end

--------------------------------------------------------------- FRONT-END ---------------------------------------------------------------
local win = loadstring(game:HttpGet("https://raw.githubusercontent.com/z4gs/scripts/master/solarisUI.lua"))():New({
    Name = "Project New World",
    FolderToSave = "Project New World294382149"
})

-- TABS
local mainTab = win:Tab("Main")
local miscTab = win:Tab("Misc")

-- SECTIONS
local mainSection = mainTab:Section("Main")
local miscSection = miscTab:Section("Misc")

local questLevelSelectionDropdown

mainSection:Dropdown("Quest", 
(function()
    local tbl = {}

    for i,v in pairs(options.QuestGivers) do
        table.insert(tbl, v.id.." - "..v.npc.DisplayName.Value:split("|")[1])
    end

    table.sort(tbl, function(a, b)
        local first = tonumber(a:split(" - ")[1])
        local second = tonumber(b:split(" - ")[1])

        return first < second
    end)
    
    return tbl
end)(), false, nil, function(opt)
    local selectedOpt = opt:split(" - ")[1]

    for i,v in pairs(options.QuestGivers) do
        if selectedOpt == v.id then
            options.QuestSelected = v.npc
            options.QuestOptions = v.npc.Configuration.Quests

            local tbl = {}

            for i2,v2 in pairs(options.QuestOptions:GetChildren()) do
                table.insert(tbl, v2.Name:gsub("%D", "").." - "..v2:FindFirstChildOfClass("Folder").Name)
            end

            table.sort(tbl, function(a, b) 
                local first = tonumber(a:split(" - ")[1])
                local second = tonumber(b:split(" - ")[1])
        
                return first < second
            end)

            questLevelSelectionDropdown:Refresh(tbl, true)

            break
        end
    end
end)

questLevelSelectionDropdown = mainSection:Dropdown("Quest Level", {}, false, nil, function(opt)
    options.QuestLevelSelected = options.QuestOptions["Level "..opt:split(" - ")[1]]
end)

mainSection:Toggle("Get best quest", false, "Toggle", function(opt)
    options.BestQuest = opt
end)

mainSection:Toggle("Farm", false, "Toggle", function(opt)
    options.Farm = opt
    autoFarm()
end)

miscSection:Toggle("Hide name", false, "Toggle", function(opt)
    options.HideName = opt

    while options.HideName do
        local tag = plr.Character:FindFirstChild("TopHead")

        if tag then
            tag:Destroy()
        end

        wait()
    end
end)

miscSection:Toggle("TP to fruits", false, "Toggle", function(opt)
    options.TPFruit = opt

    while options.TPFruit do
        local fruit = workspace:FindFirstChildOfClass("Tool")
        
        if fruit then
            plr.Character.HumanoidRootPart.CFrame = fruit.Handle.CFrame * CFrame.new(0,3,0)
            fireproximityprompt(fruit.Handle.ProximityPrompt)
        end

        task.wait()
    end
end)

miscSection:Toggle("Dash no stamina drain", false, "Toggle", function(opt)
    options.InfDash = opt
end)

miscSection:Toggle("Geppo no stamina drain", false, "Toggle", function(opt)
    options.InfGeppo = opt
end)
