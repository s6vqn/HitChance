 
                                                                                local Players=game:    
                                                                        GetService("Players");local RunService=game:     
                                                                    GetService("RunService");local UIS=game:GetService(            
                                                                "UserInputService");local LP=Players.LocalPlayer;local C={Enabled=false  
                                                            ,HoldKey=Enum.UserInputType.MouseButton2,ToggleKey=Enum.KeyCode.T,Smoothing=2  
                                                          ,FOV=40,MaxDistance=500,WallCheck=true,Part="Head"};local E={Enabled=true,         
                                                        ToggleKey=Enum.KeyCode.K,Fill=Color3.fromRGB(255,255,255),Outline=Color3.fromRGB(255,  
                                                      0,0),FillTransparency=1,MaxDistance=5000,ShowNPCs=true,TeamCheck=false,MaxHighlights=20,   
                                                    HPBar=true,HideGameNames=true};if getgenv then for _,k in ipairs({"__CamlockEspCleanup",       
                                                  "__CamlockCleanup","__ChamsCleanup"}) do if getgenv()[k] then pcall(getgenv()[k]);end end end      
                                                  pcall(function() RunService:UnbindFromRenderStep("CamlockStep");end);pcall(function() RunService:    
                                                UnbindFromRenderStep("ChamsStep");end);local parents={};pcall(function() table.insert(parents,game:      
                                                GetService("CoreGui"));end);if LP:FindFirstChild("PlayerGui") then table.insert(parents,LP.PlayerGui);end  
                                               if gethui then local okH,h=pcall(gethui);if (okH and h) then table.insert(parents,h);end end for _,parent in  
                                               ipairs(parents) do for _,c in ipairs(parent:GetChildren()) do if ((c.Name=="ChamsHolder") or (c.Name==        
                                            "CamlockBtn") or (c.Name=="ExilWatermark")) then pcall(function() c:Destroy();end);end end end local touchLock=    
                                            false;local function isDown(key) if touchLock then return true;end if (key.EnumType==Enum.UserInputType) then        
                                          return UIS:IsMouseButtonPressed(key);end return UIS:IsKeyDown(key);end local function getPart(char) if (C.Part=="Head")  
                                           then return char:FindFirstChild("Head");end return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or   
                                          char:FindFirstChild("HumanoidRootPart") ;end local function isDead(char,hum) if ((hum.Health<=0) or (hum:GetState()==Enum.   
                                          HumanoidStateType.Dead)) then return true;end local ok,ko=pcall(function() local be=char:FindFirstChild("BodyEffects");      
                                        local v=be and be:FindFirstChild("K.O") ;return v and v.Value ;end);return ok and (ko==true) ;end local function visible(cam,    
                                        part,char) if  not C.WallCheck then return true;end local params=     --[[==============================]]RaycastParams.new();     
                                        params.FilterType=Enum.RaycastFilterType.Exclude;local      --[[============================================]]ignore={char};if LP  
                                        .Character then table.insert(ignore,LP.Character);end   --[[======================================================]]params.          
                                      FilterDescendantsInstances=ignore;local origin=cam.   --[[==========================================================]]CFrame.Position;   
                                      local dir=part.Position-origin ;for _=1,8 do local  --[[==============================================================]]hit=workspace:   
                                      Raycast(origin,dir,params);if  not hit then return  --[[================================================================]]true;end local   
                                      inst=hit.Instance;if ((inst.Transparency>=0.9) or   --[[==================================================================]]not inst.      
                                      CanCollide) then table.insert(ignore,inst);params.  --[[==================================================================]]                   
                                    FilterDescendantsInstances=ignore;else return false;  --[[====================================================================]]end end        
                    return false;end local function findTarget(cam) local center=cam.     --[[====================================================================]]ViewportSize/2   
              ;local best,bestD=nil,C.FOV;for _,plr in ipairs(Players:GetPlayers()) do if --[[======================================================================]] ((plr~=LP)    
            and plr.Character) then local char=plr.Character;local hum=char:              --[[======================================================================]]               
          FindFirstChildOfClass("Humanoid");local part=getPart(char);if (hum and part and --[[======================================================================]]  not isDead(  
        char,hum)) then local pos,onScreen=cam:WorldToViewportPoint(part.Position);local  --[[======================================================================]]dist3=(part.   
        Position-cam.CFrame.Position).Magnitude;if (onScreen and (dist3<=C.MaxDistance))  --[[======================================================================]]then local d=  
      (Vector2.new(pos.X,pos.Y) -center).Magnitude;if ((d<bestD) and visible(cam,part,    --[[======================================================================]]char)) then    
      best,bestD=plr,d;end end end end end return best;end local locked=nil;local tried=    --[[==================================================================]]false;local      
      lastSearch,cachedCand=0,nil;local function camStep(dt) local cam=workspace.           --[[================================================================]]CurrentCamera;if   
    ( not cam or  not C.Enabled or  not isDown(C.HoldKey)) then locked=nil;tried=false;     --[[==============================================================]]return;end if      
    locked then local char=locked.Character;local hum=char and char:FindFirstChildOfClass(    --[[==========================================================]]"Humanoid") ;local   
    part=char and getPart(char) ;if ( not (hum and part) or isDead(char,hum)) then locked=nil;  --[[====================================================]]end end local now=os.    
    clock();if ((now-lastSearch)>=0.05) then lastSearch=now;cachedCand=findTarget(cam);end local  --[[==============================================]]cand=cachedCand;if (cand   
    and (cand~=locked)) then locked=cand;end if  not locked then return;end local part=getPart(locked --[[====================================]].Character);if  not part then  
     locked=nil;return;end local s=math.max(1,C.Smoothing);local alpha=1 -((1 -(1/s))^(math.clamp(dt,0,   --[[========================]]0.1) * 60)) ;local goal=CFrame.new(    
    cam.CFrame.Position,part.Position);cam.CFrame=cam.CFrame:Lerp(goal,alpha);end local btnGui;if UIS.TouchEnabled then btnGui=Instance.new("ScreenGui");btnGui.Name=        
  "CamlockBtn";btnGui.ResetOnSpawn=false;local okP=pcall(function() btnGui.Parent=(gethui and gethui()) or game:GetService("CoreGui") ;end);if  not okP then btnGui.       
  Parent=LP:WaitForChild("PlayerGui");end local b=Instance.new("TextButton");b.Size=UDim2.new(0,80,0,80);b.Position=UDim2.new(1, -110,0.5, -40);b.BackgroundColor3=      
  Color3.new(0,0,0);b.BackgroundTransparency=0.3;b.BorderColor3=Color3.fromRGB(0,200,120);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.SourceSansBold;b.TextSize=18;b.  
  Text="LOCK\nOFF";b.Active=true;b.Draggable=true;b.Parent=btnGui;b.MouseButton1Click:Connect(function() C.Enabled=true;touchLock= not touchLock;locked=nil;b.Text=(       
  touchLock and "LOCK\nON") or "LOCK\nOFF" ;pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Camlock",Text=(touchLock and "ON") or "OFF"  
   ,Duration=2});end);end);end RunService:BindToRenderStep("CamlockStep",Enum.RenderPriority.Camera.Value + 1 ,function(dt) pcall(camStep,dt);end);local holder=Instance.  
  new("Folder");holder.Name="ChamsHolder";local okH2=pcall(function() holder.Parent=(gethui and gethui()) or game:GetService("CoreGui") ;end);if  not okH2 then holder.    
  Parent=LP:WaitForChild("PlayerGui");end local tracked={};local models={};local function tryAdd(inst) if ((inst.ClassName=="Humanoid") or ((inst.Name==                   
  "HumanoidRootPart") and inst:IsA("BasePart"))) then local m=inst.Parent;if (m and m:IsA("Model")) then models[m]=true;end end end for _,d in ipairs(workspace:           
  GetDescendants()) do tryAdd(d);end local cAdded=workspace.DescendantAdded:Connect(tryAdd);local function create(model) local hl=Instance.new("Highlight");hl.Adornee=    
  model;hl.FillColor=E.Fill;hl.FillTransparency=E.FillTransparency;hl.OutlineColor=E.Outline;hl.OutlineTransparency=0;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl  
  .Parent=holder;local bb=Instance.new("BillboardGui");bb.Size=UDim2.new(3.5,0,0.06,0);bb.StudsOffsetWorldSpace=Vector3.new(0, -3.7,0);bb.AlwaysOnTop=true;bb.               
  LightInfluence=0;bb.Enabled=false;bb.Parent=holder;local bg=Instance.new("Frame");bg.Size=UDim2.new(1,0,1,0);bg.BackgroundColor3=Color3.new(0,0,0);bg.                     
  BackgroundTransparency=0.3;bg.BorderSizePixel=0;bg.Parent=bb;local fill=Instance.new("Frame");fill.Size=UDim2.new(1,0,1,0);fill.BackgroundColor3=Color3.fromRGB(0,255,0);  
  fill.BorderSizePixel=0;fill.Parent=bg;local o={hl=hl,bb=bb,fill=fill};tracked[model]=o;return o;end local function remove(model) local o=tracked[model];if o then pcall(   
  function() o.hl:Destroy();end);pcall(function() o.bb:Destroy();end);tracked[model]=nil;end end local espAcc=0;local function espStep(dt) espAcc+=dt if (espAcc<0.1) then   
  return;end espAcc=0;local cam=workspace.CurrentCamera;if  not cam then return;end local on=E.Enabled and  not (getgenv and getgenv().ChamsOff) ;local camPos=cam.CFrame.   
  Position;local shownList={};for model in pairs(models) do if ( not model.Parent or  not model:IsDescendantOf(workspace)) then models[model]=nil;remove(model);elseif (     
  model~=LP.Character) then local o=tracked[model] or create(model) ;local hum=o.hum;if ( not hum or (hum.Parent~=model)) then hum=model:FindFirstChildOfClass("Humanoid");  
  o.hum=hum;end local root=o.root;if ( not root or (root.Parent~=model)) then root=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild(    
  "Torso") or model:FindFirstChild("Head") ;o.root=root;end if (E.HideGameNames and hum and  not o.nameHidden) then o.nameHidden=true;pcall(function() hum.                  
  DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;end);end local plr=((E.TeamCheck or  not E.ShowNPCs) and Players:GetPlayerFromCharacter(model)) or nil ;local    
  hide= not on or  not root or (hum and (hum.Health<=0)) or ( not E.ShowNPCs and  not plr) or (E.TeamCheck and plr and (plr.Team~=nil) and (plr.Team==LP.Team)) ;if ( not    
  hide and ((root.Position-camPos).Magnitude>E.MaxDistance)) then hide=true;end if hide then if (o.shown~=false) then o.shown=false;o.hl.Enabled=false;o.hlOn=false;o.bb.    
  Enabled=false;o.bbOn=false;end else o.shown=true;o.dist=(root.Position-camPos).Magnitude;table.insert(shownList,o);if (o.adornee~=root) then o.adornee=root;o.bb.        
  Adornee=root;end if (o.bbOn~=E.HPBar) then o.bbOn=E.HPBar;o.bb.Enabled=E.HPBar;end local frac=(hum and math.clamp(hum.Health/math.max(hum.MaxHealth,1) ,0,1)) or 1 ;if   
  (frac~=o.frac) then o.frac=frac;o.fill.Size=UDim2.new(frac,0,1,0);o.fill.BackgroundColor3=Color3.fromHSV(frac * 0.33 ,1,1);end end end end table.sort(shownList,         
    function(a,b) return a.dist<b.dist ;end);for i,o in ipairs(shownList) do local want=i<=E.MaxHighlights ;if (o.hlOn~=want) then o.hlOn=want;o.hl.Enabled=want;end end   
    end RunService:BindToRenderStep("ChamsStep",Enum.RenderPriority.Camera.Value + 2 ,function(dt) pcall(espStep,dt);end);local function notify(title,text) pcall(         
    function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=title,Text=text,Duration=2});end);end local inputConn=UIS.InputBegan:Connect(function(      
    input,gpe) if gpe then return;end if (input.KeyCode==C.ToggleKey) then C.Enabled= not C.Enabled;locked=nil;print("[Camlock] Enabled:",C.Enabled);notify("Camlock",(C.  
      Enabled and "ON") or "OFF" );elseif (input.KeyCode==E.ToggleKey) then E.Enabled= not E.Enabled;print("[Chams] Enabled:",E.Enabled);notify("ESP",(E.Enabled and     
      "ON") or "OFF" );end end);if getgenv then getgenv().__CamlockEspCleanup=function() pcall(function() RunService:UnbindFromRenderStep("CamlockStep");end);pcall(     
      function() RunService:UnbindFromRenderStep("ChamsStep");end);inputConn:Disconnect();cAdded:Disconnect();if btnGui then btnGui:Destroy();end holder:Destroy();end;  
        end print("[Camlock+ESP] Loaded. T = camlock ON/OFF (hold right click), K = ESP ON/OFF.");pcall(function() game:GetService("StarterGui"):SetCore(                
        "SendNotification",{Title="Camlock + ESP",Text="made by exil",Duration=4});end);local R={Enabled=true,Scale=0,ToggleKey=Enum.KeyCode.Y};local SKIP={"rate",      
        "rpm","delay","ammo","damage","speed","time","cooldown","range","spread","mag"};if getgenv then if getgenv().RecoilRestore then pcall(getgenv().RecoilRestore);  
          end if getgenv().__RecoilConn then pcall(function() getgenv().__RecoilConn:Disconnect();end);end end local recoilOriginals={};local function                 
            recoilKeySkipped(k) local s=string.lower(tostring(k));for _,w in ipairs(SKIP) do if string.find(s,w,1,true) then return true;end end return false;end      
              local function recoilScale(data) local n=0;local function mul(t,k) local v=t[k];if (type(v)=="number") then table.insert(recoilOriginals,{t,k,v});t[k]=  
                v * R.Scale ;n+=1 end end if (type(data.Scale)=="table") then for k in pairs(data.Scale) do mul(data.Scale,k);end end if (type(data.Feel)=="table")    
                  then for _,feel in pairs(data.Feel) do if (type(feel)=="table") then for k in pairs(feel) do mul(feel,k);end end end end if (type(data.Guns)==     
                      "table") then for _,g in pairs(data.Guns) do if (type(g)=="table") then for _,k in ipairs({"V","First","Random","Bias"}) do mul(g,k);end for   
                                  _,list in ipairs({g.Up or {} ,g.Side or {} }) do for _,point in ipairs(list) do if (type(point)=="table") then mul(point,2);end    
                                      end end end end end return n;end local function recoilRestore() for _,e in ipairs(recoilOriginals) do pcall(function() e[1][e  
                                      [2]]=e[3];end);end recoilOriginals={};end local function              recoilApply() recoilRestore();local RS=game:GetService(  
                                      "ReplicatedStorage");local mod=RS:FindFirstChild(                     "RecoilPatterns",true);if  not mod then warn(          
                                      "[Recoil] Hindi nahanap ang RecoilPatterns sa larong ito.");          return;end local ok,data=pcall(require,mod);if ( not   
                                      ok or (type(data)~="table")) then warn(                               "[Recoil] Hindi ma-require ang RecoilPatterns:",(ok    
                                      and type(data)) or data );return;end local okS,count=pcall(             recoilScale,data);print((okS and string.format(      
                                                                                                                                                                   
                                                                                                                                                                 
                                                                                                                                                                 
                                                                                                                                                                 
                                                                                                                                                               
                                                                                                                                                               
                                                                                                                                                             
                                                                                                                                                             
                                                                                                                                                           
                                                                                                                                                       
                                                                                                                                                   
                                                                                                                                           
                                                                                             
                                                                                           
                                                                                         
                                                                                   


"[Recoil] Nabawasan ang %d na value (x%s). I-equip ulit ang baril kung walang pagbabago.",count,tostring(R.Scale))) or ("[Recoil] Error: "   .. tostring(count)) );end if getgenv then getgenv().RecoilRestore=recoilRestore;end pcall(recoilApply);local recoilConn=UIS.InputBegan:Connect(function(input,gpe) if gpe then return;end if (input.KeyCode==R.ToggleKey) then R.Enabled= not R.Enabled;if R.Enabled then pcall(recoilApply);else recoilRestore();end print("[Recoil] Enabled:",R.Enabled);pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Recoil",Text=(R.Enabled and "ON") or "OFF" ,Duration=2});end);end end);if getgenv then getgenv().__RecoilConn=recoilConn;end local F={Enabled=true,ToggleKey=Enum.KeyCode.J,Quality=3};if (getgenv and getgenv().__FpsRestore) then pcall(getgenv().__FpsRestore);end local Lighting=game:GetService("Lighting");local fpsOriginal={};local function fpsApply() fpsOriginal={fx={}};pcall(function() fpsOriginal.shadows=Lighting.GlobalShadows;Lighting.GlobalShadows=false;end);pcall(function() local r=settings().Rendering;fpsOriginal.quality=r.QualityLevel;r.QualityLevel=Enum.QualityLevel["Level0"   .. tostring(math.clamp(F.Quality,1,9)) ];end);pcall(function() for _,v in ipairs(Lighting:GetChildren()) do if (v:IsA("PostEffect") and v.Enabled) then table.insert(fpsOriginal.fx,v);v.Enabled=false;end end end);pcall(function() local t=workspace:FindFirstChildOfClass("Terrain");if t then fpsOriginal.deco=t.Decoration;t.Decoration=false;end end);end local function fpsRestore() pcall(function() if (fpsOriginal.shadows~=nil) then Lighting.GlobalShadows=fpsOriginal.shadows;end end);pcall(function() if (fpsOriginal.quality~=nil) then settings().Rendering.QualityLevel=fpsOriginal.quality;end end);pcall(function() for _,v in ipairs(fpsOriginal.fx or {} ) do v.Enabled=true;end end);pcall(function() local t=workspace:FindFirstChildOfClass("Terrain");if (t and (fpsOriginal.deco~=nil)) then t.Decoration=fpsOriginal.deco;end end);end if getgenv then getgenv().__FpsRestore=fpsRestore;end if F.Enabled then fpsApply();end local fpsConn=UIS.InputBegan:Connect(function(input,gpe) if gpe then return;end if (input.KeyCode==F.ToggleKey) then F.Enabled= not F.Enabled;if F.Enabled then fpsApply();else fpsRestore();end pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="FPS Boost",Text=(F.Enabled and "ON") or "OFF" ,Duration=2});end);end end);if getgenv then local prev=getgenv().__FpsConn;if prev then pcall(function() prev:Disconnect();end);end getgenv().__FpsConn=fpsConn;end
