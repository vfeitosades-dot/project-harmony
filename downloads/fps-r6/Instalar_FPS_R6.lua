-- INSTALADOR FPS R6. Execute na Command Bar do Studio fora do Play.
local USE_CUSTOM_R6 = true -- false se a experiencia ja cria seus proprios personagens R6.
assert(not game:GetService('RunService'):IsRunning(),'Pare o Play antes de instalar.')
local RS=game:GetService('ReplicatedStorage') local SS=game:GetService('ServerScriptService') local SP=game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts') local Pack=game:GetService('StarterPack')
assert(not RS:FindFirstChild('FPSSystem') and not SS:FindFirstChild('GunServer') and not Pack:FindFirstChild('Rifle') and not SP:FindFirstChild('FPSObserver'),'Ja existe um sistema com esses nomes; nada foi sobrescrito.')
local function node(parent,kind,name) local x=Instance.new(kind) x.Name=name x.Parent=parent return x end
local sys=node(RS,'Folder','FPSSystem') local mods=node(sys,'Folder','Modules') local rem=node(sys,'Folder','Remotes') local assets=node(sys,'Folder','Assets')
for _,name in ipairs({'Fire','Reload','WeaponFX','State','Action','Hit','MatchFeed','Session','SessionState','Skill','SkillFX'}) do node(rem,'RemoteEvent',name) end
do local x=node(mods,'ModuleScript',"AbilityController") x.Source=[=[local Players=game:GetService("Players") local Input=game:GetService("UserInputService") local Run=game:GetService("RunService") local Tween=game:GetService("TweenService") local Debris=game:GetService("Debris")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem") local Agents=require(script.Parent.AgentCatalog)
local A={} local closePrevious
function A.init()
 if closePrevious then closePrevious() end
 local player=Players.LocalPlayer local links={} local alive=true
 local gui=Instance.new("ScreenGui") gui.Name="FPSAbilities" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=22 gui.Parent=player:WaitForChild("PlayerGui")
 local compact=Input.TouchEnabled local width=compact and 50 or 58 local gap=8 local total=width*3+gap*2 local y=compact and -220 or -100
 local tiles={}
 local function label(parent,text,size,pos,fontSize)
  local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(240,246,255) t.Font=Enum.Font.GothamBold t.TextSize=fontSize t.Parent=parent return t
 end
 local function cast(index)
  if player:GetAttribute("FPSMode")=="Lobby" or player:GetAttribute("FPSMenuOpen")==true then return end
  local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid") if not h or h.Health<=0 then return end
  local cam=workspace.CurrentCamera if not cam then return end
  local direction=index=="Dash" and h.MoveDirection.Magnitude>.1 and h.MoveDirection or cam.CFrame.LookVector
  system.Remotes.Skill:FireServer(index,direction)
 end
 for i=1,3 do
  local button=Instance.new("TextButton") button.Name="Ability"..i button.Text="" button.Size=UDim2.fromOffset(width,48) button.Position=UDim2.new(.5,-total/2+(i-1)*(width+gap),1,y) button.BackgroundColor3=Color3.fromRGB(22,33,49) button.BackgroundTransparency=.2 button.BorderSizePixel=0 button.Parent=gui
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,5) corner.Parent=button
  local stroke=Instance.new("UIStroke") stroke.Thickness=1 stroke.Transparency=.3 stroke.Color=Color3.fromRGB(85,225,245) stroke.Parent=button
  local key=label(button,({"Q","E","C"})[i],UDim2.fromOffset(20,18),UDim2.fromOffset(3,1),12)
  local name=label(button,"",UDim2.new(1,-4,0,18),UDim2.fromOffset(2,26),compact and 8 or 9)
  local cooldown=label(button,"",UDim2.new(1,0,0,26),UDim2.fromOffset(0,4),19)
  local bar=Instance.new("Frame") bar.Size=UDim2.new(1,0,0,2) bar.Position=UDim2.new(0,0,1,-2) bar.BorderSizePixel=0 bar.BackgroundColor3=stroke.Color bar.Parent=button
  table.insert(tiles,{button=button,name=name,key=key,cooldown=cooldown,bar=bar,stroke=stroke})
  table.insert(links,button.Activated:Connect(function() cast(i) end))
 end
 local dash=Instance.new("TextButton") dash.Name="Dash" dash.Text="CTRL  /  DASH" dash.Size=UDim2.fromOffset(compact and 82 or 160,compact and 38 or 24) dash.Position=compact and UDim2.new(1,-100,.5,-58) or UDim2.new(.5,-80,1,-47) dash.BackgroundTransparency=compact and .3 or 1 dash.BackgroundColor3=Color3.fromRGB(22,33,49) dash.TextColor3=Color3.fromRGB(204,223,240) dash.Font=Enum.Font.GothamBold dash.TextSize=10 dash.Parent=gui
 table.insert(links,dash.Activated:Connect(function() cast("Dash") end))
 table.insert(links,Input.InputBegan:Connect(function(i,processed)
  if processed or Input:GetFocusedTextBox() then return end
  if i.KeyCode==Enum.KeyCode.Q then cast(1) elseif i.KeyCode==Enum.KeyCode.E then cast(2) elseif i.KeyCode==Enum.KeyCode.C then cast(3) elseif i.KeyCode==Enum.KeyCode.LeftControl or i.KeyCode==Enum.KeyCode.F then cast("Dash") end
 end))
 table.insert(links,Run.Heartbeat:Connect(function()
  if not alive then return end local agent=Agents.Agents[player:GetAttribute("FPSAgent") or "ION"] local now=workspace:GetServerTimeNow()
  local color=Color3.fromRGB(table.unpack(agent.Color))
  gui.Enabled=player:GetAttribute("FPSMode")~="Lobby" and player:GetAttribute("FPSGameMenu")~=true
  for i,t in ipairs(tiles) do
   local left=math.max(0,(player:GetAttribute("FPSNextSkill"..i) or 0)-now) local skill=agent.Skills[i]
   t.name.Text=skill.Name:match("^(%S+)") or skill.Name t.cooldown.Text=left>.05 and tostring(math.ceil(left)) or "" t.key.TextTransparency=left>0 and .6 or 0
   t.bar.Size=UDim2.new(math.clamp(1-left/skill.Cooldown,0,1),0,0,2) t.bar.BackgroundColor3=color t.stroke.Color=color
  end
  local dashLeft=math.max(0,(player:GetAttribute("FPSNextDash") or 0)-now) dash.Text=dashLeft>.05 and ("DASH  "..string.format("%.1f",dashLeft)) or "CTRL  /  DASH"
 end))
 local function visual(name,size,cf,color,alpha,duration,goal)
  local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.Neon p.Transparency=alpha p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=workspace
  if goal then Tween:Create(p,TweenInfo.new(duration),goal):Play() end Debris:AddItem(p,duration+.04) return p
 end
 table.insert(links,system.Remotes.SkillFX.OnClientEvent:Connect(function(kind,a,b,id,owner)
  local agent=Agents.Agents[id] or Agents.Agents.ION local color=Color3.fromRGB(table.unpack(agent.Color))
  if kind=="Reveal" and typeof(a)=="Instance" and a:IsA("Model") then
   local h=Instance.new("Highlight") h.Adornee=a h.FillColor=color h.OutlineColor=color h.FillTransparency=.8 h.OutlineTransparency=.1 h.DepthMode=Enum.HighlightDepthMode.Occluded h.Parent=a Debris:AddItem(h,b) return
  end
  if kind=="SoundPing" and typeof(a)=="Vector3" then
   local anchor=visual("Ping",Vector3.new(.1,.1,.1),CFrame.new(a),color,1,b)
   local bill=Instance.new("BillboardGui") bill.Size=UDim2.fromOffset(45,45) bill.AlwaysOnTop=true bill.StudsOffsetWorldSpace=Vector3.new(0,2,0) bill.Parent=anchor
   local t=label(bill,"!",UDim2.fromScale(1,1),UDim2.fromScale(0,0),30) t.TextColor3=color return
  end
  if player:GetAttribute("FPSVFXEnabled")==false or typeof(a)~="Vector3" then return end
  if kind=="Dash" and typeof(b)=="Vector3" then
   local delta=b-a if delta.Magnitude<.01 then return end
   local basis=CFrame.lookAt(a,b)
   for i=1,5 do local start=basis*CFrame.new((i%2==0 and 1 or -1)*.8,(i%3-1)*.5,-i*.5)
    visual("DashStreak",Vector3.new(.04,.04,1.3),start,color,.35,.25,{Transparency=1,CFrame=start*CFrame.new(0,0,-2),Size=Vector3.new(.01,.01,.2)})
   end
  else
   local radius=kind=="ArcBurst" and 7 or kind=="RevealPulse" and 18 or kind=="Heal" and 8 or 2
   local sphere=visual("AbilityPulse",Vector3.new(.2,.2,.2),CFrame.new(a),color,.65,.35,{Transparency=1,Size=Vector3.new(radius*2,radius*2,radius*2)}) sphere.Shape=Enum.PartType.Ball
   for i=1,5 do local angle=i*2.399 local offset=Vector3.new(math.cos(angle)*1.2,.2,math.sin(angle)*1.2)
    visual("PrismSpark",Vector3.new(.08,.16,.08),CFrame.new(a+offset)*CFrame.Angles(.3,i,.5),color,.15,.4,{Transparency=1,CFrame=CFrame.new(a+offset*2+Vector3.new(0,1.3,0))})
   end
  end
 end))
 local function cleanup() alive=false for _,c in ipairs(links) do c:Disconnect() end gui:Destroy() end closePrevious=cleanup return cleanup
end
return A
]=] end
do local x=node(mods,'ModuleScript',"AgentCatalog") x.Source=[=[return {
 Order={"ION","AMBAR","VEU"},
 Agents={
 ION={Name="ION",Role="Vetor de mobilidade",Price=0,Color={69,215,255},Description="Controla ritmo e deslocamento. Pressiona sem depender de dano explosivo.",Skills={
  {Name="Arco condutor",Key="Q",Cooldown=18,Description="Orbita curta: 12 de dano e lentidao leve por 2s, raio de 7 studs."},
  {Name="Trilho de impulso",Key="E",Cooldown=24,Description="Trilho de 12 studs concede 12% de velocidade aos aliados por 3s."},
  {Name="Eco residual",Key="C",Cooldown=26,Description="Um eco visivel com 20 HP distrai inimigos por 4s. Nao causa dano."}}},
 AMBAR={Name="AMBAR",Role="Engenharia de suporte",Price=220,Color={255,173,66},Description="Protege por pouco tempo e cria oportunidades de reposicionamento.",Skills={
  {Name="Pelicula cinetica",Key="Q",Cooldown=24,Description="Absorve ate 25 de dano por 4s. Nao concede invulnerabilidade."},
  {Name="Sutura de campo",Key="E",Cooldown=26,Description="Estacao por 5s restaura 2 HP/s aos aliados fora de combate."},
  {Name="Tranca de pulso",Key="C",Cooldown=28,Description="Cobertura de energia por 4s, destrutivel com 40 de dano."}}},
 VEU={Name="VEU",Role="Leitura de combate",Price=220,Color={178,139,255},Description="Informacao localizada e controle de visao, com janelas curtas.",Skills={
  {Name="Farol espectral",Key="Q",Cooldown=22,Description="Pulso revela por 0,8s inimigos em linha de visao a ate 18 studs."},
  {Name="Neblina fragmentada",Key="E",Cooldown=26,Description="Nuvem pequena bloqueia visao por 4s; balas ainda atravessam."},
  {Name="Escuta direcional",Key="C",Cooldown=24,Description="Sensor por 6s pinga a origem de disparos inimigos proximos."}}}
 }
}
]=] end
do local x=node(mods,'ModuleScript',"AnimationController") x.Source=[=[-- Timelines autorais. Campos: tempo, transformacao da arma, mao esquerda, carregador.
local A={}
local I=CFrame.new()
local function cf(x,y,z,rx,ry,rz) return CFrame.new(x,y,z)*CFrame.Angles(math.rad(rx or 0),math.rad(ry or 0),math.rad(rz or 0)) end
A.Clips={
 Equipping={{0,cf(.12,-1.15,.4,-25,10,14),cf(-.15,-.4,.25),I},{.12,cf(.06,-.55,.18,-12,5,6),cf(-.1,-.18,.1),I},{.27,cf(-.015,.035,-.015,1,0,-2),cf(-.025,-.015,0),I},{.36,cf(0,-.012,0,-.4,0,.6),I,I},{.45,I,I,I}},
 Unequipping={{0,I,I,I},{.3,cf(.2,-1.3,.4,-35,15,20),cf(-.2,-.3,.2),I}},
 Reloading={{0,I,I,I},{.16,cf(-.04,.01,.05,-3,0,-15),cf(-.1,-.1,.2),I},
 {.28,cf(-.07,.025,.09,-5,0,-24),cf(-.15,-.2,.3),I},
 {.5,cf(-.07,.025,.09,-5,0,-26),cf(-.15,-.4,.4),cf(0,-.45,.08,0,0,-7)},
 {.68,cf(-.07,.025,.09,-5,0,-26),cf(-.2,-.65,.4),cf(0,-1.05,.16,0,0,-12)},
 {.86,cf(-.07,.025,.09,-5,0,-25),cf(-.2,-.7,.4),cf(0,-1.15,.18,0,0,-12)},
 {1.01,cf(-.065,.02,.08,-4,0,-22),cf(-.1,-.4,.2),cf(0,-.5,.08,0,0,-5)},
 {1.2,cf(-.03,.035,.04,-2,0,-14),cf(-.04,-.1,.1),cf(0,.025,0)},
 {1.36,cf(0,-.01,.015,.8,0,-4),I,I},{1.65,I,I,I}},
 Inspecting={{0,I,I,I},{.45,cf(-.22,.1,.12,5,-25,-22),cf(-.1,-.05,.05),I},{1.05,cf(-.08,.15,.3,-8,20,30),cf(.05,0,0),I},{1.65,cf(-.15,.06,.15,3,-18,-16),I,I},{2.15,cf(0,.02,0,0,0,2),I,I},{2.5,I,I,I}},
}
function A.Sample(name,time)
 local list=A.Clips[name] if not list then return I,I,I end
 if time<=list[1][1] then return list[1][2],list[1][3],list[1][4] end
 for n=2,#list do local b=list[n] local a=list[n-1] if time<=b[1] then local t=math.clamp((time-a[1])/(b[1]-a[1]),0,1) t=t*t*(3-2*t) return a[2]:Lerp(b[2],t),a[3]:Lerp(b[3],t),a[4]:Lerp(b[4],t) end end
 local last=list[#list] return last[2],last[3],last[4]
end
function A.ReloadHandWeight(time)
 local v=time<.28 and math.clamp(time/.28,0,1) or time>1.35 and 1-math.clamp((time-1.35)/.3,0,1) or 1
 return v*v*(3-2*v)
end
function A.MagazineAlpha(time) if time<.72 or time>1.04 then return 0 end if time<.82 then return (time-.72)/.1 elseif time<.94 then return 1 else return 1-(time-.94)/.1 end end
function A.State(equipped,age,reload,inspect,running,aiming,firing,walking)
 if not equipped then return "Unequipping" elseif age<.45 then return "Equipping" elseif reload then return "Reloading" elseif inspect then return "Inspecting" elseif firing then return "Firing" elseif aiming then return "Aiming" elseif running then return "Running" elseif walking then return "Walking" else return "Idle" end
end
-- Authored third-person chest-ready idle; no uploaded AnimationId required.
-- Stock is kept outside the front of a standard R6 torso.
A.WorldIdle={{0,CFrame.new()},{1.2,CFrame.new(0,.006,0)},{2.4,CFrame.new()}}
local function worldIdle(time)
 local phase=time%2.4
 for i=2,#A.WorldIdle do
  local a,b=A.WorldIdle[i-1],A.WorldIdle[i]
  if phase<=b[1] then local t=(phase-a[1])/(b[1]-a[1]) t=t*t*(3-2*t) return a[2]:Lerp(b[2],t) end
 end
 return CFrame.new()
end
function A.WorldBase(torso)
 -- Right-handed stance: butt plate rests on the front of the right shoulder.
 -- Offsets use the R6 torso, never accessory bounds.
 return CFrame.new(torso.Size.X*.45,torso.Size.Y*.26,-torso.Size.Z*.5-1.05)
end
function A.WorldSample(now,phase,move,run,jump,aim)
 local steady=1-.8*aim
 return worldIdle(now)*CFrame.new(math.sin(phase)*.02*move*steady,
  math.cos(phase*2)*(.016+.012*run)*move*steady+.055*jump+.045*aim-.06*run,-.025*aim+.045*run)
  *CFrame.Angles(-.055*run+.035*jump,math.sin(phase)*.02*move*steady,.018*run)
end
function A.ActionSample(kind,age)
 local cycle=kind=="Shotgun" and .42 or kind=="Sniper" and .45 or .16
 if age<0 or age>=cycle then return CFrame.new() end
 local amount=math.sin(math.pi*age/cycle)
 return CFrame.new(0,0,amount*(kind=="Shotgun" and .22 or kind=="Sniper" and .18 or .13))
end
return A
]=] end
do local x=node(mods,'ModuleScript',"AvatarAppearance") x.Source=[=[-- Executado no servidor. A aparencia vem da conta; so o rig e convertido em R6.
local Players=game:GetService("Players")
local A={} local templates={} local loading={}
local function neutral()
 local d=Instance.new("HumanoidDescription")
 local skin=Color3.fromRGB(211,180,153)
 d.HeadColor=skin d.LeftArmColor=skin d.RightArmColor=skin
 d.TorsoColor=Color3.fromRGB(55,65,81) d.LeftLegColor=Color3.fromRGB(31,41,55) d.RightLegColor=d.LeftLegColor
 return d
end
function A.Create(userId)
 userId=tonumber(userId) or 0
 while loading[userId] do task.wait(.1) end
 local cached=templates[userId]
 if cached and (not cached:GetAttribute("AppearanceFallback") or userId<=0) then return cached:Clone() end
 loading[userId]=true
 local description local fallback=false
 if userId>0 then
  for attempt=1,3 do local ok,result=pcall(Players.GetHumanoidDescriptionFromUserIdAsync,Players,userId) if ok then description=result break end if attempt<3 then task.wait(attempt) end end
 end
 if not description then description=neutral() fallback=true end
 local ok,model=pcall(Players.CreateHumanoidModelFromDescriptionAsync,Players,description,Enum.HumanoidRigType.R6)
 description:Destroy()
 if not ok then loading[userId]=nil return nil,tostring(model) end
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end end
 local h=model:FindFirstChildOfClass("Humanoid") if h then h.Health=h.MaxHealth end
 model:SetAttribute("AppearanceFallback",fallback) model:SetAttribute("AppearanceUserId",userId)
 if cached then cached:Destroy() end templates[userId]=model loading[userId]=nil
 return model:Clone()
end
function A.Clear(userId) local m=templates[userId] if m then m:Destroy() templates[userId]=nil end end
return A
]=] end
do local x=node(mods,'ModuleScript',"BotService") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService") local CS=game:GetService("CollectionService") local Path=game:GetService("PathfindingService") local Debris=game:GetService("Debris")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local Avatar=require(script.Parent.AvatarAppearance) local World=require(script.Parent.WorldService) local Factory=require(script.Parent.WeaponFactory) local Catalog=require(script.Parent.WeaponCatalog) local Combat=require(script.Parent.CombatService) local Skills=require(script.Parent.SkillService) local Anim=require(script.Parent.AnimationController)
local B={} local bots={} local spawning={} local started=false local random=Random.new()
local function now() return workspace:GetServerTimeNow() end
local function participants(mode) local out={} for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("FPSMode")==mode then table.insert(out,p) end end return out end
local function remove(key,b) if b and b.model.Parent then b.model:Destroy() end bots[key]=nil end
local function spawn(mode,index,owner)
 local key=mode..index if spawning[key] or bots[key] then return end spawning[key]=true
 local id=owner.UserId if id<=0 and game.CreatorType==Enum.CreatorType.User and game.CreatorId>0 then id=game.CreatorId end
 local model=Avatar.Create(id) if not model or #participants(mode)==0 then if model then model:Destroy() end spawning[key]=nil return end
 local root=model:FindFirstChild("HumanoidRootPart") local h=model:FindFirstChildOfClass("Humanoid") local torso=model:FindFirstChild("Torso")
 if not root or not h or not torso then model:Destroy() spawning[key]=nil return end
 local stationary=mode=="Training" and index<=2
 model.Name=(stationary and "ALVO " or "SENTINELA ")..string.format("%02d",index)
 h.DisplayName=model.Name h.MaxHealth=100 h.Health=100 h.BreakJointsOnDeath=false h.WalkSpeed=stationary and 0 or 18 h.JumpPower=50
 model:SetAttribute("FPSBotBaseSpeed",stationary and 0 or 18) model:SetAttribute("FPSMode",mode) model:SetAttribute("FPSMatchId",mode) model:SetAttribute("FPSSide","Hostile")
 local weapon=Catalog.Order[(index-1)%#Catalog.Order+1] if mode=="Training" then weapon=index==3 and "NOMAD" or "VETOR" end
 local cfg=Catalog.Get(weapon)
 local tool=Instance.new("Tool") tool.Name="Rifle" tool.CanBeDropped=false tool.RequiresHandle=true Factory.Mount(tool,weapon)
 tool:SetAttribute("EquippedAt",now()-1) tool:SetAttribute("ReloadEnd",0) tool:SetAttribute("AimPitch",0) tool.Parent=model
 local grip=Instance.new("Motor6D") grip.Name="WorldGrip" grip.Part0=torso grip.Part1=tool.Handle grip.C0=Anim.WorldBase(torso) grip.Parent=tool.Handle
 local arm=model:FindFirstChild("Right Arm") if arm then
  local function clear(j) if j.Name=="RightGrip" and j:IsA("JointInstance") and j.Part1==tool.Handle then j:Destroy() end end
  for _,j in ipairs(arm:GetChildren()) do clear(j) end arm.ChildAdded:Connect(clear)
 end
 for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CollisionGroup="Characters" if p.Parent and p.Parent:IsA("Accessory") then p.CanQuery=false end end end
 local nodes=World.Spawns[mode] local at=nodes[(index+3)%#nodes+1]
 model.PrimaryPart=root model:PivotTo(CFrame.new(at)) model.Parent=workspace root.Anchored=stationary pcall(function() if not stationary then root:SetNetworkOwner(nil) end end)
 CS:AddTag(model,"FPSDemoBot")
 local shield=Instance.new("ForceField") shield.Visible=false shield.Parent=model Debris:AddItem(shield,1.5)
 local bot={model=model,h=h,root=root,tool=tool,cfg=cfg,ammo=cfg.Magazine,stationary=stationary,mode=mode,key=key,lastShot=-100,nextThink=0,burst=0,pause=0,pathAt=0,seenAt=0,difficulty=mode=="Training" and "Easy" or "Normal"}
 bots[key]=bot spawning[key]=nil
 h.Died:Connect(function() bot.dead=true Debris:AddItem(model,1.5) task.delay(2,function() if bots[key]==bot then bots[key]=nil end end) end)
end
local function target(bot)
 local nearest local distance=math.huge local list={}
 for _,p in ipairs(participants(bot.mode)) do if p.Character then table.insert(list,p.Character) end end
 for _,m in ipairs(CS:GetTagged("VyrelDecoy")) do if m.Parent then table.insert(list,m) end end
 for _,m in ipairs(list) do local root=m:FindFirstChild("HumanoidRootPart") local h=m:FindFirstChildOfClass("Humanoid")
  if root and h and h.Health>0 and Combat.Allowed(bot.model,m) then
   local d=(root.Position-bot.root.Position).Magnitude
   if d<105 and d<distance and Combat.Visible(bot.root.Position+Vector3.new(0,1,0),root.Position,{bot.model,m}) and not Skills.SmokeBlocks(bot.root.Position,root.Position,bot.mode) then nearest=m distance=d end
  end
 end return nearest,distance
end
local function pathTo(bot,goal)
 if bot.busyPath or now()-bot.pathAt<1.4 then return end bot.pathAt=now() bot.busyPath=true
 task.spawn(function()
  local path=Path:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
  local ok=pcall(function() path:ComputeAsync(bot.root.Position,goal) end)
  if ok and path.Status==Enum.PathStatus.Success and bot.model.Parent then bot.route=path:GetWaypoints() bot.waypoint=2 end bot.busyPath=false
 end)
end
local function walk(bot,goal)
 if bot.stationary then return end
 if Combat.Visible(bot.root.Position,goal,{bot.model}) then bot.h:MoveTo(goal) bot.route=nil
 else
  pathTo(bot,goal)
  local point=bot.route and bot.route[bot.waypoint or 2]
  if point then
   if (bot.root.Position-point.Position).Magnitude<3 then bot.waypoint+=1 else bot.h:MoveTo(point.Position) if point.Action==Enum.PathWaypointAction.Jump then bot.h.Jump=true end end
  end
 end
end
local function shoot(bot,enemy)
 local time=now() if time<bot.pause or time-bot.lastShot<math.max(bot.cfg.FireInterval,.13) then return end
 if bot.ammo<=0 then
  if not bot.reloadEnd then bot.reloadEnd=time+bot.cfg.ReloadTime bot.tool:SetAttribute("ReloadEnd",bot.reloadEnd)
  elseif time>=bot.reloadEnd then bot.ammo=bot.cfg.Magazine bot.reloadEnd=nil bot.tool:SetAttribute("ReloadEnd",0) end return
 end
 local head=bot.model:FindFirstChild("Head") local victim=enemy:FindFirstChild(random:NextNumber()<.12 and "Head" or "Torso") if not head or not victim then return end
 if (victim.Position-head.Position).Magnitude<.1 then return end
 local spread=bot.difficulty=="Easy" and 6 or 3.2 local basis=CFrame.lookAt(head.Position,victim.Position)
 local direction=(basis*CFrame.Angles(math.rad(random:NextNumber(-spread,spread)),math.rad(random:NextNumber(-spread,spread)),0)).LookVector
 local hit=workspace:Raycast(head.Position,direction*bot.cfg.Range,Combat.Params({bot.model})) local endpoint=hit and hit.Position or head.Position+direction*bot.cfg.Range
 if hit and not Combat.Barrier(hit.Instance,bot.cfg.Damage) then
  local model=hit.Instance:FindFirstAncestorOfClass("Model") local critical=hit.Instance.Name=="Head"
  Combat.Apply(bot.model,model,bot.cfg.Damage*(bot.difficulty=="Easy" and .65 or .9)*(critical and bot.cfg.Critical or 1),critical,endpoint)
 end
 bot.lastShot=time bot.ammo-=1 bot.burst+=1 if bot.burst>=3 then bot.pause=time+(bot.difficulty=="Easy" and 1.1 or .65) bot.burst=0 end
 local muzzle=bot.tool.Handle:FindFirstChild("Muzzle") local start=muzzle and muzzle.WorldPosition or head.Position
 bot.model:SetAttribute("FPSLastShotAt",time) Skills.OnShot(bot.model,start)
 system.Remotes.WeaponFX:FireAllClients(-10000-tonumber(bot.key:match("%d+")),start,endpoint,hit and hit.Normal or nil)
end
local function think(bot)
 if bot.dead or not bot.model.Parent or bot.h.Health<=0 or bot.stationary then return end
 local enemy,distance=target(bot)
 local base=enemy and 18 or 22 bot.model:SetAttribute("FPSBotBaseSpeed",base)
 local mult=(bot.model:GetAttribute("FPSSlowUntil") or 0)>now() and .86 or 1
 bot.h.WalkSpeed=base*mult bot.tool:SetAttribute("Running",enemy==nil)
 if enemy then
  if bot.target~=enemy then bot.target=enemy bot.seenAt=now() end
  local er=enemy:FindFirstChild("HumanoidRootPart") local p=bot.root.Position
  if er then bot.lastKnown=er.Position bot.lastKnownAt=now() end
  if er then
   bot.h.AutoRotate=false local facing=Vector3.new(er.Position.X,p.Y,er.Position.Z) if (facing-p).Magnitude>.1 then bot.root.CFrame=bot.root.CFrame:Lerp(CFrame.lookAt(p,facing),.45) end
   bot.tool:SetAttribute("AimPitch",math.clamp(math.atan2(er.Position.Y-p.Y,distance),-.7,.7))
   if bot.h.Health<35 or bot.reloadEnd then
    local best local score=math.huge
    for _,node in ipairs(World.Cover[bot.mode]) do local d=(node-p).Magnitude if d<score and not Combat.Visible(er.Position,node,{bot.model,enemy}) then best=node score=d end end
    if best then walk(bot,best) else walk(bot,p+(p-er.Position).Unit*8) end
   else
    local strafe=bot.root.CFrame.RightVector*(math.sin(now()*1.6+tonumber(bot.key:match("%d+")))>0 and 7 or -7)
    if distance>40 then walk(bot,er.Position+(p-er.Position).Unit*25+strafe) else walk(bot,p+strafe) end
   end
   if now()-bot.seenAt>(bot.difficulty=="Easy" and .6 or .3) then shoot(bot,enemy) end
  end
 else
  bot.target=nil bot.h.AutoRotate=true
  if not bot.goal or (bot.root.Position-bot.goal).Magnitude<5 or now()-(bot.goalAt or 0)>6 then local nodes=World.Cover[bot.mode] bot.goal=nodes[random:NextInteger(1,#nodes)] bot.goalAt=now() end
  walk(bot,bot.lastKnown and now()-(bot.lastKnownAt or 0)<2.5 and bot.lastKnown or bot.goal)
  if bot.ammo<bot.cfg.Magazine*.3 and not bot.reloadEnd then bot.reloadEnd=now()+bot.cfg.ReloadTime bot.tool:SetAttribute("ReloadEnd",bot.reloadEnd) end
 end
 if bot.reloadEnd and now()>=bot.reloadEnd then bot.ammo=bot.cfg.Magazine bot.reloadEnd=nil bot.tool:SetAttribute("ReloadEnd",0) end
end
function B.Init()
 if started then return end started=true World.Build()
 local elapsed=0 Run.Heartbeat:Connect(function(dt)
  for _,bot in pairs(bots) do if now()>=bot.nextThink then bot.nextThink=now()+.15 think(bot) end end
  elapsed+=dt if elapsed<1 then return end elapsed=0
  for _,mode in ipairs({"Casual","Training"}) do
   local list=participants(mode) local desired=#list==0 and 0 or mode=="Training" and 3 or math.min(6,#list*2)
   for i=1,6 do local key=mode..i if i<=desired then if not bots[key] then task.spawn(spawn,mode,i,list[1]) end elseif bots[key] then remove(key,bots[key]) end end
  end
 end)
end
return B
]=] end
do local x=node(mods,'ModuleScript',"ClientController") x.Source=[=[local Players=game:GetService("Players") local Input=game:GetService("UserInputService") local Run=game:GetService("RunService") local Gui=game:GetService("GuiService")
local System=game:GetService("ReplicatedStorage").FPSSystem local R=System.Remotes
local Catalog=require(script.Parent.WeaponCatalog)
local Default=require(script.Parent.WeaponConfig) local Anim=require(script.Parent.AnimationController) local View=require(script.Parent.ViewModelController) local HUD=require(script.Parent.HUD) local Effects=require(script.Parent.WeaponEffects)
local Controller={} Controller.__index=Controller local active
local function now() return workspace:GetServerTimeNow() end
function Controller:Cleanup()
 self.token+=1 self.equipped=false self.holding=false self.wantAim=false self.wantRun=false
 if self.vm then self.vm:Destroy() self.vm=nil end
 if self.descendant then self.descendant:Disconnect() self.descendant=nil end
 for object,value in pairs(self.hidden) do if object.Parent then if object:IsA("BasePart") then object.LocalTransparencyModifier=value else object.Enabled=value end end end self.hidden={}
 if active==self then
  Run:UnbindFromRenderStep("VetorFPSPre") Run:UnbindFromRenderStep("VetorFPSPost")
  local camera=workspace.CurrentCamera if camera then camera.CFrame=camera.CFrame*self.lastKick:Inverse() camera.FieldOfView=self.oldFOV or self.cfg.FOV end self.lastKick=CFrame.new()
  Players.LocalPlayer.CameraMode=self.cfg.AlwaysFirstPerson and Enum.CameraMode.LockFirstPerson or self.oldMode or Enum.CameraMode.Classic Input.MouseDeltaSensitivity=self.oldSensitivity or 1 Input.MouseIconEnabled=self.oldIcon~=false Input.MouseBehavior=self.oldMouse or Enum.MouseBehavior.Default
  self.hud:SetVisible(false) active=nil
 end
end
function Controller:Equip()
 self.weaponId=self.tool:GetAttribute("WeaponId") or self.weaponId or "VETOR" self.cfg=Catalog.Get(self.weaponId)
 if self.hud then self.hud:SetWeapon(self.cfg) end
 if active then active:Cleanup() end self:Cleanup() active=self
 self.token+=1 self.equipped=true self.at=now() self.lastFire=-1e5 self.pending={} self.sentAim=false self.sentRun=false
 local camera=workspace.CurrentCamera self.oldFOV=camera.FieldOfView self.oldMode=Players.LocalPlayer.CameraMode self.oldMouse=Input.MouseBehavior self.oldIcon=Input.MouseIconEnabled self.oldSensitivity=Input.MouseDeltaSensitivity or 1
 Players.LocalPlayer.CameraMode=Enum.CameraMode.LockFirstPerson Input.MouseIconEnabled=false
 self.vm=View.new(camera,self.weaponId) self.hud:SetVisible(true)
 local char=Players.LocalPlayer.Character self.character=char
 local function hide(obj)
  if obj:IsA("BasePart") then if self.hidden[obj]==nil then self.hidden[obj]=obj.LocalTransparencyModifier end obj.LocalTransparencyModifier=1
  elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then if self.hidden[obj]==nil then self.hidden[obj]=obj.Enabled end obj.Enabled=false end
 end
 if char then for _,obj in ipairs(char:GetDescendants()) do hide(obj) end self.descendant=char.DescendantAdded:Connect(hide) end
 R.Action:FireServer("Sync")
 Run:BindToRenderStep("VetorFPSPre",Enum.RenderPriority.Camera.Value-1,function()
  local cam=workspace.CurrentCamera if cam then cam.CFrame=cam.CFrame*self.lastKick:Inverse() end self.lastKick=CFrame.new()
 end)
 Run:BindToRenderStep("VetorFPSPost",Enum.RenderPriority.Camera.Value+1,function(dt) self:Step(dt) end)
end
function Controller:Unequip()
 if not self.vm then self:Cleanup() return end
 self.equipped=false self.holding=false self.wantAim=false self.wantRun=false self.exitAt=now() self.token+=1 local token=self.token
 task.delay(self.cfg.UnequipTime,function() if self.token==token then self:Cleanup() end end)
end
function Controller:Reload()
 if not self.equipped or self.life==0 or self.reloading or now()<self.at+self.cfg.EquipTime or self:Ammo()>=self.cfg.Magazine or self.reserve<=0 then return end
 self.wantRun=false self.sentRun=false R.Action:FireServer("Run",false)
 self.reloadRequestedAt=now() self.reloading=true self.reloadEnd=now()+self.cfg.ReloadTime self.inspectEnd=0 R.Reload:FireServer(self.life)
end
function Controller:Inspect()
 if not self.equipped or self.reloading or now()<self.at+self.cfg.EquipTime then return end
 self.wantAim=false self.wantRun=false self.holding=false
 if self.inspectEnd>now() then self.inspectEnd=0 R.Action:FireServer("CancelInspect") else self.inspectEnd=now()+self.cfg.InspectTime R.Action:FireServer("Inspect") end
end
function Controller:Ammo() local count=0 for seq in pairs(self.pending) do if seq>self.ack then count+=1 end end return math.max(0,self.ammo-count) end
function Controller:Shoot()
 if not self.equipped or (self.character and ((self.character:GetAttribute("FPSDashUntil") or 0)>now() or (self.character:GetAttribute("FPSCastUntil") or 0)>now())) or self.life==0 or self.reloading or not self.serverEquipped or now()<self.readyAt or now()<self.at+self.cfg.EquipTime or now()-self.lastFire<self.cfg.FireInterval then return end
 if self:Ammo()<=0 then self:Reload() return end
 self.lastFire=now() self.inspectEnd=0 self.seq+=1 self.pending[self.seq]=true self.triggerReady=false self.vm:Fire()
 local camera=workspace.CurrentCamera local direction=camera.CFrame.LookVector
 R.Fire:FireServer(self.life,self.seq,camera.CFrame.Position,direction)
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={self.character,self.vm.model} params.IgnoreWater=true
 local hit=workspace:Raycast(camera.CFrame.Position,direction*self.cfg.Range,params)
 local muzzle=self.vm.gun.Handle.Muzzle.WorldPosition Effects.Shot(muzzle,hit and hit.Position or camera.CFrame.Position+direction*self.cfg.Range,hit and hit.Normal or nil)
 self.hud:Pulse()
end
function Controller:Step(dt)
 if active~=self or not self.vm then return end
 local char=Players.LocalPlayer.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if char~=self.character or not h or h.Health<=0 then self:Cleanup() return end
 if Input:GetFocusedTextBox() or Players.LocalPlayer:GetAttribute("FPSMenuOpen")==true then self.holding=false self.wantAim=false self.wantRun=false end
 if self.equipped and not Input.TouchEnabled and not Input:GetFocusedTextBox() and Players.LocalPlayer:GetAttribute("FPSMenuOpen")~=true then
  if Input.IsKeyDown then self.wantRun=Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift) end
  if self.holding and Input.IsMouseButtonPressed and not Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then self.holding=false end
 end
 local t=now() local age=t-self.at local dashing=(char:GetAttribute("FPSDashUntil") or 0)>t local casting=(char:GetAttribute("FPSCastUntil") or 0)>t local busy=self.reloading or age<self.cfg.EquipTime or not self.equipped or dashing or casting
 local aim=self.wantAim and not busy
 local running=self.wantRun and not self.wantAim and not self.holding and not busy and h.MoveDirection.Magnitude>.05
 if self.equipped then
  local pitch=math.clamp(math.asin(math.clamp(workspace.CurrentCamera.CFrame.LookVector.Y,-1,1)),-1.1,1.1)
  if t-(self.pitchAt or 0)>.125 and math.abs(pitch-(self.pitch or 0))>.025 then self.pitchAt=t self.pitch=pitch R.Action:FireServer("Pitch",pitch) end
  if self.reloadRequestedAt and t-self.reloadRequestedAt>.4 then self.reloadRequestedAt=nil R.Action:FireServer("Sync") end
  if aim~=self.sentAim then self.sentAim=aim R.Action:FireServer("Aim",aim) end
  if running~=self.sentRun then self.sentRun=running R.Action:FireServer("Run",running) end
 end
 if (aim or running or self.holding) and self.inspectEnd>t then self.inspectEnd=0 R.Action:FireServer("CancelInspect") end
 if self.holding and (self.cfg.Automatic or self.triggerReady) and not Input:GetFocusedTextBox() then self:Shoot() end
 local state=Anim.State(self.equipped,age,self.reloading,self.inspectEnd>t,running,aim,t-self.lastFire<.12,h.MoveDirection.Magnitude>.05)
 local phase=state=="Reloading" and t-(self.reloadEnd-self.cfg.ReloadTime) or state=="Inspecting" and t-(self.inspectEnd-self.cfg.InspectTime) or state=="Unequipping" and t-self.exitAt or age
 local root=char:FindFirstChild("HumanoidRootPart") local speed=root and h.MoveDirection.Magnitude>.05 and h.FloorMaterial~=Enum.Material.Air and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude or 0
 local camera=workspace.CurrentCamera local kick,alpha=self.vm:Step(dt,camera,{state=state,time=math.max(0,phase),speed=speed,running=running,aim=aim,grounded=h.FloorMaterial~=Enum.Material.Air,dash=(char:GetAttribute("FPSDashUntil") or 0)>t,casting=casting,castIndex=char:GetAttribute("FPSCastIndex"),castPhase=math.clamp(1-((char:GetAttribute("FPSCastUntil") or t)-t)/.26,0,1)},Input:GetMouseDelta())
 camera.CFrame=camera.CFrame*kick self.lastKick=kick self.vm.root.CFrame=camera.CFrame
 camera.FieldOfView=self.oldFOV+(self.cfg.ADSFOV-self.oldFOV)*alpha+(Players.LocalPlayer:GetAttribute("FPSRunFOV")==false and 0 or 4)*(self.vm.run+.75*self.vm.dash)*(1-alpha)
 Input.MouseDeltaSensitivity=self.oldSensitivity*(1-.42*alpha)
 self.hud:Tick(alpha,dt,speed,running) self.hud:Update(self:Ammo(),self.reserve,state,self.reloading and math.clamp(phase/self.cfg.ReloadTime,0,1) or 0,phase)
end
function Controller.attach(tool)
 local cfg=Catalog.Get(tool:GetAttribute("WeaponId"))
 local self=setmetatable({cfg=cfg,weaponId=cfg.Id,triggerReady=true,tool=tool,token=0,connections={},hidden={},pending={},life=0,revision=0,seq=0,ack=0,ammo=cfg.Magazine,reserve=cfg.Reserve,reloading=false,reloadEnd=0,inspectEnd=0,readyAt=0,equipped=false,lastKick=CFrame.new()},Controller)
 self.hud=HUD.new({fire=function(v) if self.equipped then if v and not self.holding then self.triggerReady=true end self.holding=v end end,aim=function() self.wantAim=not self.wantAim end,run=function() self.wantRun=not self.wantRun end,reload=function() self:Reload() end,inspect=function() self:Inspect() end},cfg)
 local function connect(signal,fn) table.insert(self.connections,signal:Connect(fn)) end
 connect(tool.Equipped,function() self:Equip() end) connect(tool.Unequipped,function() self:Unequip() end)
 connect(tool.Activated,function() if self.equipped then if not self.holding then self.triggerReady=true end self.holding=true end end) connect(tool.Deactivated,function() self.holding=false end)
 connect(Input.InputBegan,function(i,processed)
  if not self.equipped or processed or Input:GetFocusedTextBox() or Players.LocalPlayer:GetAttribute("FPSMenuOpen")==true then return end
  if i.UserInputType==Enum.UserInputType.MouseButton1 then if not self.holding then self.triggerReady=true end self.holding=true elseif i.UserInputType==Enum.UserInputType.MouseButton2 then self.wantAim=true
  elseif i.KeyCode==Enum.KeyCode.R then self:Reload() elseif i.KeyCode==Enum.KeyCode.H then self:Inspect() elseif (i.KeyCode==Enum.KeyCode.LeftShift or i.KeyCode==Enum.KeyCode.RightShift) then self.wantRun=true end
 end)
 connect(Input.InputEnded,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then self.holding=false elseif i.UserInputType==Enum.UserInputType.MouseButton2 then self.wantAim=false elseif (i.KeyCode==Enum.KeyCode.LeftShift or i.KeyCode==Enum.KeyCode.RightShift) then self.wantRun=false end
 end)
 local function release() self.holding=false self.wantAim=false self.wantRun=false end
 connect(Input.WindowFocusReleased,release) connect(Gui.MenuOpened,release)
 connect(R.State.OnClientEvent,function(d)
  if type(d)~="table" or d.life<self.life or (d.life==self.life and d.revision<=self.revision) then return end
  if d.life~=self.life then self.life=d.life self.seq=0 self.ack=0 self.pending={} end
  self.revision=d.revision self.ammo=d.ammo self.reserve=d.reserve self.ack=d.ack self.seq=math.max(self.seq,d.ack)
  for seq in pairs(self.pending) do if seq<=d.ack then self.pending[seq]=nil end end
  if d.reloading then self.reloading=true self.reloadEnd=d.reloadEnd self.reloadRequestedAt=nil
  elseif not self.reloadRequestedAt or now()-self.reloadRequestedAt>.35 or d.reason then self.reloading=false self.reloadEnd=0 self.reloadRequestedAt=nil end
  self.inspectEnd=d.inspectEnd self.readyAt=d.readyAt self.serverEquipped=d.equipped
  if d.weaponId and d.weaponId~=self.weaponId then
   self.weaponId=d.weaponId self.cfg=Catalog.Get(d.weaponId) self.hud:SetWeapon(self.cfg)
   if self.equipped then self:Equip() end
  end
 end)
 connect(R.Hit.OnClientEvent,function(critical,amount,killed) if active==self then self.hud:Hit(critical,amount,killed) end end)
 connect(tool.Destroying,function() self:Cleanup() for _,c in ipairs(self.connections) do c:Disconnect() end self.hud:Destroy() end)
 R.Action:FireServer("Sync")
 return self
end
return Controller
]=] end
do local x=node(mods,'ModuleScript',"CombatService") x.Source=[=[local Players=game:GetService("Players") local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local Match=require(script.Parent.MatchState)
local D={}
function D.Actor(model)
 return Players:GetPlayerFromCharacter(model) or model
end
function D.Attribute(actor,key) return actor and actor:GetAttribute(key) end
function D.Allowed(attacker,model)
 if not attacker or not model then return false end
 local source=attacker:IsA("Player") and attacker.Character or attacker if source==model then return false end
 local target=D.Actor(model) local mode=D.Attribute(attacker,"FPSMode") local targetMode=D.Attribute(target,"FPSMode")
 if mode=="Lobby" or targetMode=="Lobby" then return false end
 local arena=D.Attribute(attacker,"FPSMatchId") local other=D.Attribute(target,"FPSMatchId")
 if arena and other and arena~=other then return false end
 local side=D.Attribute(attacker,"FPSSide") local targetSide=D.Attribute(target,"FPSSide") if side and targetSide and side==targetSide then return false end
 if not (side and targetSide) and target:IsA("Player") and attacker:IsA("Player") and not attacker.Neutral and not target.Neutral and attacker.Team==target.Team then return false end
 return true
end
function D.Apply(attacker,model,damage,critical,position)
 if not D.Allowed(attacker,model) then return 0,false end
 local h=model:FindFirstChildOfClass("Humanoid") if not h or h.Health<=0 or model:FindFirstChildOfClass("ForceField") then return 0,false end
 local now=workspace:GetServerTimeNow() local shield=model:GetAttribute("FPSShield") or 0
 if (model:GetAttribute("FPSShieldUntil") or 0)>now and shield>0 then local used=math.min(shield,damage) damage-=used model:SetAttribute("FPSShield",shield-used) end
 local before=h.Health if damage>0 then h:TakeDamage(damage) end
 local applied=before-h.Health if applied<=0 then return 0,false end
 model:SetAttribute("FPSLastDamageAt",now)
 if h.Health<=0 and not model:GetAttribute("FPSKillCounted") then
  model:SetAttribute("FPSKillCounted",true)
  if model:GetAttribute("FPSDecoy") then return applied,true end
  if attacker:IsA("Player") then Match.Kill(attacker,model,critical)
  else
   local victim=Players:GetPlayerFromCharacter(model)
   if victim then victim:SetAttribute("FPSDeaths",(victim:GetAttribute("FPSDeaths") or 0)+1) end
   system.Remotes.MatchFeed:FireAllClients(attacker.Name,victim and (victim.DisplayName or victim.Name) or model.Name,critical==true,attacker:GetAttribute("FPSMatchId"))
  end
 end
 return applied,h.Health<=0
end
function D.Barrier(part,damage)
 local hp=part:GetAttribute("FPSBarrierHP") if not hp then return false end
 hp-=damage part:SetAttribute("FPSBarrierHP",hp) if hp<=0 then part:Destroy() end return true
end
function D.Params(exclude)
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances=exclude or {} params.IgnoreWater=true return params
end
function D.Visible(origin,target,exclude)
 local delta=target-origin if delta.Magnitude<.01 then return true end
 local hit=workspace:Raycast(origin,delta,D.Params(exclude)) return not hit or (hit.Position-target).Magnitude<1.5
end
return D
]=] end
do local x=node(mods,'ModuleScript',"GameMenu") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService") local Input=game:GetService("UserInputService") local Tween=game:GetService("TweenService")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem") local R=system.Remotes
local Weapons=require(script.Parent.WeaponCatalog) local Agents=require(script.Parent.AgentCatalog) local Factory=require(script.Parent.WeaponFactory)
local G={} local oldCleanup
function G.init()
 if oldCleanup then oldCleanup() end
 local player=Players.LocalPlayer local pg=player:WaitForChild("PlayerGui") local links={} local pageLinks={} local alive=true
 local state={Credits=500,Weapons={VETOR=true,NOMAD=true},Agents={ION=true},Primary="VETOR",Secondary="NOMAD",Agent="ION",Elo=1000,RankMatches=0,Wins=0,Mode="Lobby",Storage="Carregando",Prices={}}
 local page="INICIO" local selectedWeapon="VETOR" local selectedAgent="ION" local storeTab="DESTAQUES" local signature="" local exitGui local preview local currentNav={} local open=true local syncAt=0
 local compact=Input.TouchEnabled or workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize and workspace.CurrentCamera.ViewportSize.X<1000
 local coral=Color3.fromRGB(248,119,111) local white=Color3.fromRGB(239,245,252) local muted=Color3.fromRGB(161,179,201) local dark=Color3.fromRGB(13,26,43)
 local function connect(event,fn,list) table.insert(list or links,event:Connect(fn)) end
 local gui=Instance.new("ScreenGui") gui.Name="VYRELMenu" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=60 gui.Parent=pg
 local root=Instance.new("Frame") root.Name="Root" root.Size=UDim2.fromScale(1,1) root.BackgroundColor3=dark root.BorderSizePixel=0 root.Parent=gui
 local gradient=Instance.new("UIGradient") gradient.Color=ColorSequence.new(Color3.fromRGB(13,31,47),Color3.fromRGB(53,40,78)) gradient.Rotation=22 gradient.Parent=root
 local modal=Instance.new("TextButton") modal.Name="CursorCapture" modal.Text="" modal.BackgroundTransparency=1 modal.Size=UDim2.fromScale(1,1) modal.Modal=true modal.Parent=root
 local function frame(parent,name,size,pos,alpha,color)
  local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundTransparency=alpha or 0 f.BackgroundColor3=color or dark f.BorderSizePixel=0 f.Parent=parent return f
 end
 local function text(parent,name,value,size,pos,fs,color)
  local t=Instance.new("TextLabel") t.Name=name t.Text=value t.Size=size t.Position=pos t.BackgroundTransparency=1 t.TextColor3=color or white t.Font=Enum.Font.GothamMedium t.TextSize=fs t.TextXAlignment=Enum.TextXAlignment.Left t.TextWrapped=true t.Parent=parent return t
 end
 local function line(parent,width,pos,color) return frame(parent,"Line",UDim2.new(width,0,0,2),pos,0,color or coral) end
 local function button(parent,name,value,size,pos,action,accent,permanent)
  local b=Instance.new("TextButton") b.Name=name b.Text=value b.Size=size b.Position=pos b.BackgroundColor3=accent and coral or Color3.fromRGB(32,49,69) b.TextColor3=accent and Color3.fromRGB(18,25,35) or white b.BorderSizePixel=0 b.AutoButtonColor=false b.Font=Enum.Font.GothamBold b.TextSize=compact and 11 or 14 b.TextWrapped=true b.Parent=parent
  local stroke=Instance.new("UIStroke") stroke.Thickness=1 stroke.Transparency=accent and .9 or .65 stroke.Color=white stroke.Parent=b
  local list=permanent and links or pageLinks
  connect(b.Activated,action,list)
  connect(b.MouseEnter,function() Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=accent and Color3.fromRGB(255,153,143) or Color3.fromRGB(54,73,97)}):Play() end,list)
  connect(b.MouseLeave,function() Tween:Create(b,TweenInfo.new(.12),{BackgroundColor3=accent and coral or Color3.fromRGB(32,49,69)}):Play() end,list)
  return b
 end
 local city=Instance.new("ViewportFrame") city.Name="CitadelaViva" city.BackgroundTransparency=1 city.Size=UDim2.fromScale(.72,.9) city.Position=UDim2.fromScale(.25,.08) city.Ambient=Color3.fromRGB(150,160,190) city.LightColor=Color3.fromRGB(255,201,179) city.LightDirection=Vector3.new(-1,-2,-1) city.Parent=root
 local cityWorld=Instance.new("WorldModel") cityWorld.Parent=city local cityCamera=Instance.new("Camera") cityCamera.FieldOfView=48 cityCamera.Parent=city city.CurrentCamera=cityCamera
 local cityReady=false
 local function loadCity()
  if cityReady then return end local world=workspace:FindFirstChild("VYRELWorld") local source=world and world:FindFirstChild("Citadela") if not source then return end
  local clone=source:Clone() clone.Parent=cityWorld cityReady=true
 end
 local shade=frame(root,"Shade",UDim2.fromScale(1,1),UDim2.fromScale(0,0),.35,dark)
 local shadeGradient=Instance.new("UIGradient") shadeGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,.7),NumberSequenceKeypoint.new(1,.25)}) shadeGradient.Parent=shade
 local top=frame(root,"Navigation",UDim2.new(1,0,0,compact and 96 or 82),UDim2.fromScale(0,0),.2)
 local brand=text(top,"Brand","VYREL",UDim2.fromOffset(130,45),UDim2.fromOffset(18,15),compact and 24 or 28) brand.Font=Enum.Font.GothamBlack
 local wallet=text(top,"Wallet","CR  500",UDim2.fromOffset(185,26),UDim2.new(1,-205,0,compact and 70 or 19),14,Color3.fromRGB(255,218,104)) wallet.TextXAlignment=Enum.TextXAlignment.Right
 local pageRoot=frame(root,"Page",UDim2.new(1,0,1,compact and -126 or -110),UDim2.fromOffset(0,compact and 106 or 94),1)
 local toast=text(root,"Notice","",UDim2.new(.8,0,0,36),UDim2.new(.1,0,1,-48),13) toast.TextXAlignment=Enum.TextXAlignment.Center local toastUntil=0
 local storage=text(root,"Storage","",UDim2.new(.7,0,0,16),UDim2.new(.02,0,1,-20),10,muted)
 local controls
 pcall(function() controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls() end)
 local function applyOpen(value)
  open=value gui.Enabled=value if exitGui then exitGui.Enabled=false end player:SetAttribute("FPSGameMenu",value) player:SetAttribute("FPSMenuOpen",value)
  Input.MouseIconEnabled=value
  for _,name in ipairs({"FPSLoadout","FPSMatchHUD","FPSAbilities"}) do local other=pg:FindFirstChild(name) if other then other.Enabled=not value end end
  local hud=pg:FindFirstChild("GunHUD") if hud and value then hud.Enabled=false end
  local match=pg:FindFirstChild("FPSMatchHUD") if match and match:FindFirstChild("Settings") then match.Settings.Visible=false end
  if controls then if value then controls:Disable() else controls:Enable() end end
 end
 local function send(action,value,extra)
  if action~="Sync" and action~="Leave" and player:GetAttribute("FPSProfileReady")~=true then toast.Text="Carregando seu perfil..." toastUntil=os.clock()+3 return end
  R.Session:FireServer(action,value,extra)
 end
 local function inspectWeapon(parent,id,size,pos)
  local viewport=Instance.new("ViewportFrame") viewport.Name="PreviewArma" viewport.Size=size viewport.Position=pos viewport.BackgroundTransparency=1 viewport.Ambient=Color3.fromRGB(180,190,205) viewport.LightColor=Color3.fromRGB(255,232,207) viewport.LightDirection=Vector3.new(-1,-2,-1) viewport.Parent=parent
  local world=Instance.new("WorldModel") world.Parent=viewport local model=Factory.Build(world,1,id)
  for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.Anchored=true end end
  local cf,bounds=model:GetBoundingBox() local focus=cf.Position local length=math.max(bounds.X,bounds.Y,bounds.Z)
  local cam=Instance.new("Camera") cam.FieldOfView=38 cam.Parent=viewport viewport.CurrentCamera=cam
  preview={viewport=viewport,camera=cam,focus=focus,distance=length*(Weapons.Get(id).Kind=="Pistol" and 1.65 or 1.05)} return viewport
 end
 local render
 local function choose(nextPage) page=nextPage if page=="LOJA" and storeTab=="DESTAQUES" then selectedWeapon=state.Featured or "KESTREL" end signature="" render() end
 for i,name in ipairs({"INICIO","JOGAR","ARSENAL","OPERADORES","LOJA","CARREIRA"}) do
  local pos=compact and UDim2.fromOffset(112+((i-1)%3)*66,8+math.floor((i-1)/3)*28) or UDim2.fromOffset(172+(i-1)*105,22)
  local b=button(top,"Nav"..i,name,UDim2.fromOffset(compact and 64 or 99,compact and 25 or 34),pos,function() choose(name) end,false,true) b.TextSize=compact and 9 or 12 b.BackgroundTransparency=1 local stroke=b:FindFirstChildOfClass("UIStroke") if stroke then stroke.Transparency=1 end local indicator=line(b,1,UDim2.new(0,0,1,-2),coral) indicator.Name="Selected" indicator.Visible=false currentNav[name]=b
 end
 local function title(value,sub)
  text(pageRoot,"Title",value,UDim2.new(1,-48,0,40),UDim2.fromOffset(24,4),compact and 24 or 32)
  if sub then text(pageRoot,"Subtitle",sub,UDim2.new(1,-48,0,34),UDim2.fromOffset(24,46),compact and 11 or 13,muted) end
 end
 local function home()
  local x=compact and 24 or .36
  local hero=frame(pageRoot,"Hero",UDim2.new(compact and 1 or .55,compact and -48 or 0,.65,0),compact and UDim2.fromOffset(24,80) or UDim2.fromScale(.34,.25),1)
  text(hero,"Season","FRACTURA / TEMPORADA ZERO",UDim2.new(1,0,0,26),UDim2.fromOffset(0,0),12,coral)
  local logo=text(hero,"Logo","VYREL",UDim2.new(1,0,0,100),UDim2.fromOffset(0,28),compact and 58 or 88) logo.Font=Enum.Font.GothamBlack
  text(hero,"Tagline","ESCOLHA SEU RITMO. ROMPA O CAMPO.",UDim2.new(1,-20,0,44),UDim2.fromOffset(0,125),compact and 11 or 15)
  button(hero,"Play","JOGAR",UDim2.fromOffset(compact and 240 or 290,58),UDim2.fromOffset(0,190),function() choose("JOGAR") end,true)
  if not compact then
   local missions=frame(pageRoot,"Missions",UDim2.fromOffset(258,254),UDim2.new(0,24,.2,0),.22)
   text(missions,"Header","SUA PROXIMA FRONTEIRA",UDim2.new(1,-24,0,32),UDim2.fromOffset(12,8),14)
   line(missions,.9,UDim2.fromOffset(12,43))
      for i,v in ipairs({{"OPERADOR",Agents.Agents[state.Agent].Name},{"ARSENAL",Weapons.Get(state.Primary).Name},{"OBJETIVO","Complete partidas para ganhar creditos"},{"PROGRESSO",(player:GetAttribute("FPSXP") or 0).." XP nesta sessao"}}) do
    text(missions,"Label"..i,v[1],UDim2.new(1,-24,0,18),UDim2.fromOffset(12,55+(i-1)*46),10,muted)
    text(missions,"Value"..i,v[2],UDim2.new(1,-24,0,25),UDim2.fromOffset(12,71+(i-1)*46),13)
   end
   local social=frame(pageRoot,"Social",UDim2.fromOffset(190,240),UDim2.new(1,-210,0,10),.2)
   text(social,"Title","NESTE SERVIDOR",UDim2.new(1,-20,0,30),UDim2.fromOffset(10,6),12)
   for i,p in ipairs(Players:GetPlayers()) do if i<=7 then text(social,"Player"..i,p.DisplayName or p.Name,UDim2.new(1,-20,0,25),UDim2.fromOffset(10,39+(i-1)*26),12,muted) end end
  end
 end
 local function play()
  title("ESCOLHA SEU CAMPO","Primeira pessoa, R6, habilidade e gunplay. Sua skin permanece sua.")
  local choices={{"Casual","CASUAL","ESQUADRAO VS SENTINELAS","Partidas de 5 minutos contra bots taticos. Ganhe creditos e experimente seu operador."},{"Ranked","RANQUEADO","DUELO PVP / PRIMEIRO A 5","Adversarios humanos neste servidor. Vitorias e derrotas ajustam sua classificacao; bots nao alteram Elo."},{"Training","TREINAMENTO","ARSENAL LIVRE","Experimente qualquer arma e pratique habilidades sem precisar comprar o equipamento."}}
  for i,d in ipairs(choices) do
   local size=compact and UDim2.new(1,-48,0,132) or UDim2.new(.3,0,.66,0)
   local pos=compact and UDim2.fromOffset(24,88+(i-1)*140) or UDim2.new(.025+(i-1)*.325,0,0,96)
   local card=frame(pageRoot,"Mode"..i,size,pos,.15) line(card,1,UDim2.fromScale(0,0),i==2 and Color3.fromRGB(173,144,245) or coral)
   text(card,"Name",d[2],UDim2.new(1,-28,0,40),UDim2.fromOffset(14,12),compact and 20 or 25)
   text(card,"Type",d[3],UDim2.new(1,-28,0,32),UDim2.fromOffset(14,48),10,coral)
   text(card,"Description",d[4],UDim2.new(1,-28,compact and 0 or .4,compact and 0 or 0),UDim2.fromOffset(14,90),12,muted).Visible=not compact
   button(card,"Start",state.Queued and d[1]=="Ranked" and "BUSCANDO..." or "ENTRAR",UDim2.new(1,-28,0,compact and 32 or 44),UDim2.new(0,14,1,compact and -42 or -58),function() send("Play",d[1]) end,i==1)
  end
  if state.Queued then button(pageRoot,"CancelQueue","CANCELAR BUSCA",UDim2.fromOffset(230,34),UDim2.new(.5,-115,1,-42),function() send("CancelQueue") end,false) end
 end
 local function weaponPage()
  title(page=="LOJA" and "LOJA / ARMAMENTO" or "ARSENAL", "12 projetos distintos. Creditos de partida, desbloqueios deterministas e teste gratuito no treino.")
  if page=="LOJA" then
   for i,v in ipairs({"DESTAQUES","ARMAS","OPERADORES"}) do button(pageRoot,"Category"..i,v,UDim2.fromOffset(compact and 92 or 135,28),UDim2.fromOffset(24+(i-1)*(compact and 98 or 142),80),function() if v=="OPERADORES" then choose("OPERADORES") else storeTab=v render() end end,false) end
  end
  local list=Instance.new("ScrollingFrame") list.Name="WeaponGrid" list.Size=UDim2.new(compact and .48 or .58,-32,1,-130) list.Position=UDim2.fromOffset(24,120) list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=3 list.Parent=pageRoot
  local columns=compact and 1 or 3 local total=0
  for _,id in ipairs(Weapons.Order) do
   if page~="LOJA" or storeTab~="DESTAQUES" or id==(state.Featured or "KESTREL") or id=="BASIL" or id=="LYRA" then
    local index=total total+=1 local cfg=Weapons.Get(id) local owned=state.Weapons[id] local price=state.Prices and state.Prices[id] or cfg.Price
    local card=button(list,"Weapon"..id,"",UDim2.new(1/columns,-8,0,110),UDim2.new((index%columns)/columns,0,0,math.floor(index/columns)*120),function() selectedWeapon=id render() end,id==selectedWeapon)
    text(card,"Name",cfg.Name,UDim2.new(1,-18,0,35),UDim2.fromOffset(9,12),compact and 10 or 13, id==selectedWeapon and dark or white)
    text(card,"Kind",cfg.Kind,UDim2.new(1,-18,0,20),UDim2.fromOffset(9,47),11,id==selectedWeapon and dark or muted)
    text(card,"Price",owned and "POSSUIDA" or price.." CR",UDim2.new(1,-18,0,22),UDim2.fromOffset(9,78),12,id==selectedWeapon and dark or Color3.fromRGB(255,215,114))
   end
  end
  list.CanvasSize=UDim2.fromOffset(0,math.ceil(total/columns)*120)
  local cfg=Weapons.Get(selectedWeapon) local panel=frame(pageRoot,"WeaponDetails",UDim2.new(compact and .5 or .37,-24,1,-130),UDim2.new(compact and .5 or .62,0,0,120),.3)
  text(panel,"Name",cfg.Name,UDim2.new(1,-24,0,34),UDim2.fromOffset(12,8),compact and 15 or 24)
  inspectWeapon(panel,cfg.Id,UDim2.new(1,0,.42,0),UDim2.fromScale(0,.08))
  text(panel,"Stats",string.format("DANO %d  /  CABECA x%.1f\n%d + %d municoes\n%d tiros/min  |  recarga %.2fs",cfg.Damage,cfg.Critical,cfg.Magazine,cfg.Reserve,math.floor(60/cfg.FireInterval),cfg.ReloadTime),UDim2.new(1,-24,0,92),UDim2.new(0,12,.52,0),compact and 10 or 13)
  text(panel,"Description",cfg.Description,UDim2.new(1,-24,0,60),UDim2.new(0,12,.72,-10),11,muted).Visible=not compact
  local owned=state.Weapons[cfg.Id] local price=state.Prices and state.Prices[cfg.Id] or cfg.Price
  button(panel,"Purchase",owned and "EQUIPAR" or "DESBLOQUEAR / "..price.." CR",UDim2.new(1,-24,0,compact and 36 or 44),UDim2.new(0,12,1,-102),function() send(owned and "Equip" or "Buy","Weapon",cfg.Id) end,true)
  button(panel,"Trial","TESTAR NO TREINO",UDim2.new(1,-24,0,36),UDim2.new(0,12,1,-50),function() send("TryWeapon",cfg.Id) end,false)
 end
 local function avatarPreview(parent)
  local char=player.Character local h=char and char:FindFirstChildOfClass("Humanoid") if not char or not h or h.Health<=0 then return end
  local vp=Instance.new("ViewportFrame") vp.Name="SeuAvatar" vp.Size=UDim2.new(.24,0,0,180) vp.Position=UDim2.new(.73,0,0,62) vp.BackgroundTransparency=1 vp.Ambient=Color3.fromRGB(180,190,210) vp.LightColor=Color3.fromRGB(255,220,200) vp.Parent=parent
  local world=Instance.new("WorldModel") world.Parent=vp
  local old=char.Archivable char.Archivable=true local clone=char:Clone() char.Archivable=old
  for _,v in ipairs(clone:GetDescendants()) do if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Tool") then v:Destroy() elseif v:IsA("BasePart") then v.Anchored=true v.LocalTransparencyModifier=0 end end
  clone:PivotTo(CFrame.new()) clone.Parent=world
  local torso=clone:FindFirstChild("Torso") if torso then for _,name in ipairs({"Right Arm","Left Arm"}) do local arm=clone:FindFirstChild(name) if arm then arm.CFrame=torso.CFrame*CFrame.new(name=="Right Arm" and 1.5 or -1.5,0,0) end end end
  for pass=1,2 do for _,j in ipairs(clone:GetDescendants()) do if j:IsA("Weld") and j.Part0 and j.Part1 then j.Part1.CFrame=j.Part0.CFrame*j.C0*j.C1:Inverse() end end end
  local camera=Instance.new("Camera") camera.FieldOfView=38 camera.CFrame=CFrame.lookAt(Vector3.new(4,2,7),Vector3.new(0,-.3,0)) camera.Parent=vp vp.CurrentCamera=camera
 end
 local function agentPage()
  title("OPERADORES", "3 identidades de combate, 3 habilidades cada. Nenhuma troca de roupa do avatar.")
  for i,id in ipairs(Agents.Order) do local a=Agents.Agents[id]
   local card=button(pageRoot,"Agent"..id,a.Name.."\n"..a.Role,UDim2.new(compact and .28 or .2,0,0,compact and 70 or 92),UDim2.new(.025+(i-1)*(compact and .32 or .23),0,0,88),function() selectedAgent=id render() end,id==selectedAgent)
   card.Text=""
   local color=Color3.fromRGB(table.unpack(a.Color)) line(card,1,UDim2.fromScale(0,0),color)
   local sigil=frame(card,"Sigil",UDim2.fromOffset(14,22),UDim2.fromOffset(12,17),0,color) sigil.Rotation=20+i*12
   text(card,"AgentName",a.Name,UDim2.new(1,-46,0,26),UDim2.fromOffset(38,10),compact and 13 or 19,id==selectedAgent and dark or white)
   text(card,"Role",a.Role,UDim2.new(1,-46,0,32),UDim2.fromOffset(38,38),compact and 9 or 11,id==selectedAgent and dark or muted)
  end
  if not compact then avatarPreview(pageRoot) end
  local a=Agents.Agents[selectedAgent] local color=Color3.fromRGB(table.unpack(a.Color))
  text(pageRoot,"AgentTitle",a.Name.." / "..a.Role,UDim2.new(1,-48,0,40),UDim2.fromOffset(24,compact and 168 or 194),compact and 16 or 24,color)
  for i,skill in ipairs(a.Skills) do
   local card=frame(pageRoot,"Skill"..i,UDim2.new(compact and 1 or .3,compact and -48 or 0,0,compact and 74 or 150),compact and UDim2.fromOffset(24,204+(i-1)*80) or UDim2.new(.025+(i-1)*.325,0,0,252),.18)
   text(card,"Name",skill.Key.." / "..skill.Name,UDim2.new(1,-24,0,32),UDim2.fromOffset(12,6),compact and 13 or 17,color)
   text(card,"Description",skill.Description.."\nRecarga: "..skill.Cooldown.."s",UDim2.new(1,-24,1,-44),UDim2.fromOffset(12,38),compact and 10 or 13,muted)
  end
  local owned=state.Agents[selectedAgent]
  button(pageRoot,"SelectAgent",owned and (state.Agent==selectedAgent and "OPERADOR SELECIONADO" or "SELECIONAR") or "DESBLOQUEAR / "..a.Price.." CR",UDim2.fromOffset(compact and 270 or 340,46),UDim2.new(.5,compact and -135 or -170,1,-58),function() send(owned and "Equip" or "Buy","Agent",selectedAgent) end,true)
 end
 local function career()
  title("SUA TRAJETORIA","Classificacao baseada apenas em duelos humanos. Treinamento e bots nao alteram Elo.")
  local rank=state.Elo<900 and "FERRO" or state.Elo<1100 and "COBRE" or state.Elo<1300 and "PRATA" or state.Elo<1500 and "OURO" or "PRISMA"
  local progress=state.RankMatches<5 and "EM CLASSIFICACAO / "..state.RankMatches.." de 5 partidas" or rank
  text(pageRoot,"Rank",progress,UDim2.new(1,-48,0,60),UDim2.fromOffset(24,100),compact and 23 or 38,coral)
  for i,d in ipairs({{"ELO",state.Elo},{"PARTIDAS RANQUEADAS",state.RankMatches},{"VITORIAS",state.Wins},{"CREDITOS",state.Credits}}) do
   local panel=frame(pageRoot,"CareerStat"..i,UDim2.new(compact and .44 or .21,0,0,100),UDim2.new(.025+((i-1)%(compact and 2 or 4))*(compact and .48 or .24),0,0,210+math.floor((i-1)/(compact and 2 or 4))*114),.2)
   text(panel,"Value",tostring(d[2]),UDim2.new(1,-24,0,52),UDim2.fromOffset(12,8),34)
   text(panel,"Label",d[1],UDim2.new(1,-24,0,26),UDim2.fromOffset(12,66),10,muted)
  end
 end
 render=function()
  for _,c in ipairs(pageLinks) do c:Disconnect() end table.clear(pageLinks) pageRoot:ClearAllChildren() preview=nil
  for name,b in pairs(currentNav) do b.TextColor3=name==page and coral or white b.Selected.Visible=name==page end
  if page=="INICIO" then home() elseif page=="JOGAR" then play() elseif page=="ARSENAL" or page=="LOJA" then weaponPage() elseif page=="OPERADORES" then agentPage() else career() end
 end
 local function update(data)
  if type(data)~="table" or type(data.Weapons)~="table" or type(data.Agents)~="table" then return end state=data
  wallet.Text="CR  "..state.Credits storage.Text=state.Storage=="Carregando" and "Sincronizando perfil..." or state.Storage=="Persistente" and "" or state.Storage=="Em uso" and "Perfil em uso em outro servidor. Treinamento disponivel." or "Progresso desta sessao: DataStore indisponivel neste ambiente."
  if data.Message and data.Message~="" then toast.Text=data.Message toastUntil=os.clock()+5 end
  local id=data.Mode..":"..tostring(data.Queued)..":"..data.Credits..":"..data.Primary..":"..data.Secondary..":"..data.Agent..":"..data.RankMatches
  for _,w in ipairs(Weapons.Order) do if data.Weapons[w] then id=id..":"..w end end for _,a in ipairs(Agents.Order) do if data.Agents[a] then id=id..":"..a end end
  if id~=signature then signature=id render() end
  applyOpen(data.Mode=="Lobby")
 end
 exitGui=Instance.new("ScreenGui") exitGui.Name="VYRELExit" exitGui.IgnoreGuiInset=true exitGui.ResetOnSpawn=false exitGui.DisplayOrder=61 exitGui.Enabled=false exitGui.Parent=pg
 local exitModal=Instance.new("TextButton") exitModal.Text="" exitModal.Size=UDim2.fromScale(1,1) exitModal.BackgroundColor3=dark exitModal.BackgroundTransparency=.2 exitModal.Modal=true exitModal.Parent=exitGui
 local exitPanel=frame(exitGui,"Confirm",UDim2.fromOffset(300,190),UDim2.new(.5,-150,.5,-95),.03)
 text(exitPanel,"Title","SAIR DO RANQUEADO?",UDim2.new(1,-28,0,36),UDim2.fromOffset(14,10),18,coral)
 text(exitPanel,"Warning","Sair agora encerra o duelo como derrota. Voce quer continuar jogando?",UDim2.new(1,-28,0,66),UDim2.fromOffset(14,50),13)
 button(exitPanel,"Stay","CONTINUAR",UDim2.fromOffset(130,36),UDim2.fromOffset(14,132),function() exitGui.Enabled=false player:SetAttribute("FPSMenuOpen",false) Input.MouseIconEnabled=false end,true,true)
 button(exitPanel,"Leave","SAIR",UDim2.fromOffset(130,36),UDim2.fromOffset(156,132),function() exitGui.Enabled=false send("Leave") end,false,true)
 connect(R.SessionState.OnClientEvent,update)
 connect(Input.InputBegan,function(i,processed)
  if processed or Input:GetFocusedTextBox() then return end
  if i.KeyCode==Enum.KeyCode.B and not open then if player:GetAttribute("FPSMode")=="Ranked" then exitGui.Enabled=true player:SetAttribute("FPSMenuOpen",true) Input.MouseIconEnabled=true else send("Leave") end end
 end)
 connect(player.CharacterAdded,function() task.defer(function() applyOpen((player:GetAttribute("FPSMode") or state.Mode or "Lobby")=="Lobby") if open and page=="OPERADORES" then render() end end) end)
 connect(Run.Heartbeat,function(dt)
  if not alive then return end
  if controls then if player:GetAttribute("FPSMenuOpen")==true then controls:Disable() else controls:Enable() end end
  if open then
   loadCity() local time=os.clock()
   cityCamera.CFrame=CFrame.lookAt(Vector3.new(75+math.sin(time*.08)*12,54,345),Vector3.new(0,16,260))
   if preview and preview.viewport.Parent then local angle=.55+math.sin(time*.3)*.2 preview.camera.CFrame=CFrame.lookAt(preview.focus+Vector3.new(math.cos(angle)*preview.distance,preview.distance*.32,math.sin(angle)*preview.distance),preview.focus) end
   if time>syncAt then syncAt=time+3 send("Sync") end
  end
  if os.clock()>toastUntil then toast.Text="" end
 end)
 render() applyOpen(true) send("Sync")
 local function cleanup()
  alive=false for _,c in ipairs(links) do c:Disconnect() end for _,c in ipairs(pageLinks) do c:Disconnect() end applyOpen(false) exitGui:Destroy() gui:Destroy()
 end oldCleanup=cleanup return cleanup
