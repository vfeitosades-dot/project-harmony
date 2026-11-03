-- INSTALADOR FPS R6. Execute na Command Bar do Studio fora do Play.
local USE_CUSTOM_R6 = true -- false se a experiencia ja cria seus proprios personagens R6.
assert(not game:GetService('RunService'):IsRunning(),'Pare o Play antes de instalar.')
local RS=game:GetService('ReplicatedStorage') local SS=game:GetService('ServerScriptService') local SP=game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts') local Pack=game:GetService('StarterPack')
assert(not RS:FindFirstChild('FPSSystem') and not SS:FindFirstChild('GunServer') and not Pack:FindFirstChild('Rifle') and not SP:FindFirstChild('FPSObserver'),'Ja existe um sistema com esses nomes; nada foi sobrescrito.')
local function node(parent,kind,name) local x=Instance.new(kind) x.Name=name x.Parent=parent return x end
local sys=node(RS,'Folder','FPSSystem') local mods=node(sys,'Folder','Modules') local rem=node(sys,'Folder','Remotes') local assets=node(sys,'Folder','Assets')
for _,name in ipairs({'Fire','Reload','WeaponFX','State','Action','Hit','MatchFeed'}) do node(rem,'RemoteEvent',name) end
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
 return CFrame.new(torso.Size.X*.45,torso.Size.Y*.26,-torso.Size.Z*.5-1.02)
