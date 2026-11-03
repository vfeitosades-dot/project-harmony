-- INSTALADOR FPS R6. Execute na Command Bar do Studio fora do Play.
local USE_CUSTOM_R6 = true -- false se a experiencia ja cria seus proprios personagens R6.
assert(not game:GetService('RunService'):IsRunning(),'Pare o Play antes de instalar.')
local RS=game:GetService('ReplicatedStorage') local SS=game:GetService('ServerScriptService') local SP=game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts') local Pack=game:GetService('StarterPack')
assert(not RS:FindFirstChild('FPSSystem') and not SS:FindFirstChild('GunServer') and not Pack:FindFirstChild('Rifle') and not SP:FindFirstChild('FPSObserver'),'Ja existe um sistema com esses nomes; nada foi sobrescrito.')
local function node(parent,kind,name) local x=Instance.new(kind) x.Name=name x.Parent=parent return x end
local sys=node(RS,'Folder','FPSSystem') local mods=node(sys,'Folder','Modules') local rem=node(sys,'Folder','Remotes') local assets=node(sys,'Folder','Assets')
for _,name in ipairs({'Fire','Reload','WeaponFX','State','Action','Hit'}) do node(rem,'RemoteEvent',name) end
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
  Players.LocalPlayer.CameraMode=self.oldMode or Enum.CameraMode.Classic Input.MouseIconEnabled=self.oldIcon~=false Input.MouseBehavior=self.oldMouse or Enum.MouseBehavior.Default
  self.hud:SetVisible(false) active=nil
 end
end
function Controller:Equip()
 if active then active:Cleanup() end self:Cleanup() active=self
 self.token+=1 self.equipped=true self.at=now() self.lastFire=-1e5 self.pending={} self.sentAim=false self.sentRun=false
 local camera=workspace.CurrentCamera self.oldFOV=camera.FieldOfView self.oldMode=Players.LocalPlayer.CameraMode self.oldMouse=Input.MouseBehavior self.oldIcon=Input.MouseIconEnabled
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
 local muzzle=self.vm.gun.Handle.Muzzle.WorldPosition Effects.Shot(muzzle,hit and hit.Position or camera.CFrame.Position+direction*C.Range)
end
function Controller:Step(dt)
 if active~=self or not self.vm then return end
 local char=Players.LocalPlayer.Character local h=char and char:FindFirstChildOfClass("Humanoid")
 if char~=self.character or not h or h.Health<=0 then self:Cleanup() return end
 if Input:GetFocusedTextBox() then self.holding=false self.wantAim=false self.wantRun=false end
 if self.equipped and not Input.TouchEnabled and not Input:GetFocusedTextBox() then
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
 local camera=workspace.CurrentCamera local kick,alpha=self.vm:Step(dt,camera,{state=state,time=math.max(0,phase),speed=speed,running=running,aim=aim},Input:GetMouseDelta())
 camera.CFrame=camera.CFrame*kick self.lastKick=kick self.vm.root.CFrame=camera.CFrame
 camera.FieldOfView=self.oldFOV+(C.ADSFOV-self.oldFOV)*alpha
 self.hud:Tick(alpha) self.hud:Update(self:Ammo(),self.reserve,state,self.reloading and math.clamp(phase/C.ReloadTime,0,1) or 0,phase)