end
return G
]=] end
do local x=node(mods,'ModuleScript',"HUD") x.Source=[=[local Players=game:GetService("Players") local Input=game:GetService("UserInputService")
local C=require(script.Parent.WeaponConfig)
local H={} H.__index=H
function H.new(actions,cfg)
 local C=cfg or C
 local pg=Players.LocalPlayer:WaitForChild("PlayerGui") local gui=pg:FindFirstChild("GunHUD") or Instance.new("ScreenGui") gui.Name="GunHUD" gui.ResetOnSpawn=false gui.DisplayOrder=20 gui.IgnoreGuiInset=true gui.Enabled=false gui.Parent=pg
 local old=gui:FindFirstChild("Root") if old then old:Destroy() end
 local root=Instance.new("Frame") root.Name="Root" root.Size=UDim2.fromScale(1,1) root.BackgroundTransparency=1 root.Parent=gui
 local function label(text,size,pos,fs)
  local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(235,242,248) t.Font=Enum.Font.GothamMedium t.TextSize=fs t.Parent=root return t
 end
 local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
 local compact=Input.TouchEnabled or viewport and viewport.X<1000
 local ammo=label(tostring(C.Magazine),UDim2.fromOffset(90,60),UDim2.new(1,compact and -145 or -516,1,compact and -158 or -130),compact and 36 or 52) ammo.TextXAlignment=Enum.TextXAlignment.Left ammo.Font=Enum.Font.GothamBlack
 local reserveText=label(tostring(C.Reserve).." III",UDim2.fromOffset(88,28),UDim2.new(1,compact and -64 or -426,1,compact and -133 or -103),compact and 14 or 20) reserveText.TextColor3=Color3.fromRGB(242,244,240) reserveText.Font=Enum.Font.GothamBold
 local weapon=label(C.Name,UDim2.fromOffset(210,28),UDim2.new(1,compact and -210 or -516,1,compact and -106 or -76),compact and 15 or 23) weapon.TextXAlignment=Enum.TextXAlignment.Left weapon.Font=Enum.Font.GothamBold
 local debugLabel=label("",UDim2.fromOffset(240,24),UDim2.fromOffset(12,12),12) debugLabel.Visible=C.DebugHUD
 local status=label("",UDim2.new(.8,0,0,24),UDim2.new(.1,0,.6,0),13)
 local hint=label("TAB placar   B menu   M ajustes",UDim2.new(.9,0,0,22),UDim2.new(.05,0,1,-30),11) hint.TextColor3=Color3.fromRGB(151,168,187) hint.Visible=not Input.TouchEnabled hint.Size=UDim2.fromOffset(340,14) hint.Position=UDim2.new(.5,-170,1,-20) hint.TextSize=9
 local cross={}
 for _,v in ipairs({{-7,0,4,1},{4,0,4,1},{0,-7,1,4},{0,4,1,4}}) do local f=Instance.new("Frame") f.Size=UDim2.fromOffset(v[3],v[4]) f.Position=UDim2.new(.5,v[1],.5,v[2]) f.BackgroundColor3=Color3.fromRGB(225,240,248) f.BorderSizePixel=0 f.Parent=root table.insert(cross,f) end
 local dot=Instance.new("Frame") dot.Name="CenterDot" dot.Size=UDim2.fromOffset(2,2) dot.Position=UDim2.new(.5,-1,.5,-1) dot.BorderSizePixel=0 dot.BackgroundColor3=Color3.fromRGB(255,207,109) dot.Parent=root
 local damage=label("",UDim2.fromOffset(100,24),UDim2.new(.5,20,.5,-33),16) damage.Visible=false
 local kill=label("ELIMINADO",UDim2.fromOffset(160,24),UDim2.new(.5,-80,.5,44),11) kill.TextColor3=Color3.fromRGB(255,207,104) kill.Visible=false
 local speedLines={}
 for side=0,1 do for i=1,3 do
  local f=Instance.new("Frame") f.Name="SprintLine" f.Size=UDim2.fromOffset(26+i*6,1) f.Position=UDim2.new(side,side==0 and 14 or -54,.3+i*.11,0) f.Rotation=side==0 and -16 or 16 f.BorderSizePixel=0 f.BackgroundColor3=Color3.fromRGB(223,234,245) f.BackgroundTransparency=1 f.Parent=root table.insert(speedLines,f)
 end end
 local hit=label("×",UDim2.fromOffset(42,42),UDim2.new(.5,-21,.5,-21),32) hit.Visible=false
 local track=Instance.new("Frame") track.Size=UDim2.fromOffset(130,2) track.Position=UDim2.new(.5,-65,.6,26) track.BackgroundColor3=Color3.fromRGB(36,53,71) track.BorderSizePixel=0 track.Visible=false track.Parent=root
 local fill=Instance.new("Frame") fill.Size=UDim2.fromScale(0,1) fill.BackgroundColor3=Color3.fromRGB(76,197,214) fill.BorderSizePixel=0 fill.Parent=track
 local connections={}
 local function button(text,pos,fn,hold)
  local b=Instance.new("TextButton") b.Text=text b.Size=UDim2.fromOffset(64,48) b.Position=pos b.BackgroundColor3=Color3.fromRGB(25,41,58) b.BackgroundTransparency=.15 b.TextColor3=Color3.fromRGB(234,244,248) b.Font=Enum.Font.GothamMedium b.TextSize=12 b.Parent=root b.Visible=Input.TouchEnabled
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,12) c.Parent=b
  if hold then
   local finger
   table.insert(connections,b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then finger=i fn(true) end end))
   table.insert(connections,Input.InputEnded:Connect(function(i) if i==finger then finger=nil fn(false) end end))
  else table.insert(connections,b.Activated:Connect(fn)) end
 end
 button("ATIRAR",UDim2.new(1,-84,.5,30),actions.fire,true)
 button("MIRA",UDim2.new(1,-158,.5,30),actions.aim)
 button("RELOAD",UDim2.new(1,-84,.5,90),actions.reload)
 button("CORRER",UDim2.new(0,20,.5,90),actions.run)
 button("INSPECT",UDim2.new(0,20,.5,30),actions.inspect)
 return setmetatable({weapon=weapon,cfg=C,gui=gui,root=root,ammo=ammo,status=status,debugLabel=debugLabel,ammoBase=compact and 36 or 52,reserveText=reserveText,damage=damage,kill=kill,speedLines=speedLines,sprintWeight=0,hit=hit,cross=cross,dot=dot,bloom=0,track=track,fill=fill,connections=connections},H)