end
function A.WorldSample(now,phase,move,run,jump,aim)
 local steady=1-.8*aim
 return worldIdle(now)*CFrame.new(math.sin(phase)*.02*move*steady,
  math.cos(phase*2)*(.016+.012*run)*move*steady+.055*jump+.045*aim-.06*run,-.025*aim+.045*run)
  *CFrame.Angles(-.055*run+.035*jump,math.sin(phase)*.02*move*steady,.018*run)
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
do local x=node(mods,'ModuleScript',"ClientController") x.Source=[=[local Players=game:GetService("Players") local Input=game:GetService("UserInputService") local Run=game:GetService("RunService") local Gui=game:GetService("GuiService")
local System=game:GetService("ReplicatedStorage").FPSSystem local R=System.Remotes
local C=require(script.Parent.WeaponConfig) local Anim=require(script.Parent.AnimationController) local View=require(script.Parent.ViewModelController) local HUD=require(script.Parent.HUD) local Effects=require(script.Parent.WeaponEffects)
local Controller={} Controller.__index=Controller local active
local function now() return workspace:GetServerTimeNow() end
function Controller:Cleanup()
 self.token+=1 self.equipped=false self.holding=false self.wantAim=false self.wantRun=false
 if self.vm then self.vm:Destroy() self.vm=nil end
 if self.descendant then self.descendant:Disconnect() self.descendant=nil end
 for object,value in pairs(self.hidden) do if object.Parent then if object:IsA("BasePart") then object.LocalTransparencyModifier=value else object.Enabled=value end end end self.hidden={}
 if active==self then
  Run:UnbindFromRenderStep("VetorFPSPre") Run:UnbindFromRenderStep("VetorFPSPost")
  local camera=workspace.CurrentCamera if camera then camera.CFrame=camera.CFrame*self.lastKick:Inverse() camera.FieldOfView=self.oldFOV or C.FOV end self.lastKick=CFrame.new()
  Players.LocalPlayer.CameraMode=C.AlwaysFirstPerson and Enum.CameraMode.LockFirstPerson or self.oldMode or Enum.CameraMode.Classic Input.MouseDeltaSensitivity=self.oldSensitivity or 1 Input.MouseIconEnabled=self.oldIcon~=false Input.MouseBehavior=self.oldMouse or Enum.MouseBehavior.Default
  self.hud:SetVisible(false) active=nil
 end
end
function Controller:Equip()
 if active then active:Cleanup() end self:Cleanup() active=self
 self.token+=1 self.equipped=true self.at=now() self.lastFire=-1e5 self.pending={} self.sentAim=false self.sentRun=false
 local camera=workspace.CurrentCamera self.oldFOV=camera.FieldOfView self.oldMode=Players.LocalPlayer.CameraMode self.oldMouse=Input.MouseBehavior self.oldIcon=Input.MouseIconEnabled self.oldSensitivity=Input.MouseDeltaSensitivity or 1
 Players.LocalPlayer.CameraMode=Enum.CameraMode.LockFirstPerson Input.MouseIconEnabled=false
 self.vm=View.new(camera) self.hud:SetVisible(true)
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
 task.delay(C.UnequipTime,function() if self.token==token then self:Cleanup() end end)
end
function Controller:Reload()
 if not self.equipped or self.life==0 or self.reloading or now()<self.at+C.EquipTime or self:Ammo()>=C.Magazine or self.reserve<=0 then return end
 self.wantRun=false self.sentRun=false R.Action:FireServer("Run",false)
 self.reloadRequestedAt=now() self.reloading=true self.reloadEnd=now()+C.ReloadTime self.inspectEnd=0 R.Reload:FireServer(self.life)
end
function Controller:Inspect()
 if not self.equipped or self.reloading or now()<self.at+C.EquipTime then return end
 self.wantAim=false self.wantRun=false self.holding=false
 if self.inspectEnd>now() then self.inspectEnd=0 R.Action:FireServer("CancelInspect") else self.inspectEnd=now()+C.InspectTime R.Action:FireServer("Inspect") end
end
function Controller:Ammo() local count=0 for seq in pairs(self.pending) do if seq>self.ack then count+=1 end end return math.max(0,self.ammo-count) end
function Controller:Shoot()
 if not self.equipped or self.life==0 or self.reloading or not self.serverEquipped or now()<self.readyAt or now()<self.at+C.EquipTime or now()-self.lastFire<C.FireInterval then return end
 if self:Ammo()<=0 then self:Reload() return end
 self.lastFire=now() self.inspectEnd=0 self.seq+=1 self.pending[self.seq]=true self.vm:Fire()
 local camera=workspace.CurrentCamera local direction=camera.CFrame.LookVector
 R.Fire:FireServer(self.life,self.seq,camera.CFrame.Position,direction)
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={self.character,self.vm.model} params.IgnoreWater=true
 local hit=workspace:Raycast(camera.CFrame.Position,direction*C.Range,params)
 local muzzle=self.vm.gun.Handle.Muzzle.WorldPosition Effects.Shot(muzzle,hit and hit.Position or camera.CFrame.Position+direction*C.Range,hit and hit.Normal or nil)
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
 local t=now() local age=t-self.at local busy=self.reloading or age<C.EquipTime or not self.equipped
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
 if self.holding and not Input:GetFocusedTextBox() then self:Shoot() end
 local state=Anim.State(self.equipped,age,self.reloading,self.inspectEnd>t,running,aim,t-self.lastFire<.12,h.MoveDirection.Magnitude>.05)
 local phase=state=="Reloading" and t-(self.reloadEnd-C.ReloadTime) or state=="Inspecting" and t-(self.inspectEnd-C.InspectTime) or state=="Unequipping" and t-self.exitAt or age
 local root=char:FindFirstChild("HumanoidRootPart") local speed=root and h.MoveDirection.Magnitude>.05 and h.FloorMaterial~=Enum.Material.Air and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude or 0
 local camera=workspace.CurrentCamera local kick,alpha=self.vm:Step(dt,camera,{state=state,time=math.max(0,phase),speed=speed,running=running,aim=aim,grounded=h.FloorMaterial~=Enum.Material.Air},Input:GetMouseDelta())
 camera.CFrame=camera.CFrame*kick self.lastKick=kick self.vm.root.CFrame=camera.CFrame
 camera.FieldOfView=self.oldFOV+(C.ADSFOV-self.oldFOV)*alpha+(Players.LocalPlayer:GetAttribute("FPSRunFOV")==false and 0 or 4)*self.vm.run*(1-alpha)
 Input.MouseDeltaSensitivity=self.oldSensitivity*(1-.42*alpha)
 self.hud:Tick(alpha,dt,speed,running) self.hud:Update(self:Ammo(),self.reserve,state,self.reloading and math.clamp(phase/C.ReloadTime,0,1) or 0,phase)
end
function Controller.attach(tool)
 local self=setmetatable({tool=tool,token=0,connections={},hidden={},pending={},life=0,revision=0,seq=0,ack=0,ammo=C.Magazine,reserve=C.Reserve,reloading=false,reloadEnd=0,inspectEnd=0,readyAt=0,equipped=false,lastKick=CFrame.new()},Controller)
 self.hud=HUD.new({fire=function(v) if self.equipped then self.holding=v end end,aim=function() self.wantAim=not self.wantAim end,run=function() self.wantRun=not self.wantRun end,reload=function() self:Reload() end,inspect=function() self:Inspect() end})
 local function connect(signal,fn) table.insert(self.connections,signal:Connect(fn)) end
 connect(tool.Equipped,function() self:Equip() end) connect(tool.Unequipped,function() self:Unequip() end)
 connect(tool.Activated,function() if self.equipped then self.holding=true end end) connect(tool.Deactivated,function() self.holding=false end)
 connect(Input.InputBegan,function(i,processed)
  if not self.equipped or processed or Input:GetFocusedTextBox() or Players.LocalPlayer:GetAttribute("FPSMenuOpen")==true then return end
  if i.UserInputType==Enum.UserInputType.MouseButton1 then self.holding=true elseif i.UserInputType==Enum.UserInputType.MouseButton2 then self.wantAim=true
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
 end)
 connect(R.Hit.OnClientEvent,function(critical,amount,killed) if active==self then self.hud:Hit(critical,amount,killed) end end)
 connect(tool.Destroying,function() self:Cleanup() for _,c in ipairs(self.connections) do c:Disconnect() end self.hud:Destroy() end)
 R.Action:FireServer("Sync")
 return self
end
return Controller
]=] end
do local x=node(mods,'ModuleScript',"HUD") x.Source=[=[local Players=game:GetService("Players") local Input=game:GetService("UserInputService")
local C=require(script.Parent.WeaponConfig)
local H={} H.__index=H
function H.new(actions)
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
 local hint=label("Placar [TAB]   Objetivos [V]   Ajustes [M]",UDim2.new(.9,0,0,22),UDim2.new(.05,0,1,-30),11) hint.TextColor3=Color3.fromRGB(151,168,187) hint.Visible=not Input.TouchEnabled
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
 return setmetatable({gui=gui,root=root,ammo=ammo,status=status,debugLabel=debugLabel,ammoBase=compact and 36 or 52,reserveText=reserveText,damage=damage,kill=kill,speedLines=speedLines,sprintWeight=0,hit=hit,cross=cross,dot=dot,bloom=0,track=track,fill=fill,connections=connections},H)
end
function H:SetVisible(v) self.gui.Enabled=v end
function H:Update(ammo,reserve,state,progress,phase)
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
 for i=2,4 do
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
  slot.Active=tool~=nil selected.Visible=equipped==true border.Transparency=equipped and .15 or .7
  name.Text=tool and C.Name or "AGUARDANDO" caption.Text=equipped and "EQUIPADO" or "EQUIPAR"
  local h=humanoid() local value=h and math.max(0,h.Health) or 0 local max=h and math.max(1,h.MaxHealth) or 100
  hp.Text=tostring(math.ceil(value)) fill.Size=UDim2.fromScale(math.clamp(value/max,0,1),1)
  fill.BackgroundColor3=value<=max*.3 and Color3.fromRGB(255,112,100) or Color3.fromRGB(88,255,34)
 end
 local function toggle()
  local h=humanoid() local tool=rifle()
  if not h or h.Health<=0 or not tool then return end
  if tool.Parent==player.Character then h:UnequipTools() else h:EquipTool(tool) end
  task.defer(refresh)
 end
 connect(links,slot.Activated,toggle)
 connect(links,Input.InputBegan,function(i,processed)
  if not processed and not Input:GetFocusedTextBox() and (i.KeyCode==Enum.KeyCode.One or i.KeyCode==Enum.KeyCode.ButtonR1) then toggle() end
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
  local list=Players:GetPlayers()
  table.sort(list,function(a,b) local x,y=a:GetAttribute("FPSRoundKills") or 0,b:GetAttribute("FPSRoundKills") or 0 if x==y then return a.UserId<b.UserId end return x>y end)
  return list
 end
 local function refresh()
  if not alive then return end
  local left=math.max(0,math.ceil((system:GetAttribute("FPSRoundEnd") or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
  clock.Text=string.format("%d:%02d",math.floor(left/60),left%60)
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
 connect(system.Remotes:WaitForChild("MatchFeed").OnClientEvent,function(attacker,victim,critical)
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
  for _,p in ipairs(Players:GetPlayers()) do add(p,"FPSRounds",1) p:SetAttribute("FPSRoundKills",0) rewards(p) end
  system:SetAttribute("FPSRound",(system:GetAttribute("FPSRound") or 1)+1)
  system:SetAttribute("FPSRoundEnd",workspace:GetServerTimeNow()+duration)
 end)
end
function M.Equip(p) M.Init() p:SetAttribute("FPSHasEquipped",true) rewards(p) end
function M.Kill(p,model,critical)
 M.Init() add(p,"FPSKills",1) add(p,"FPSRoundKills",1) add(p,"FPSXP",10) rewards(p)
 local victim=Players:GetPlayerFromCharacter(model) if victim then add(victim,"FPSDeaths",1) end
 system.Remotes.MatchFeed:FireAllClients(p.DisplayName or p.Name,victim and (victim.DisplayName or victim.Name) or model.Name,critical==true)
end
return M
]=] end
do local x=node(mods,'ModuleScript',"Recoil") x.Source=[=[local Spring=require(script.Parent.Spring)
local R={} R.__index=R
function R.new() return setmetatable({spring=Spring.new(Vector3.zero,20),random=Random.new()},R) end
function R:Fire(ads) self.spring:Impulse(Vector3.new(ads and .32 or .65,self.random:NextNumber(-.12,.12)*(ads and .45 or 1),0)) end
function R:Step(dt) local v=self.spring:Step(dt) return Vector3.new(math.clamp(v.X,-.02,.045),math.clamp(v.Y,-.025,.025),0) end
return R
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
   local jump=r.h.FloorMaterial==Enum.Material.Air and not r.root.Anchored
   r.jumpWeight+=((jump and 1 or 0)-r.jumpWeight)*alpha
   r.aimWeight+=((held and held:GetAttribute("Aiming") and 1 or 0)-r.aimWeight)*alpha
   for name,j in pairs(r.j) do if j.Parent and not (held and (name=="Right Shoulder" or name=="Left Shoulder")) then
    local target=CFrame.new()
    if name=="Right Hip" then target=CFrame.Angles(jump and -.4 or stride,0,0) elseif name=="Left Hip" then target=CFrame.Angles(jump and .28 or -stride,0,0)
    elseif name=="Right Shoulder" then target=CFrame.Angles(-stride,0,.04) elseif name=="Left Shoulder" then target=CFrame.Angles(stride,0,-.04)
    elseif name=="RootJoint" then target=CFrame.new(0,math.sin(now*2)*.006+math.cos(r.phase*2)*.018*r.moveWeight*(1-r.jumpWeight),0)*CFrame.Angles(-.17*r.runWeight*r.moveWeight+.04*r.jumpWeight,0,math.sin(r.phase)*.015*r.moveWeight) end
    local basis=bases[j].Rotation apply(j,basis:Inverse()*target*basis,alpha)
   end end
   local tool=r.char:FindFirstChild("Rifle") local handle=tool and tool:FindFirstChild("Handle") local grip=handle and handle:FindFirstChild("WorldGrip")
   if handle and grip then
    local age=now-(tool:GetAttribute("EquippedAt") or now) local reloadEnd=tool:GetAttribute("ReloadEnd") or 0 local inspectEnd=tool:GetAttribute("InspectEnd") or 0 local running=tool:GetAttribute("Running")
    local state=Anim.State(true,age,reloadEnd>now,inspectEnd>now,running,tool:GetAttribute("Aiming"),now-(r.char:GetAttribute("FPSLastShotAt") or -1e5)<.12)
    local phase=state=="Reloading" and now-(reloadEnd-C.ReloadTime) or state=="Inspecting" and now-(inspectEnd-C.InspectTime) or age
    local pose,left,mag=Anim.Sample(state,math.max(0,phase))
    if state=="Equipping" then
     local blend=math.clamp(phase/C.EquipTime,0,1) blend=blend*blend*(3-2*blend)
     pose=(CFrame.new(0,-.25,.15)*CFrame.Angles(-.12,0,.06)):Lerp(CFrame.new(),blend)
    end
    pose=Anim.WorldSample(now,r.phase,r.moveWeight,r.runWeight,r.jumpWeight,r.aimWeight)*pose
    local since=now-(r.char:GetAttribute("FPSLastShotAt") or -1e5) if since>=0 and since<.15 then pose=pose*CFrame.new(0,0,.08*math.exp(-since*25))*CFrame.Angles(.035*math.exp(-since*25),0,0) end
    r.pose=r.pose:Lerp(pose,alpha) r.magPose=r.magPose:Lerp(mag,alpha) if r.grip~=grip then r.grip=grip r.configureGrip=true end
    -- Pivot elevation around the stock, rather than swinging the gun through the torso.
    local stock=CFrame.new(0,.1066,.9512)
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
     if state=="Reloading" then target=support.CFrame:Lerp(handle.MagazinePivot.CFrame*r.magPose*CFrame.new(-.25,0,0),Anim.ReloadHandWeight(phase)) end
     arm(r.j["Left Shoulder"],r.torso,(gunCF*target).Position,dt)
    end
    local magazine=handle:FindFirstChild("MagazineMotor") if magazine then if r.magazine~=magazine then r.magazine=magazine r.magBase=magazine.C0 end magazine.Transform=CFrame.new() magazine.C0=r.magBase*r.magPose end
    local targetAlpha=state=="Reloading" and Anim.MagazineAlpha(phase) or 0 r.magAlpha+=(targetAlpha-r.magAlpha)*alpha
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
local C=require(script.Parent.WeaponConfig)
local V={} V.__index=V
function V.new(camera)
 local model=Instance.new("Model") model.Name="R6ViewModel"
 local root=Instance.new("Part") root.Name="CameraRoot" root.Size=Vector3.new(.1,.1,.1) root.CFrame=CFrame.new() root.Transparency=1 root.Anchored=true root.CanCollide=false root.CanQuery=false root.CanTouch=false root.Parent=model model.PrimaryPart=root
 local gun=Factory.Build(model) local handle=gun.Handle for _,p in ipairs(gun:GetDescendants()) do if p:IsA("BasePart") then p.CastShadow=false end end
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
 return setmetatable({model=model,root=root,gun=gun,joint=joint,right=right,left=left,leftBase=left.C0,leftRotation=CFrame.Angles(2.15,0,.25),mag=handle.MagazineMotor,magBase=handle.MagazineMotor.C0,magAlpha=0,magParts=magParts,recoil=Recoil.new(),sway=Spring.new(Vector3.zero,14),aim=0,run=0,move=0,jump=0,grounded=true,landing=Spring.new(Vector3.zero,18),phase=0,pose=CFrame.new(),leftPose=CFrame.new(),magPose=CFrame.new()},V)
end
function V:Fire() self.recoil:Fire(self.aim>.5) end
function V:Step(dt,camera,info,mouse)
 local smoothing=1-math.exp(-dt*16)
 self.aim+=((info.aim and 1 or 0)-self.aim)*(1-math.exp(-dt/C.ADSTime*4)) self.run+=((info.running and 1 or 0)-self.run)*smoothing
 local gunPose,leftPose,magPose=Anim.Sample(info.state,info.time)
 if info.state=="Running" then gunPose=CFrame.new(.12,-.22,.12)*CFrame.Angles(-.2,.15,.15) end
 self.pose=self.pose:Lerp(gunPose,smoothing) self.leftPose=self.leftPose:Lerp(leftPose,smoothing) self.magPose=self.magPose:Lerp(magPose,smoothing)
 local targetAlpha=info.state=="Reloading" and Anim.MagazineAlpha(info.time) or 0 self.magAlpha+=(targetAlpha-self.magAlpha)*smoothing for _,p in ipairs(self.magParts) do if p.Parent then p.Transparency=self.magAlpha end end
 self.mag.C0=self.magBase*self.magPose
 local leftTarget=self.leftBase
 if info.state=="Reloading" then
  local hand=self.gun.Handle.LeftGrip.CFrame:Lerp(self.magBase*self.magPose*CFrame.new(-.25,0,0),Anim.ReloadHandWeight(info.time))
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
 local gait=CFrame.Angles(.012*self.run*math.cos(self.phase*2)+.025*self.jump,0,.018*self.run*math.sin(self.phase))
 self.joint.C0=offset*CFrame.new(bob+breath+land+jump)*CFrame.Angles(sway.X,sway.Y,0)*gait*self.pose*visualKick
 return CFrame.Angles(kick.X,kick.Y,0),self.aim
end
function V:Destroy() if self.model then self.model:Destroy() end end
return V
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
local F={}
local dark=Color3.fromRGB(35,47,65) local blue=Color3.fromRGB(47,139,171) local pale=Color3.fromRGB(182,203,214) local gold=Color3.fromRGB(255,197,80)
function F.Build(parent,scale)
 scale=scale or 1
 local m=Instance.new("Model") m.Name="RifleModel"
 local root=Instance.new("Part") root.Name="Handle" root.Size=Vector3.new(.25,.25,.25) root.CFrame=CFrame.new() root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Massless=true root.Parent=m m.PrimaryPart=root
 local magazine
 for _,d in ipairs(require(script.Parent.WeaponGeometry)) do
  local p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part") p.Name=d.name
  p.Size=Vector3.new(d.size[1],d.size[2],d.size[3])*scale
  p.CFrame=CFrame.new(Vector3.new(d.pos[1],d.pos[2],d.pos[3])*scale)*CFrame.Angles(math.rad(d.rot[1]),math.rad(d.rot[2]),math.rad(d.rot[3]))
  if d.shape=="Tube" then p.Shape=Enum.PartType.Cylinder p.Size=Vector3.new(d.size[3],d.size[1],d.size[2])*scale p.CFrame=p.CFrame*CFrame.Angles(0,math.pi/2,0) end
  p.Color=Color3.fromRGB(d.color[1],d.color[2],d.color[3]) p.Material=d.name=="Ponto reflex" and Enum.Material.Neon or Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.Reflectance=0 p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Parent=m
  if d.name=="Magazine" then
   magazine=p p:SetAttribute("MagazinePart",true)
   local motor=Instance.new("Motor6D") motor.Name="MagazineMotor" motor.Part0=root motor.Part1=p motor.C0=p.CFrame motor.Parent=root
  else
   local parentPart=d.group=="Mag" and magazine or root
   if d.group=="Mag" then p:SetAttribute("MagazinePart",true) end
   local w=Instance.new("Weld") w.Part0=parentPart w.Part1=p w.C0=parentPart.CFrame:Inverse()*p.CFrame w.Parent=p
  end
 end
 local function point(name,pos) local a=Instance.new("Attachment") a.Name=name a.CFrame=CFrame.new(pos*scale) a.Parent=root return a end
 point("WorldLeftGrip",Vector3.new(-.58,-.08,-.24))
 point("AimPoint",Vector3.new(0,1.04,.55)) point("Muzzle",Vector3.new(0,.29,-3.38)) point("LeftGrip",Vector3.new(-.3,-.08,-.95)) point("RightGripPoint",Vector3.new(.05,-.3,.12)) point("MagazinePivot",Vector3.new(0,-.46,-.65))
 m.Parent=parent return m
end
function F.Mount(tool)
 if tool:GetAttribute("FactoryRuntimeBuilt") then return end
 for _,old in ipairs(tool:GetChildren()) do if old:IsA("BasePart") or old:IsA("Model") then old:Destroy() end end
 tool:SetAttribute("FactoryRuntimeBuilt",true)
 local model=F.Build(nil,.82) for _,p in ipairs(model:GetChildren()) do p.Parent=tool end model:Destroy()
end
return F
]=] end
do local x=node(mods,'ModuleScript',"WeaponGeometry") x.Source=[=[-- Exportado da modelagem original no Blender.
return {{["name"]="Receiver",["size"]={0.57,0.46,1.9},["pos"]={0,0.25,-0.65},["color"]={48,104,135},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Upper receiver",["size"]={0.62,0.14,1.45},["pos"]={0,0.55,-0.55},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer frente",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,-1.55},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer traseiro",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,0.28},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body"},{["name"]="Handguard",["size"]={0.49,0.4,0.9},["pos"]={0,0.24,-1.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cano virtual",["size"]={0.16,0.16,0.8},["pos"]={0,0.29,-2.78},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Emissor",["size"]={0.29,0.29,0.28},["pos"]={0,0.29,-3.22},["color"]={24,30,39},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Anel frontal",["size"]={0.34,0.34,0.07},["pos"]={0,0.29,-3.12},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Trilho",["size"]={0.29,0.07,1.7},["pos"]={0,0.66,-0.7},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,0.05},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={-0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={-0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={-0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Coronha",["size"]={0.38,0.34,0.65},["pos"]={0,0.2,0.77},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Haste da coronha",["size"]={0.24,0.19,0.4},["pos"]={0,0.32,0.33},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ombreira",["size"]={0.44,0.57,0.12},["pos"]={0,0.13,1.16},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,-0.04,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.08,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.2,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.32,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cabo",["size"]={0.33,0.58,0.36},["pos"]={0,-0.34,0.12},["color"]={48,55,62},["shape"]="Block",["rot"]={-10,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.5,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.38,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.26,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda inferior",["size"]={0.34,0.055,0.43},["pos"]={0,-0.25,-0.22},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda frontal",["size"]={0.34,0.2,0.055},["pos"]={0,-0.13,-0.42},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Magazine",["size"]={0.39,0.63,0.53},["pos"]={0,-0.46,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Base magazine",["size"]={0.44,0.08,0.56},["pos"]={0,-0.8,-0.65},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Mira traseira",["size"]={0.37,0.09,0.22},["pos"]={0,0.71,0.15},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={-0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira frontal",["size"]={0.06,0.16,0.1},["pos"]={0,0.79,-1.7},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Suporte da mira",["size"]={0.18,0.25,0.24},["pos"]={0,0.56,-1.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Moldura frontal",["size"]={0.25,0.07,0.2},["pos"]={0,0.7,-1.7},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Base reflex",["size"]={0.46,0.09,0.5},["pos"]={0,0.785,-0.25},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Arco reflex",["size"]={0.065,0.44,0.095},["pos"]={-0.235,1.04,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Arco reflex",["size"]={0.065,0.44,0.095},["pos"]={0.235,1.04,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Topo reflex",["size"]={0.53,0.065,0.095},["pos"]={0,1.26,-0.25},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ponto reflex",["size"]={0.018,0.018,0.018},["pos"]={0,1.04,-0.25},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ajuste reflex",["size"]={0.1,0.13,0.17},["pos"]={0.3,0.85,-0.25},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"}}
]=] end
do local x=node(mods,'ModuleScript',"WeaponState") x.Source=[=[local C=require(script.Parent.WeaponConfig)
local S={}
function S.New(life) return {life=life,ammo=C.Magazine,reserve=C.Reserve,equipped=false,reloading=false,reloadEnd=0,inspectEnd=0,running=false,aiming=false,pitch=0,readyAt=0,lastShot=-1e6,lastSeq=0,generation=0,revision=0} end
function S.Equip(s,value,now)
 s.generation+=1 s.equipped=value s.reloading=false s.reloadEnd=0 s.inspectEnd=0 s.running=false s.aiming=false s.readyAt=now+(value and C.EquipTime or 0)
end
function S.Acknowledge(s,seq)
 if type(seq)~="number" or seq%1~=0 or seq<=s.lastSeq or seq>s.lastSeq+1000 then return false end s.lastSeq=seq return true
end
function S.Fire(s,seq,now)
 if not S.Acknowledge(s,seq) then return false,"Sequence" end
 if not s.equipped or now<s.readyAt then return false,"Equip" end
 if s.reloading or s.running then return false,"Busy" end
 if now-s.lastShot<C.FireInterval-.002 then return false,"Cadence" end
 if s.ammo<=0 then return false,"Empty" end
 s.inspectEnd=0 s.lastShot=now s.ammo-=1 return true
end
function S.Reload(s,now)
 if not s.equipped or now<s.readyAt or s.reloading or s.running or s.ammo>=C.Magazine or s.reserve<=0 then return false end
 s.generation+=1 s.reloading=true s.reloadEnd=now+C.ReloadTime s.inspectEnd=0 s.aiming=false return true,s.generation
end
function S.FinishReload(s,token,now)
 if token~=s.generation or not s.reloading or not s.equipped or now+.001<s.reloadEnd then return false end
 local count=math.min(C.Magazine-s.ammo,s.reserve) s.ammo+=count s.reserve-=count s.reloading=false s.reloadEnd=0 return true
end
return S
]=] end
local rifle=node(Pack,'Tool','Rifle') rifle.RequiresHandle=true rifle.CanBeDropped=false require(mods.WeaponFactory).Mount(rifle)
do local x=node(rifle,'LocalScript','Controller') x.Source=[=[local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
require(system.Modules.ClientController).attach(script.Parent)
]=] end
do local x=node(SP,'LocalScript','FPSObserver') x.Source=[=[local system=game:GetService("ReplicatedStorage"):WaitForChild("FPSSystem")
local modules=system:WaitForChild("Modules")
local cleanup=require(modules:WaitForChild("LoadoutController")).init()
local matchCleanup=require(modules:WaitForChild("MatchHUD")).init()
script.Destroying:Connect(function() cleanup() matchCleanup() end)
system:WaitForChild("Remotes"):WaitForChild("WeaponFX")
require(modules:WaitForChild("ThirdPersonController")).init(false)
]=] end
do local x=Instance.new('Script') x.Name="GunServer" x.Source=[=[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Physics=game:GetService("PhysicsService")
pcall(function() Physics:RegisterCollisionGroup("FPSViewModel") end)
for _,g in ipairs(Physics:GetRegisteredCollisionGroups()) do Physics:CollisionGroupSetCollidable("FPSViewModel",g.name,false) end
local System=RS:WaitForChild("FPSSystem") local Modules=System.Modules
local C=require(Modules.WeaponConfig) local Logic=require(Modules.WeaponState) local Factory=require(Modules.WeaponFactory)
local Anim=require(Modules.AnimationController) local Match=require(Modules.MatchState)
local Remotes=System:WaitForChild("Remotes")
local states={} local lives={} local windows={}
local function now() return workspace:GetServerTimeNow() end
local function rate(p,key,limit)
 local t=now() local buckets=windows[p] or {} windows[p]=buckets local b=buckets[key] or {t=t,n=0} buckets[key]=b
 if t-b.t>=1 then b.t=t b.n=0 end b.n+=1 return b.n<=limit
end
local function snapshot(p,s,reason)
 if not p.Parent or states[p]~=s then return end s.revision+=1
 if s.tool and s.tool.Parent then for k,v in pairs({ReloadEnd=s.reloadEnd,InspectEnd=s.inspectEnd,Running=s.running,Aiming=s.aiming,AimPitch=s.pitch,EquippedAt=s.readyAt-C.EquipTime}) do s.tool:SetAttribute(k,v) end end
 Remotes.State:FireClient(p,{life=s.life,revision=s.revision,ammo=s.ammo,reserve=s.reserve,ack=s.lastSeq,reloading=s.reloading,reloadEnd=s.reloadEnd,readyAt=s.readyAt,equipped=s.equipped,inspectEnd=s.inspectEnd,reason=reason})
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
 if not healthy(p,s) then reject("Equip") return end
 if not finite(origin) or not finite(direction) or direction.Magnitude<.5 or direction.Magnitude>1.5 then reject("Intent") return end
 local head=p.Character:FindFirstChild("Head") if not head or (origin-head.Position).Magnitude>5 then reject("Origin") return end
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={p.Character} params.IgnoreWater=true
 if (origin-head.Position).Magnitude>.1 and workspace:Raycast(head.Position,origin-head.Position,params) then reject("OriginBlocked") return end
 local ok,reason=Logic.Fire(s,seq,now()) if not ok then snapshot(p,s,reason) return end
 local dir=direction.Unit local hit=workspace:Raycast(head.Position,dir*C.Range,params) local target=hit and hit.Position or head.Position+dir*C.Range
 local muzzle=s.tool.Handle:FindFirstChild("Muzzle") local joint=s.tool.Handle:FindFirstChild("WorldGrip") local torso=p.Character:FindFirstChild("Torso")
 local gunCF
 if torso and joint then
  local shoulder=torso:FindFirstChild("Right Shoulder")
  if shoulder and joint.Part0==shoulder.Part1 then
   gunCF=torso.CFrame*shoulder.C0*shoulder.C1:Inverse()*joint.C0*(joint.C1 or CFrame.new()):Inverse()
  else gunCF=torso.CFrame*joint.C0 end
 end
 local start=gunCF and muzzle and (gunCF*muzzle.CFrame).Position or head.Position
 if (start-head.Position).Magnitude>6 or workspace:Raycast(head.Position,start-head.Position,params) then start=head.Position end
 if hit then
  local model=hit.Instance:FindFirstAncestorOfClass("Model") local humanoid=model and model:FindFirstChildOfClass("Humanoid")
  local victim=model and Players:GetPlayerFromCharacter(model)
  local friendly=victim and not p.Neutral and not victim.Neutral and p.Team==victim.Team
  if humanoid and humanoid.Health>0 and model~=p.Character and not friendly and not model:FindFirstChildOfClass("ForceField") then
   local critical=hit.Instance.Name=="Head" local before=humanoid.Health humanoid:TakeDamage(C.Damage*(critical and C.Critical or 1))
   if humanoid.Health<before then Remotes.Hit:FireClient(p,critical,before-humanoid.Health,humanoid.Health<=0) if humanoid.Health<=0 then Match.Kill(p,model,critical) end end
  end
 end
 p.Character:SetAttribute("FPSLastShotAt",now())
 Remotes.WeaponFX:FireAllClients(p.UserId,start,target,hit and hit.Normal or nil)
 snapshot(p,s)
end)
Remotes.Reload.OnServerEvent:Connect(function(p,life)
 if not rate(p,"reload",6) then return end local s=states[p]
 if not s or life~=s.life or not healthy(p,s) then return end
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
 if not healthy(p,s) or s.reloading or now()<s.readyAt then return end
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
 lives[p]=(lives[p] or 0)+1 local s=Logic.New(lives[p]) s.connections={} states[p]=s
 local function connect(signal,fn) local c=signal:Connect(fn) table.insert(s.connections,c) end
 local backpack=p:WaitForChild("Backpack",10) if not backpack or p.Character~=char or states[p]~=s then return end
 for _,parent in ipairs({backpack,char}) do for _,t in ipairs(parent:GetChildren()) do if t:IsA("Tool") and t.Name=="Rifle" then t:Destroy() end end end
 local tool=game:GetService("StarterPack"):WaitForChild("Rifle"):Clone() Factory.Mount(tool) s.tool=tool tool.CanBeDropped=false
 local function cancel()
  Logic.Equip(s,false,now()) local grip=tool.Handle:FindFirstChild("WorldGrip") if grip then grip:Destroy() end
  if h.Parent then h.WalkSpeed=C.WalkSpeed end snapshot(p,s)
 end
 connect(tool.Equipped,function()
  if states[p]~=s or p.Character~=char or tool.Parent~=char or h.Health<=0 then return end
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
 local function rejectDuplicate(t) if t:IsA("Tool") and t.Name=="Rifle" and t~=tool then task.defer(function() if t.Parent then t:Destroy() end end) end end
 connect(backpack.ChildAdded,rejectDuplicate) connect(char.ChildAdded,rejectDuplicate)
 local shield=Instance.new("ForceField") shield.Parent=char game:GetService("Debris"):AddItem(shield,3)
end
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
local Avatar=require(System.Modules.AvatarAppearance)
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
 model.PrimaryPart=root h.DisplayName=p.DisplayName h.WalkSpeed=C.WalkSpeed h.UseJumpPower=true h.JumpPower=50
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("BasePart") then v.CollisionGroup="Characters" end end
 model:PivotTo(CFrame.new(C.LOBBY.ORIGIN+Vector3.new(0,5,-5))) model.Parent=workspace p.Character=model
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
print('FPS R6 instalado. Use Play e equipe Rifle. Nenhum mapa, economia ou matchmaking foi instalado.')