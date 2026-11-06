local ok,src=pcall(function()
    return game:HttpGet"https://raw.githubusercontent.com/nonfq/BitchBot-UiLibrary/main/main.luau"
end)
assert(ok and type(src)=="string"and#src>1000,"Could not download the UI library from: https://raw.githubusercontent.com/nonfq/BitchBot-UiLibrary/main/main.luau")
local chunk,err=loadstring(src)
assert(chunk,"Library failed to compile: "..tostring(err))
local Lib=chunk{
    Name="justlocklol",
    ToggleKey=Enum.KeyCode.LeftAlt
}
local Players=game:GetService"Players"
local RunService=game:GetService"RunService"
local UserInputService=game:GetService"UserInputService"
local Workspace=game:GetService"Workspace"
local CoreGui=game:GetService"CoreGui"
local HttpService=game:GetService"HttpService"
local LocalPlayer=Players.LocalPlayer
local env=(getgenv and getgenv())or _G
local moveRel=mousemoverel or env.mousemoverel
local moveAbs=mousemoveabs or env.mousemoveabs
local hasDrawing=type(Drawing)=="table"and Drawing.new~=nil
local canSave=writefile~=nil and readfile~=nil and isfile~=nil
local cfg={}
local controls={}
if canSave then
    pcall(function()
        if isfile"justlocklol/config.json"then
            local data=HttpService:JSONDecode(readfile"justlocklol/config.json")
            if type(data)=="table"then
                cfg=data
            end
        end
    end)
end
local function toRGB(c)
    return{
        math.floor(c.R*255+0.5),
        math.floor(c.G*255+0.5),
        math.floor(c.B*255+0.5)
    }
end
local function parseKey(t)
    if type(t)=="table"and t[1]and t[2]then
        local okK,v=pcall(function()
            return Enum[t[1]][t[2]]
        end)
        if okK and v then
            return v
        end
    end
    return nil
end
local function copy(t)
    local out={}
    for k,v in pairs(t)do
        out[k]=v
    end
    return out
end
local function newToggle(group,key,name,default,opts)
    opts=opts or{}
    local o=copy(opts)
    local def=default
    local s=cfg[key]
    if type(s)=="table"then
        if s.on~=nil then
            def=s.on
        end
        if type(s.color)=="table"and o.Color then
            o.Color=s.color
        end
        if type(s.colors)=="table"and o.Colors then
            o.Colors=s.colors
        end
        if o.Keybind and s.key then
            local kc=parseKey(s.key)
            if kc then
                o.Keybind=kc
            end
        end
    end
    local h=group:AddToggle(name,def,o)
    controls[#controls+1]={
        key=key,
        kind="toggle",
        h=h,
        hasColor=opts.Color~=nil,
        hasColors=opts.Colors~=nil,
        hasKey=opts.Keybind~=nil
    }
    return h
end
local function newSlider(group,key,name,start,min,max,opts)
    local s=tonumber(cfg[key])
    if s then
        start=math.clamp(s,min,max)
    end
    local h=group:AddSlider(name,start,min,max,opts)
    controls[#controls+1]={
        key=key,
        kind="slider",
        h=h
    }
    return h
end
local function newDropdown(group,key,name,list,default)
    local i=tonumber(cfg[key])
    if i and i>=1 and i<=#list then
        default=math.floor(i)
    end
    local h=group:AddDropdown(name,list,default)
    controls[#controls+1]={
        key=key,
        kind="dropdown",
        h=h
    }
    return h
end
local function newMulti(group,key,name,entries)
    local saved=cfg[key]
    local list={}
    for _,e in ipairs(entries)do
        local on=e[2]
        if type(saved)=="table"and saved[e[1]]~=nil then
            on=saved[e[1]]
        end
        list[#list+1]={
            e[1],
            on
        }
    end
    local h=group:AddMultiDropdown(name,list)
    controls[#controls+1]={
        key=key,
        kind="multi",
        h=h
    }
    return h
end
local function snapshot()
    local out={}
    for _,c in ipairs(controls)do
        local okC,val=pcall(function()
            if c.kind=="toggle"then
                local v={
                    on=c.h:Get()
                }
                if c.hasColor then
                    v.color=toRGB(c.h:GetColor3())
                end
                if c.hasColors then
                    v.colors={
                        toRGB(c.h:GetColor3(1)),
                        toRGB(c.h:GetColor3(2))
                    }
                end
                if c.hasKey then
                    local k=c.h:GetKeybind()
                    if typeof(k)=="EnumItem"then
                        v.key={
                            tostring(k.EnumType),
                            k.Name
                        }
                    elseif type(k)=="string"and k~=""then
                        v.key={
                            "KeyCode",
                            k
                        }
                    end
                end
                return v
            elseif c.kind=="multi"then
                return c.h:GetTable()
            end
            return c.h:Get()
        end)
        if okC and val~=nil then
            out[c.key]=val
        end
    end
    return out
end
local lastSaved=nil
local function saveConfig(force)
    if not canSave then
        return false
    end
    local okE,enc=pcall(function()
        return HttpService:JSONEncode(snapshot())
    end)
    if not okE then
        return false
    end
    if not force and enc==lastSaved then
        return true
    end
    local okW=pcall(function()
        if makefolder and isfolder and not isfolder"justlocklol"then
            makefolder"justlocklol"
        end
        writefile("justlocklol/config.json",enc)
    end)
    if okW then
        lastSaved=enc
    end
    return okW
end
local Tab=Lib:AddTab"Aimlock"
local Main=Tab:AddGroup("Aimlock","left")
local enabled=newToggle(Main,"aim_enabled","Enabled",true,{
    Keybind=true,
    KeybindMode="Hold"
})
local aimKey=newDropdown(Main,"aim_key","Aim Key",{
    "Keybind",
    "Right Mouse",
    "Left Mouse",
    "Q",
    "E",
    "Left Shift",
    "Always On"
},2)
local priority=newMulti(Main,"aim_priority","Lock Priority",{
    {
        "Closest",
        true
    },
    {
        "Distance",
        false
    }
})
local targetPart=newDropdown(Main,"aim_part","Target Part",{
    "Head",
    "Torso",
    "Closest Part"
},1)
local smoothness=newSlider(Main,"aim_smooth","Smoothness",5,1,30,{
    Custom={
        [1]="Instant"
    }
})
local fovSlider=newSlider(Main,"aim_fov","FOV Radius",300,20,1000,{
    Suffix="px"
})
local method=newDropdown(Main,"aim_method","Move Method",{
    "mousemoverel",
    "mousemoveabs"
},1)
local Checks=Tab:AddGroup("Checks","right")
local teamCheck=newToggle(Checks,"aim_team","Team Check",true)
local wallCheck=newToggle(Checks,"aim_wall","Wall Check",true)
local aliveCheck=newToggle(Checks,"aim_alive","Alive Check",true)
local stickyToggle=newToggle(Checks,"aim_sticky","Sticky Target",false)
local autoSwitch=newToggle(Checks,"aim_autoswitch","Auto Switch",true)
local Visuals=Tab:AddGroup("Visuals","right")
local fovToggle=newToggle(Visuals,"fov_show","Show FOV Circle",true,{
    Color={
        160,
        90,
        255
    },
    ColorName="Circle"
})
local fovTeamColor=newToggle(Visuals,"fov_team","FOV Team Color",false)
local Config=Tab:AddGroup("Config","left")
local autoSave=newToggle(Config,"cfg_autosave","Auto Save",true)
Config:AddButton("Save Now",function()
    if saveConfig(true)then
        Lib:Notify"Config saved to justlocklol/config.json"
    else
        Lib:Notify"Could not save: your executor has no file functions."
    end
end)
Config:AddButton("Test Mouse Move",function()
    if method:GetText()=="mousemoverel"and moveRel then
        moveRel(120,0)
        Lib:Notify"Sent mousemoverel(120, 0) - did the cursor move right?"
    elseif moveAbs then
        local p=UserInputService:GetMouseLocation()
        moveAbs(p.X+120,p.Y)
        Lib:Notify"Sent mousemoveabs - did the cursor move right?"
    else
        Lib:Notify"Your executor has no mouse move function for this method."
    end
end)
local EspTab=Lib:AddTab"ESP"
local EspMain=EspTab:AddGroup("ESP","left")
local espEnabled=newToggle(EspMain,"esp_enabled","Enable ESP",false)
local espTeam=newToggle(EspMain,"esp_team","Team Check",true)
local espTeamColor=newToggle(EspMain,"esp_teamcolors","Team Colors",true)
local espBoxes=newToggle(EspMain,"esp_boxes","Boxes",true,{
    Color={
        160,
        90,
        255
    },
    ColorName="Box"
})
local espSkeletons=newToggle(EspMain,"esp_skeletons","Skeletons",false,{
    Color={
        255,
        255,
        255
    },
    ColorName="Skeleton"
})
local espChams=newToggle(EspMain,"esp_chams","Chams",false,{
    Colors={
        {
            160,
            90,
            255
        },
        {
            255,
            255,
            255
        }
    },
    ColorNames={
        "Fill",
        "Outline"
    }
})
local EspInfo=EspTab:AddGroup("Info","right")
local espHealth=newToggle(EspInfo,"esp_health","Health",true)
local espName=newToggle(EspInfo,"esp_name","Name",true,{
    Color={
        255,
        255,
        255
    },
    ColorName="Name"
})
local espDistance=newToggle(EspInfo,"esp_distance","Distance",true,{
    Color={
        200,
        200,
        200
    },
    ColorName="Distance"
})
local espTracers=newToggle(EspInfo,"esp_tracers","Tracers",false,{
    Color={
        160,
        90,
        255
    },
    ColorName="Tracer"
})
local tracerOrigin=newDropdown(EspInfo,"esp_tracer_origin","Tracer Origin",{
    "Bottom",
    "Center",
    "Mouse"
},1)
local TrigTab=Lib:AddTab"Trigger Bot"
local TrigMain=TrigTab:AddGroup("Trigger Bot","left")
local trigEnabled=newToggle(TrigMain,"trig_enabled","Enable Trigger Bot",false)
local trigDelay=newSlider(TrigMain,"trig_delay","Delay",40,0,500,{
    Suffix="ms"
})
local trigRate=newSlider(TrigMain,"trig_rate","Fire Rate",90,0,500,{
    Suffix="ms"
})
local trigTeam=newToggle(TrigMain,"trig_team","Team Check",true)
local trigNeedKey=newToggle(TrigMain,"trig_needkey","Require Aim Key",false)
Lib:Show()
if not moveRel and not moveAbs then
    Lib:Notify"No mousemoverel/mousemoveabs found in your executor."
end
if not hasDrawing then
    Lib:Notify"Drawing library missing: only Chams will work in the ESP tab."
end
if not canSave then
    Lib:Notify"No file functions found: Auto Save is unavailable."
end
local fovCircle
if hasDrawing then
    fovCircle=Drawing.new"Circle"
    fovCircle.Thickness=1
    fovCircle.NumSides=64
    fovCircle.Filled=false
    fovCircle.Visible=false
end
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater=true
local lockedPlayer
local stickyLost=false
local remX,remY=0,0
local function dropdownKeyHeld()
    local k=aimKey:GetText()
    if k=="Right Mouse"then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif k=="Left Mouse"then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif k=="Q"then
        return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif k=="E"then
        return UserInputService:IsKeyDown(Enum.KeyCode.E)
    elseif k=="Left Shift"then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    end
    return true
end
local function keybindActive()
    local okA,active=pcall(function()
        return enabled:IsKeyActive()
    end)
    return okA and active==true
end
local function lockKeyActive()
    if aimKey:GetText()=="Keybind"then
        return keybindActive()
    end
    return dropdownKeyHeld()
end
local function getAimPart(char,mousePos,camera)
    local mode=targetPart:GetText()
    if mode=="Head"then
        return char:FindFirstChild"Head"
    elseif mode=="Torso"then
        return char:FindFirstChild"HumanoidRootPart"or char:FindFirstChild"UpperTorso"or char:FindFirstChild"Torso"
    end
    local best,bestDist
    for _,p in ipairs(char:GetChildren())do
        if p:IsA"BasePart"then
            local sp,on=camera:WorldToViewportPoint(p.Position)
            if on then
                local d=(Vector2.new(sp.X,sp.Y)-mousePos).Magnitude
                if not bestDist or d<bestDist then
                    best,bestDist=p,d
                end
            end
        end
    end
    return best
end
local function isValid(plr,camera,mousePos,ignoreFov)
    if plr==LocalPlayer then
        return nil
    end
    local char=plr.Character
    if not char then
        return nil
    end
    local hum=char:FindFirstChildOfClass"Humanoid"
    if aliveCheck:Get()and(not hum or hum.Health<=0)then
        return nil
    end
    if teamCheck:Get()and plr.Team~=nil and plr.Team==LocalPlayer.Team then
        return nil
    end
    local part=getAimPart(char,mousePos,camera)
    if not part then
        return nil
    end
    local sp,onScreen=camera:WorldToViewportPoint(part.Position)
    if not onScreen or sp.Z<=0 then
        return nil
    end
    local screenPos=Vector2.new(sp.X,sp.Y)
    local dist=(screenPos-mousePos).Magnitude
    if not ignoreFov and dist>fovSlider:Get()then
        return nil
    end
    if wallCheck:Get()then
        local filter={
            char
        }
        if LocalPlayer.Character then
            table.insert(filter,LocalPlayer.Character)
        end
        rayParams.FilterDescendantsInstances=filter
        local origin=camera.CFrame.Position
        if Workspace:Raycast(origin,part.Position-origin,rayParams)then
            return nil
        end
    end
    return part,screenPos,dist
end
local function findTarget(camera,mousePos)
    local sel=priority:GetTable()
    local useClosest=sel.Closest==true
    local useDistance=sel.Distance==true
    if not useClosest and not useDistance then
        useClosest=true
    end
    local fov=math.max(fovSlider:Get(),1)
    local bestPlr,bestScore
    for _,plr in ipairs(Players:GetPlayers())do
        local okV,part,_,screenDist=pcall(isValid,plr,camera,mousePos,false)
        if okV and part then
            local score=0
            if useClosest then
                score=score+screenDist/fov
            end
            if useDistance then
                score=score+(camera.CFrame.Position-part.Position).Magnitude/300
            end
            if not bestScore or score<bestScore then
                bestPlr,bestScore=plr,score
            end
        end
    end
    return bestPlr
end
local function moveMouse(dx,dy,mousePos)
    if method:GetText()=="mousemoverel"and moveRel then
        remX=remX+dx
        remY=remY+dy
        local ix=remX>=0 and math.floor(remX)or math.ceil(remX)
        local iy=remY>=0 and math.floor(remY)or math.ceil(remY)
        remX=remX-ix
        remY=remY-iy
        if ix~=0 or iy~=0 then
            moveRel(ix,iy)
        end
    elseif moveAbs then
        moveAbs(mousePos.X+dx,mousePos.Y+dy)
    end
end
local function step()
    local camera=Workspace.CurrentCamera
    if not camera then
        return
    end
    local mousePos=UserInputService:GetMouseLocation()
    local active=enabled:Get()and lockKeyActive()
    if fovCircle then
        fovCircle.Visible=fovToggle:Get()and enabled:Get()
        if fovCircle.Visible then
            fovCircle.Position=mousePos
            fovCircle.Radius=fovSlider:Get()
            if fovTeamColor:Get()and LocalPlayer.Team~=nil then
                fovCircle.Color=LocalPlayer.TeamColor.Color
            else
                fovCircle.Color=fovToggle:GetColor3()
            end
        end
    end
    if not active then
        lockedPlayer=nil
        stickyLost=false
        remX,remY=0,0
        return
    end
    local part,screenPos
    if stickyToggle:Get()then
        if lockedPlayer then
            local okV,p,sp=pcall(isValid,lockedPlayer,camera,mousePos,true)
            if okV and p then
                part,screenPos=p,sp
            else
                lockedPlayer=nil
                if not autoSwitch:Get()then
                    stickyLost=true
                end
            end
        end
        if not lockedPlayer and not stickyLost then
            lockedPlayer=findTarget(camera,mousePos)
        end
    else
        lockedPlayer=findTarget(camera,mousePos)
    end
    if lockedPlayer and not part then
        local okV,p,sp=pcall(isValid,lockedPlayer,camera,mousePos,true)
        if okV and p then
            part,screenPos=p,sp
        end
    end
    if not(part and screenPos)then
        return
    end
    local s=math.max(smoothness:Get(),1)
    local delta=screenPos-mousePos
    moveMouse(delta.X/s,delta.Y/s,mousePos)
end
local BLACK=Color3.new(0,0,0)
local RED=Color3.fromRGB(255,60,60)
local GREEN=Color3.fromRGB(60,255,90)
local R15_BONES={
    {
        "Head",
        "UpperTorso"
    },
    {
        "UpperTorso",
        "LowerTorso"
    },
    {
        "UpperTorso",
        "LeftUpperArm"
    },
    {
        "LeftUpperArm",
        "LeftLowerArm"
    },
    {
        "LeftLowerArm",
        "LeftHand"
    },
    {
        "UpperTorso",
        "RightUpperArm"
    },
    {
        "RightUpperArm",
        "RightLowerArm"
    },
    {
        "RightLowerArm",
        "RightHand"
    },
    {
        "LowerTorso",
        "LeftUpperLeg"
    },
    {
        "LeftUpperLeg",
        "LeftLowerLeg"
    },
    {
        "LeftLowerLeg",
        "LeftFoot"
    },
    {
        "LowerTorso",
        "RightUpperLeg"
    },
    {
        "RightUpperLeg",
        "RightLowerLeg"
    },
    {
        "RightLowerLeg",
        "RightFoot"
    }
}
local R6_BONES={
    {
        "Head",
        "Torso"
    },
    {
        "Torso",
        "Left Arm"
    },
    {
        "Torso",
        "Right Arm"
    },
    {
        "Torso",
        "Left Leg"
    },
    {
        "Torso",
        "Right Leg"
    }
}
local espObjects={}
local function newDraw(kind,props)
    local d=Drawing.new(kind)
    for k,v in pairs(props)do
        d[k]=v
    end
    return d
end
local function createEsp(plr)
    local o={
        Skeleton={}
    }
    if hasDrawing then
        o.BoxOutline=newDraw("Square",{
            Thickness=3,
            Filled=false,
            Color=BLACK,
            Visible=false
        })
        o.Box=newDraw("Square",{
            Thickness=1,
            Filled=false,
            Visible=false
        })
        o.HealthOutline=newDraw("Line",{
            Thickness=4,
            Color=BLACK,
            Visible=false
        })
        o.Health=newDraw("Line",{
            Thickness=2,
            Visible=false
        })
        o.Name=newDraw("Text",{
            Size=13,
            Center=true,
            Outline=true,
            Visible=false
        })
        o.Distance=newDraw("Text",{
            Size=13,
            Center=true,
            Outline=true,
            Visible=false
        })
        o.Tracer=newDraw("Line",{
            Thickness=1,
            Visible=false
        })
        for i=1,#R15_BONES do
            o.Skeleton[i]=newDraw("Line",{
                Thickness=1,
                Visible=false
            })
        end
    end
    espObjects[plr]=o
    return o
end
local function hideDrawings(o)
    if not hasDrawing then
        return
    end
    o.BoxOutline.Visible=false
    o.Box.Visible=false
    o.HealthOutline.Visible=false
    o.Health.Visible=false
    o.Name.Visible=false
    o.Distance.Visible=false
    o.Tracer.Visible=false
    for _,line in ipairs(o.Skeleton)do
        line.Visible=false
    end
end
local function hideEsp(o)
    hideDrawings(o)
    if o.Highlight then
        o.Highlight.Enabled=false
    end
end
local function removeEsp(plr)
    local o=espObjects[plr]
    if not o then
        return
    end
    espObjects[plr]=nil
    for key,obj in pairs(o)do
        if key=="Skeleton"then
            for _,line in ipairs(obj)do
                pcall(function()
                    line:Remove()
                end)
            end
        elseif key=="Highlight"then
            pcall(function()
                obj:Destroy()
            end)
        else
            pcall(function()
                obj:Remove()
            end)
        end
    end
end
local function espColor(plr,toggle,index)
    if espTeamColor:Get()and plr.Team~=nil then
        return plr.TeamColor.Color
    end
    return toggle:GetColor3(index)
end
local function ensureHighlight(o,char,plr)
    if not o.Highlight or o.Highlight.Parent==nil then
        local h=Instance.new"Highlight"
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency=0.5
        h.OutlineTransparency=0
        pcall(function()
            h.Parent=(gethui and gethui())or CoreGui
        end)
        o.Highlight=h
    end
    local h=o.Highlight
    h.Adornee=char
    h.FillColor=espColor(plr,espChams,1)
    h.OutlineColor=espChams:GetColor3(2)
    h.Enabled=true
end
local function updatePlayerEsp(plr,o,camera,mousePos)
    local char=plr.Character
    local hum=char and char:FindFirstChildOfClass"Humanoid"
    local root=char and char:FindFirstChild"HumanoidRootPart"
    local show=espEnabled:Get()and hum~=nil and root~=nil and hum.Health>0
    if show and espTeam:Get()and plr.Team~=nil and plr.Team==LocalPlayer.Team then
        show=false
    end
    if not show then
        hideEsp(o)
        return
    end
    if espChams:Get()then
        ensureHighlight(o,char,plr)
    elseif o.Highlight then
        o.Highlight.Enabled=false
    end
    if not hasDrawing then
        return
    end
    local rootSp=camera:WorldToViewportPoint(root.Position)
    if rootSp.Z<=0 then
        hideDrawings(o)
        return
    end
    local head=char:FindFirstChild"Head"
    local headTop=head and(head.Position+Vector3.new(0,head.Size.Y/2+0.15,0))or(root.Position+Vector3.new(0,2.5,0))
    local topSp=camera:WorldToViewportPoint(headTop)
    local botSp=camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
    local height=math.abs(botSp.Y-topSp.Y)
    local width=height/1.8
    local cx=rootSp.X
    local topY=topSp.Y
    local botY=botSp.Y
    local left=cx-width/2
    if espBoxes:Get()then
        o.BoxOutline.Position=Vector2.new(left,topY)
        o.BoxOutline.Size=Vector2.new(width,height)
        o.BoxOutline.Visible=true
        o.Box.Position=Vector2.new(left,topY)
        o.Box.Size=Vector2.new(width,height)
        o.Box.Color=espColor(plr,espBoxes)
        o.Box.Visible=true
    else
        o.BoxOutline.Visible=false
        o.Box.Visible=false
    end
    if espHealth:Get()then
        local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local barX=left-5
        o.HealthOutline.From=Vector2.new(barX,botY+1)
        o.HealthOutline.To=Vector2.new(barX,topY-1)
        o.HealthOutline.Visible=true
        o.Health.From=Vector2.new(barX,botY)
        o.Health.To=Vector2.new(barX,botY-height*pct)
        o.Health.Color=RED:Lerp(GREEN,pct)
        o.Health.Visible=true
    else
        o.HealthOutline.Visible=false
        o.Health.Visible=false
    end
    if espName:Get()then
        o.Name.Text=plr.Name
        o.Name.Position=Vector2.new(cx,topY-16)
        o.Name.Color=espName:GetColor3()
        o.Name.Visible=true
    else
        o.Name.Visible=false
    end
    if espDistance:Get()then
        local dist=(camera.CFrame.Position-root.Position).Magnitude
        o.Distance.Text="["..math.floor(dist).."m]"
        o.Distance.Position=Vector2.new(cx,botY+2)
        o.Distance.Color=espDistance:GetColor3()
        o.Distance.Visible=true
    else
        o.Distance.Visible=false
    end
    if espTracers:Get()then
        local viewport=camera.ViewportSize
        local originMode=tracerOrigin:GetText()
        local from
        if originMode=="Mouse"then
            from=mousePos
        elseif originMode=="Center"then
            from=Vector2.new(viewport.X/2,viewport.Y/2)
        else
            from=Vector2.new(viewport.X/2,viewport.Y)
        end
        o.Tracer.From=from
        o.Tracer.To=Vector2.new(rootSp.X,rootSp.Y)
        o.Tracer.Color=espColor(plr,espTracers)
        o.Tracer.Visible=true
    else
        o.Tracer.Visible=false
    end
    if espSkeletons:Get()then
        local bones=char:FindFirstChild"UpperTorso"and R15_BONES or R6_BONES
        local color=espColor(plr,espSkeletons)
        for i,line in ipairs(o.Skeleton)do
            local pair=bones[i]
            local drawn=false
            if pair then
                local a,b=char:FindFirstChild(pair[1]),char:FindFirstChild(pair[2])
                if a and b then
                    local sa=camera:WorldToViewportPoint(a.Position)
                    local sb=camera:WorldToViewportPoint(b.Position)
                    if sa.Z>0 and sb.Z>0 then
                        line.From=Vector2.new(sa.X,sa.Y)
                        line.To=Vector2.new(sb.X,sb.Y)
                        line.Color=color
                        line.Visible=true
                        drawn=true
                    end
                end
            end
            if not drawn then
                line.Visible=false
            end
        end
    else
        for _,line in ipairs(o.Skeleton)do
            line.Visible=false
        end
    end
end
local function espStep()
    local camera=Workspace.CurrentCamera
    if not camera then
        return
    end
    local mousePos=UserInputService:GetMouseLocation()
    for _,plr in ipairs(Players:GetPlayers())do
        if plr~=LocalPlayer then
            local o=espObjects[plr]or createEsp(plr)
            pcall(updatePlayerEsp,plr,o,camera,mousePos)
        end
    end
end
local clickFn=mouse1click or env.mouse1click
local pressFn=mouse1press or env.mouse1press
local releaseFn=mouse1release or env.mouse1release
local trigParams=RaycastParams.new()
trigParams.FilterType=Enum.RaycastFilterType.Exclude
trigParams.IgnoreWater=true
local trigSince,lastShot=nil,0
local function fireClick()
    if clickFn then
        clickFn()
    elseif pressFn and releaseFn then
        pressFn()
        task.wait(0.02)
        releaseFn()
    end
end
local function playerUnderCursor(camera,mousePos)
    local filter={}
    if LocalPlayer.Character then
        table.insert(filter,LocalPlayer.Character)
    end
    trigParams.FilterDescendantsInstances=filter
    local ray=camera:ViewportPointToRay(mousePos.X,mousePos.Y)
    local result=Workspace:Raycast(ray.Origin,ray.Direction*5000,trigParams)
    if not result then
        return nil
    end
    local inst=result.Instance
    while inst and inst~=Workspace do
        if inst:IsA"Model"and inst:FindFirstChildOfClass"Humanoid"then
            return Players:GetPlayerFromCharacter(inst),inst
        end
        inst=inst.Parent
    end
    return nil
end
local function triggerStep()
    if not trigEnabled:Get()then
        trigSince=nil
        return
    end
    if trigNeedKey:Get()and not(enabled:Get()and lockKeyActive())then
        trigSince=nil
        return
    end
    local camera=Workspace.CurrentCamera
    if not camera then
        return
    end
    local mousePos=UserInputService:GetMouseLocation()
    local plr,char=playerUnderCursor(camera,mousePos)
    local valid=plr~=nil and plr~=LocalPlayer
    if valid then
        local hum=char:FindFirstChildOfClass"Humanoid"
        if not hum or hum.Health<=0 then
            valid=false
        end
        if valid and trigTeam:Get()and plr.Team~=nil and plr.Team==LocalPlayer.Team then
            valid=false
        end
    end
    if not valid then
        trigSince=nil
        return
    end
    local now=os.clock()
    if not trigSince then
        trigSince=now
    end
    if now-trigSince>=trigDelay:Get()/1000 and now-lastShot>=trigRate:Get()/1000 then
        lastShot=now
        task.spawn(fireClick)
    end
end
local removingConn=Players.PlayerRemoving:Connect(removeEsp)
local lastErr=0
local function connectLoop()
    return RunService.RenderStepped:Connect(function()
        local okStep,e1=pcall(step)
        local okEsp,e2=pcall(espStep)
        local okTrig,e3=pcall(triggerStep)
        if(not okStep or not okEsp or not okTrig)and os.clock()-lastErr>5 then
            lastErr=os.clock()
            local e=(not okStep and e1)or(not okEsp and e2)or e3
            warn("[justlocklol] error: "..tostring(e))
            pcall(function()
                Lib:Notify("justlocklol error: "..tostring(e))
            end)
        end
    end)
end
local conn=connectLoop()
local running=true
task.spawn(function()
    local ticks=0
    while running do
        task.wait(1)
        ticks=ticks+1
        if not conn.Connected then
            conn=connectLoop()
        end
        if hasDrawing and fovCircle then
            local alive=pcall(function()
                return fovCircle.Visible
            end)
            if not alive then
                fovCircle=Drawing.new"Circle"
                fovCircle.Thickness=1
                fovCircle.NumSides=64
                fovCircle.Filled=false
                fovCircle.Visible=false
            end
        end
        if ticks%3==0 and autoSave:Get()then
            saveConfig(false)
        end
    end
end)
Lib:OnUnload(function()
    running=false
    if autoSave:Get()then
        saveConfig(true)
    end
    conn:Disconnect()
    removingConn:Disconnect()
    for plr in pairs(espObjects)do
        removeEsp(plr)
    end
    if fovCircle then
        pcall(function()
            fovCircle:Remove()
        end)
    end
end)