end
function H:SetWeapon(cfg) self.cfg=cfg self.weapon.Text=cfg.Name end
function H:SetVisible(v) self.gui.Enabled=v end
function H:Update(ammo,reserve,state,progress,phase)
 local C=self.cfg
 if C.DebugHUD then self.debugLabel.Text=string.format("%s · %.2fs",state,phase or 0) end
 self.ammo.Text=string.format("%02d",math.max(0,ammo)) self.reserveText.Text=tostring(reserve).." III"
 self.ammo.TextColor3=ammo<=5 and Color3.fromRGB(255,151,133) or Color3.fromRGB(235,242,248)
 self.status.Text=state=="Reloading" and "Recarregando" or state=="Equipping" and "Equipando" or state=="Inspecting" and "Inspecionando" or ""
 self.track.Visible=state=="Reloading" self.fill.Size=UDim2.fromScale(math.clamp(progress or 0,0,1),1)
end
function H:Hit(critical,amount,killed)
 local t=os.clock() self.hitAt=t+.18 self.damageAt=t+.55 self.hit.Visible=true
 local color=critical and Color3.fromRGB(255,192,91) or Color3.fromRGB(235,242,248)
 self.hit.TextColor3=color self.damage.TextColor3=color
 self.damage.Text=amount and string.format("%d%s",math.floor(amount+.5),critical and "!" or "") or ""
 if killed then self.killAt=t+.9 end
end
function H:Pulse() self.bloom=math.min((self.bloom or 0)+3,13) end
function H:Tick(aim,dt,speed,running)
 dt=dt or 1/60 self.bloom=(self.bloom or 0)*math.exp(-dt*13)
 local gap=5+math.clamp((speed or 0)/16,0,1)*4+self.bloom+(running and 6 or 0)
 local offsets={{-gap-4,-.5},{gap,-.5},{-.5,-gap-4},{-.5,gap}}
 for i,f in ipairs(self.cross) do
  f.Position=UDim2.new(.5,offsets[i][1],.5,offsets[i][2]) f.BackgroundTransparency=aim f.Visible=aim<.98
 end
 self.dot.BackgroundTransparency=aim self.dot.Visible=aim<.98
 self.ammo.TextSize=self.ammoBase+math.min(self.bloom,4)*.35
 self.sprintWeight+=((running and 1 or 0)-self.sprintWeight)*(1-math.exp(-dt*9))
 for _,f in ipairs(self.speedLines) do f.BackgroundTransparency=1-self.sprintWeight*.2 end
 local damageLeft=(self.damageAt or 0)-os.clock() self.damage.Visible=damageLeft>0 self.damage.TextTransparency=1-math.clamp(damageLeft/.3,0,1)
 self.damage.Position=UDim2.new(.5,20,.5,-33-(.55-math.max(0,damageLeft))*12)
 local killLeft=(self.killAt or 0)-os.clock() self.kill.Visible=killLeft>0 self.kill.TextTransparency=1-math.clamp(killLeft/.3,0,1)
 local left=(self.hitAt or 0)-os.clock() self.hit.Visible=left>0 self.hit.TextTransparency=1-math.clamp(left/.15,0,1)