end
function Controller.attach(tool)
 local self=setmetatable({tool=tool,token=0,connections={},hidden={},pending={},life=0,revision=0,seq=0,ack=0,ammo=C.Magazine,reserve=C.Reserve,reloading=false,reloadEnd=0,inspectEnd=0,readyAt=0,equipped=false,lastKick=CFrame.new()},Controller)
 self.hud=HUD.new({fire=function(v) if self.equipped then self.holding=v end end,aim=function() self.wantAim=not self.wantAim end,run=function() self.wantRun=not self.wantRun end,reload=function() self:Reload() end,inspect=function() self:Inspect() end})
 local function connect(signal,fn) table.insert(self.connections,signal:Connect(fn)) end
 connect(tool.Equipped,function() self:Equip() end) connect(tool.Unequipped,function() self:Unequip() end)
 connect(tool.Activated,function() if self.equipped then self.holding=true end end) connect(tool.Deactivated,function() self.holding=false end)
 connect(Input.InputBegan,function(i,processed)
  if not self.equipped or processed or Input:GetFocusedTextBox() then return end
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
 connect(R.Hit.OnClientEvent,function(critical) if active==self then self.hud:Hit(critical) end end)
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
 local pg=Players.LocalPlayer:WaitForChild("PlayerGui") local gui=pg:FindFirstChild("GunHUD") or Instance.new("ScreenGui") gui.Name="GunHUD" gui.ResetOnSpawn=false gui.DisplayOrder=20 gui.IgnoreGuiInset=false gui.Enabled=false gui.Parent=pg
 local old=gui:FindFirstChild("Root") if old then old:Destroy() end
 local root=Instance.new("Frame") root.Name="Root" root.Size=UDim2.fromScale(1,1) root.BackgroundTransparency=1 root.Parent=gui
 local function label(text,size,pos,fs)
  local t=Instance.new("TextLabel") t.Text=text t.Size=size t.Position=pos t.BackgroundTransparency=1 t.TextColor3=Color3.fromRGB(235,242,248) t.Font=Enum.Font.GothamMedium t.TextSize=fs t.Parent=root return t
 end
 local ammo=label(C.Magazine.." / "..C.Reserve,UDim2.fromOffset(210,44),UDim2.new(1,-230,1,-92),26) ammo.TextXAlignment=Enum.TextXAlignment.Right
 local weapon=label(C.Name,UDim2.fromOffset(210,24),UDim2.new(1,-230,1,-116),12) weapon.TextXAlignment=Enum.TextXAlignment.Right weapon.TextColor3=Color3.fromRGB(130,161,180)
 local debugLabel=label("",UDim2.fromOffset(240,24),UDim2.fromOffset(12,12),12) debugLabel.Visible=C.DebugHUD
 local status=label("",UDim2.new(.8,0,0,24),UDim2.new(.1,0,.6,0),13)
 local hint=label("R  recarregar    H  inspecionar    Shift  correr",UDim2.new(.9,0,0,22),UDim2.new(.05,0,1,-30),11) hint.TextColor3=Color3.fromRGB(151,168,187) hint.Visible=not Input.TouchEnabled
 local cross={}
 for _,v in ipairs({{-7,0,4,1},{4,0,4,1},{0,-7,1,4},{0,4,1,4}}) do local f=Instance.new("Frame") f.Size=UDim2.fromOffset(v[3],v[4]) f.Position=UDim2.new(.5,v[1],.5,v[2]) f.BackgroundColor3=Color3.fromRGB(225,240,248) f.BorderSizePixel=0 f.Parent=root table.insert(cross,f) end
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
 return setmetatable({gui=gui,root=root,ammo=ammo,status=status,debugLabel=debugLabel,hit=hit,cross=cross,track=track,fill=fill,connections=connections},H)
end
function H:SetVisible(v) self.gui.Enabled=v end
function H:Update(ammo,reserve,state,progress,phase)
 if C.DebugHUD then self.debugLabel.Text=string.format("%s · %.2fs",state,phase or 0) end
 self.ammo.Text=string.format("%02d / %02d",math.max(0,ammo),reserve)
 self.ammo.TextColor3=ammo<=5 and Color3.fromRGB(255,151,133) or Color3.fromRGB(235,242,248)
 self.status.Text=state=="Reloading" and "Recarregando" or state=="Equipping" and "Equipando" or state=="Inspecting" and "Inspecionando" or ""
 self.track.Visible=state=="Reloading" self.fill.Size=UDim2.fromScale(math.clamp(progress or 0,0,1),1)
end
function H:Hit(critical)
 self.hitAt=os.clock()+.15 self.hit.Visible=true self.hit.TextColor3=critical and Color3.fromRGB(255,192,91) or Color3.fromRGB(235,242,248)
end
function H:Tick(aim) if (self.hitAt or 0)<os.clock() then self.hit.Visible=false end for _,f in ipairs(self.cross) do f.Visible=aim<.9 end end
function H:Destroy() for _,c in ipairs(self.connections) do c:Disconnect() end if self.root.Parent then self.root:Destroy() end end
return H
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
local T={} local rigs={} local shotAt={}
local function bind(p,char)
 local torso=char:WaitForChild("Torso",8) local h=char:FindFirstChildOfClass("Humanoid") local root=char:FindFirstChild("HumanoidRootPart") if not torso or not h or not root then return end
 if p:IsA("Player") and p.Character~=char then return end
 local j={} for _,v in ipairs(char:GetDescendants()) do if v:IsA("Motor6D") and v.Name~="WorldGrip" and v.Name~="MagazineMotor" then j[v.Name]=v end end
 rigs[p]={char=char,torso=torso,h=h,root=root,j=j,pose=CFrame.new(),magPose=CFrame.new(),phase=0,moveWeight=0,runWeight=0,magAlpha=0}
end
local function arm(joint,torso,target,dt)
 if not joint or not joint.Parent then return end
 local shoulder=(torso.CFrame*joint.C0).Position local delta=target-shoulder if delta.Magnitude<.05 then return end
 local rotation=CFrame.lookAt(Vector3.zero,delta.Unit)*CFrame.Angles(math.pi/2,0,0)
 local desired=CFrame.new(target-delta.Unit)*rotation.Rotation
 local transform=joint.C0:Inverse()*torso.CFrame:ToObjectSpace(desired)*joint.C1
 joint.Transform=joint.Transform:Lerp(transform,1-math.exp(-dt*18))
end
function T.init()
 local function add(p) p.CharacterAdded:Connect(function(char) task.spawn(bind,p,char) end) if p.Character then task.spawn(bind,p,p.Character) end end
 Players.PlayerAdded:Connect(add) Players.PlayerRemoving:Connect(function(p) rigs[p]=nil shotAt[p]=nil end) for _,p in ipairs(Players:GetPlayers()) do add(p) end
 for _,bot in ipairs(CS:GetTagged("FPSDemoBot")) do task.spawn(bind,bot,bot) end
 CS:GetInstanceAddedSignal("FPSDemoBot"):Connect(function(bot) task.spawn(bind,bot,bot) end)
 CS:GetInstanceRemovedSignal("FPSDemoBot"):Connect(function(bot) rigs[bot]=nil end)
 RS.FPSSystem.Remotes.WeaponFX.OnClientEvent:Connect(function(id,a,b)
  local p=Players:GetPlayerByUserId(id) if p then shotAt[p]=workspace:GetServerTimeNow() end
  if id~=Players.LocalPlayer.UserId then Effects.Shot(a,b) end
 end)
 Run.PreSimulation:Connect(function(dt)
  local now=workspace:GetServerTimeNow() local alpha=1-math.exp(-dt*16)
  for p,r in pairs(rigs) do
   if not r.char.Parent then rigs[p]=nil continue end
   local speed=Vector3.new(r.root.AssemblyLinearVelocity.X,0,r.root.AssemblyLinearVelocity.Z).Magnitude
   if p==Players.LocalPlayer and r.h.MoveDirection.Magnitude<.05 then speed=0 end
   local held=r.char:FindFirstChild("Rifle") local sprint=held and held:GetAttribute("Running")==true
   r.moveWeight+=(math.clamp(speed/C.WalkSpeed,0,1)-r.moveWeight)*alpha
   r.runWeight+=((sprint and 1 or 0)-r.runWeight)*alpha
   r.phase+=dt*(7.5+3.5*r.runWeight)*math.clamp(speed/C.WalkSpeed,0,1.5)
   local stride=math.sin(r.phase)*(.5+.4*r.runWeight)*r.moveWeight
   local jump=r.h.FloorMaterial==Enum.Material.Air and not r.root.Anchored
   for name,j in pairs(r.j) do if j.Parent then
    local target=CFrame.new()
    if name=="Right Hip" then target=CFrame.Angles(jump and -.25 or stride,0,0) elseif name=="Left Hip" then target=CFrame.Angles(jump and .25 or -stride,0,0)
    elseif name=="Right Shoulder" then target=CFrame.Angles(-stride,0,.04) elseif name=="Left Shoulder" then target=CFrame.Angles(stride,0,-.04)
    elseif name=="RootJoint" then target=CFrame.new(0,math.sin(now*2)*.012,0)*CFrame.Angles(-.12*r.runWeight*r.moveWeight,0,0) end
    local basis=j.C0.Rotation j.Transform=j.Transform:Lerp(basis:Inverse()*target*basis,alpha)
   end end
   local tool=r.char:FindFirstChild("Rifle") local handle=tool and tool:FindFirstChild("Handle") local grip=handle and handle:FindFirstChild("WorldGrip")
   if handle and grip then
    local age=now-(tool:GetAttribute("EquippedAt") or now) local reloadEnd=tool:GetAttribute("ReloadEnd") or 0 local inspectEnd=tool:GetAttribute("InspectEnd") or 0 local running=tool:GetAttribute("Running")
    local state=Anim.State(true,age,reloadEnd>now,inspectEnd>now,running,tool:GetAttribute("Aiming"),now-(shotAt[p] or -1e5)<.12)
    local phase=state=="Reloading" and now-(reloadEnd-C.ReloadTime) or state=="Inspecting" and now-(inspectEnd-C.InspectTime) or age
    local pose,left,mag=Anim.Sample(state,math.max(0,phase))
    if state=="Running" then pose=CFrame.new(.1,-.2,.1)*CFrame.Angles(-.25,.15,.15) end
    if tool:GetAttribute("Aiming") then pose=CFrame.new(0,.65,.05)*pose end
    local since=now-(shotAt[p] or -1e5) if since>=0 and since<.15 then pose=pose*CFrame.new(0,0,.08*math.exp(-since*25))*CFrame.Angles(.035*math.exp(-since*25),0,0) end
    r.pose=r.pose:Lerp(CFrame.Angles(tool:GetAttribute("AimPitch") or 0,0,0)*pose,alpha) r.magPose=r.magPose:Lerp(mag,alpha) grip.Transform=r.pose
    local neck=r.j.Neck
    if neck and neck.Parent then local basis=neck.C0.Rotation local target=CFrame.Angles((tool:GetAttribute("AimPitch") or 0)*.4,0,0) neck.Transform=neck.Transform:Lerp(basis:Inverse()*target*basis,alpha) end
    local gunCF=r.torso.CFrame*grip.C0*r.pose
    local right=handle:FindFirstChild("RightGripPoint") local support=handle:FindFirstChild("LeftGrip")
    if right then arm(r.j["Right Shoulder"],r.torso,(gunCF*right.CFrame).Position,dt) end
    if support then
     local target=support.CFrame*left
     if state=="Reloading" then target=support.CFrame:Lerp(handle.MagazinePivot.CFrame*r.magPose*CFrame.new(-.25,0,0),Anim.ReloadHandWeight(phase)) end
     arm(r.j["Left Shoulder"],r.torso,(gunCF*target).Position,dt)
    end
    local magazine=handle:FindFirstChild("MagazineMotor") if magazine then magazine.Transform=r.magPose end
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
  local p=original and original:Clone() or Instance.new("Part")
  for _,v in ipairs(p:GetDescendants()) do if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end end
  p.Name=name p.Size=Vector3.new(.8,1.8,.8)
  if not original then p.Color=Color3.fromRGB(211,180,153) end
  p.Anchored=false p.Material=Enum.Material.SmoothPlastic p.CanCollide=false p.CanQuery=false p.CanTouch=false p.Massless=true p.CastShadow=false p.LocalTransparencyModifier=0 p.Parent=model
  local rot=CFrame.Angles(angle,0,name=="Left Arm" and .12 or -.12)
  local motor=Instance.new("Motor6D") motor.Name=name.."Joint" motor.Part0=handle motor.Part1=p motor.C0=point.CFrame*rot*CFrame.new(0,.9,0) motor.Parent=handle p.CFrame=motor.C0
  return motor
 end
 local right=arm("Right Arm",handle.RightGripPoint,1.1) local left=arm("Left Arm",handle.LeftGrip,1.15)
 local player=game:GetService("Players").LocalPlayer local character=player and player.Character
 local torso=Instance.new("Part") torso.Name="Torso" torso.Size=Vector3.new(2,2,1) torso.Transparency=1 torso.CanCollide=false torso.CanTouch=false torso.CanQuery=false torso.Massless=true torso.Parent=model
 local w=Instance.new("Weld") w.Part0=root w.Part1=torso w.Parent=torso
 local hrp=Instance.new("Part") hrp.Name="HumanoidRootPart" hrp.Size=Vector3.new(.1,.1,.1) hrp.Transparency=1 hrp.CanCollide=false hrp.CanTouch=false hrp.CanQuery=false hrp.Massless=true hrp.Parent=model
 local rw=Instance.new("Weld") rw.Part0=root rw.Part1=hrp rw.Parent=hrp
 local controller=Instance.new("Humanoid") controller.RigType=Enum.HumanoidRigType.R6 controller.RequiresNeck=false controller.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None controller.EvaluateStateMachine=false controller.PlatformStand=true controller.AutoRotate=false controller.Parent=model
 local animator=Instance.new("Animator") animator.Parent=controller
 if character then
  for _,v in ipairs(character:GetChildren()) do
   if v:IsA("Shirt") or v:IsA("BodyColors") or (v:IsA("CharacterMesh") and (v.BodyPart==Enum.BodyPart.LeftArm or v.BodyPart==Enum.BodyPart.RightArm)) then v:Clone().Parent=model end
  end
 end
 local magParts={} for _,p in ipairs(gun:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("MagazinePart") then table.insert(magParts,p) end end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true part.CollisionGroup="FPSViewModel" end
 end
 model.Parent=camera
 return setmetatable({model=model,root=root,gun=gun,joint=joint,right=right,left=left,leftBase=left.C0,leftRotation=CFrame.Angles(1.15,0,.12),mag=handle.MagazineMotor,magBase=handle.MagazineMotor.C0,magAlpha=0,magParts=magParts,recoil=Recoil.new(),sway=Spring.new(Vector3.zero,14),aim=0,run=0,phase=0,pose=CFrame.new(),leftPose=CFrame.new(),magPose=CFrame.new()},V)
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
  leftTarget=hand*self.leftRotation*CFrame.new(0,.9,0) self.left.Transform=CFrame.new()
 else self.left.Transform=self.leftPose end
 self.left.C0=self.left.C0:Lerp(leftTarget,smoothing)
 local kick=self.recoil:Step(dt) self.right.Transform=CFrame.Angles(kick.X*.3,0,0)
 local rate=mouse/math.max(dt,1/300)
 self.sway.target=Vector3.new(math.clamp(-rate.Y*.000012,-.025,.025),math.clamp(-rate.X*.000012,-.025,.025),0)
 local sway=self.sway:Step(dt)*(1-self.aim) self.phase+=dt*(info.running and 11 or 7.5)*math.clamp(info.speed/16,0,1.5)
 local moving=math.clamp(info.speed/16,0,1)
 local bob=Vector3.new(math.sin(self.phase)*(.018+self.run*.017),math.cos(self.phase*2)*(.025+self.run*.035),0)*moving*(1-self.aim)
 local breath=Vector3.new(0,math.sin(os.clock()*3.49)*.0035,0)*(1-self.aim)
 local offset=CFrame.new(.65,-.8,-1.2):Lerp(self.gun.Handle.AimPoint.CFrame:Inverse(),self.aim)
 local visualKick=CFrame.new(0,0,kick.X*6)*CFrame.Angles(kick.X,kick.Y,0)
 self.root.CFrame=camera.CFrame
 self.joint.C0=offset*CFrame.new(bob+breath)*CFrame.Angles(sway.X,sway.Y,0)*self.pose*visualKick
 return CFrame.Angles(kick.X,kick.Y,0),self.aim
end
function V:Destroy() if self.model then self.model:Destroy() end end
return V
]=] end
do local x=node(mods,'ModuleScript',"WeaponConfig") x.Source=[=[--!strict
return table.freeze({
 Name="VETOR-30", DebugHUD=false, Magazine=30, Reserve=90, Damage=20, Critical=1.5,
 FireInterval=.11, ReloadTime=1.65, EquipTime=.45, UnequipTime=.3, InspectTime=2.5,
 Range=500, FOV=70, ADSFOV=55, ADSTime=.22, WalkSpeed=16, RunSpeed=22,
 LOBBY={ORIGIN=Vector3.new(0,4,16)},RUNNER={WALKSPEED=16,JUMPPOWER=50},
 Sounds={}, -- Silencioso ate configurar audios proprios/licenciados.
})
]=] end
do local x=node(mods,'ModuleScript',"WeaponEffects") x.Source=[=[local Debris=game:GetService("Debris") local Tween=game:GetService("TweenService")
local E={}
function E.Shot(a,b)
 local distance=(b-a).Magnitude
 if distance>.01 then
  local p=Instance.new("Part") p.Name="TracerVirtual" p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Material=Enum.Material.Neon p.Color=Color3.fromRGB(255,208,116) p.Size=Vector3.new(.025,.025,math.min(distance,500)) p.CFrame=CFrame.lookAt((a+b)/2,b) p.Parent=workspace Debris:AddItem(p,.065)
 end
 local flash=Instance.new("Part") flash.Shape=Enum.PartType.Ball flash.Size=Vector3.new(.16,.16,.16) flash.Position=a flash.Material=Enum.Material.Neon flash.Color=Color3.fromRGB(255,214,134) flash.Anchored=true flash.CanCollide=false flash.CanTouch=false flash.CanQuery=false flash.Parent=workspace Debris:AddItem(flash,.045)
 local chip=Instance.new("Part") chip.Size=Vector3.new(.08,.08,.08) chip.Position=b chip.Color=Color3.fromRGB(145,198,214) chip.Anchored=true chip.CanCollide=false chip.CanTouch=false chip.CanQuery=false chip.Parent=workspace
 Tween:Create(chip,TweenInfo.new(.2),{Transparency=1,Size=Vector3.new(.2,.2,.2)}):Play() Debris:AddItem(chip,.22)
end
return E
]=] end
do local x=node(mods,'ModuleScript',"WeaponFactory") x.Source=[=[-- Rifle virtual original em pecas nativas, sem assets externos.
local F={}
local dark=Color3.fromRGB(35,47,65) local blue=Color3.fromRGB(47,139,171) local pale=Color3.fromRGB(182,203,214) local gold=Color3.fromRGB(255,197,80)
function F.Build(parent)
 local m=Instance.new("Model") m.Name="RifleModel"
 local root=Instance.new("Part") root.Name="Handle" root.Size=Vector3.new(.25,.25,.25) root.CFrame=CFrame.new() root.Transparency=1 root.CanCollide=false root.CanTouch=false root.CanQuery=false root.Massless=true root.Parent=m m.PrimaryPart=root
 local magazine
 for _,d in ipairs(require(script.Parent.WeaponGeometry)) do
  local p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part") p.Name=d.name
  p.Size=Vector3.new(d.size[1],d.size[2],d.size[3])
  p.CFrame=CFrame.new(d.pos[1],d.pos[2],d.pos[3])*CFrame.Angles(math.rad(d.rot[1]),math.rad(d.rot[2]),math.rad(d.rot[3]))
  if d.shape=="Tube" then p.Shape=Enum.PartType.Cylinder p.Size=Vector3.new(d.size[3],d.size[1],d.size[2]) p.CFrame=p.CFrame*CFrame.Angles(0,math.pi/2,0) end
  p.Color=Color3.fromRGB(d.color[1],d.color[2],d.color[3]) p.Material=Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Parent=m
  if d.name=="Magazine" then
   magazine=p p:SetAttribute("MagazinePart",true)
   local motor=Instance.new("Motor6D") motor.Name="MagazineMotor" motor.Part0=root motor.Part1=p motor.C0=p.CFrame motor.Parent=root
  else
   local parentPart=d.group=="Mag" and magazine or root
   if d.group=="Mag" then p:SetAttribute("MagazinePart",true) end
   local w=Instance.new("Weld") w.Part0=parentPart w.Part1=p w.C0=parentPart.CFrame:Inverse()*p.CFrame w.Parent=p
  end
 end
 local function point(name,pos) local a=Instance.new("Attachment") a.Name=name a.CFrame=CFrame.new(pos) a.Parent=root return a end
 point("AimPoint",Vector3.new(0,.78,.65)) point("Muzzle",Vector3.new(0,.29,-3.38)) point("LeftGrip",Vector3.new(-.3,-.4,-1.0)) point("RightGripPoint",Vector3.new(.05,-.45,.1)) point("MagazinePivot",Vector3.new(0,-.46,-.65))
 m.Parent=parent return m
end
function F.Mount(tool)
 if tool:GetAttribute("FactoryRuntimeBuilt") then return end
 for _,old in ipairs(tool:GetChildren()) do if old:IsA("BasePart") or old:IsA("Model") then old:Destroy() end end
 tool:SetAttribute("FactoryRuntimeBuilt",true)
 local model=F.Build(nil) for _,p in ipairs(model:GetChildren()) do p.Parent=tool end model:Destroy()
end
return F
]=] end
do local x=node(mods,'ModuleScript',"WeaponGeometry") x.Source=[=[-- Exportado da modelagem original no Blender.
return {{["name"]="Receiver",["size"]={0.57,0.46,1.9},["pos"]={0,0.25,-0.65},["color"]={48,104,135},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Upper receiver",["size"]={0.62,0.14,1.45},["pos"]={0,0.55,-0.55},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer frente",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,-1.55},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,0,0},["group"]="Body"},{["name"]="Chamfer traseiro",["size"]={0.57,0.16,0.28},["pos"]={0,0.51,0.28},["color"]={48,104,135},["shape"]="Wedge",["rot"]={0,180,0},["group"]="Body"},{["name"]="Handguard",["size"]={0.49,0.4,0.9},["pos"]={0,0.24,-1.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cano virtual",["size"]={0.16,0.16,0.8},["pos"]={0,0.29,-2.78},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Emissor",["size"]={0.29,0.29,0.28},["pos"]={0,0.29,-3.22},["color"]={24,30,39},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Anel frontal",["size"]={0.34,0.34,0.07},["pos"]={0,0.29,-3.12},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,0,0},["group"]="Body"},{["name"]="Trilho",["size"]={0.29,0.07,1.7},["pos"]={0,0.66,-0.7},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-1.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.95},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.45},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,-0.2},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Dente do trilho",["size"]={0.34,0.05,0.09},["pos"]={0,0.715,0.05},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={-0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={-0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={-0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={-0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={-0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel lateral",["size"]={0.045,0.3,1.1},["pos"]={0.3,0.26,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Faixa lateral",["size"]={0.05,0.055,0.7},["pos"]={0.3,0.46,-0.5},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-1.05},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.75},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.45},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Parafuso",["size"]={0.06,0.06,0.025},["pos"]={0.3,0.25,-0.15},["color"]={151,170,184},["shape"]="Tube",["rot"]={0,90,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.22},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-2.02},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.82},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Janela de ventilacao",["size"]={0.025,0.12,0.11},["pos"]={0.252,0.27,-1.62},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Painel traseiro",["size"]={0.045,0.18,0.27},["pos"]={0.3,0.3,0.1},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Coronha",["size"]={0.38,0.34,0.65},["pos"]={0,0.2,0.77},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Haste da coronha",["size"]={0.24,0.19,0.4},["pos"]={0,0.32,0.33},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Ombreira",["size"]={0.44,0.57,0.12},["pos"]={0,0.13,1.16},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,-0.04,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.08,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.2,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Textura ombreira",["size"]={0.46,0.035,0.13},["pos"]={0,0.32,1.17},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Cabo",["size"]={0.33,0.58,0.36},["pos"]={0,-0.34,0.12},["color"]={48,55,62},["shape"]="Block",["rot"]={-10,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.5,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.38,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Relevo cabo",["size"]={0.35,0.035,0.34},["pos"]={0,-0.26,0.13},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda inferior",["size"]={0.34,0.055,0.43},["pos"]={0,-0.25,-0.22},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Guarda frontal",["size"]={0.34,0.2,0.055},["pos"]={0,-0.13,-0.42},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Magazine",["size"]={0.39,0.63,0.53},["pos"]={0,-0.46,-0.65},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={-0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.65,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.48,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Rib magazine",["size"]={0.035,0.045,0.48},["pos"]={0.205,-0.31,-0.65},["color"]={48,55,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Base magazine",["size"]={0.44,0.08,0.56},["pos"]={0,-0.8,-0.65},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Mag"},{["name"]="Mira traseira",["size"]={0.37,0.09,0.22},["pos"]={0,0.71,0.15},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={-0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira lateral",["size"]={0.065,0.17,0.12},["pos"]={0.13,0.79,0.15},["color"]={151,170,184},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Mira frontal",["size"]={0.06,0.16,0.1},["pos"]={0,0.79,-1.7},["color"]={235,170,62},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Suporte da mira",["size"]={0.18,0.25,0.24},["pos"]={0,0.56,-1.7},["color"]={36,48,67},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"},{["name"]="Moldura frontal",["size"]={0.25,0.07,0.2},["pos"]={0,0.7,-1.7},["color"]={24,30,39},["shape"]="Block",["rot"]={0,0,0},["group"]="Body"}}
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
require(system.Modules.ThirdPersonController).init()
]=] end
do local x=Instance.new('Script') x.Name="GunServer" x.Source=[=[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Physics=game:GetService("PhysicsService")
pcall(function() Physics:RegisterCollisionGroup("FPSViewModel") end)
for _,g in ipairs(Physics:GetRegisteredCollisionGroups()) do Physics:CollisionGroupSetCollidable("FPSViewModel",g.name,false) end
local System=RS:WaitForChild("FPSSystem") local Modules=System.Modules
local C=require(Modules.WeaponConfig) local Logic=require(Modules.WeaponState) local Factory=require(Modules.WeaponFactory)
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
 local gunCF=torso and joint and torso.CFrame*joint.C0*CFrame.Angles(s.pitch,0,0)*CFrame.new(0,s.aiming and .65 or 0,s.aiming and .05 or 0)
 local start=gunCF and muzzle and (gunCF*muzzle.CFrame).Position or head.Position
 if (start-head.Position).Magnitude>6 or workspace:Raycast(head.Position,start-head.Position,params) then start=head.Position end
 if hit then
  local model=hit.Instance:FindFirstAncestorOfClass("Model") local humanoid=model and model:FindFirstChildOfClass("Humanoid")
  local victim=model and Players:GetPlayerFromCharacter(model)
  local friendly=victim and not p.Neutral and not victim.Neutral and p.Team==victim.Team
  if humanoid and humanoid.Health>0 and model~=p.Character and not friendly and not model:FindFirstChildOfClass("ForceField") then
   local critical=hit.Instance.Name=="Head" local before=humanoid.Health humanoid:TakeDamage(C.Damage*(critical and C.Critical or 1))
   if humanoid.Health<before then Remotes.Hit:FireClient(p,critical) end
  end
 end
 Remotes.WeaponFX:FireAllClients(p.UserId,start,target)
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
  local joint=Instance.new("Motor6D") joint.Name="WorldGrip" joint.Part0=torso joint.Part1=tool.Handle joint.C0=CFrame.new(0,-.05,-.4) joint.Parent=tool.Handle
  Logic.Equip(s,true,now()) snapshot(p,s)
 end)
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
local function add(p) if bound[p] then return end bound[p]=true task.spawn(spawn,p) end
Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(function(p) spawning[p]=nil bound[p]=nil Avatar.Clear(p.UserId) end)
for _,p in ipairs(Players:GetPlayers()) do add(p) end
]=] x.Parent=SS end
require(mods.WeaponFactory).Build(assets)
local vm=require(mods.ViewModelController).new(workspace.CurrentCamera) vm.model.Parent=assets
print('FPS R6 instalado. Use Play e equipe Rifle. Nenhum mapa, economia ou matchmaking foi instalado.')