end
function H:Destroy() for _,c in ipairs(self.connections) do c:Disconnect() end if self.root.Parent then self.root:Destroy() end end
return H
]=] end
do local x=node(mods,'ModuleScript',"LoadoutController") x.Source=[=[-- Persistent custom loadout: one real weapon slot, never decorative fake weapons.
local Players=game:GetService("Players") local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui") local C=require(script.Parent.WeaponConfig)
local Catalog=require(script.Parent.WeaponCatalog)
local remotes=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem"):WaitForChild("Remotes")
local L={} local previousCleanup
function L.init()
 if previousCleanup then previousCleanup() end
 local player=Players.LocalPlayer local pg=player:WaitForChild("PlayerGui")
 local alive=true local links={} local charLinks={} local saved={}
 local function connect(list,event,fn) table.insert(list,event:Connect(fn)) end
 local function disconnect(list) for _,c in ipairs(list) do c:Disconnect() end table.clear(list) end
 local function disable(attempt)
  if not alive then return end
  local ok=pcall(function()
   for _,kind in ipairs({Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health,Enum.CoreGuiType.PlayerList}) do
    if saved[kind]==nil then saved[kind]=StarterGui:GetCoreGuiEnabled(kind) end
    StarterGui:SetCoreGuiEnabled(kind,false)
   end
  end)
  if not ok and attempt<24 then task.delay(.25,function() disable(attempt+1) end) end
 end
 disable(0)
 local oldMode,oldMin,oldMax=player.CameraMode,player.CameraMinZoomDistance,player.CameraMaxZoomDistance
 local function lockCamera()
  if C.AlwaysFirstPerson and alive then player.CameraMode=Enum.CameraMode.LockFirstPerson player.CameraMinZoomDistance=.5 player.CameraMaxZoomDistance=.5 Input.MouseIconEnabled=player:GetAttribute("FPSMenuOpen")==true end
 end
 lockCamera() connect(links,game:GetService("RunService").Heartbeat,lockCamera)
 local old=pg:FindFirstChild("FPSLoadout") if old then old:Destroy() end
 local gui=Instance.new("ScreenGui") gui.Name="FPSLoadout" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=19 gui.Parent=pg
 local function frame(parent,name,size,pos,color,alpha)
  local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=color f.BackgroundTransparency=alpha or 0 f.BorderSizePixel=0 f.Parent=parent return f
 end
 local function label(parent,name,text,size,pos,fontSize)
  local t=Instance.new("TextLabel") t.Name=name t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1 t.Font=Enum.Font.GothamMedium t.TextSize=fontSize t.TextColor3=Color3.fromRGB(241,245,250) t.TextXAlignment=Enum.TextXAlignment.Left t.Parent=parent return t
 end
 local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
 local compact=Input.TouchEnabled or viewport and viewport.X<1000
 local width=compact and 46 or 66 local gap=compact and 5 or 6 local slotHeight=compact and 56 or 72
 local first=18+width*4+gap*3
 local slot=Instance.new("TextButton") slot.Name="PrimarySlot" slot.Text="" slot.Size=UDim2.fromOffset(width,slotHeight) slot.Position=UDim2.new(1,-first,1,-slotHeight-28) slot.BackgroundColor3=Color3.fromRGB(20,24,30) slot.BackgroundTransparency=.4 slot.BorderSizePixel=0 slot.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,5) corner.Parent=slot
 local border=Instance.new("UIStroke") border.Thickness=1 border.Transparency=.65 border.Color=Color3.fromRGB(220,230,240) border.Parent=slot
 local selected=frame(slot,"Selection",UDim2.new(1,0,0,2),UDim2.new(0,0,1,-2),Color3.fromRGB(245,248,255))
 label(slot,"Key","1",UDim2.fromOffset(16,18),UDim2.new(0,5,1,-20),12)
 local name=label(slot,"Weapon",C.Name,UDim2.new(1,-8,0,16),UDim2.fromOffset(4,2),9) name.Visible=false
 local caption=label(slot,"State","EQUIPAR",UDim2.fromOffset(68,14),UDim2.fromOffset(28,33),9) caption.TextColor3=Color3.fromRGB(152,166,180) caption.Visible=false
 -- Original vector silhouette of this rifle, no external icon assets.
 local icon=frame(slot,"RifleIcon",UDim2.fromOffset(70,24),UDim2.new(.5,compact and -20 or -30,.5,-10),Color3.fromRGB(255,255,255),1)
 for i,d in ipairs({{17,7,30,8},{46,8,19,3},{63,7,5,5},{8,9,10,7},{2,8,7,12},{21,15,5,7},{32,15,7,8},{23,4,17,2}}) do
  frame(icon,"Piece"..i,UDim2.fromOffset(d[3],d[4]),UDim2.fromOffset(d[1],d[2]),Color3.fromRGB(226,234,242))
 end
 local scale=Instance.new("UIScale") scale.Scale=compact and .58 or .85 scale.Parent=icon
 local secondary=Instance.new("TextButton") secondary.Name="SecondarySlot" secondary.Text="" secondary.Size=UDim2.fromOffset(width,slotHeight) secondary.Position=UDim2.new(1,-first+width+gap,1,-slotHeight-28) secondary.BackgroundColor3=Color3.fromRGB(20,24,30) secondary.BackgroundTransparency=.55 secondary.BorderSizePixel=0 secondary.Parent=gui
 local secondaryStroke=Instance.new("UIStroke") secondaryStroke.Color=Color3.fromRGB(245,248,255) secondaryStroke.Transparency=.8 secondaryStroke.Parent=secondary
 label(secondary,"Key","2",UDim2.fromOffset(16,18),UDim2.new(0,5,1,-20),12)
 local secondaryIcon=frame(secondary,"PistolIcon",UDim2.fromOffset(34,11),UDim2.new(.5,-17,.5,-8),Color3.fromRGB(206,217,230))
 local grip=frame(secondaryIcon,"Grip",UDim2.fromOffset(9,17),UDim2.fromOffset(4,8),Color3.fromRGB(206,217,230)) grip.Rotation=-12
 for i=3,4 do
  local empty=Instance.new("Frame") empty.Name="EmptySlot"..i empty.Size=UDim2.fromOffset(width,slotHeight) empty.Position=UDim2.new(1,-first+(i-1)*(width+gap),1,-slotHeight-28) empty.BackgroundColor3=Color3.fromRGB(20,24,30) empty.BackgroundTransparency=.65 empty.BorderSizePixel=0 empty.Parent=gui
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,5) c.Parent=empty
  local key=label(empty,"Key",tostring(i),UDim2.fromOffset(16,18),UDim2.new(0,5,1,-20),12) key.TextTransparency=.4
  local dash=label(empty,"Empty","-",UDim2.new(1,0,1,-20),UDim2.fromOffset(0,0),18) dash.TextXAlignment=Enum.TextXAlignment.Center dash.TextTransparency=.75
 end
 local healthWidth=compact and 130 or 290
 local health=frame(gui,"Health",UDim2.fromOffset(healthWidth,compact and 24 or 30),UDim2.new(0,compact and 18 or 32,1,compact and -132 or -76),Color3.fromRGB(16,19,20),.05)
 local hc=Instance.new("UICorner") hc.CornerRadius=UDim.new(1,0) hc.Parent=health
 local outline=Instance.new("UIStroke") outline.Thickness=2 outline.Transparency=.15 outline.Color=Color3.fromRGB(0,0,0) outline.Parent=health
 local track=frame(health,"Track",UDim2.new(1,-10,1,-10),UDim2.fromOffset(5,5),Color3.fromRGB(42,70,27),0)
 local tc=Instance.new("UICorner") tc.CornerRadius=UDim.new(1,0) tc.Parent=track
 local fill=frame(track,"Fill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Color3.fromRGB(88,255,34))
 local fc=Instance.new("UICorner") fc.CornerRadius=UDim.new(1,0) fc.Parent=fill
 local hp=label(health,"Value","100",UDim2.new(1,-15,1,0),UDim2.fromOffset(0,0),compact and 11 or 14) hp.TextXAlignment=Enum.TextXAlignment.Right hp.TextColor3=Color3.fromRGB(33,92,14) hp.ZIndex=3
 local function humanoid() local char=player.Character return char and char:FindFirstChildOfClass("Humanoid") end
 local function rifle()
  local char=player.Character local bag=player:FindFirstChild("Backpack")
  local tool=char and char:FindFirstChild("Rifle") or bag and bag:FindFirstChild("Rifle")
  return tool and tool:IsA("Tool") and tool or nil
 end
 local function refresh()
  if not alive then return end
  local tool=rifle() local equipped=tool and tool.Parent==player.Character
  local activeId=tool and tool:GetAttribute("WeaponId") or player:GetAttribute("FPSWeapon") or "VETOR"
  local isSecondary=Catalog.Get(activeId).Kind=="Pistol"
  slot.Active=tool~=nil selected.Visible=equipped==true and not isSecondary border.Transparency=equipped and not isSecondary and .15 or .7
  secondaryStroke.Transparency=equipped and isSecondary and .15 or .8
  name.Text=tool and C.Name or "AGUARDANDO" caption.Text=equipped and "EQUIPADO" or "EQUIPAR"
  local h=humanoid() local value=h and math.max(0,h.Health) or 0 local max=h and math.max(1,h.MaxHealth) or 100
  hp.Text=tostring(math.ceil(value)) fill.Size=UDim2.fromScale(math.clamp(value/max,0,1),1)
  fill.BackgroundColor3=value<=max*.3 and Color3.fromRGB(255,112,100) or Color3.fromRGB(88,255,34)
 end
 local function toggle(index)
  if player:GetAttribute("FPSMode")=="Lobby" or player:GetAttribute("FPSGameMenu")==true then return end
  local h=humanoid() local tool=rifle() if not h or h.Health<=0 or not tool then return end
  local desired=index==2 and (player:GetAttribute("FPSSecondary") or "NOMAD") or (player:GetAttribute("FPSPrimary") or "VETOR")
  if (tool:GetAttribute("WeaponId") or "VETOR")~=desired then remotes.Session:FireServer("EquipSlot",index)
  elseif tool.Parent~=player.Character then h:EquipTool(tool) end
  task.defer(refresh)
 end
 connect(links,slot.Activated,function() toggle(1) end) connect(links,secondary.Activated,function() toggle(2) end)
 connect(links,Input.InputBegan,function(i,processed)
  if processed or Input:GetFocusedTextBox() then return end
  if i.KeyCode==Enum.KeyCode.One then toggle(1) elseif i.KeyCode==Enum.KeyCode.Two then toggle(2)
  elseif i.KeyCode==Enum.KeyCode.ButtonR1 then local tool=rifle() toggle(tool and Catalog.Get(tool:GetAttribute("WeaponId")).Kind=="Pistol" and 1 or 2) end
 end)
 local function bindCharacter(char)
  lockCamera()
  disconnect(charLinks)
  if not char then refresh() return end
  connect(charLinks,char.ChildAdded,function() task.defer(refresh) end)
  connect(charLinks,char.ChildRemoved,function() task.defer(refresh) end)
  local h=char:WaitForChild("Humanoid",10)
  if h and player.Character==char then
   connect(charLinks,h.HealthChanged,refresh) connect(charLinks,h.Died,refresh)
  end
  refresh()
 end
 local bag=player:WaitForChild("Backpack",10)
 if bag then connect(links,bag.ChildAdded,refresh) connect(links,bag.ChildRemoved,function() task.defer(refresh) end) end
 connect(links,player.CharacterAdded,bindCharacter)
 if player.Character then bindCharacter(player.Character) else refresh() end
 local function cleanup()
  if not alive then return end alive=false disconnect(links) disconnect(charLinks) gui:Destroy()
  for kind,value in pairs(saved) do pcall(function() StarterGui:SetCoreGuiEnabled(kind,value) end) end
  player.CameraMode=oldMode or Enum.CameraMode.Classic if oldMin then player.CameraMinZoomDistance=oldMin end if oldMax then player.CameraMaxZoomDistance=oldMax end
 end
 previousCleanup=cleanup return cleanup
end
return L
]=] end
do local x=node(mods,'ModuleScript',"MatchHUD") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService") local Input=game:GetService("UserInputService")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local U={} local cleanupPrevious
function U.init()
 if cleanupPrevious then cleanupPrevious() end
 local player=Players.LocalPlayer local pg=player:WaitForChild("PlayerGui") local links={} local alive=true
 local gui=Instance.new("ScreenGui") gui.Name="FPSMatchHUD" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=18 gui.Parent=pg
 local function connect(event,fn) table.insert(links,event:Connect(fn)) end
 local function frame(parent,name,size,pos,alpha)
  local f=Instance.new("Frame") f.Name=name f.Size=size f.Position=pos f.BackgroundColor3=Color3.fromRGB(24,26,33) f.BackgroundTransparency=alpha or .3 f.BorderSizePixel=0 f.Parent=parent return f
 end
 local function text(parent,name,value,size,pos,fontSize)
  local t=Instance.new("TextLabel") t.Name=name t.Text=value t.Size=size t.Position=pos t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(255,255,255) t.Font=Enum.Font.GothamBold t.TextSize=fontSize t.TextStrokeTransparency=.6 t.TextStrokeColor3=Color3.fromRGB(0,0,0) t.TextXAlignment=Enum.TextXAlignment.Left t.Parent=parent return t
 end
 local function round(f,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=f end
 local compact=Input.TouchEnabled or workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize and workspace.CurrentCamera.ViewportSize.X<1000
 local timer=frame(gui,"RoundClock",UDim2.fromOffset(86,42),UDim2.new(.5,-43,0,8),.22) round(timer,6)
 local clock=text(timer,"Time","4:00",UDim2.fromScale(1,1),UDim2.fromScale(0,0),26) clock.TextXAlignment=Enum.TextXAlignment.Center
 local ranking=frame(gui,"Ranking",UDim2.fromOffset(500,94),UDim2.new(.5,-250,0,58),1)
 local tasks=frame(gui,"Tasks",UDim2.fromOffset(compact and 180 or 260,190),UDim2.new(0,16,.35,0),1)
 local heading=text(tasks,"Heading","Objetivos [0/3]",UDim2.new(1,0,0,30),UDim2.fromOffset(0,0),compact and 14 or 19)
 local rows={}
 for i,d in ipairs({{"Equipe uma arma",1,25},{"Elimine alvos",5,75},{"Conclua uma rodada",1,50}}) do
  local row=frame(tasks,"Task"..i,UDim2.new(1,0,0,43),UDim2.fromOffset(0,31+(i-1)*46),1)
  text(row,"Title","> "..d[1],UDim2.new(1,-48,0,20),UDim2.fromOffset(0,0),compact and 10 or 13)
  local track=frame(row,"Track",UDim2.new(1,-60,0,3),UDim2.fromOffset(14,24),.4)
  local fill=frame(track,"Fill",UDim2.fromScale(0,1),UDim2.fromScale(0,0),0) fill.BackgroundColor3=Color3.fromRGB(111,255,45)
  local count=text(row,"Count","0 / "..d[2],UDim2.fromOffset(66,15),UDim2.new(1,-110,0,28),10)
  local reward=text(row,"Reward","+"..d[3].." XP",UDim2.fromOffset(58,20),UDim2.new(1,-58,0,6),compact and 10 or 12) reward.TextColor3=Color3.fromRGB(255,222,54)
  rows[i]={fill=fill,count=count,target=d[2]}
 end
 local xp=text(tasks,"XP","XP da sessao: 0",UDim2.new(1,0,0,18),UDim2.fromOffset(14,174),10)
 local feed=frame(gui,"KillFeed",UDim2.fromOffset(compact and 210 or 360,94),UDim2.new(1,compact and -220 or -372,0,10),1)
 local board=frame(gui,"Scoreboard",UDim2.new(.7,0,.6,0),UDim2.new(.15,0,.2,0),.08) round(board,8) board.Visible=false
 text(board,"Title","PLACAR DA RODADA",UDim2.new(1,-32,0,38),UDim2.fromOffset(16,10),20)
 local boardRows=frame(board,"Players",UDim2.new(1,-32,1,-64),UDim2.fromOffset(16,58),1)
 local settings=frame(gui,"Settings",UDim2.fromOffset(300,190),UDim2.new(.5,-150,.5,-95),.05) round(settings,8) settings.Visible=false
 text(settings,"Title","AJUSTES",UDim2.new(1,-32,0,30),UDim2.fromOffset(16,10),20)
 local function button(y,fn)
  local b=Instance.new("TextButton") b.Size=UDim2.fromOffset(268,34) b.Position=UDim2.fromOffset(16,y) b.BackgroundColor3=Color3.fromRGB(48,52,63) b.TextColor3=Color3.fromRGB(255,255,255) b.Font=Enum.Font.GothamBold b.TextSize=12 b.Parent=settings round(b,4) connect(b.Activated,function() fn(b) end) return b
 end
 local vfx=button(54,function(b) player:SetAttribute("FPSVFXEnabled",player:GetAttribute("FPSVFXEnabled")==false) b.Text="EFEITOS: "..(player:GetAttribute("FPSVFXEnabled")==false and "DESLIGADOS" or "LIGADOS") end) vfx.Text="EFEITOS: "..(player:GetAttribute("FPSVFXEnabled")==false and "DESLIGADOS" or "LIGADOS")
 local fov=button(96,function(b) player:SetAttribute("FPSRunFOV",player:GetAttribute("FPSRunFOV")==false) b.Text="FOV NA CORRIDA: "..(player:GetAttribute("FPSRunFOV")==false and "DESLIGADO" or "LIGADO") end) fov.Text="FOV NA CORRIDA: "..(player:GetAttribute("FPSRunFOV")==false and "DESLIGADO" or "LIGADO")
 local close=button(138,function() settings.Visible=false end) close.Text="FECHAR" close.Modal=true
 local function menu(value)
  settings.Visible=value player:SetAttribute("FPSMenuOpen",value) Input.MouseIconEnabled=value
 end
 connect(close.Activated,function() menu(false) end)
 if compact then
  local menus=frame(gui,"Menus",UDim2.fromOffset(150,28),UDim2.new(0,16,.29,0),1)
  for i,d in ipairs({{"PLACAR",function() board.Visible=not board.Visible end},{"AJUSTES",function() menu(not settings.Visible) end}}) do
   local b=Instance.new("TextButton") b.Text=d[1] b.Size=UDim2.fromOffset(70,26) b.Position=UDim2.fromOffset((i-1)*76,0) b.BackgroundTransparency=.4 b.BackgroundColor3=Color3.fromRGB(24,26,33) b.TextColor3=Color3.fromRGB(255,255,255) b.Font=Enum.Font.GothamBold b.TextSize=10 b.Parent=menus connect(b.Activated,d[2])
  end
 end
 connect(Input.InputBegan,function(i,processed)
  if processed or Input:GetFocusedTextBox() then return end
  if i.KeyCode==Enum.KeyCode.Tab then board.Visible=true elseif i.KeyCode==Enum.KeyCode.V then tasks.Visible=not tasks.Visible elseif i.KeyCode==Enum.KeyCode.M then menu(not settings.Visible) end
 end)
 connect(Input.InputEnded,function(i) if i.KeyCode==Enum.KeyCode.Tab then board.Visible=false end end)
 local messages={} local thumbs={} local signature="" local accumulated=1
 local function sorted()
  local list={} for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("FPSMatchId")==player:GetAttribute("FPSMatchId") then table.insert(list,p) end end
  table.sort(list,function(a,b) local x,y=a:GetAttribute("FPSRoundKills") or 0,b:GetAttribute("FPSRoundKills") or 0 if x==y then return a.UserId<b.UserId end return x>y end)
  return list
 end
 local function refresh()
  if not alive then return end
  local left=math.max(0,math.ceil((player:GetAttribute("FPSMatchEnd") and player:GetAttribute("FPSMatchEnd")>0 and player:GetAttribute("FPSMatchEnd") or system:GetAttribute("FPSRoundEnd") or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
  clock.Text=player:GetAttribute("FPSMode")=="Training" and "TREINO" or string.format("%d:%02d",math.floor(left/60),left%60) clock.TextSize=player:GetAttribute("FPSMode")=="Training" and 16 or 26
  local progress={player:GetAttribute("FPSHasEquipped") and 1 or 0,player:GetAttribute("FPSKills") or 0,player:GetAttribute("FPSRounds") or 0} local done=0
  for i,row in ipairs(rows) do local n=math.min(progress[i],row.target) row.count.Text=n.." / "..row.target row.fill.Size=UDim2.fromScale(n/row.target,1) if n>=row.target then done+=1 end end
  heading.Text="Objetivos ["..done.."/3]" xp.Text="XP da sessao: "..(player:GetAttribute("FPSXP") or 0)
  local list=sorted() local ids={} for _,p in ipairs(list) do table.insert(ids,p.UserId..":"..(p:GetAttribute("FPSRoundKills") or 0)) end
  local key=table.concat(ids,",")
  if key~=signature then
   signature=key ranking:ClearAllChildren() boardRows:ClearAllChildren()
   local max=compact and 5 or 10 local width=compact and 40 or 56 local gap=compact and 6 or 10 local count=math.min(max,#list)
   ranking.Size=UDim2.fromOffset(count*(width+gap),94) ranking.Position=UDim2.new(.5,-count*(width+gap)/2,0,58)
   for i,p in ipairs(list) do
    if i<=max then
     local card=frame(ranking,"Rank"..i,UDim2.fromOffset(width,64),UDim2.fromOffset((i-1)*(width+gap),15),0) card.BackgroundColor3=i==1 and Color3.fromRGB(119,82,21) or Color3.fromRGB(91,40,149) round(card,9)
     local rank=text(card,"Rank","#"..i,UDim2.new(1,0,0,20),UDim2.fromOffset(0,-20),16) rank.TextXAlignment=Enum.TextXAlignment.Center
     local initial=text(card,"Initial",string.sub(p.DisplayName or p.Name,1,1),UDim2.fromScale(1,1),UDim2.fromScale(0,0),24) initial.TextXAlignment=Enum.TextXAlignment.Center
     local pic=Instance.new("ImageLabel") pic.Name="Avatar" pic.Size=UDim2.fromScale(1,1) pic.BackgroundTransparency=1 pic.Parent=card
     if thumbs[p.UserId] then pic.Image=thumbs[p.UserId] initial.Visible=false else
      task.spawn(function() local ok,url=pcall(function() return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end) if ok then thumbs[p.UserId]=url if alive and pic.Parent then pic.Image=url initial.Visible=false end end end)
     end
     local score=text(card,"Score",tostring(p:GetAttribute("FPSRoundKills") or 0),UDim2.new(1,0,0,32),UDim2.fromOffset(0,48),compact and 24 or 32) score.TextXAlignment=Enum.TextXAlignment.Center score.ZIndex=3
    end
    if i<=12 then text(boardRows,"Player"..i,string.format("%d.  %s    %d",i,p.DisplayName or p.Name,p:GetAttribute("FPSRoundKills") or 0),UDim2.new(1,0,0,26),UDim2.fromOffset(0,(i-1)*28),16) end
   end
  end
  for i=#messages,1,-1 do if workspace:GetServerTimeNow()-messages[i].at>5 then messages[i].frame:Destroy() table.remove(messages,i) end end
  for i,m in ipairs(messages) do m.frame.Position=UDim2.fromOffset(0,(i-1)*29) end
 end
 connect(system.Remotes:WaitForChild("MatchFeed").OnClientEvent,function(attacker,victim,critical,arena)
  if arena and arena~=player:GetAttribute("FPSMatchId") then return end
  if type(attacker)~="string" or type(victim)~="string" then return end
  local row=frame(feed,"Elimination",UDim2.new(1,0,0,25),UDim2.fromOffset(0,0),.18) round(row,4)
  local label=text(row,"Names",attacker.."   [VETOR] "..(critical and "* " or "")..victim,UDim2.new(1,-12,1,0),UDim2.fromOffset(6,0),compact and 10 or 13) label.TextTruncate=Enum.TextTruncate.AtEnd
  table.insert(messages,1,{frame=row,at=workspace:GetServerTimeNow()}) if #messages>3 then messages[#messages].frame:Destroy() table.remove(messages) end refresh()
 end)
 connect(Run.Heartbeat,function(dt) accumulated+=dt if accumulated>=.25 then accumulated=0 refresh() end end)
 refresh()
 local function cleanup() alive=false player:SetAttribute("FPSMenuOpen",false) for _,c in ipairs(links) do c:Disconnect() end gui:Destroy() end
 cleanupPrevious=cleanup return cleanup
end
return U
]=] end
do local x=node(mods,'ModuleScript',"MatchState") x.Source=[=[-- Server-owned session statistics and a real four-minute round clock.
local Players=game:GetService("Players") local Run=game:GetService("RunService")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local M={} local started=false local duration=240
local function add(p,key,n) p:SetAttribute(key,(p:GetAttribute(key) or 0)+n) end
local function rewards(p)
 for _,d in ipairs({{"Equip",p:GetAttribute("FPSHasEquipped") and 1 or 0,1,25},{"Kills",p:GetAttribute("FPSKills") or 0,5,75},{"Rounds",p:GetAttribute("FPSRounds") or 0,1,50}}) do
  if d[2]>=d[3] and not p:GetAttribute("FPSReward"..d[1]) then p:SetAttribute("FPSReward"..d[1],true) add(p,"FPSXP",d[4]) end
 end
end
local function bind(p)
 for _,key in ipairs({"FPSKills","FPSRoundKills","FPSDeaths","FPSRounds","FPSWins","FPSXP"}) do if p:GetAttribute(key)==nil then p:SetAttribute(key,0) end end
 rewards(p)
end
function M.Init()
 if started then return end started=true
 system:SetAttribute("FPSRoundEnd",workspace:GetServerTimeNow()+duration) system:SetAttribute("FPSRound",1)
 Players.PlayerAdded:Connect(bind) for _,p in ipairs(Players:GetPlayers()) do bind(p) end
 Run.Heartbeat:Connect(function()
  if workspace:GetServerTimeNow()<(system:GetAttribute("FPSRoundEnd") or math.huge) then return end
  local best=0 local winners={}
  for _,p in ipairs(Players:GetPlayers()) do
   local score=p:GetAttribute("FPSRoundKills") or 0
   if score>best then best=score winners={p} elseif score==best and score>0 then table.insert(winners,p) end
  end
  if #winners==1 then add(winners[1],"FPSWins",1) end
  for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("FPSMode")==nil then add(p,"FPSRounds",1) p:SetAttribute("FPSRoundKills",0) rewards(p) end end
  system:SetAttribute("FPSRound",(system:GetAttribute("FPSRound") or 1)+1)
  system:SetAttribute("FPSRoundEnd",workspace:GetServerTimeNow()+duration)
 end)
end
function M.Equip(p) M.Init() p:SetAttribute("FPSHasEquipped",true) rewards(p) end
function M.Kill(p,model,critical)
 M.Init() add(p,"FPSKills",1) add(p,"FPSRoundKills",1) add(p,"FPSXP",10) rewards(p)
 local victim=Players:GetPlayerFromCharacter(model) if victim then add(victim,"FPSDeaths",1) end
 system.Remotes.MatchFeed:FireAllClients(p.DisplayName or p.Name,victim and (victim.DisplayName or victim.Name) or model.Name,critical==true,p:GetAttribute("FPSMatchId"))
 if p:GetAttribute("FPSMode") then require(script.Parent.SessionService).RecordKill(p,victim) end
end
function M.Complete(p) rewards(p) end
return M
]=] end
do local x=node(mods,'ModuleScript',"MovementService") x.Source=[=[local Run=game:GetService("RunService") local Players=game:GetService("Players")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem") local Combat=require(script.Parent.CombatService)
local M={} local initialized=false local active={}
local function stop(p,s)
 if s.root and s.root.Parent then
  local v=s.root.AssemblyLinearVelocity s.root.AssemblyLinearVelocity=Vector3.new(0,v.Y,0)
  pcall(function() s.root:SetNetworkOwner(p) end)
 end
 if s.h and s.h.Parent then s.h.AutoRotate=s.auto s.h.WalkSpeed=p:GetAttribute("FPSMode")=="Lobby" and 0 or s.speed end active[p]=nil
end
function M.Dash(p,direction)
 local now=workspace:GetServerTimeNow() local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid") local root=char and char:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not root or h.FloorMaterial==Enum.Material.Air or p:GetAttribute("FPSMode")=="Lobby" or now<(p:GetAttribute("FPSNextDash") or 0) or active[p] then return false end
 if typeof(direction)~="Vector3" or direction.X~=direction.X or direction.Y~=direction.Y or direction.Z~=direction.Z or direction.Magnitude>2 then return false end
 local dir=Vector3.new(direction.X,0,direction.Z) if dir.Magnitude<.1 then dir=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z) end if dir.Magnitude<.1 then return false end dir=dir.Unit
 local params=Combat.Params({char}) local length=8
 local hit=workspace:Blockcast(root.CFrame,Vector3.new(1.8,3.5,1.5),dir*length,params) if hit then length=math.max(0,hit.Distance-.8) end if length<1 then return false end
 local time=.18 local s={root=root,h=h,char=char,start=root.Position,dir=dir,length=length,finish=now+time,speed=h.WalkSpeed,auto=h.AutoRotate}
 active[p]=s p:SetAttribute("FPSNextDash",now+4) char:SetAttribute("FPSDashUntil",now+time+.08) char:SetAttribute("FPSDashDirection",dir)
 h.AutoRotate=false h.WalkSpeed=0 pcall(function() root:SetNetworkOwner(nil) end)
 system.Remotes.SkillFX:FireAllClients("Dash",root.Position,root.Position+dir*length,p:GetAttribute("FPSAgent"),p.UserId)
 return true
end
function M.Init()
 if initialized then return end initialized=true
 Run.Heartbeat:Connect(function(dt)
  local now=workspace:GetServerTimeNow()
  for p,s in pairs(active) do
   if p.Character~=s.char or p:GetAttribute("FPSMode")=="Lobby" or (s.char:GetAttribute("FPSDashUntil") or 0)<=now or not s.root.Parent or s.h.Health<=0 or now>=s.finish then stop(p,s)
   else
    local remain=math.max(0,s.length-(s.root.Position-s.start):Dot(s.dir))
    local hit=workspace:Blockcast(s.root.CFrame,Vector3.new(1.8,3.5,1.5),s.dir*math.min(remain,48*dt+.4),Combat.Params({s.char}))
    if hit or remain<.35 then stop(p,s) else local v=s.root.AssemblyLinearVelocity s.root.AssemblyLinearVelocity=s.dir*math.min(48,remain/math.max(.02,s.finish-now))+Vector3.new(0,v.Y,0) end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) if active[p] then stop(p,active[p]) end end)
end
return M
]=] end
do local x=node(mods,'ModuleScript',"ProfileService") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService")
local Http=game:GetService("HttpService") local Catalog=require(script.Parent.WeaponCatalog) local Agents=require(script.Parent.AgentCatalog)
local P={} local profiles={} local initialized=false local token=(game.JobId or "")..Http:GenerateGUID(false)
local store local ok,result=pcall(function() return game:GetService("DataStoreService"):GetDataStore("VYREL_Profile_v1") end) if ok then store=result end
local function default()
 return {Version=1,Credits=500,Weapons={VETOR=true,NOMAD=true},Agents={ION=true},Primary="VETOR",Secondary="NOMAD",Agent="ION",Elo=1000,RankMatches=0,Wins=0}
end
local function sanitize(d)
 local n=default() if type(d)~="table" then return n end
 for _,key in ipairs({"Credits","Elo","RankMatches","Wins"}) do if type(d[key])=="number" and d[key]==d[key] then n[key]=math.clamp(math.floor(d[key]),0,10000000) end end
 for id,v in pairs(type(d.Weapons)=="table" and d.Weapons or {}) do if v==true and Catalog.Weapons[id] then n.Weapons[id]=true end end
 for id,v in pairs(type(d.Agents)=="table" and d.Agents or {}) do if v==true and Agents.Agents[id] then n.Agents[id]=true end end
 if n.Weapons[d.Primary] and Catalog.Get(d.Primary).Kind~="Pistol" then n.Primary=d.Primary end
 if n.Weapons[d.Secondary] and Catalog.Get(d.Secondary).Kind=="Pistol" then n.Secondary=d.Secondary end
 if n.Agents[d.Agent] then n.Agent=d.Agent end return n
end
local function dirty(s) s.Dirty=true s.Revision=(s.Revision or 0)+1 end
local function attrs(p,s)
 p:SetAttribute("FPSCredits",s.Data.Credits) p:SetAttribute("FPSAgent",s.Data.Agent)
 p:SetAttribute("FPSPrimary",s.Data.Primary) p:SetAttribute("FPSSecondary",s.Data.Secondary)
 p:SetAttribute("FPSElo",s.Data.Elo) p:SetAttribute("FPSRankMatches",s.Data.RankMatches)
 p:SetAttribute("FPSStorage",s.Savable and "Persistente" or s.ReadOnly and "Em uso" or "Sessao") p:SetAttribute("FPSProfileReady",true)
end
function P.Load(p)
 if profiles[p] then return profiles[p] end
 local s={Data=default(),Savable=false,ReadOnly=false,Dirty=false,Loading=true} profiles[p]=s
 if store and p.UserId>0 then
  local busy=false
  local loaded,data
  for attempt=1,3 do
   loaded,data=pcall(function() return store:UpdateAsync("u_"..p.UserId,function(old)
   if type(old)=="table" and old.Session and old.Session~=token and os.time()-(old.Touch or 0)<120 then busy=true return nil end
   local next=sanitize(old) next.Session=token next.Touch=os.time() return next
   end) end)
   if loaded or Run:IsStudio() then break end if attempt<3 then task.wait(attempt) end
  end
  if loaded and type(data)=="table" then s.Data=sanitize(data) s.Savable=true elseif busy then s.ReadOnly=true end
 end
 s.Loading=false attrs(p,s) return s
end
function P.Get(p)
 local s=profiles[p] or P.Load(p)
 local deadline=os.clock()+10 while s.Loading and p.Parent and os.clock()<deadline do task.wait(.05) end
 return s.Data,s
end
function P.Save(p,release)
 local s=profiles[p] if not s or not s.Savable or s.Loading or s.Saving then return false end s.Saving=true
 local written=false local writtenRevision=-1
 local success=pcall(function() store:UpdateAsync("u_"..p.UserId,function(old)
  if type(old)=="table" and old.Session and old.Session~=token then return nil end
  written=true writtenRevision=s.Revision or 0 local out=sanitize(s.Data) out.Session=release and nil or token out.Touch=os.time() return out
 end) end)
 s.Saving=false if success and written then s.Dirty=(s.Revision or 0)~=writtenRevision else if success then s.Savable=false s.ReadOnly=true attrs(p,s) end end return success and written
end
function P.Snapshot(p)
 local d,s=P.Get(p) local prices={} for id in pairs(Catalog.Weapons) do prices[id]=P.Price(id,"Weapon") end return {Prices=prices,Featured=Catalog.Order[math.floor(os.time()/86400)%#Catalog.Order+1],Credits=d.Credits,Weapons=d.Weapons,Agents=d.Agents,Primary=d.Primary,Secondary=d.Secondary,Agent=d.Agent,Elo=d.Elo,RankMatches=d.RankMatches,Wins=d.Wins,Storage=s.Loading and "Carregando" or s.Savable and "Persistente" or s.ReadOnly and "Em uso" or "Sessao"}
end
function P.Price(id,kind)
 if kind=="Agent" then local a=Agents.Agents[id] return a and a.Price end
 local w=Catalog.Weapons[id] if not w then return nil end
 local day=math.floor(os.time()/86400) local featured=Catalog.Order[day%#Catalog.Order+1]
 return id==featured and math.floor(w.Price*.8) or w.Price
end
function P.Buy(p,kind,id)
 if type(id)~="string" or (kind~="Weapon" and kind~="Agent") then return false,"Item invalido." end
 local d,s=P.Get(p) if s.ReadOnly or s.Loading then return false,"Progresso indisponivel; use o treinamento." end
 local price=P.Price(id,kind) if price==nil then return false,"Item inexistente." end
 local owned=kind=="Agent" and d.Agents or d.Weapons
 if owned[id] then return false,"Voce ja possui este item." end
 if d.Credits<price then return false,"Creditos insuficientes." end
 d.Credits-=price owned[id]=true dirty(s) attrs(p,s) task.spawn(P.Save,p,false) return true,"Desbloqueado!"
end
function P.Equip(p,kind,id)
 local d,s=P.Get(p) if s.Loading then return false,"Carregando perfil." end
 if kind=="Agent" then if not d.Agents[id] then return false,"Operador bloqueado." end d.Agent=id
 elseif kind=="Weapon" then
  if not d.Weapons[id] then return false,"Arma bloqueada." end
  if Catalog.Get(id).Kind=="Pistol" then d.Secondary=id else d.Primary=id end
 else return false,"Categoria invalida." end
 dirty(s) attrs(p,s) return true,"Equipado."
end
function P.Reward(p,amount)
 local d,s=P.Get(p) if s.ReadOnly or s.Loading or amount<=0 then return end
 d.Credits=math.clamp(d.Credits+math.max(0,math.floor(amount)),0,10000000) dirty(s) attrs(p,s)
end
function P.RankedResult(p,win)
 local d,s=P.Get(p) if s.ReadOnly then return end
 d.RankMatches+=1 d.Elo=math.clamp(d.Elo+(win==true and 24 or win==false and -18 or 0),100,3000) if win==true then d.Wins+=1 end
 dirty(s) P.Reward(p,win==true and 100 or win==false and 45 or 60) attrs(p,s) task.spawn(P.Save,p,false)
end
function P.Init()
 if initialized then return end initialized=true
 Players.PlayerAdded:Connect(function(p) task.spawn(P.Load,p) end)
 Players.PlayerRemoving:Connect(function(p) if P.BeforeRelease then P.BeforeRelease(p) end local s=profiles[p] local deadline=os.clock()+10 while s and s.Saving and os.clock()<deadline do task.wait(.05) end P.Save(p,true) profiles[p]=nil end)
 for _,p in ipairs(Players:GetPlayers()) do task.spawn(P.Load,p) end
 local accumulated=0 Run.Heartbeat:Connect(function(dt) accumulated+=dt if accumulated>=45 then accumulated=0 for p in pairs(profiles) do task.spawn(P.Save,p,false) end end end)
 game:BindToClose(function() local pending=0 for p in pairs(profiles) do pending+=1 task.spawn(function() P.Save(p,true) pending-=1 end) end local untilTime=os.clock()+6 while pending>0 and os.clock()<untilTime do task.wait(.1) end end)
end
P.Default=default P.Sanitize=sanitize
return P
]=] end
do local x=node(mods,'ModuleScript',"Recoil") x.Source=[=[local Spring=require(script.Parent.Spring)
local R={} R.__index=R
function R.new(scale) return setmetatable({scale=scale or 1,spring=Spring.new(Vector3.zero,20),random=Random.new()},R) end
function R:Fire(ads) self.spring:Impulse(Vector3.new(ads and .32 or .65,self.random:NextNumber(-.12,.12)*(ads and .45 or 1),0)*self.scale) end
function R:Step(dt) local v=self.spring:Step(dt) return Vector3.new(math.clamp(v.X,-.02,.045),math.clamp(v.Y,-.025,.025),0) end
return R
]=] end
do local x=node(mods,'ModuleScript',"SessionService") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem") local R=system.Remotes
local Profiles=require(script.Parent.ProfileService) local Catalog=require(script.Parent.WeaponCatalog) local World=require(script.Parent.WorldService)
local S={WeaponChanged=Instance.new("BindableEvent")} local ready=false local queue={} local matches={} local last={} local lastSync={} local busy={} local casualEnd=0 local serial=0
local function now() return workspace:GetServerTimeNow() end
function S.Send(p,message)
 if not p.Parent then return end local data=Profiles.Snapshot(p)
 data.Mode=p:GetAttribute("FPSMode") or "Lobby" data.Queued=queue[p]~=nil data.Weapon=p:GetAttribute("FPSWeapon") or data.Primary data.Message=message or "" data.RoundEnd=p:GetAttribute("FPSMatchEnd") or 0
 R.SessionState:FireClient(p,data)
end
local function move(p)
 local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid") local root=char and char:FindFirstChild("HumanoidRootPart")
 if h then h:UnequipTools() h.WalkSpeed=p:GetAttribute("FPSMode")=="Lobby" and 0 or 16 if h.Health>0 then h.Health=h.MaxHealth end end
 if root then root.AssemblyLinearVelocity=Vector3.zero root.CFrame=CFrame.new(World.GetSpawn(p)) end
end
local function setMode(p,mode,arena,matchId,side,deadline)
 p:SetAttribute("FPSMode",mode) p:SetAttribute("FPSArena",arena) p:SetAttribute("FPSMatchId",matchId) p:SetAttribute("FPSSide",side or "Human") p:SetAttribute("FPSMatchEnd",deadline or 0)
 p:SetAttribute("FPSRoundKills",0) p:SetAttribute("FPSNextDash",0) p:SetAttribute("FPSMatchJoined",now())
 for i=1,3 do p:SetAttribute("FPSNextSkill"..i,0) end
 local char=p.Character if char then
  for _,key in ipairs({"FPSDashUntil","FPSCastUntil","FPSShieldUntil","FPSShield","FPSBoostUntil","FPSSlowUntil"}) do char:SetAttribute(key,0) end
  local glow=char:FindFirstChild("VYRELShield") if glow then glow:Destroy() end
 end
 queue[p]=nil move(p)
 local d=Profiles.Get(p) local weapon=p:GetAttribute("FPSTrialWeapon")
 if mode~="Training" or not Catalog.Weapons[weapon] then weapon=d.Primary end
 p:SetAttribute("FPSWeapon",weapon) S.WeaponChanged:Fire(p,weapon,true) S.Send(p)
end
local function complete(p,reward)
 p:SetAttribute("FPSRounds",(p:GetAttribute("FPSRounds") or 0)+1)
 Profiles.Reward(p,reward)
 local Match=require(script.Parent.MatchState) if Match.Complete then Match.Complete(p) end
end
local function finishRanked(index,winner,leaver)
 local m=matches[index] if not m or m.Done then return end m.Done=true matches[index]=nil
 for _,p in ipairs(m.Players) do
  local outcome if winner then outcome=p==winner end Profiles.RankedResult(p,outcome) complete(p,0)
  p:SetAttribute("FPSLastResult",p==winner and "VITORIA" or winner and "DERROTA" or "EMPATE")
  if p~=leaver and p.Parent then setMode(p,"Lobby","Lobby","Lobby",nil,0) S.Send(p,p==winner and "Vitoria ranqueada!" or "Partida ranqueada encerrada.") end
 end
end
local function cancelQueue(p) queue[p]=nil end
function S.Leave(p)
 cancelQueue(p)
 for i,m in pairs(matches) do if m.Players[1]==p or m.Players[2]==p then finishRanked(i,m.Players[1]==p and m.Players[2] or m.Players[1],p) end end
end
function S.RecordKill(p,victim)
 if p:GetAttribute("FPSMode")=="Ranked" then
  for i,m in pairs(matches) do
   if (m.Players[1]==p or m.Players[2]==p) and victim and victim:GetAttribute("FPSMatchId")==p:GetAttribute("FPSMatchId") then
    if (p:GetAttribute("FPSRoundKills") or 0)>=5 then finishRanked(i,p) end
   end
  end
 elseif p:GetAttribute("FPSMode")=="Casual" then Profiles.Reward(p,6) end
end
local function request(p,command,value,extra)
 if command=="Sync" then S.Send(p) return end
 if command=="CancelQueue" then cancelQueue(p) S.Send(p,"Busca cancelada.") return end
 if command=="Leave" then S.Leave(p) setMode(p,"Lobby","Lobby","Lobby",nil,0) return end
 if command=="Play" then
  if p:GetAttribute("FPSMode")~="Lobby" then S.Send(p,"Volte ao menu antes de trocar de modo.") return end
  local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid") if not char or not char:FindFirstChild("Torso") or not h or h.Health<=0 then S.Send(p,"Preparando seu avatar R6...") return end
  local d,state=Profiles.Get(p) if state.Loading then S.Send(p,"Perfil carregando.") return end
  if value=="Ranked" then
   if state.ReadOnly then S.Send(p,"Progresso em uso. Treinamento disponivel.") return end
   queue[p]=now() S.Send(p,"Buscando um adversario humano neste servidor...")
  elseif value=="Training" then setMode(p,"Training","Training","Training","Human",0)
  elseif value=="Casual" then if casualEnd<=now() then casualEnd=now()+300 end setMode(p,"Casual","Casual","Casual","Human",casualEnd) end
  return
 end
 if command=="EquipSlot" then
  if value~=1 and value~=2 then return end local d=Profiles.Get(p) local id=value==2 and d.Secondary or d.Primary
  if p:GetAttribute("FPSMode")=="Training" and value==1 and Catalog.Weapons[p:GetAttribute("FPSTrialWeapon")] then id=p:GetAttribute("FPSTrialWeapon") end
  p:SetAttribute("FPSWeapon",id) S.WeaponChanged:Fire(p,id,false) S.Send(p) return
 end
 if p:GetAttribute("FPSMode")~="Lobby" then S.Send(p,"A loja e a selecao ficam disponiveis no menu.") return end
 if command=="Buy" then local ok,message=Profiles.Buy(p,value,extra) S.Send(p,message)
 elseif command=="Equip" then
  local ok,message=Profiles.Equip(p,value,extra) if ok and value=="Weapon" then local d=Profiles.Get(p) p:SetAttribute("FPSTrialWeapon",nil) p:SetAttribute("FPSWeapon",d.Primary) S.WeaponChanged:Fire(p,d.Primary,true) end S.Send(p,message)
 elseif command=="TryWeapon" and Catalog.Weapons[value] then p:SetAttribute("FPSTrialWeapon",value) setMode(p,"Training","Training","Training","Human",0)
 end
end
function S.Init()
 if ready then return end ready=true World.Build() Profiles.Init()
 local function bind(p)
  p:SetAttribute("FPSMode","Lobby") p:SetAttribute("FPSArena","Lobby") p:SetAttribute("FPSMatchId","Lobby") p:SetAttribute("FPSSide","Human") p:SetAttribute("FPSWeapon","VETOR")
 end
 Players.PlayerAdded:Connect(bind) for _,p in ipairs(Players:GetPlayers()) do bind(p) end
 Profiles.BeforeRelease=S.Leave
 Players.PlayerRemoving:Connect(function(p) S.Leave(p) last[p]=nil lastSync[p]=nil busy[p]=nil end)
 R.Session.OnServerEvent:Connect(function(p,command,value,extra)
  if type(command)~="string" or busy[p] then return end
  if command=="Sync" then if now()-(lastSync[p] or -math.huge)<.5 then return end lastSync[p]=now()
  else if now()-(last[p] or -math.huge)<.1 then return end last[p]=now() end
  busy[p]=true
  local ok,err=pcall(request,p,command,value,extra) busy[p]=nil if not ok then warn("[VYREL] Session: "..tostring(err)) S.Send(p,"Nao foi possivel concluir esta acao.") end
 end)
 local accumulated=0 Run.Heartbeat:Connect(function(dt)
  accumulated+=dt if accumulated<.5 then return end accumulated=0
  local waiting={} for p,t in pairs(queue) do if p.Parent and p:GetAttribute("FPSMode")=="Lobby" then table.insert(waiting,p) else queue[p]=nil end end
  table.sort(waiting,function(a,b) return (queue[a] or 0)<(queue[b] or 0) end)
  for i=1,3 do if not matches[i] and #waiting>=2 then
   local first=waiting[1] local elo=Profiles.Get(first).Elo local bestIndex=2 local distance=math.huge
   for j=2,#waiting do local d=math.abs(Profiles.Get(waiting[j]).Elo-elo) if d<distance then distance=d bestIndex=j end end
   local a=table.remove(waiting,1) local b=table.remove(waiting,bestIndex-1) local deadline=now()+240 serial+=1 local id="Ranked"..i.."_"..serial
   matches[i]={Players={a,b},End=deadline,Id=id}
   setMode(a,"Ranked","Ranked"..i,id,"A",deadline) setMode(b,"Ranked","Ranked"..i,id,"B",deadline)
  end end
  for i,m in pairs(matches) do if now()>=m.End then
   local a,b=m.Players[1],m.Players[2] local x,y=a:GetAttribute("FPSRoundKills") or 0,b:GetAttribute("FPSRoundKills") or 0
   finishRanked(i,x>y and a or y>x and b or nil)
  end end
  if casualEnd>0 and now()>=casualEnd then
   casualEnd=now()+300
   for _,p in ipairs(Players:GetPlayers()) do if p:GetAttribute("FPSMode")=="Casual" then
    complete(p,now()-(p:GetAttribute("FPSMatchJoined") or now())>=60 and 70 or 15)
    p:SetAttribute("FPSRoundKills",0) p:SetAttribute("FPSMatchEnd",casualEnd) S.Send(p,"Rodada concluida. Nova rodada iniciada!")
   end end
  end
 end)
end
return S
]=] end
do local x=node(mods,'ModuleScript',"SkillService") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService") local CS=game:GetService("CollectionService") local Debris=game:GetService("Debris")
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem") local R=system.Remotes
local Agents=require(script.Parent.AgentCatalog) local Combat=require(script.Parent.CombatService) local Movement=require(script.Parent.MovementService)
local K={} local started=false local projectiles={} local fields={} local sensors={} local smoke={}
local folder=Instance.new("Folder") folder.Name="VYRELAbilities" folder.Parent=workspace
local function now() return workspace:GetServerTimeNow() end
local function fx(p,name,a,b) R.SkillFX:FireAllClients(name,a,b,p:GetAttribute("FPSAgent") or "ION",p.UserId) end
local function part(name,size,cf,color,duration)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.Neon p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=folder Debris:AddItem(p,duration) return p
end
local function entities()
 local out={} for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(out,{actor=p,model=p.Character}) end end
 for _,m in ipairs(CS:GetTagged("FPSDemoBot")) do if m.Parent then table.insert(out,{actor=m,model=m}) end end
 for _,m in ipairs(CS:GetTagged("VyrelDecoy")) do if m.Parent then table.insert(out,{actor=m,model=m}) end end return out
end
local function allied(p,actor)
 return p:GetAttribute("FPSMatchId")==actor:GetAttribute("FPSMatchId") and p:GetAttribute("FPSSide")==actor:GetAttribute("FPSSide")
end
local function rootOf(model) return model:FindFirstChild("HumanoidRootPart") end
local function burst(p,pos)
 fx(p,"ArcBurst",pos,7)
 for _,e in ipairs(entities()) do local root=rootOf(e.model)
  if root and (root.Position-pos).Magnitude<=7 and Combat.Allowed(p,e.model) and Combat.Visible(pos,root.Position,{p.Character,e.model}) then
   Combat.Apply(p,e.model,12,false,root.Position) e.model:SetAttribute("FPSSlowUntil",now()+2)
  end
 end
end
function K.SmokeBlocks(a,b,matchId)
 local delta=b-a local squared=delta:Dot(delta) if squared<.01 then return false end
 for _,s in ipairs(smoke) do if s.finish>now() and s.match==matchId then local t=math.clamp((s.pos-a):Dot(delta)/squared,0,1) if (a+delta*t-s.pos).Magnitude<s.radius then return true end end end return false
end
function K.OnShot(actor,pos)
 local model=actor:IsA("Player") and actor.Character or actor
 for _,s in ipairs(sensors) do if s.part.Parent and s.finish>now() and s.owner.Parent and model and Combat.Allowed(s.owner,model) and (s.part.Position-pos).Magnitude<25 and now()-(s.last or 0)>.7 then
  s.last=now() R.SkillFX:FireClient(s.owner,"SoundPing",pos,.7,"VEU",0)
 end end
end
local function cast(p,index,direction)
 local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid") local root=char and rootOf(char)
 if not root or not h or h.Health<=0 or p:GetAttribute("FPSMode")=="Lobby" or (char:GetAttribute("FPSDashUntil") or 0)>now() then return false end
 local agent=Agents.Agents[p:GetAttribute("FPSAgent") or "ION"] if not agent or index%1~=0 or not agent.Skills[index] then return false end
 if (p:GetAttribute("FPSNextSkill"..index) or 0)>now() then return false end
 if typeof(direction)~="Vector3" or direction.Magnitude<.5 or direction.Magnitude>1.5 or direction.X~=direction.X or direction.Y~=direction.Y or direction.Z~=direction.Z then return false end
 direction=direction.Unit local color=Color3.fromRGB(table.unpack(agent.Color)) local flat=Vector3.new(direction.X,0,direction.Z) if flat.Magnitude<.1 then flat=root.CFrame.LookVector end flat=Vector3.new(flat.X,0,flat.Z).Unit
 local agentId=p:GetAttribute("FPSAgent") or "ION" local origin=root.Position local forward=origin+flat*6
 if agentId=="ION" and index==1 then
  local orb=part("ArcoCondutor",Vector3.new(.45,.45,.45),CFrame.new(origin+Vector3.new(0,1,0)+direction*2),color,2.2) orb.Shape=Enum.PartType.Ball
  table.insert(projectiles,{part=orb,pos=orb.Position,velocity=direction*45,finish=now()+1.25,owner=p})
 elseif agentId=="ION" and index==2 then
  local cf=CFrame.lookAt(origin+flat*6-Vector3.new(0,2.5,0),origin+flat*7-Vector3.new(0,2.5,0))
  local lane=part("Trilho",Vector3.new(3,.08,12),cf,color,5) lane.Transparency=.4
  table.insert(fields,{kind="Lane",part=lane,owner=p,finish=now()+5}) fx(p,"Lane",lane.Position,12)
 elseif agentId=="ION" and index==3 then
  local old=char.Archivable char.Archivable=true local echo=char:Clone() char.Archivable=old
  for _,v in ipairs(echo:GetDescendants()) do if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Tool") then v:Destroy() elseif v:IsA("BasePart") then v.CanCollide=false v.CanTouch=false v.Transparency=math.max(v.Transparency,.35) end end
  local eh=echo:FindFirstChildOfClass("Humanoid") local er=rootOf(echo) if not eh or not er then echo:Destroy() return false end
  eh.MaxHealth=20 eh.Health=20 eh.DisplayName="Eco" eh.EvaluateStateMachine=false er.Anchored=true echo.Name="EcoResidual" echo:SetAttribute("FPSKillCounted",nil) echo:SetAttribute("FPSDecoy",true) echo:SetAttribute("FPSMatchId",p:GetAttribute("FPSMatchId")) echo:SetAttribute("FPSMode",p:GetAttribute("FPSMode")) echo:SetAttribute("FPSSide",p:GetAttribute("FPSSide"))
  echo:PivotTo(root.CFrame*CFrame.new(-2,0,-1)) echo.Parent=workspace CS:AddTag(echo,"VyrelDecoy") Debris:AddItem(echo,4)
 elseif agentId=="AMBAR" and index==1 then
  char:SetAttribute("FPSShield",25) char:SetAttribute("FPSShieldUntil",now()+4)
  local glow=Instance.new("Highlight") glow.Name="VYRELShield" glow.Adornee=char glow.FillColor=color glow.OutlineColor=color glow.FillTransparency=.86 glow.OutlineTransparency=.35 glow.DepthMode=Enum.HighlightDepthMode.Occluded glow.Parent=char Debris:AddItem(glow,4) fx(p,"Shield",origin,4)
 elseif agentId=="AMBAR" and index==2 then
  local station=part("Sutura",Vector3.new(2,.18,2),CFrame.new(origin-Vector3.new(0,2.5,0)),color,5) table.insert(fields,{kind="Heal",part=station,owner=p,finish=now()+5,last=now()}) fx(p,"Heal",station.Position,8)
 elseif agentId=="AMBAR" and index==3 then
  local cf=CFrame.lookAt(forward,forward+flat) local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={char,folder}
  for _,v in ipairs(workspace:GetPartBoundsInBox(cf,Vector3.new(7.5,3.5,.6),params)) do if v.CanCollide then return false end end
  local wall=part("Tranca",Vector3.new(8,4,.4),cf,color,4) wall.Transparency=.32 wall.CanCollide=true wall.CanQuery=true wall:SetAttribute("FPSBarrierHP",40) fx(p,"Barrier",wall.Position,4)
 elseif agentId=="VEU" and index==1 then
  fx(p,"RevealPulse",origin,18)
  for _,e in ipairs(entities()) do local er=rootOf(e.model) if er and (er.Position-origin).Magnitude<18 and Combat.Allowed(p,e.model) and Combat.Visible(origin,er.Position,{char,e.model}) then R.SkillFX:FireClient(p,"Reveal",e.model,.8,agentId,p.UserId) end end
 elseif agentId=="VEU" and index==2 then
  local hit=workspace:Raycast(origin+Vector3.new(0,1,0),direction*20,Combat.Params({char})) local pos=hit and hit.Position or origin+direction*15
  local cloud=part("Neblina",Vector3.new(8,8,8),CFrame.new(pos+Vector3.new(0,1,0)),color,4) cloud.Shape=Enum.PartType.Ball cloud.Transparency=.25 cloud.Material=Enum.Material.SmoothPlastic
  for i=1,5 do local angle=i*2.399 local offset=Vector3.new(math.cos(angle)*1.5,math.sin(angle*.7)*.7,math.sin(angle)*1.5)
   local puff=part("FragmentoNeblina",Vector3.new(5.5,5.5,5.5),CFrame.new(cloud.Position+offset),Color3.fromRGB(114+i*5,93+i*3,159+i*5),4) puff.Shape=Enum.PartType.Ball puff.Material=Enum.Material.SmoothPlastic puff.Transparency=.45
  end
  table.insert(smoke,{pos=cloud.Position,radius=4,finish=now()+4,match=p:GetAttribute("FPSMatchId")}) fx(p,"Smoke",cloud.Position,4)
 elseif agentId=="VEU" and index==3 then
  local sensor=part("Escuta",Vector3.new(.7,.7,.7),CFrame.new(forward-Vector3.new(0,2,0)),color,6) sensor.Shape=Enum.PartType.Ball sensor.CanQuery=true sensor:SetAttribute("FPSBarrierHP",15)
  table.insert(sensors,{owner=p,part=sensor,finish=now()+6}) fx(p,"Sensor",sensor.Position,6)
 end
 p:SetAttribute("FPSNextSkill"..index,now()+agent.Skills[index].Cooldown) char:SetAttribute("FPSCastUntil",now()+.26) char:SetAttribute("FPSCastIndex",index) fx(p,"Cast",origin,index)
 return true
end
function K.Init()
 if started then return end started=true Movement.Init()
 local last={}
 system.Remotes.Skill.OnServerEvent:Connect(function(p,index,direction)
  if now()-(last[p] or -math.huge)<.12 then return end last[p]=now()
  if index=="Dash" then Movement.Dash(p,direction) elseif type(index)=="number" and index>=1 and index<=3 then cast(p,index,direction) end
 end)
 Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
 local accumulated=0 Run.Heartbeat:Connect(function(dt)
  for i=#projectiles,1,-1 do local orb=projectiles[i]
   if not orb.part.Parent or not orb.owner.Parent then if orb.part.Parent then orb.part:Destroy() end table.remove(projectiles,i)
   else
    orb.velocity+=Vector3.new(0,-30,0)*dt local delta=orb.velocity*dt local hit=workspace:Raycast(orb.pos,delta,Combat.Params({orb.owner.Character,folder}))
    if hit or now()>=orb.finish then burst(orb.owner,hit and hit.Position or orb.pos) orb.part:Destroy() table.remove(projectiles,i)
    else orb.pos+=delta orb.part.CFrame=CFrame.new(orb.pos) end
   end
  end
  accumulated+=dt if accumulated<.2 then return end local step=accumulated accumulated=0
  local actors=entities()
  for i=#fields,1,-1 do local f=fields[i]
   if not f.part.Parent or f.finish<=now() or not f.owner.Parent then if f.part.Parent then f.part:Destroy() end table.remove(fields,i)
   else for _,e in ipairs(actors) do local er=rootOf(e.model) local h=e.model:FindFirstChildOfClass("Humanoid")
    if er and h and h.Health>0 and allied(f.owner,e.actor) then
     if f.kind=="Lane" then local point=f.part.CFrame:PointToObjectSpace(er.Position) if math.abs(point.X)<2 and math.abs(point.Z)<6 and math.abs(point.Y)<4 then e.model:SetAttribute("FPSBoostUntil",now()+3) end
     elseif (er.Position-f.part.Position).Magnitude<8 and now()-(e.model:GetAttribute("FPSLastDamageAt") or -100)>2 then h.Health=math.min(h.MaxHealth,h.Health+2*step) end
    end
   end end
  end
  for _,e in ipairs(actors) do local h=e.model:FindFirstChildOfClass("Humanoid")
   if h and h.Health>0 and e.actor:GetAttribute("FPSMode")~="Lobby" and (e.model:GetAttribute("FPSDashUntil") or 0)<=now() then
    local tool=e.model:FindFirstChild("Rifle") local base=e.model:GetAttribute("FPSBotBaseSpeed") or (tool and tool:GetAttribute("Running") and 22 or 16)
    local mult=(e.model:GetAttribute("FPSBoostUntil") or 0)>now() and 1.12 or 1
    if (e.model:GetAttribute("FPSSlowUntil") or 0)>now() then mult*=.86 end
    if e.actor:IsA("Player") or mult~=1 then h.WalkSpeed=base*mult end
   end
  end
  for i=#sensors,1,-1 do if sensors[i].finish<now() or not sensors[i].part.Parent then table.remove(sensors,i) end end
  for i=#smoke,1,-1 do if smoke[i].finish<now() then table.remove(smoke,i) end end
 end)
end
return K
]=] end
do local x=node(mods,'ModuleScript',"Spring") x.Source=[=[-- Solucao analitica criticamente amortecida: independente da taxa de quadros.
local S={} S.__index=S
function S.new(value,frequency) return setmetatable({position=value,velocity=value*0,target=value,frequency=frequency or 18},S) end
function S:Impulse(value) self.velocity+=value end
function S:Step(dt)
 dt=math.max(0,dt) local w=self.frequency local offset=self.position-self.target
 local j=self.velocity+offset*w local decay=math.exp(-w*dt)
 self.position=self.target+(offset+j*dt)*decay self.velocity=(self.velocity-j*w*dt)*decay
 return self.position
end
return S
]=] end
do local x=node(mods,'ModuleScript',"ThirdPersonController") x.Source=[=[local Players=game:GetService("Players") local Run=game:GetService("RunService") local RS=game:GetService("ReplicatedStorage")
local CS=game:GetService("CollectionService")
local C=require(script.Parent.WeaponConfig) local Anim=require(script.Parent.AnimationController) local Effects=require(script.Parent.WeaponEffects)
local Catalog=require(script.Parent.WeaponCatalog)
local T={} local rigs={} local bases={} local poses={}
local bodyJoint={["Right Shoulder"]=true,["Left Shoulder"]=true,["Right Hip"]=true,["Left Hip"]=true,Neck=true,RootJoint=true}
local function unbind(p)
 local r=rigs[p] if r then for _,j in pairs(r.j) do bases[j]=nil poses[j]=nil end end rigs[p]=nil
end
local function apply(j,target,alpha)
 local base=bases[j] if not base then base=j.C0 bases[j]=base poses[j]=CFrame.new() end
 poses[j]=poses[j]:Lerp(target,alpha) j.Transform=CFrame.new() j.C0=base*poses[j]
end
local function bind(p,char)
 if rigs[p] and rigs[p].char==char then return end
 local torso=char:WaitForChild("Torso",8) local h=char:WaitForChild("Humanoid",10) local root=char:WaitForChild("HumanoidRootPart",10) if not torso or not h or not root then return end
 if p:IsA("Player") and p.Character~=char then return end
 for _,name in ipairs({"Right Shoulder","Left Shoulder","Right Hip","Left Hip","Neck"}) do if not torso:WaitForChild(name,10) then return end end
 unbind(p)
 local j={} for _,v in ipairs(char:GetDescendants()) do if v:IsA("Motor6D") and bodyJoint[v.Name] and (v.Part0==torso or v.Part0==root) then j[v.Name]=v bases[v]=v.C0 poses[v]=CFrame.new() end end
 rigs[p]={char=char,torso=torso,h=h,root=root,j=j,pose=CFrame.new(),magPose=CFrame.new(),phase=0,moveWeight=0,runWeight=0,jumpWeight=0,aimWeight=0,pitch=0,magAlpha=0}
end
local function arm(joint,torso,target,dt)
 if not joint or not joint.Parent then return end
 local base=bases[joint] or joint.C0
 local part=joint.Part1 if not part then return end
 local half=part.Size.Y*.5
 -- Solve the palm at the actual bottom of the R6 arm, not its centre.
 local rest=torso.CFrame*base*joint.C1:Inverse()
 local shoulder=(rest*CFrame.new(0,half,0)).Position
 local delta=target-shoulder if delta.Magnitude<.05 then return end
 -- Roll around the arm length: keep the palm contact, turn sleeves outward.
 local roll=joint.Name=="Right Shoulder" and -.15 or .2
 local rotation=CFrame.lookAt(Vector3.zero,delta.Unit)*CFrame.Angles(math.pi/2,0,0)*CFrame.Angles(0,roll,0)
 local desired=CFrame.new(target-delta.Unit*half)*rotation.Rotation
 local transform=base:Inverse()*torso.CFrame:ToObjectSpace(desired)*joint.C1
 -- Weapon motion is already smoothed. A second arm lerp breaks palm contact.
 apply(joint,transform,1)
end
function T.init(serverMode)
 if not serverMode then
  -- Animator.Transform is client-local; neutralize its tool/idle arm offsets
  -- after animation evaluation, preserving the replicated server C0 pose.
  Run.PreSimulation:Connect(function()
   for _,player in ipairs(Players:GetPlayers()) do
    local char=player.Character local torso=char and char:FindFirstChild("Torso") local tool=char and char:FindFirstChild("Rifle")
    if torso and tool and tool:FindFirstChild("Handle") and tool.Handle:FindFirstChild("WorldGrip") then
     for _,name in ipairs({"Right Shoulder","Left Shoulder","Right Hip","Left Hip","Neck"}) do local joint=torso:FindFirstChild(name) if joint then joint.Transform=CFrame.new() end end
     local root=char:FindFirstChild("HumanoidRootPart") local rootJoint=root and root:FindFirstChild("RootJoint") or torso:FindFirstChild("RootJoint") if rootJoint then rootJoint.Transform=CFrame.new() end
     tool.Handle.WorldGrip.Transform=CFrame.new() local mag=tool.Handle:FindFirstChild("MagazineMotor") if mag then mag.Transform=CFrame.new() end
    end
   end
  end)
  RS:WaitForChild("FPSSystem"):WaitForChild("Remotes"):WaitForChild("WeaponFX").OnClientEvent:Connect(function(id,a,b,normal)
   if id~=Players.LocalPlayer.UserId then Effects.Shot(a,b,normal) end
  end)
  return
 end
 local function add(p) p.CharacterAdded:Connect(function(char) task.spawn(bind,p,char) end) if p.Character then task.spawn(bind,p,p.Character) end end
 Players.PlayerAdded:Connect(add) Players.PlayerRemoving:Connect(unbind) for _,p in ipairs(Players:GetPlayers()) do add(p) end
 for _,bot in ipairs(CS:GetTagged("FPSDemoBot")) do task.spawn(bind,bot,bot) end
 CS:GetInstanceAddedSignal("FPSDemoBot"):Connect(function(bot) task.spawn(bind,bot,bot) end)
 CS:GetInstanceRemovedSignal("FPSDemoBot"):Connect(function(bot) unbind(bot) end)
 local accumulated=0
 Run.Heartbeat:Connect(function(dt)
  accumulated+=dt if accumulated<1/30 then return end dt=accumulated accumulated=0
  local now=workspace:GetServerTimeNow() local alpha=1-math.exp(-dt*16)
  for p,r in pairs(rigs) do
   if not r.char.Parent then unbind(p) continue end
   local speed=Vector3.new(r.root.AssemblyLinearVelocity.X,0,r.root.AssemblyLinearVelocity.Z).Magnitude
   if speed<1 or r.root.Anchored then speed=0 end
   local held=r.char:FindFirstChild("Rifle") local sprint=held and held:GetAttribute("Running")==true
   r.moveWeight+=(math.clamp(speed/C.WalkSpeed,0,1)-r.moveWeight)*alpha
   r.runWeight+=((sprint and 1 or 0)-r.runWeight)*alpha
   r.phase+=dt*(7.5+3.5*r.runWeight)*math.clamp(speed/C.WalkSpeed,0,1.5)
   local stride=math.sin(r.phase)*(.48+.52*r.runWeight)*r.moveWeight
   local dashing=(r.char:GetAttribute("FPSDashUntil") or 0)>now
   local jump=r.h.FloorMaterial==Enum.Material.Air and not r.root.Anchored
   r.jumpWeight+=((jump and 1 or 0)-r.jumpWeight)*alpha
   r.aimWeight+=((held and held:GetAttribute("Aiming") and 1 or 0)-r.aimWeight)*alpha
   for name,j in pairs(r.j) do if j.Parent and not (held and (name=="Right Shoulder" or name=="Left Shoulder")) then
    local target=CFrame.new()
    if name=="Right Hip" then target=CFrame.Angles(jump and -.4 or stride,0,0) elseif name=="Left Hip" then target=CFrame.Angles(jump and .28 or -stride,0,0)
    elseif name=="Right Shoulder" then target=CFrame.Angles(-stride,0,.04) elseif name=="Left Shoulder" then target=CFrame.Angles(stride,0,-.04)
    elseif name=="RootJoint" then target=CFrame.new(0,math.sin(now*2)*.006+math.cos(r.phase*2)*.018*r.moveWeight*(1-r.jumpWeight),0)*CFrame.Angles(-.17*r.runWeight*r.moveWeight+.04*r.jumpWeight-(dashing and .2 or 0),0,math.sin(r.phase)*.015*r.moveWeight) end
    local basis=bases[j].Rotation apply(j,basis:Inverse()*target*basis,alpha)
   end end
   local tool=r.char:FindFirstChild("Rifle") local handle=tool and tool:FindFirstChild("Handle") local grip=handle and handle:FindFirstChild("WorldGrip")
   if handle and grip then
    local C=Catalog.Get(tool:GetAttribute("WeaponId"))
    local age=now-(tool:GetAttribute("EquippedAt") or now) local reloadEnd=tool:GetAttribute("ReloadEnd") or 0 local inspectEnd=tool:GetAttribute("InspectEnd") or 0 local running=tool:GetAttribute("Running")
    local state=Anim.State(true,age,reloadEnd>now,inspectEnd>now,running,tool:GetAttribute("Aiming"),now-(r.char:GetAttribute("FPSLastShotAt") or -1e5)<.12)
    local phase=state=="Reloading" and now-(reloadEnd-C.ReloadTime) or state=="Inspecting" and now-(inspectEnd-C.InspectTime) or age
    local pose,left,mag=Anim.Sample(state,math.max(0,state=="Reloading" and phase*1.65/C.ReloadTime or phase))
    if state=="Equipping" then
     local blend=math.clamp(phase/C.EquipTime,0,1) blend=blend*blend*(3-2*blend)
     pose=(CFrame.new(0,-.25,.15)*CFrame.Angles(-.12,0,.06)):Lerp(CFrame.new(),blend)
    end
    pose=Anim.WorldSample(now,r.phase,r.moveWeight,r.runWeight,r.jumpWeight,r.aimWeight)*pose
    local since=now-(r.char:GetAttribute("FPSLastShotAt") or -1e5) if since>=0 and since<.15 then pose=pose*CFrame.new(0,0,.08*math.exp(-since*25))*CFrame.Angles(.035*math.exp(-since*25),0,0) end
    r.pose=r.pose:Lerp(pose,alpha) r.magPose=r.magPose:Lerp(mag,alpha) if r.grip~=grip then r.grip=grip r.configureGrip=true end
    -- Pivot elevation around the stock, rather than swinging the gun through the torso.
    local stock=handle:FindFirstChild("StockPivot") and handle.StockPivot.CFrame or CFrame.new(0,.1066,.9512)
    local base=Anim.WorldBase(r.torso)
    r.pitch+=((tool:GetAttribute("AimPitch") or 0)-r.pitch)*alpha
    local pitch=r.pitch
    local localGun=base*stock*CFrame.Angles(pitch,0,0)*stock:Inverse()*r.pose
    local neck=r.j.Neck
    if neck and neck.Parent then local basis=bases[neck].Rotation local target=CFrame.Angles((tool:GetAttribute("AimPitch") or 0)*.4,0,0) apply(neck,basis:Inverse()*target*basis,alpha) end
    local gunCF=r.torso.CFrame*localGun
    local right=handle:FindFirstChild("RightGripPoint") local support=handle:FindFirstChild("WorldLeftGrip") or handle:FindFirstChild("LeftGrip")
    if right then arm(r.j["Right Shoulder"],r.torso,(gunCF*right.CFrame).Position,dt) end
    -- A real arm-to-weapon Motor6D carries the rifle. Shoulder animation and
    -- tool grip are solved from the same weapon pose, avoiding duplicate constraints.
    local rightJoint=r.j["Right Shoulder"]
    if rightJoint and rightJoint.Part1 then
     local armCF=r.torso.CFrame*rightJoint.C0*rightJoint.C1:Inverse()
     grip.Part0=rightJoint.Part1 grip.C1=CFrame.new() grip.Transform=CFrame.new()
     grip.C0=armCF:ToObjectSpace(gunCF)
     if r.configureGrip then
      tool.Grip=grip.C0:Inverse()*CFrame.new(0,-rightJoint.Part1.Size.Y*.5,0) r.configureGrip=false
     end
    end
    if support then
     local target=support.CFrame*left
     if (r.char:GetAttribute("FPSCastUntil") or 0)>now then
      local progress=math.clamp(1-((r.char:GetAttribute("FPSCastUntil") or now)-now)/.26,0,1) local weight=math.sin(progress*math.pi)
      local index=r.char:GetAttribute("FPSCastIndex") local offset=index==2 and Vector3.new(-.15,-.1,-.3) or index==3 and Vector3.new(-.3,.35,-.08) or Vector3.new(-.1,.25,-.35)
      target=target*CFrame.new(offset*weight)
     end
     if state=="Reloading" then target=support.CFrame:Lerp(handle.MagazinePivot.CFrame*r.magPose*CFrame.new(-.25,0,0),Anim.ReloadHandWeight(phase*1.65/C.ReloadTime)) end
     arm(r.j["Left Shoulder"],r.torso,(gunCF*target).Position,dt)
    end
    local magazine=handle:FindFirstChild("MagazineMotor") if magazine then if r.magazine~=magazine then r.magazine=magazine r.magBase=magazine.C0 end magazine.Transform=CFrame.new() magazine.C0=r.magBase*r.magPose end
    local action=handle:FindFirstChild("ActionMotor")
    if action then if r.action~=action then r.action=action r.actionBase=action.C0 end action.Transform=CFrame.new() action.C0=r.actionBase*Anim.ActionSample(C.Kind,now-(r.char:GetAttribute("FPSLastShotAt") or -1e5)) end
    local targetAlpha=state=="Reloading" and Anim.MagazineAlpha(phase*1.65/C.ReloadTime) or 0 r.magAlpha+=(targetAlpha-r.magAlpha)*alpha
    for _,part in ipairs(tool:GetDescendants()) do if part:IsA("BasePart") and part:GetAttribute("MagazinePart") then part.Transparency=r.magAlpha end end
   end
  end
 end)
end
return T
]=] end
do local x=node(mods,'ModuleScript',"ViewModelController") x.Source=[=[local Factory=require(script.Parent.WeaponFactory)
local Spring=require(script.Parent.Spring)
local Recoil=require(script.Parent.Recoil)
local Anim=require(script.Parent.AnimationController)
local Catalog=require(script.Parent.WeaponCatalog)
local V={} V.__index=V
function V.new(camera,id)
 local C=Catalog.Get(id)
 local model=Instance.new("Model") model.Name="R6ViewModel"
 local root=Instance.new("Part") root.Name="CameraRoot" root.Size=Vector3.new(.1,.1,.1) root.CFrame=CFrame.new() root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanQuery=false root.CanTouch=false root.Parent=model model.PrimaryPart=root
 local gun=Factory.Build(model,nil,C.Id) local handle=gun.Handle for _,p in ipairs(gun:GetDescendants()) do if p:IsA("BasePart") then p.CastShadow=false end end
 local joint=Instance.new("Motor6D") joint.Name="WeaponMotor" joint.Part0=root joint.Part1=handle joint.Parent=root
 local function arm(name,point,angle)
  local player=game:GetService("Players").LocalPlayer local character=player and player.Character
  local original=character and character:FindFirstChild(name)
  -- Package meshes can extend far outside an R6 arm's Part bounds.
  -- Use bounded first-person geometry and copy skin colour/clothing only.
  local p=Instance.new("Part") p.Name=name p.Size=Vector3.new(.65,1.65,.65)
  p.Color=original and original.Color or Color3.fromRGB(211,180,153)
  p.Anchored=false p.Material=Enum.Material.SmoothPlastic p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Massless=true p.CastShadow=false p.LocalTransparencyModifier=0 p.Parent=model
  local rot=CFrame.Angles(angle,0,name=="Left Arm" and .25 or -.25)
  local motor=Instance.new("Motor6D") motor.Name=name.."Joint" motor.Part0=handle motor.Part1=p motor.C0=point.CFrame*rot*CFrame.new(0,.825,0) motor.Parent=handle p.CFrame=motor.C0
  return motor
 end
 local right=arm("Right Arm",handle.RightGripPoint,2.2) local left=arm("Left Arm",handle.LeftGrip,2.15)
 local player=game:GetService("Players").LocalPlayer local character=player and player.Character
 local torso=Instance.new("Part") torso.Name="Torso" torso.Size=Vector3.new(2,2,1) torso.Transparency=1 torso.CanCollide=false torso.CanTouch=false torso.CanQuery=false torso.Massless=true torso.Parent=model
 local w=Instance.new("Weld") w.Part0=root w.Part1=torso w.Parent=torso
 local hrp=Instance.new("Part") hrp.Name="HumanoidRootPart" hrp.Size=Vector3.new(.1,.1,.1) hrp.Transparency=1 hrp.CanCollide=false hrp.CanTouch=false hrp.CanQuery=false hrp.Massless=true hrp.Parent=model
 local rw=Instance.new("Weld") rw.Part0=root rw.Part1=hrp rw.Parent=hrp
 local controller=Instance.new("Humanoid") controller.RigType=Enum.HumanoidRigType.R6 controller.RequiresNeck=false controller.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None controller.EvaluateStateMachine=false controller.PlatformStand=true controller.AutoRotate=false controller.Parent=model
 if character then
  for _,v in ipairs(character:GetChildren()) do
   if v:IsA("Shirt") or v:IsA("BodyColors") then v:Clone().Parent=model end
  end
 end
 local magParts={} for _,p in ipairs(gun:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("MagazinePart") then table.insert(magParts,p) end end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true part.CollisionGroup="FPSViewModel" end
 end
 model.Parent=camera
 return setmetatable({cfg=C,action=handle:FindFirstChild("ActionMotor"),actionBase=handle:FindFirstChild("ActionMotor") and handle.ActionMotor.C0 or CFrame.new(),fireTime=-math.huge,model=model,root=root,gun=gun,joint=joint,right=right,left=left,leftBase=left.C0,leftRotation=CFrame.Angles(2.15,0,.25),mag=handle.MagazineMotor,magBase=handle.MagazineMotor.C0,magAlpha=0,magParts=magParts,recoil=Recoil.new(C.RecoilScale),sway=Spring.new(Vector3.zero,14),aim=0,run=0,dash=0,move=0,jump=0,grounded=true,landing=Spring.new(Vector3.zero,18),phase=0,pose=CFrame.new(),leftPose=CFrame.new(),magPose=CFrame.new()},V)
end
function V:Fire() self.fireTime=workspace:GetServerTimeNow() self.recoil:Fire(self.aim>.5) end
function V:Step(dt,camera,info,mouse)
 local C=self.cfg
 local smoothing=1-math.exp(-dt*16)
 self.aim+=((info.aim and 1 or 0)-self.aim)*(1-math.exp(-dt/C.ADSTime*4)) self.run+=((info.running and 1 or 0)-self.run)*smoothing self.dash+=((info.dash and 1 or 0)-self.dash)*(1-math.exp(-dt*22))
 local gunPose,leftPose,magPose=Anim.Sample(info.state,info.state=="Reloading" and info.time*1.65/C.ReloadTime or info.time)
 if info.state=="Running" then gunPose=CFrame.new(.12,-.22,.12)*CFrame.Angles(-.2,.15,.15) end
 self.pose=self.pose:Lerp(gunPose,smoothing) self.leftPose=self.leftPose:Lerp(leftPose,smoothing) self.magPose=self.magPose:Lerp(magPose,smoothing)
 local targetAlpha=info.state=="Reloading" and Anim.MagazineAlpha(info.time*1.65/C.ReloadTime) or 0 self.magAlpha+=(targetAlpha-self.magAlpha)*smoothing for _,p in ipairs(self.magParts) do if p.Parent then p.Transparency=self.magAlpha end end
 self.mag.C0=self.magBase*self.magPose
 if self.action then self.action.C0=self.actionBase*Anim.ActionSample(C.Kind,workspace:GetServerTimeNow()-self.fireTime) end
 local leftTarget=self.leftBase
 if info.state=="Reloading" then
  local hand=self.gun.Handle.LeftGrip.CFrame:Lerp(self.magBase*self.magPose*CFrame.new(-.25,0,0),Anim.ReloadHandWeight(info.time*1.65/C.ReloadTime))
  leftTarget=hand*self.leftRotation*CFrame.new(0,.825,0) self.left.Transform=CFrame.new()
 else self.left.Transform=self.leftPose end
 self.left.C0=self.left.C0:Lerp(leftTarget,smoothing)
 local kick=self.recoil:Step(dt) self.right.Transform=CFrame.Angles(kick.X*.3,0,0)
 local rate=mouse/math.max(dt,1/300)
 self.sway.target=Vector3.new(math.clamp(-rate.Y*.000012,-.025,.025),math.clamp(-rate.X*.000012,-.025,.025),0)
 local sway=self.sway:Step(dt)*(1-self.aim) self.phase+=dt*(info.running and 11 or 7.5)*math.clamp(info.speed/16,0,1.5)
 local grounded=info.grounded~=false
 if grounded and not self.grounded then self.landing:Impulse(Vector3.new(0,-.7,.22)) end self.grounded=grounded
 self.move+=(math.clamp(info.speed/16,0,1)-self.move)*smoothing
 self.jump+=((grounded and 0 or 1)-self.jump)*smoothing
 local moving=self.move
 local bob=Vector3.new(math.sin(self.phase)*(.018+self.run*.027),math.cos(self.phase*2)*(.018+self.run*.033),0)*moving*(1-self.aim)
 local breath=Vector3.new(0,math.sin(os.clock()*3.49)*.0035,0)*(1-self.aim)
 local offset=CFrame.new(.65,-.8,-1.2):Lerp(self.gun.Handle.AimPoint.CFrame:Inverse(),self.aim)
 local visualKick=CFrame.new(0,0,kick.X*6)*CFrame.Angles(kick.X,kick.Y,0)
 self.root.CFrame=camera.CFrame
 local land=self.landing:Step(dt)*(1-self.aim*.7)
 local jump=Vector3.new(0,-.035*self.jump,.04*self.jump)
 jump+=Vector3.new(.04,-.09,.12)*self.dash
 if info.casting then
  local weight=math.sin(math.pi*math.clamp(info.castPhase or 0,0,1))
  local offset=info.castIndex==2 and Vector3.new(-.14,-.09,-.25) or info.castIndex==3 and Vector3.new(-.25,.28,-.08) or Vector3.new(-.1,.18,-.22)
  self.left.Transform=CFrame.new(offset*weight)*CFrame.Angles(.2*weight,0,-.15*weight)
 end
 local gait=CFrame.Angles(.012*self.run*math.cos(self.phase*2)+.025*self.jump,0,.018*self.run*math.sin(self.phase))
 self.joint.C0=offset*CFrame.new(bob+breath+land+jump)*CFrame.Angles(sway.X,sway.Y,0)*gait*self.pose*visualKick
 return CFrame.Angles(kick.X,kick.Y,0),self.aim
end
function V:Destroy() if self.model then self.model:Destroy() end end
return V
]=] end
do local x=node(mods,'ModuleScript',"WeaponCatalog") x.Source=[=[local Base=require(script.Parent.WeaponConfig)
local A={Order={"VETOR","KESTREL","LYRA","FERAL","PULSAR","BASIL","ARGO","TORQ","MAREA","RUPTURA","VESPER","NOMAD"},Weapons={}}
local function weapon(id,name,kind,price,damage,head,mag,reserve,interval,reload,ads,range,auto,pellets,spread)
 local cfg={} for k,v in pairs(Base) do cfg[k]=v end
 cfg.Id=id cfg.Name=name cfg.Kind=kind cfg.Price=price cfg.Damage=damage cfg.Critical=head cfg.Magazine=mag cfg.Reserve=reserve cfg.FireInterval=interval cfg.ReloadTime=reload cfg.ADSFOV=ads cfg.Range=range cfg.Automatic=auto cfg.Pellets=pellets or 1 cfg.Spread=spread or 0 cfg.RecoilScale=(kind=="Sniper" and 2.2 or kind=="Shotgun" and 1.7 or kind=="SMG" and .65 or 1)
 cfg.Description=kind=="Sniper" and "Precisao de longo alcance. Ferrolho, luneta e alto dano por disparo." or kind=="Shotgun" and "Dispersao curta. Cada cartucho lanca varios projeteis." or kind=="Pistol" and "Arma secundaria leve, disparo semiautomatico." or kind=="SMG" and "Compacta, agil e eficaz em combate proximo." or kind=="LMG" and "Suporte automatico com grande capacidade de municao." or "Fuzil versatil, tiro controlavel e alcance intermediario."
 A.Weapons[id]=table.freeze(cfg)
end
weapon("VETOR","VETOR C4","Rifle",0,20,2,30,120,.105,1.8,55,500,true)
weapon("KESTREL","KESTREL K7","Rifle",160,25,2,30,120,.135,2.15,55,500,true)
weapon("LYRA","LYRA B9","Rifle",180,22,2,30,120,.115,2,50,500,true)
weapon("FERAL","FERAL S5","SMG",90,15,1.9,30,150,.075,1.65,60,260,true)
weapon("PULSAR","PULSAR V2","SMG",140,13,1.9,25,150,.065,1.7,60,240,true)
weapon("BASIL","BASIL A1","Sniper",260,65,2.3,5,30,1.1,2.7,28,800,false)
weapon("ARGO","ARGO D6","DMR",210,36,2,15,75,.28,2.3,40,650,false)
weapon("TORQ","TORQ M8","LMG",230,20,1.8,60,180,.105,3.2,55,500,true)
weapon("MAREA","MAREA P8","Shotgun",130,12,1.5,8,48,.8,2.7,60,150,false,6,3.3)
weapon("RUPTURA","RUPTURA D2","Shotgun",100,14,1.5,2,32,.6,1.8,60,120,false,7,4)
weapon("VESPER","VESPER H50","Pistol",100,38,2,7,56,.28,1.7,60,400,false)
weapon("NOMAD","NOMAD P9","Pistol",0,21,2,15,75,.19,1.5,60,350,false)
function A.Get(id) return A.Weapons[id] or A.Weapons.VETOR end
return A
]=] end
do local x=node(mods,'ModuleScript',"WeaponConfig") x.Source=[=[--!strict
return table.freeze({
 Name="VETOR-30", AlwaysFirstPerson=true, DebugHUD=false, Magazine=30, Reserve=90, Damage=20, Critical=1.5,
 FireInterval=.11, ReloadTime=1.65, EquipTime=.45, UnequipTime=.3, InspectTime=2.5,
 Range=500, FOV=70, ADSFOV=55, ADSTime=.22, WalkSpeed=16, RunSpeed=22,
 LOBBY={ORIGIN=Vector3.new(0,4,16)},RUNNER={WALKSPEED=16,JUMPPOWER=50},
 Sounds={}, -- Silencioso ate configurar audios proprios/licenciados.
})
]=] end
do local x=node(mods,'ModuleScript',"WeaponEffects") x.Source=[=[-- Local, short-lived effects. No physical forces or external texture assets.
local Debris=game:GetService("Debris") local Tween=game:GetService("TweenService")
local E={}
local warm=Color3.fromRGB(255,201,104)
local function part(name,size,cf,color,material,alpha)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
 p.Transparency=alpha or 0 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Parent=workspace
 return p
end
local function fade(p,duration,goal)
 Tween:Create(p,TweenInfo.new(duration),goal):Play() Debris:AddItem(p,duration+.03)
end
function E.Shot(a,b,normal)
 local player=game:GetService("Players").LocalPlayer if player and player:GetAttribute("FPSVFXEnabled")==false then return end
 local delta=b-a if delta.Magnitude<.01 then return end
 local forward=CFrame.lookAt(a,b)
 local tracer=part("TracerVirtual",Vector3.new(.018,.018,math.min(delta.Magnitude,500)),CFrame.lookAt((a+b)/2,b),warm,Enum.Material.Neon,.25)
 fade(tracer,.065,{Transparency=1})
 local flash=part("MuzzleFlash",Vector3.new(.12,.12,.38),forward*CFrame.new(0,0,-.12),warm,Enum.Material.Neon,.12)
 flash.Shape=Enum.PartType.Ball
 local light=Instance.new("PointLight") light.Color=warm light.Brightness=2 light.Range=7 light.Shadows=false light.Parent=flash
 fade(flash,.045,{Transparency=1,Size=Vector3.new(.025,.025,.1)})
 -- Cross-shaped flash gives a crisp arcade silhouette without texture assets.
 for i=1,2 do
  local petal=part("MuzzlePetal",Vector3.new(.28,.035,.2),forward*CFrame.new(0,0,-.18)*CFrame.Angles(0,0,i*math.pi/2+.3),warm,Enum.Material.Neon,.25)
  fade(petal,.04,{Transparency=1,Size=Vector3.new(.07,.015,.05)})
 end
 local shell=part("Cartridge",Vector3.new(.06,.12,.06),forward*CFrame.new(.16,-.06,.35),Color3.fromRGB(194,157,78),Enum.Material.SmoothPlastic)
 fade(shell,.24,{Transparency=1,CFrame=forward*CFrame.new(.7,-.42,.6)*CFrame.Angles(1.6,.8,2.2)})
 local smoke=part("MuzzleSmoke",Vector3.new(.12,.12,.18),forward*CFrame.new(0,.04,-.28),Color3.fromRGB(163,176,184),Enum.Material.SmoothPlastic,.85)
 smoke.Shape=Enum.PartType.Ball fade(smoke,.22,{Transparency=1,Size=Vector3.new(.4,.4,.5),CFrame=forward*CFrame.new(0,.2,-.55)})
 -- A miss ends at range and must not produce an impact floating in the sky.
 if typeof(normal)~="Vector3" or normal.Magnitude<.5 then return end
 local surface=CFrame.lookAt(b+normal*.025,b+normal,math.abs(normal.Y)>.95 and Vector3.new(0,0,1) or Vector3.new(0,1,0))
 local ring=part("ImpactGlow",Vector3.new(.13,.13,.025),surface,Color3.fromRGB(255,217,151),Enum.Material.Neon,.1)
 fade(ring,.16,{Transparency=1,Size=Vector3.new(.3,.3,.025)})
 local mark=part("ImpactMark",Vector3.new(.1,.1,.012),surface,Color3.fromRGB(65,68,73),Enum.Material.SmoothPlastic,.3)
 fade(mark,.65,{Transparency=1})
 local dust=part("ImpactDust",Vector3.new(.16,.16,.16),surface,Color3.fromRGB(167,160,143),Enum.Material.SmoothPlastic,.6)
 dust.Shape=Enum.PartType.Ball fade(dust,.28,{Transparency=1,Size=Vector3.new(.55,.55,.55),CFrame=surface*CFrame.new(0,.12,-.22)})
 for i=1,3 do
  local angle=i*2.399 local offset=Vector3.new(math.cos(angle)*.25,math.sin(angle)*.25,-.35)
  local spark=part("ImpactSpark",Vector3.new(.025,.025,.11),surface,warm,Enum.Material.Neon)
  fade(spark,.1+i*.018,{Transparency=1,CFrame=surface*CFrame.new(offset)})
 end
end
return E
]=] end
do local x=node(mods,'ModuleScript',"WeaponFactory") x.Source=[=[-- Rifle virtual original em pecas nativas, sem assets externos.
local Models=require(script.Parent.WeaponModels)
local F={}
local dark=Color3.fromRGB(35,47,65) local blue=Color3.fromRGB(47,139,171) local pale=Color3.fromRGB(182,203,214) local gold=Color3.fromRGB(255,197,80)
function F.Build(parent,scale,id)
 id=id or "VETOR"
 scale=scale or 1
 local m=Instance.new("Model") m.Name="RifleModel"
 local root=Instance.new("Part") root.Name="Handle" root.Size=Vector3.new(.25,.25,.25) root.CFrame=CFrame.new() root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Massless=true root.Parent=m m.PrimaryPart=root
 local magazine local action
 for _,d in ipairs(Models.Models[id] or Models.Models.VETOR) do
  local p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part") p.Name=d.name
  p.Size=Vector3.new(d.size[1],d.size[2],d.size[3])*scale
  p.CFrame=CFrame.new(Vector3.new(d.pos[1],d.pos[2],d.pos[3])*scale)*CFrame.Angles(math.rad(d.rot[1]),math.rad(d.rot[2]),math.rad(d.rot[3]))
  if d.shape=="Tube" then p.Shape=Enum.PartType.Cylinder p.Size=Vector3.new(d.size[3],d.size[1],d.size[2])*scale p.CFrame=p.CFrame*CFrame.Angles(0,math.pi/2,0) end
  p.Color=Color3.fromRGB(d.color[1],d.color[2],d.color[3]) p.Transparency=d.alpha or 0 p.Material=(d.name=="Reticle" or d.name=="Ponto reflex") and Enum.Material.Neon or Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  if d.name~="Reticle" and d.name~="Ponto reflex" then
   if d.color[1]==111 and d.color[2]==60 then p.Material=Enum.Material.Wood
   elseif not (d.name:find("Grip") or d.name:find("Stock") or d.name:find("Pump") or d.name=="ButtPlate") then p.Material=Enum.Material.Metal end
  end
  p.Reflectance=p.Material==Enum.Material.Metal and .015 or 0 p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Parent=m
  if d.name=="Magazine" then
   magazine=p if d.group~="Hidden" then p:SetAttribute("MagazinePart",true) end
   local motor=Instance.new("Motor6D") motor.Name="MagazineMotor" motor.Part0=root motor.Part1=p motor.C0=p.CFrame motor.Parent=root
  elseif d.name=="Slide" or d.name=="Pump" or d.name=="BoltLever" then
   action=p local motor=Instance.new("Motor6D") motor.Name="ActionMotor" motor.Part0=root motor.Part1=p motor.C0=p.CFrame motor.C1=CFrame.new() motor.Parent=root
  else
   local followsAction=action and ((action.Name=="Slide" and (d.name=="SlideSerration" or d.name=="RearSight" or d.name=="RearPost" or d.name=="FrontPost")) or action.Name=="Pump" and d.name=="PumpRib" or action.Name=="BoltLever" and d.name=="BoltKnob")
   local parentPart=d.group=="Mag" and magazine or followsAction and action or root
   if d.group=="Mag" then p:SetAttribute("MagazinePart",true) end
   local w=Instance.new("Weld") w.Part0=parentPart w.Part1=p w.C0=parentPart.CFrame:Inverse()*p.CFrame w.Parent=p
  end
 end
 local function point(name,pos) local a=Instance.new("Attachment") a.Name=name a.CFrame=CFrame.new(pos*scale) a.Parent=root return a end
 for name,pos in pairs(Models.Attachments[id] or Models.Attachments.VETOR) do point(name,Vector3.new(pos[1],pos[2],pos[3])) end
 m.Parent=parent return m
end
function F.Mount(tool,id)
 id=id or tool:GetAttribute("WeaponId") or "VETOR"
 if tool:GetAttribute("FactoryRuntimeWeapon")==id then return end
 for _,old in ipairs(tool:GetChildren()) do if old:IsA("BasePart") or old:IsA("Model") then old:Destroy() end end
 tool:SetAttribute("FactoryRuntimeBuilt",true) tool:SetAttribute("FactoryRuntimeWeapon",id) tool:SetAttribute("WeaponId",id)
 local model=F.Build(nil,.82,id) for _,p in ipairs(model:GetChildren()) do p.Parent=tool end model:Destroy()
end
return F
]=] end
do local x=node(mods,'ModuleScript',"WeaponGeometry") x.Source=[=[-- Exportado da modelagem original no Blender.
return {{["name"]="Receiver",["size"]={0.57,0.46,1.9},["pos"]={0,0.25,-0.65},["color"]={48,104,135},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Upper receiver",["size"]={0.62,0.14,1.45},["pos"]={0,0.55,-0.55},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer frente",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,-1.55},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer traseiro",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,0.28},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body"},{["name"]="Handguard",["size"]={0.49,0.4,0.9},["pos"]={0,0.24,-1.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cano virtual",["size"]={0.16,0.16,0.8},["pos"]={0,0.29,-2.78},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Emissor",["size"]={0.29,0.29,0.28},["pos"]={0,0.29,-3.22},["color"]={24,30,39},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Anel frontal",["size"]={0.34,0.34,0.07},["pos"]={0,0.29,-3.12},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Trilho",["size"]={0.29,0.07,1.7},["pos"]={0,0.66,-0.7},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,0.05},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={-0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={-0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={-0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Coronha",["size"]={0.38,0.34,0.65},["pos"]={0,0.2,0.77},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Haste da coronha",["size"]={0.24,0.19,0.4},["pos"]={0,0.32,0.33},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ombreira",["size"]={0.44,0.57,0.12},["pos"]={0,0.13,1.16},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,-0.04,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.08,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.2,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.32,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cabo",["size"]={0.33,0.58,0.36},["pos"]={0,-0.34,0.12},["color"]={48,55,62},["shape"]="Block",["rot"]={-10,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.5,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.38,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.26,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda inferior",["size"]={0.34,0.055,0.43},["pos"]={0,-0.25,-0.22},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda frontal",["size"]={0.34,0.2,0.055},["pos"]={0,-0.13,-0.42},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Magazine",["size"]={0.39,0.63,0.53},["pos"]={0,-0.46,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Base magazine",["size"]={0.44,0.08,0.56},["pos"]={0,-0.8,-0.65},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Mira traseira",["size"]={0.37,0.09,0.22},["pos"]={0,0.71,0.15},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={-0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira frontal",["size"]={0.06,0.16,0.1},["pos"]={0,0.79,-1.7},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Suporte da mira",["size"]={0.18,0.25,0.24},["pos"]={0,0.56,-1.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Moldura frontal",["size"]={0.25,0.07,0.2},["pos"]={0,0.7,-1.7},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Base reflex",["size"]={0.46,0.09,0.5},["pos"]={0,0.785,-0.25},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Arco reflex",["size"]={0.065,0.44,0.095},["pos"]={-0.235,1.04,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Arco reflex",["size"]={0.065,0.44,0.095},["pos"]={0.235,1.04,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Topo reflex",["size"]={0.53,0.065,0.095},["pos"]={0,1.26,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ponto reflex",["size"]={0.018,0.018,0.018},["pos"]={0,1.04,-0.25},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ajuste reflex",["size"]={0.1,0.13,0.17},["pos"]={0.3,0.85,-0.25},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"}}
]=] end
do local x=node(mods,'ModuleScript',"WeaponModels") x.Source=[=[-- Geometria autoral do arsenal VYREL, exportada do mesmo projeto usado no Blender.
return {["Models"]={["VETOR"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.85},["pos"]={0,0.22,-1.65},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.65},["pos"]={0,0.29,-2.35},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-2.7550000000000003},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-2.685},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.8499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["KESTREL"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.85},["pos"]={0,0.22,-1.65},["color"]={111,60,31},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.65},["pos"]={0,0.29,-2.35},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-2.7550000000000003},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-2.685},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GasTube",["size"]={0.17,0.17,0.9},["pos"]={0,0.55,-1.6},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="WoodStock",["size"]={0.41,0.48,0.82},["pos"]={0,0.14,0.81},["color"]={111,60,31},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockChamfer",["size"]={0.41,0.22,0.26},["pos"]={0,0.37,1.05},["color"]={111,60,31},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={111,60,31},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.8499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="CurvedMagazine",["size"]={0.37,0.21,0.48},["pos"]={0,-0.7,-0.64},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="CurvedMagazine",["size"]={0.37,0.21,0.48},["pos"]={0,-0.85,-0.6900000000000001},["color"]={42,48,53},["shape"]="Block",["rot"]={5,0,0},["group"]="Mag",["alpha"]=0},{["name"]="CurvedMagazine",["size"]={0.37,0.21,0.48},["pos"]={0,-1.0,-0.74},["color"]={42,48,53},["shape"]="Block",["rot"]={10,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["LYRA"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={145,133,102},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={145,133,102},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.85},["pos"]={0,0.22,-1.65},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.65},["pos"]={0,0.29,-2.35},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-2.7550000000000003},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-2.685},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.705},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.6350000000000002},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BullpupStock",["size"]={0.62,0.57,0.85},["pos"]={0,0.18,0.65},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ThumbHole",["size"]={0.2,0.1,0.38},["pos"]={0,-0.17,0.2},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearMagazineWell",["size"]={0.44,0.18,0.6},["pos"]={0,-0.16,0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.956},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.8114999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6669999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.5225},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.378},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.8499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["FERAL"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.5},["pos"]={0,0.22,-1.25},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.55},["pos"]={0,0.29,-1.85},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-2.205},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-2.135},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.155},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.085},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.155},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.085},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRod",["size"]={0.06,0.06,0.75},["pos"]={-0.18,0.3,0.72},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRod",["size"]={0.06,0.06,0.75},["pos"]={0.18,0.3,0.72},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RetractableStock",["size"]={0.43,0.5,0.11},["pos"]={0,0.16,1.15},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RoundReceiver",["size"]={0.4,0.4,1.1},["pos"]={0,0.42,-0.5},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.43},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.345},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.26},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.1749999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.0899999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.43},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.345},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.26},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.1749999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.0899999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["PULSAR"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.5},["pos"]={0,0.22,-1.25},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.55},["pos"]={0,0.29,-1.85},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-2.205},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-2.135},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.155},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-2.085},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.155},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-2.085},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="VerticalReceiver",["size"]={0.52,0.7,0.55},["pos"]={0,-0.2,-0.4},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SkeletonStockTop",["size"]={0.32,0.12,0.7},["pos"]={0,0.36,0.79},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SkeletonStockBottom",["size"]={0.32,0.1,0.7},["pos"]={0,0.06,0.79},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.38,0.47,0.1},["pos"]={0,0.21,1.12},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.43},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.345},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.26},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.1749999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.0899999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.43},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.345},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.26},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.1749999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.0899999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["BASIL"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.8},["pos"]={0,0.18,-0.55},["color"]={66,79,59},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.62},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.4500000000000002},["color"]={66,79,59},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.35},["color"]={66,79,59},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,1.15},["pos"]={0,0.22,-1.8},["color"]={66,79,59},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,1.05},["pos"]={0,0.29,-2.85},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-3.455},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-3.385},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={66,79,59},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeMount",["size"]={0.09,0.2,0.28},["pos"]={-0.24,0.78,-0.42},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeMount",["size"]={0.09,0.2,0.28},["pos"]={0.24,0.78,-0.42},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.22,1.04,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,90.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104046,1.1955634918610405,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,135.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={1.3471114790620885e-17,1.26,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,180.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.15556349186104043,1.1955634918610405,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,225.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.22,1.04,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,270.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.1555634918610405,0.8844365081389596,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,315.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-4.041334437186265e-17,0.8200000000000001,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,360.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104043,0.8844365081389596,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,405.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.22,1.04,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,90.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104046,1.1955634918610405,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,135.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={1.3471114790620885e-17,1.26,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,180.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.15556349186104043,1.1955634918610405,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,225.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.22,1.04,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,270.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.1555634918610405,0.8844365081389596,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,315.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-4.041334437186265e-17,0.8200000000000001,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,360.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104043,0.8844365081389596,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,405.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTubeRail",["size"]={0.065,0.1,0.8},["pos"]={-0.21,1.04,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTubeRail",["size"]={0.065,0.1,0.8},["pos"]={0.21,1.04,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTopRail",["size"]={0.22,0.05,0.8},["pos"]={0,1.25,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,1.04,-0.83},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltLever",["size"]={0.3,0.06,0.06},["pos"]={0.39,0.35,0.02},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-25},["group"]="Body",["alpha"]=0},{["name"]="BoltKnob",["size"]={0.13,0.13,0.13},["pos"]={0.55,0.27,0.02},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["ARGO"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.8},["pos"]={0,0.18,-0.55},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.62},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.4500000000000002},["color"]={145,133,102},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.35},["color"]={145,133,102},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,1.15},["pos"]={0,0.22,-1.8},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,1.05},["pos"]={0,0.29,-2.85},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-3.455},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-3.385},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={145,133,102},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeMount",["size"]={0.09,0.2,0.28},["pos"]={-0.24,0.78,-0.42},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeMount",["size"]={0.09,0.2,0.28},["pos"]={0.24,0.78,-0.42},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.22,1.04,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,90.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104046,1.1955634918610405,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,135.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={1.3471114790620885e-17,1.26,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,180.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.15556349186104043,1.1955634918610405,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,225.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.22,1.04,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,270.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.1555634918610405,0.8844365081389596,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,315.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-4.041334437186265e-17,0.8200000000000001,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,360.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104043,0.8844365081389596,-0.9},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,405.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.22,1.04,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,90.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104046,1.1955634918610405,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,135.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={1.3471114790620885e-17,1.26,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,180.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.15556349186104043,1.1955634918610405,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,225.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.22,1.04,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,270.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-0.1555634918610405,0.8844365081389596,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,315.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={-4.041334437186265e-17,0.8200000000000001,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,360.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeRing",["size"]={0.16,0.055,0.12},["pos"]={0.15556349186104043,0.8844365081389596,-0.1},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,405.0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTubeRail",["size"]={0.065,0.1,0.8},["pos"]={-0.21,1.04,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTubeRail",["size"]={0.065,0.1,0.8},["pos"]={0.21,1.04,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ScopeTopRail",["size"]={0.22,0.05,0.8},["pos"]={0,1.25,-0.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,1.04,-0.83},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.37,0.62,0.49},["pos"]={0,-0.46,-0.6},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={-0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.65,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.48,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineRib",["size"]={0.035,0.035,0.43},["pos"]={0.2,-0.31,-0.6},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="MagazineBase",["size"]={0.43,0.07,0.54},["pos"]={0,-0.8,-0.6},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["TORQ"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.8},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.62},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.4500000000000002},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.35},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,1},["pos"]={0,0.22,-1.65},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,0.9},["pos"]={0,0.29,-2.8},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-3.33},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-3.26},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.28},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.21},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.28},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.21},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.01},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.8399999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6699999999999997},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.4999999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.3299999999999996},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.01},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.8399999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6699999999999997},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.4999999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.3299999999999996},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.8499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.71,0.68,0.73},["pos"]={0,-0.47,-0.7},["color"]={66,79,59},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.45,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.505,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.56,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.615,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.67,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.7250000000000001,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.78,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BeltRound",["size"]={0.09,0.08,0.15},["pos"]={-0.835,0.12,-0.55},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Bipod",["size"]={0.065,0.76,0.065},["pos"]={-0.25,-0.1,-2.3},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-20},["group"]="Body",["alpha"]=0},{["name"]="Bipod",["size"]={0.065,0.76,0.065},["pos"]={0.25,-0.1,-2.3},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,20},["group"]="Body",["alpha"]=0},{["name"]="CarryHandle",["size"]={0.1,0.12,0.65},["pos"]={0.17,0.79,-0.65},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0}},["MAREA"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,1.15},["pos"]={0,0.22,-1.8},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.15,0.15,1.05},["pos"]={0,0.29,-2.85},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleBrake",["size"]={0.25,0.25,0.23},["pos"]={0,0.29,-3.455},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="MuzzleRing",["size"]={0.28,0.28,0.055},["pos"]={0,0.29,-3.385},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={-0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.405},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BrakePort",["size"]={0.025,0.065,0.045},["pos"]={0.128,0.29,-3.335},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.214},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-2.0185},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.823},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.6275},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.432},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-2.0},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.1,0.1,0.1},["pos"]={0,-0.46,-0.65},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Hidden",["alpha"]=1},{["name"]="MagazineTube",["size"]={0.2,0.2,1.3},["pos"]={0,0.05,-1.9},["color"]={42,48,53},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Pump",["size"]={0.5,0.3,0.6},["pos"]={0,0.08,-1.55},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.8},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.725},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.6500000000000001},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.5750000000000002},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.5},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.425},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PumpRib",["size"]={0.53,0.035,0.03},["pos"]={0,0.25,-1.35},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0}},["RUPTURA"]={{["name"]="LowerReceiver",["size"]={0.54,0.4,1.5},["pos"]={0,0.18,-0.55},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="UpperReceiver",["size"]={0.57,0.2,1.35},["pos"]={0,0.48,-0.58},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontChamfer",["size"]={0.54,0.16,0.23},["pos"]={0,0.4,-1.3},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearChamfer",["size"]={0.54,0.16,0.2},["pos"]={0,0.4,0.19999999999999996},["color"]={25,29,34},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body",["alpha"]=0},{["name"]="Handguard",["size"]={0.48,0.39,0.8},["pos"]={0,0.22,-1.7},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TwinBarrel",["size"]={0.22,0.22,1.4},["pos"]={-0.14,0.3,-2.3},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TwinBarrel",["size"]={0.22,0.22,1.4},["pos"]={0.14,0.3,-2.3},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockTube",["size"]={0.23,0.18,0.42},["pos"]={0,0.3,0.43},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockBody",["size"]={0.38,0.36,0.62},["pos"]={0,0.2,0.83},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockCheek",["size"]={0.4,0.13,0.48},["pos"]={0,0.43,0.78},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ButtPlate",["size"]={0.44,0.59,0.11},["pos"]={0,0.13,1.18},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,-0.04,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.08,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.2,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="StockRib",["size"]={0.45,0.025,0.12},["pos"]={0,0.32,1.2},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.33,0.58,0.35},["pos"]={0,-0.34,0.12},["color"]={19,21,24},["shape"]="Block",["rot"]={-11,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.5,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.38,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripRib",["size"]={0.35,0.03,0.34},["pos"]={0,-0.26,0.13},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.045,0.42},["pos"]={0,-0.2,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuardFront",["size"]={0.34,0.16,0.045},["pos"]={0,-0.1,-0.41},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.06,0.16,0.045},["pos"]={0,-0.04,-0.12},["color"]={25,29,34},["shape"]="Block",["rot"]={-15,0,0},["group"]="Body",["alpha"]=0},{["name"]="Rail",["size"]={0.3,0.06,1.7},["pos"]={0,0.63,-0.65},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.45},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.31},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.17},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-1.0299999999999998},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.8899999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.7499999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.6099999999999999},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.46999999999999986},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.32999999999999985},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.18999999999999972},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,-0.04999999999999982},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RailTooth",["size"]={0.33,0.04,0.07},["pos"]={0,0.68,0.09000000000000008},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={-0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={-0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={-0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.988},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.8519999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.716},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.5799999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={-0.25,0.26,-1.444},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReceiverPanel",["size"]={0.025,0.22,0.96},["pos"]={0.28,0.23,-0.55},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Selector",["size"]={0.035,0.04,0.18},["pos"]={0.3,0.22,0.01},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,-15},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.95},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.6},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,-0.2},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Pin",["size"]={0.055,0.055,0.025},["pos"]={0.3,0.22,0.08},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.988},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.8519999999999999},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.716},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.5799999999999998},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Vent",["size"]={0.025,0.13,0.09},["pos"]={0.25,0.26,-1.444},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="EjectionPort",["size"]={0.035,0.14,0.36},["pos"]={0.301,0.41,-0.39},["color"]={19,21,24},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BoltHandle",["size"]={0.18,0.07,0.09},["pos"]={0.37,0.38,-0.25},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SightMount",["size"]={0.4,0.08,0.33},["pos"]={0,0.76,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={-0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexUpright",["size"]={0.06,0.35,0.09},["pos"]={0.22,0.96,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="ReflexTop",["size"]={0.5,0.06,0.09},["pos"]={0,1.14,-0.22},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Reticle",["size"]={0.014,0.014,0.014},["pos"]={0,0.96,-0.22},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontSight",["size"]={0.06,0.13,0.08},["pos"]={0,0.77,-1.9},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.1,0.1,0.1},["pos"]={0,-0.46,-0.65},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Hidden",["alpha"]=1},{["name"]="HingePin",["size"]={0.6,0.08,0.08},["pos"]={0,0.09,-0.8},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="BreakLever",["size"]={0.05,0.09,0.28},["pos"]={0,0.63,0.02},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0}},["VESPER"]={{["name"]="Frame",["size"]={0.4,0.25,1.25},["pos"]={0,0.04,-0.35},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Slide",["size"]={0.43,0.27,1.25},["pos"]={0,0.31,-0.38},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideChamfer",["size"]={0.43,0.12,0.18},["pos"]={0,0.38,-0.9125},["color"]={42,48,53},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.35,0.66,0.35},["pos"]={0,-0.34,0.13},["color"]={19,21,24},["shape"]="Block",["rot"]={-12,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.12,0.12,0.24},["pos"]={0,0.29,-1.0625},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.05},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.13},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.29},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.55,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.43,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.19,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripPanel",["size"]={0.022,0.44,0.23},["pos"]={-0.19,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.05},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.13},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.29},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.55,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.43,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.19,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripPanel",["size"]={0.022,0.44,0.23},["pos"]={0.19,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.05,0.4},["pos"]={0,-0.17,-0.21},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GuardFront",["size"]={0.34,0.18,0.05},["pos"]={0,-0.08,-0.4},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.05,0.14,0.045},["pos"]={0,-0.06,-0.14},["color"]={116,125,132},["shape"]="Block",["rot"]={-12,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearSight",["size"]={0.36,0.07,0.1},["pos"]={0,0.49,0.03},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearPost",["size"]={0.06,0.09,0.08},["pos"]={-0.13,0.55,0.03},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearPost",["size"]={0.06,0.09,0.08},["pos"]={0.13,0.55,0.03},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontPost",["size"]={0.045,0.09,0.08},["pos"]={0,0.55,-0.875},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.29,0.15,0.3},["pos"]={0,-0.65,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}},["NOMAD"]={{["name"]="Frame",["size"]={0.4,0.25,1.05},["pos"]={0,0.04,-0.35},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Slide",["size"]={0.43,0.27,1.05},["pos"]={0,0.31,-0.38},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideChamfer",["size"]={0.43,0.12,0.18},["pos"]={0,0.38,-0.7665},["color"]={42,48,53},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="PistolGrip",["size"]={0.35,0.66,0.35},["pos"]={0,-0.34,0.13},["color"]={19,21,24},["shape"]="Block",["rot"]={-12,0,0},["group"]="Body",["alpha"]=0},{["name"]="Barrel",["size"]={0.12,0.12,0.24},["pos"]={0,0.29,-0.8925},["color"]={116,125,132},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.05},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.13},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={-0.224,0.31,-0.29},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.55,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.43,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={-0.183,-0.19,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripPanel",["size"]={0.022,0.44,0.23},["pos"]={-0.19,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.05},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.13},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.21},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="SlideSerration",["size"]={0.025,0.19,0.025},["pos"]={0.224,0.31,-0.29},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.55,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.43,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripTexture",["size"]={0.025,0.035,0.26},["pos"]={0.183,-0.19,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GripPanel",["size"]={0.022,0.44,0.23},["pos"]={0.19,-0.31,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="TriggerGuard",["size"]={0.34,0.05,0.4},["pos"]={0,-0.17,-0.21},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="GuardFront",["size"]={0.34,0.18,0.05},["pos"]={0,-0.08,-0.4},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Trigger",["size"]={0.05,0.14,0.045},["pos"]={0,-0.06,-0.14},["color"]={116,125,132},["shape"]="Block",["rot"]={-12,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearSight",["size"]={0.36,0.07,0.1},["pos"]={0,0.49,0.03},["color"]={25,29,34},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearPost",["size"]={0.06,0.09,0.08},["pos"]={-0.13,0.55,0.03},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="RearPost",["size"]={0.06,0.09,0.08},["pos"]={0.13,0.55,0.03},["color"]={116,125,132},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="FrontPost",["size"]={0.045,0.09,0.08},["pos"]={0,0.55,-0.735},["color"]={184,143,70},["shape"]="Block",["rot"]={0,0,0},["group"]="Body",["alpha"]=0},{["name"]="Magazine",["size"]={0.29,0.15,0.3},["pos"]={0,-0.65,0.14},["color"]={42,48,53},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag",["alpha"]=0}}},["Attachments"]={["VETOR"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-2.8750000000000004},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["KESTREL"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-2.8750000000000004},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["LYRA"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-2.8750000000000004},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,0.6},["StockPivot"]={0,0.13,1.16}},["FERAL"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-2.325},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["PULSAR"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-2.325},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["BASIL"]={["AimPoint"]={0,1.04,0.5},["Muzzle"]={0,0.29,-3.575},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["ARGO"]={["AimPoint"]={0,1.04,0.5},["Muzzle"]={0,0.29,-3.575},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.6},["StockPivot"]={0,0.13,1.16}},["TORQ"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-3.45},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.47,-0.7},["StockPivot"]={0,0.13,1.16}},["MAREA"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-3.575},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.65},["StockPivot"]={0,0.13,1.16}},["RUPTURA"]={["AimPoint"]={0,0.96,0.52},["Muzzle"]={0,0.29,-3.2},["LeftGrip"]={-0.3,-0.08,-0.95},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.05,-0.3,0.12},["MagazinePivot"]={0,-0.46,-0.65},["StockPivot"]={0,0.13,1.16}},["VESPER"]={["AimPoint"]={0,0.57,0.48},["Muzzle"]={0,0.29,-1.225},["LeftGrip"]={-0.25,-0.18,0.05},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.04,-0.29,0.12},["MagazinePivot"]={0,-0.65,0.14},["StockPivot"]={0,0,0}},["NOMAD"]={["AimPoint"]={0,0.57,0.48},["Muzzle"]={0,0.29,-1.029},["LeftGrip"]={-0.25,-0.18,0.05},["WorldLeftGrip"]={-0.58,-0.08,-0.24},["RightGripPoint"]={0.04,-0.29,0.12},["MagazinePivot"]={0,-0.65,0.14},["StockPivot"]={0,0,0}}}}
]=] end
do local x=node(mods,'ModuleScript',"WeaponState") x.Source=[=[local Default=require(script.Parent.WeaponConfig)
local S={}
function S.New(life,cfg) local C=cfg or Default return {cfg=C,life=life,ammo=C.Magazine,reserve=C.Reserve,equipped=false,reloading=false,reloadEnd=0,inspectEnd=0,running=false,aiming=false,pitch=0,readyAt=0,lastShot=-1e6,lastSeq=0,generation=0,revision=0} end
function S.Equip(s,value,now)
 local C=s.cfg or Default
 s.generation+=1 s.equipped=value s.reloading=false s.reloadEnd=0 s.inspectEnd=0 s.running=false s.aiming=false s.readyAt=now+(value and C.EquipTime or 0)
end
function S.Acknowledge(s,seq)
 if type(seq)~="number" or seq%1~=0 or seq<=s.lastSeq or seq>s.lastSeq+1000 then return false end s.lastSeq=seq return true
end
function S.Fire(s,seq,now)
 local C=s.cfg or Default
 if not S.Acknowledge(s,seq) then return false,"Sequence" end
 if not s.equipped or now<s.readyAt then return false,"Equip" end
 if s.reloading or s.running then return false,"Busy" end
 if now-s.lastShot<C.FireInterval-.002 then return false,"Cadence" end
 if s.ammo<=0 then return false,"Empty" end
 s.inspectEnd=0 s.lastShot=now s.ammo-=1 return true
end
function S.Reload(s,now)
 local C=s.cfg or Default
 if not s.equipped or now<s.readyAt or s.reloading or s.running or s.ammo>=C.Magazine or s.reserve<=0 then return false end
 s.generation+=1 s.reloading=true s.reloadEnd=now+C.ReloadTime s.inspectEnd=0 s.aiming=false return true,s.generation
end
function S.FinishReload(s,token,now)
 local C=s.cfg or Default
 if token~=s.generation or not s.reloading or not s.equipped or now+.001<s.reloadEnd then return false end
 local count=math.min(C.Magazine-s.ammo,s.reserve) s.ammo+=count s.reserve-=count s.reloading=false s.reloadEnd=0 return true
end
return S
]=] end
do local x=node(mods,'ModuleScript',"WorldService") x.Source=[=[local W={Centers={Lobby=Vector3.new(0,0,260),Casual=Vector3.new(0,0,0),Training=Vector3.new(500,0,0)},Cover={},Spawns={}} local built=false
local function part(parent,name,size,cf,color,material,shape)
 local p=Instance.new(shape=="Wedge" and "WedgePart" or "Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material or Enum.Material.Concrete p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local stone=Color3.fromRGB(120,130,142) local trim=Color3.fromRGB(41,49,65) local cyan=Color3.fromRGB(75,229,239) local coral=Color3.fromRGB(242,115,106)
local function arena(root,key,center)
 local m=Instance.new("Model") m.Name=key m.Parent=root W.Centers[key]=center W.Cover[key]={} W.Spawns[key]={}
 local function at(v) return CFrame.new(center+v) end
 local floor=part(m,"Piso",Vector3.new(148,2,148),at(Vector3.zero),Color3.fromRGB(155,164,173)) floor.TopSurface=Enum.SurfaceType.Studs
 for _,d in ipairs({{0,5,-74,148,10,2},{0,5,74,148,10,2},{-74,5,0,2,10,148},{74,5,0,2,10,148}}) do part(m,"Muralha",Vector3.new(d[4],d[5],d[6]),at(Vector3.new(d[1],d[2],d[3])),trim) end
 for _,x in ipairs({-44,44}) do for _,z in ipairs({-42,42}) do
  local base=Vector3.new(x,3,z) part(m,"Bastiao",Vector3.new(20,6,13),at(base),stone)
  part(m,"Friso",Vector3.new(20.2,.3,13.2),at(base+Vector3.new(0,3,0)),trim)
  local window=part(m,"Painel de energia",Vector3.new(9,1,.18),at(base+Vector3.new(0,1,-6.6)),cyan,Enum.Material.Neon) window.CanCollide=false
  table.insert(W.Cover[key],center+Vector3.new(x,4,z+10))
 end end
 for _,d in ipairs({{-20,-12,12,5,4},{22,16,12,5,4},{-8,32,5,5,14},{11,-34,5,5,14},{-38,7,5,4,12},{38,-8,5,4,12}}) do
  local pos=Vector3.new(d[1],d[4]/2+1,d[2]) local crate=part(m,"Cobertura",Vector3.new(d[3],d[4],d[5]),at(pos),Color3.fromRGB(102,113,126)) crate.TopSurface=Enum.SurfaceType.Studs
  for _,side in ipairs({-1,1}) do part(m,"Cinta",Vector3.new(.25,d[4]+.1,d[5]+.1),at(pos+Vector3.new(side*d[3]*.35,0,0)),trim) end
  table.insert(W.Cover[key],center+Vector3.new(d[1],4,d[2]+d[5]/2+3))
 end
 part(m,"PlataformaCentral",Vector3.new(22,3,22),at(Vector3.new(0,2,0)),trim)
 for i=0,3 do local angle=i*math.pi/2 local cf=at(Vector3.new(math.sin(angle)*18,1.8,math.cos(angle)*18))*CFrame.Angles(0,angle,0) part(m,"Rampa",Vector3.new(14,3.6,15),cf,stone,nil,"Wedge") end
 local core=part(m,"Nucleo",Vector3.new(9,.12,9),at(Vector3.new(0,3.6,0)),cyan,Enum.Material.Neon) core.CanCollide=false
 for i=0,7 do local angle=i*math.pi/4 local pos=Vector3.new(math.sin(angle)*58,4,math.cos(angle)*58) table.insert(W.Spawns[key],center+pos) end
 for _,x in ipairs({-61,61}) do
  part(m,"Torre",Vector3.new(8,18,8),at(Vector3.new(x,10,0)),stone)
  part(m,"TopoTorre",Vector3.new(11,2,11),at(Vector3.new(x,20,0)),trim)
  part(m,"SinalTorre",Vector3.new(.2,10,.2),at(Vector3.new(x,26,0)),coral,Enum.Material.Neon).CanCollide=false
 end
 for i=1,10 do local angle=i*2.399 local radius=95+(i%3)*8 local h=14+(i%5)*7 part(m,"EstruturaDeFundo",Vector3.new(12,h,12),at(Vector3.new(math.sin(angle)*radius,h/2-2,math.cos(angle)*radius)),Color3.fromRGB(75,87,107)) end
end
function W.Build()
 if built then return end built=true
 for _,name in ipairs({"BancadaTeste","Spawn","ParedeTesteLOS","Instrucoes"}) do local old=workspace:FindFirstChild(name) if old then old:Destroy() end end
 local root=Instance.new("Folder") root.Name="VYRELWorld" root.Parent=workspace
 arena(root,"Casual",W.Centers.Casual) arena(root,"Training",W.Centers.Training)
 for i=1,3 do arena(root,"Ranked"..i,Vector3.new(1000+(i-1)*220,0,0)) end
 local lobby=Instance.new("Model") lobby.Name="Citadela" lobby.Parent=root local c=W.Centers.Lobby
 part(lobby,"Ilha",Vector3.new(120,5,100),CFrame.new(c+Vector3.new(0,-2,0)),trim)
 part(lobby,"Praca",Vector3.new(94,2,80),CFrame.new(c+Vector3.new(0,1,0)),stone)
 for i=0,7 do local angle=i*math.pi/4 local pos=c+Vector3.new(math.sin(angle)*28,17,math.cos(angle)*28)
  part(lobby,"Arco",Vector3.new(4,30,4),CFrame.new(pos)*CFrame.Angles(0,angle,.08),trim)
  part(lobby,"Cristal",Vector3.new(2,8,2),CFrame.new(pos+Vector3.new(0,19,0))*CFrame.Angles(.2,angle,.35),coral,Enum.Material.Neon)
 end
 local ring=part(lobby,"Portal",Vector3.new(17,17,2),CFrame.new(c+Vector3.new(0,14,-15)),trim) ring.Transparency=.8 ring.CanCollide=false
 for i=0,11 do local a=i*math.pi/6 part(lobby,"PortalSegmento",Vector3.new(4,.9,1),CFrame.new(c+Vector3.new(math.cos(a)*8,14+math.sin(a)*8,-16))*CFrame.Angles(0,0,a+math.pi/2),cyan,Enum.Material.Neon).CanCollide=false end
 for i=1,14 do local angle=i*2.399 local r=65+i*2 local height=12+i%4*10 part(lobby,"CidadeSuspensa",Vector3.new(14,height,14),CFrame.new(c+Vector3.new(math.sin(angle)*r,height/2-5,math.cos(angle)*r)),stone) end
end
function W.GetSpawn(p)
 W.Build() local id=p:GetAttribute("FPSArena") or "Lobby"
 if id=="Lobby" then return W.Centers.Lobby+Vector3.new(0,5,25) end
 local list=W.Spawns[id] or W.Spawns.Casual local index=p:GetAttribute("FPSSide")=="B" and 5 or 1
 if id=="Casual" or id=="Training" then index=1+(math.abs(p.UserId)%#list) end
 return list[index]
end
return W
]=] end
local rifle=node(Pack,'Tool','Rifle') rifle.RequiresHandle=true rifle.CanBeDropped=false require(mods.WeaponFactory).Mount(rifle)
do local x=node(rifle,'LocalScript','Controller') x.Source=[=[local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
require(system.Modules.ClientController).attach(script.Parent)
]=] end
do local x=node(SP,'LocalScript','FPSObserver') x.Source=[=[local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local modules=system:WaitForChild("Modules")
local cleanup=require(modules.LoadoutController).init()
local matchCleanup=require(modules.MatchHUD).init()
local abilityCleanup=require(modules.AbilityController).init()
local menuCleanup=require(modules.GameMenu).init()
script.Destroying:Connect(function() cleanup() matchCleanup() abilityCleanup() menuCleanup() end)
require(modules.ThirdPersonController).init(false)
]=] end
do local x=Instance.new('Script') x.Name="GameServer" x.Source=[=[local modules=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem"):WaitForChild("Modules")
require(modules.SessionService).Init()
require(modules.SkillService).Init()
require(modules.BotService).Init()
]=] x.Parent=SS end
do local x=Instance.new('Script') x.Name="GunServer" x.Source=[=[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Physics=game:GetService("PhysicsService")
pcall(function() Physics:RegisterCollisionGroup("FPSViewModel") end)
for _,g in ipairs(Physics:GetRegisteredCollisionGroups()) do Physics:CollisionGroupSetCollidable("FPSViewModel",g.name,false) end
local System=RS:WaitForChild("FPSSystem") local Modules=System.Modules
local C=require(Modules.WeaponConfig) local Logic=require(Modules.WeaponState) local Factory=require(Modules.WeaponFactory)
local Anim=require(Modules.AnimationController) local Match=require(Modules.MatchState)
local Catalog=require(Modules.WeaponCatalog) local Combat=require(Modules.CombatService) local Session=require(Modules.SessionService) local Skills=require(Modules.SkillService)
local Remotes=System:WaitForChild("Remotes")
local states={} local lives={} local windows={}
local function now() return workspace:GetServerTimeNow() end
local function rate(p,key,limit)
 local t=now() local buckets=windows[p] or {} windows[p]=buckets local b=buckets[key] or {t=t,n=0} buckets[key]=b
 if t-b.t>=1 then b.t=t b.n=0 end b.n+=1 return b.n<=limit
end
local function snapshot(p,s,reason)
 local C=s.cfg
 if not p.Parent or states[p]~=s then return end s.revision+=1
 if s.tool and s.tool.Parent then for k,v in pairs({ReloadEnd=s.reloadEnd,InspectEnd=s.inspectEnd,Running=s.running,Aiming=s.aiming,AimPitch=s.pitch,EquippedAt=s.readyAt-C.EquipTime}) do s.tool:SetAttribute(k,v) end end
 Remotes.State:FireClient(p,{weaponId=s.cfg.Id,life=s.life,revision=s.revision,ammo=s.ammo,reserve=s.reserve,ack=s.lastSeq,reloading=s.reloading,reloadEnd=s.reloadEnd,readyAt=s.readyAt,equipped=s.equipped,inspectEnd=s.inspectEnd,reason=reason})
end
local function healthy(p,s)
 local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 return char and h and h.Health>0 and s.tool and s.tool.Parent==char and s.equipped
end
local function finite(v)
 if typeof(v)~="Vector3" then return false end
 return v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e5 and math.abs(v.Y)<1e5 and math.abs(v.Z)<1e5
end
Remotes.Fire.OnServerEvent:Connect(function(p,life,seq,origin,direction)
 if not rate(p,"fire",40) then return end local s=states[p] if not s then return end
 if life~=s.life then snapshot(p,s,"Equip") return end
 local function reject(reason) if Logic.Acknowledge(s,seq) then snapshot(p,s,reason) end end
 if not healthy(p,s) or p:GetAttribute("FPSMode")=="Lobby" then reject("Equip") return end
 if (p.Character:GetAttribute("FPSDashUntil") or 0)>now() or (p.Character:GetAttribute("FPSCastUntil") or 0)>now() then reject("Busy") return end
 local C=s.cfg
 if not finite(origin) or not finite(direction) or direction.Magnitude<.5 or direction.Magnitude>1.5 then reject("Intent") return end
 local head=p.Character:FindFirstChild("Head") if not head or (origin-head.Position).Magnitude>5 then reject("Origin") return end
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={p.Character} params.IgnoreWater=true
 if (origin-head.Position).Magnitude>.1 and workspace:Raycast(head.Position,origin-head.Position,params) then reject("OriginBlocked") return end
 local ok,reason=Logic.Fire(s,seq,now()) if not ok then snapshot(p,s,reason) return end
 local dir=direction.Unit local basis=CFrame.lookAt(Vector3.zero,dir) local random=Random.new(s.life*100003+seq)
 local damageTotal=0 local criticalAny=false local killedAny=false local firstHit local firstTarget
 for pellet=1,(C.Pellets or 1) do
  local shotDir=dir
  if (C.Spread or 0)>0 then shotDir=(basis*CFrame.Angles(math.rad(random:NextNumber(-C.Spread,C.Spread)),math.rad(random:NextNumber(-C.Spread,C.Spread)),0)).LookVector end
  local hit=workspace:Raycast(head.Position,shotDir*C.Range,params) local target=hit and hit.Position or head.Position+shotDir*C.Range
  if pellet==1 then firstHit=hit firstTarget=target end
  if hit and not Combat.Barrier(hit.Instance,C.Damage) then
   local model=hit.Instance:FindFirstAncestorOfClass("Model") local critical=hit.Instance.Name=="Head"
   local falloff=math.clamp(1-(target-head.Position).Magnitude/C.Range*.45,.55,1)
   local amount,killed=Combat.Apply(p,model,C.Damage*falloff*(critical and C.Critical or 1),critical,target)
   damageTotal+=amount criticalAny=criticalAny or amount>0 and critical killedAny=killedAny or killed
  end
 end
 if damageTotal>0 then Remotes.Hit:FireClient(p,criticalAny,damageTotal,killedAny) end
 local muzzle=s.tool.Handle:FindFirstChild("Muzzle") local joint=s.tool.Handle:FindFirstChild("WorldGrip") local torso=p.Character:FindFirstChild("Torso")
 local gunCF
 if torso and joint then
  local shoulder=torso:FindFirstChild("Right Shoulder")
  if shoulder and joint.Part0==shoulder.Part1 then gunCF=torso.CFrame*shoulder.C0*shoulder.C1:Inverse()*joint.C0*(joint.C1 or CFrame.new()):Inverse() else gunCF=torso.CFrame*joint.C0 end
 end
 local start=gunCF and muzzle and (gunCF*muzzle.CFrame).Position or head.Position
 if (start-head.Position).Magnitude>7 or workspace:Raycast(head.Position,start-head.Position,params) then start=head.Position end
 Skills.OnShot(p,start)
 p.Character:SetAttribute("FPSLastShotAt",now())
 Remotes.WeaponFX:FireAllClients(p.UserId,start,firstTarget,firstHit and firstHit.Normal or nil)
 snapshot(p,s)
end)
Remotes.Reload.OnServerEvent:Connect(function(p,life)
 if not rate(p,"reload",6) then return end local s=states[p]
 if not s or life~=s.life or not healthy(p,s) or p:GetAttribute("FPSMode")=="Lobby" or (p.Character:GetAttribute("FPSDashUntil") or 0)>now() then return end
 local C=s.cfg
 local ok,token=Logic.Reload(s,now()) snapshot(p,s,ok and nil or "ReloadRejected") if not ok then return end
 local function finish()
  if states[p]~=s or s.generation~=token or not healthy(p,s) then return end
  local waitTime=s.reloadEnd-now() if waitTime>.001 then task.delay(waitTime,finish) return end
  Logic.FinishReload(s,token,now()) snapshot(p,s)
 end task.delay(C.ReloadTime,finish)
end)
Remotes.Action.OnServerEvent:Connect(function(p,action,value)
 if not rate(p,"action",20) or type(action)~="string" then return end local s=states[p] if not s then return end
 if action=="Sync" then snapshot(p,s) return end
 if not healthy(p,s) or s.reloading or now()<s.readyAt or p:GetAttribute("FPSMode")=="Lobby" or (p.Character:GetAttribute("FPSDashUntil") or 0)>now() then return end
 local C=s.cfg
 if action=="Pitch" and type(value)=="number" and value==value and math.abs(value)<=1.2 then s.pitch=value s.tool:SetAttribute("AimPitch",value) return end
 if action=="Aim" and type(value)=="boolean" then s.aiming=value if value then s.running=false s.inspectEnd=0 end
 elseif action=="Run" and type(value)=="boolean" then s.running=value if value then s.aiming=false s.inspectEnd=0 end
 elseif action=="Inspect" then s.inspectEnd=now()+C.InspectTime s.aiming=false s.running=false
 elseif action=="CancelInspect" then s.inspectEnd=0
 else return end
 local h=p.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=s.running and C.RunSpeed or C.WalkSpeed end snapshot(p,s)
end)
local function character(p,char)
 local h=char:WaitForChild("Humanoid",10) local torso=char:WaitForChild("Torso",10)
 if p.Character~=char or not h or not torso then return end
 local previous=states[p]
 if previous then Logic.Equip(previous,false,now()) for _,c in ipairs(previous.connections or {}) do c:Disconnect() end end
 lives[p]=(lives[p] or 0)+1 local cfg=Catalog.Get(p:GetAttribute("FPSWeapon")) local s=Logic.New(lives[p],cfg) s.connections={} states[p]=s
 local function connect(signal,fn) local c=signal:Connect(fn) table.insert(s.connections,c) end
 local backpack=p:WaitForChild("Backpack",10) if not backpack or p.Character~=char or states[p]~=s then return end
 for _,parent in ipairs({backpack,char}) do for _,t in ipairs(parent:GetChildren()) do if t:IsA("Tool") and t.Name=="Rifle" then t:Destroy() end end end
 local tool=game:GetService("StarterPack"):WaitForChild("Rifle"):Clone() Factory.Mount(tool,cfg.Id) s.tool=tool tool.ToolTip=cfg.Name s.ammoCache={} tool.CanBeDropped=false
 local function cancel()
  Logic.Equip(s,false,now()) local grip=tool.Handle:FindFirstChild("WorldGrip") if grip then grip:Destroy() end
  if h.Parent then h.WalkSpeed=p:GetAttribute("FPSMode")=="Lobby" and 0 or s.cfg.WalkSpeed end snapshot(p,s)
 end
 connect(tool.Equipped,function()
  if states[p]~=s or p.Character~=char or tool.Parent~=char or h.Health<=0 then return end
  if p:GetAttribute("FPSMode")=="Lobby" then task.defer(function() if h.Parent then h:UnequipTools() end end) return end
  local function removeDefault() local arm=char:FindFirstChild("Right Arm") local old=arm and arm:FindFirstChild("RightGrip") if old then old:Destroy() end end
  removeDefault() task.defer(removeDefault)
  local previous=tool.Handle:FindFirstChild("WorldGrip") if previous then previous:Destroy() end
  local right=char:FindFirstChild("Right Arm") local shoulder=torso:FindFirstChild("Right Shoulder")
  local joint=Instance.new("Motor6D") joint.Name="WorldGrip" joint.Part1=tool.Handle joint.C1=CFrame.new()
  local desired=torso.CFrame*Anim.WorldBase(torso)
  if right and shoulder then
   joint.Part0=right joint.C0=(torso.CFrame*shoulder.C0*shoulder.C1:Inverse()):ToObjectSpace(desired)
   tool.Grip=joint.C0:Inverse()*CFrame.new(0,-right.Size.Y*.5,0)
  else joint.Part0=torso joint.C0=Anim.WorldBase(torso) end
  joint.Parent=tool.Handle
  Logic.Equip(s,true,now()) Match.Equip(p) snapshot(p,s)
 end)
 local rightArm=char:FindFirstChild("Right Arm")
 if rightArm then connect(rightArm.ChildAdded,function(j)
  if j.Name=="RightGrip" and j:IsA("JointInstance") and j.Part1==tool.Handle and tool.Parent==char then j:Destroy() end
 end) end
 connect(tool.Unequipped,function() if states[p]==s then cancel() end end)
 connect(h.Died,function() if states[p]==s then cancel() end end)
 tool.Parent=backpack snapshot(p,s)
 if p:GetAttribute("FPSMode") and p:GetAttribute("FPSMode")~="Lobby" then task.defer(function() if states[p]==s and h.Health>0 then h:EquipTool(tool) end end) end
 local function rejectDuplicate(t) if t:IsA("Tool") and t.Name=="Rifle" and t~=tool then task.defer(function() if t.Parent then t:Destroy() end end) end end
 connect(backpack.ChildAdded,rejectDuplicate) connect(char.ChildAdded,rejectDuplicate)
 local shield=Instance.new("ForceField") shield.Parent=char game:GetService("Debris"):AddItem(shield,3)
end
Session.WeaponChanged.Event:Connect(function(p,id,fresh)
 local s=states[p] if not s or not s.tool or not Catalog.Weapons[id] then return end
 local char=p.Character local h=char and char:FindFirstChildOfClass("Humanoid") if not h or h.Health<=0 then return end
 local was=s.equipped
 s.ammoCache[s.cfg.Id]={ammo=s.ammo,reserve=s.reserve} if fresh then s.ammoCache={} end
 h:UnequipTools() Logic.Equip(s,false,now())
 s.cfg=Catalog.Get(id) local cached=s.ammoCache[id]
 s.ammo=cached and cached.ammo or s.cfg.Magazine s.reserve=cached and cached.reserve or s.cfg.Reserve
 Factory.Mount(s.tool,id) s.tool.ToolTip=s.cfg.Name snapshot(p,s)
 if p:GetAttribute("FPSMode")~="Lobby" and (was or fresh) then h:EquipTool(s.tool) end
end)
local function added(p) p.CharacterAdded:Connect(function(char) task.spawn(character,p,char) end) if p.Character then task.spawn(character,p,p.Character) end end
Players.PlayerAdded:Connect(added) Players.PlayerRemoving:Connect(function(p) local s=states[p] if s then for _,c in ipairs(s.connections or {}) do c:Disconnect() end end states[p]=nil windows[p]=nil lives[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do added(p) end
]=] x.Parent=SS end
do local x=Instance.new('Script') x.Name="MatchServer" x.Source=[=[local modules=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem"):WaitForChild("Modules")
require(modules:WaitForChild("MatchState")).Init()
]=] x.Parent=SS end
if USE_CUSTOM_R6 then local x=Instance.new('Script') x.Name="R6Characters" x.Source=[=[local Players=game:GetService("Players")
local Physics=game:GetService("PhysicsService")
local System=game:GetService("ReplicatedStorage").FPSSystem
local C=require(System.Modules.WeaponConfig)
local Avatar=require(System.Modules.AvatarAppearance) local World=require(System.Modules.WorldService)
local spawning={} local bound={}
local function spawn(p)
 if not p.Parent or spawning[p] then return end spawning[p]=true
 local id=p.UserId
 -- Clientes locais do Studio usam IDs negativos. O criador e uma referencia opcional.
 if id<=0 and game.CreatorType==Enum.CreatorType.User and game.CreatorId>0 then id=game.CreatorId end
 local model,err=Avatar.Create(id)
 if not p.Parent then if model then model:Destroy() end Avatar.Clear(id) spawning[p]=nil return end
 if not model then spawning[p]=nil warn("[R6] Avatar indisponivel: "..tostring(err)) task.delay(3,function() spawn(p) end) return end
 local old=p.Character model.Name=p.Name
 local root=model:FindFirstChild("HumanoidRootPart") local h=model:FindFirstChildOfClass("Humanoid")
 if not root or not h then model:Destroy() spawning[p]=nil return end
 model.PrimaryPart=root h.DisplayName=p.DisplayName h.WalkSpeed=p:GetAttribute("FPSMode")=="Lobby" and 0 or C.WalkSpeed h.UseJumpPower=true h.JumpPower=50
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("BasePart") then v.CollisionGroup="Characters" if v.Parent and v.Parent:IsA("Accessory") then v.CanQuery=false end end end
 model:PivotTo(CFrame.new(World.GetSpawn(p))) model.Parent=workspace p.Character=model
 if old then old:Destroy() end spawning[p]=nil
 h.Died:Connect(function() task.delay(3,function() if p.Parent and p.Character==model then spawn(p) end end) end)
 if model:GetAttribute("AppearanceFallback") then warn("[R6] Aparencia neutra temporaria; nao foi possivel carregar a conta "..id) end
end
pcall(function() Physics:RegisterCollisionGroup("Characters") end)
pcall(function() Physics:RegisterCollisionGroup("FPSViewModel") end)
Physics:CollisionGroupSetCollidable("Characters","Characters",false)
Physics:CollisionGroupSetCollidable("FPSViewModel","Characters",false)
Physics:CollisionGroupSetCollidable("FPSViewModel","Default",false)
Physics:CollisionGroupSetCollidable("FPSViewModel","FPSViewModel",false)
Players.CharacterAutoLoads=false
local function add(p) p.CameraMode=Enum.CameraMode.LockFirstPerson p.CameraMinZoomDistance=.5 p.CameraMaxZoomDistance=.5 if bound[p] then return end bound[p]=true task.spawn(spawn,p) end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(p) spawning[p]=nil bound[p]=nil Avatar.Clear(p.UserId) end)
for _,p in ipairs(Players:GetPlayers()) do add(p) end
]=] x.Parent=SS end
do local x=Instance.new('Script') x.Name="ReplicateAnimations" x.Source=[=[-- C0 e propriedades visuais atualizados no servidor replicam a todos os clientes.
local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
require(system:WaitForChild("Modules"):WaitForChild("ThirdPersonController")).init(true)
]=] x.Parent=SS end
require(mods.WeaponFactory).Build(assets)
local vm=require(mods.ViewModelController).new(workspace.CurrentCamera) vm.model.Parent=assets
print('VYREL instalado. Use Play para gerar os mapas e abrir o menu. Publicacao e DataStore sao configurados no Studio.')