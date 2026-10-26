local Art = require('src.art')
local Animation = require('src.animation')
local Path = require('src.path')
local Movement = require('src.movement')
local World = {}; World.__index=World
local SIZE=16
local STATS={
  infantry={cost=85,hp=70,speed=28,range=42,dmg=7,cooldown=0.72,size=13},
  tank={cost=220,hp=210,speed=19,range=68,dmg=24,cooldown=1.25,size=21},
  hq={cost=0,hp=1200,size=55},
  barracks={cost=340,hp=570,size=46},
  factory={cost=460,hp=710,size=48},
  turret={cost=200,hp=330,size=31,range=100,dmg=14,cooldown=0.84},
}
local function distance(x,y,a,b) return math.sqrt((x-a)^2+(y-b)^2) end
function World.new(mode,level,seed)
  local self=setmetatable({},World)
  self.mode=mode or 'scenario';self.level=level or 1
  self.seed=seed or 731;self.elapsed=0;self.w=46;self.h=38;self.tile=SIZE
  self.money={[1]=900,[2]=850};self.income={[1]=8,[2]=8}
  self.entities={};self.selected={};self.nextId=0;self.result=nil
  self.buildMode=nil;self.notice='';self.noticeTimer=0
  self.camera={x=15,y=108};self.aiTime=0;self.incomeTime=0
  self.terrain={};self.blocked={};self.obstacles={};self.queues={}
  self.tickRemainder=0;self.rngState=self.seed
  self.effects={};self.preview=nil
  local function rand(n) return self:random(n) end
  self.rand=rand
  for y=1,self.h do
    self.terrain[y]={}
    for x=1,self.w do
      local typeName = rand(100)<79 and 'grass' or 'grass2'
      if (x>=18 and x<=28 and y>=13 and y<=26) or rand(100)>93 then
        typeName=rand(2)==1 and 'dirt' or 'dirt2'
      end
      self.terrain[y][x]=typeName
    end
  end
  for i=1,160 do
    local gx,gy=rand(self.w),rand(self.h)
    if gx>10 and gx<self.w-10 and gy>4 and gy<self.h-4 then
      if rand(5)~=1 then
        self.obstacles[#self.obstacles+1]={x=gx,y=gy,typeName=rand(3)==1 and 'rocks' or 'forest'}
        self.blocked[gy*self.w+gx]=true
      end
    end
  end
  self:clearArea(7,9,7);self:clearArea(self.w-7,self.h-8,7)
  self:add('hq',1,7*SIZE,9*SIZE)
  self:add('barracks',1,11*SIZE,9*SIZE)
  self:add('factory',1,7*SIZE,13*SIZE)
  self:add('hq',2,(self.w-7)*SIZE,(self.h-8)*SIZE)
  self:add('barracks',2,(self.w-11)*SIZE,(self.h-8)*SIZE)
  self:add('factory',2,(self.w-7)*SIZE,(self.h-12)*SIZE)
  for i=1,4 do self:add('infantry',1,(6+i)*SIZE,17*SIZE) end
  self:add('tank',1,11*SIZE,18*SIZE)
  for i=1,5 do self:add('infantry',2,(self.w-13+i)*SIZE,(self.h-16)*SIZE) end
  self:add('tank',2,(self.w-11)*SIZE,(self.h-17)*SIZE)
  self:toast('Missao experimental: destrua o QG inimigo.')
  return self
end
function World:random(n)
  -- Record RNG state so loading a game preserves subsequent AI decisions.
  self.rngState=(self.rngState*48271)%2147483647
  return (self.rngState%n)+1
end
function World:toast(message)
  self.notice=message;self.noticeTimer=4.5
end
function World:clearArea(cx,cy,r)
  for i=#self.obstacles,1,-1 do
    local o=self.obstacles[i]
    if math.abs(o.x-cx)<=r and math.abs(o.y-cy)<=r then
      self.blocked[o.y*self.w+o.x]=nil
      table.remove(self.obstacles,i)
    end
  end
end
function World:refreshBlocked()
  self.blocked={}
  for _,o in ipairs(self.obstacles) do self.blocked[o.y*self.w+o.x]=true end
  for _,e in ipairs(self.entities) do
    if e.alive and e.building then
      local radius = (e.kind=='hq' and 2 or 1)
      local cx,cy=math.floor(e.x/SIZE+0.5), math.floor(e.y/SIZE+0.5)
      for dy=-radius,radius do for dx=-radius,radius do
        local x,y=cx+dx,cy+dy
        if x>=1 and y>=1 and x<=self.w and y<=self.h then self.blocked[y*self.w+x]=true end
      end end
    end
  end
end
function World:add(kind,team,x,y)
  local st=STATS[kind];if not st then return nil end
  self.nextId=self.nextId+1
  local b=kind=='hq' or kind=='barracks' or kind=='factory' or kind=='turret'
  local e={id=self.nextId,kind=kind,team=team,x=x,y=y,hp=st.hp,maxhp=st.hp,
    building=b,alive=true,cooldown=0,queue=0,production=0,angle=0,order=nil,path=nil,
    animTime=0,animationTime=0,animationState='idle',moving=false,firePulse=0,hitPulse=0}
  self.entities[#self.entities+1]=e
  if b then self:refreshBlocked() end
  return e
end
function World:entityAt(x,y,team)
  for i=#self.entities,1,-1 do
    local e=self.entities[i]
    if e.alive and (not team or e.team==team) then
      local radius=(STATS[e.kind].size or 16)*0.54
      if distance(e.x,e.y,x,y)<=radius then return e end
    end
  end
  return nil
end
function World:select(e,additive)
  if not additive then self.selected={} end
  if e and e.team==1 and e.alive then self.selected[e.id]=true end
end
function World:selectBox(x1,y1,x2,y2,additive)
  if not additive then self.selected={} end
  local left,right=math.min(x1,x2),math.max(x1,x2)
  local top,bottom=math.min(y1,y2),math.max(y1,y2)
  for _,e in ipairs(self.entities) do
    if e.alive and e.team==1 and not e.building and e.x>=left and e.x<=right and e.y>=top and e.y<=bottom then
      self.selected[e.id]=true
    end
  end
end
function World:selectedList()
  local list={};for _,e in ipairs(self.entities) do
    if e.alive and self.selected[e.id] then list[#list+1]=e end
  end
  return list
end
function World:moveSelected(x,y)
  local units={}
  for _,e in ipairs(self:selectedList()) do
    if not e.building then units[#units+1]=e end
  end
  if #units==0 then return end
  local target=self:entityAt(x,y)
  if target and target.team==1 then target=nil end
  self:refreshBlocked()
  local destinations=target and {} or Movement.formationSlots(self,units,x,y,self.selected)
  for _,e in ipairs(units) do
    local goal={x=x,y=y,target=target and target.id or nil,manualAttack=target~=nil}
    if not target then
      local spot=destinations[e.id]
      -- Do not issue an impossible formation slot if the ground is full.
      if spot then goal.x,goal.y=spot.x,spot.y else goal=nil end
    end
    e.order=goal;e.path=nil;e.pathTime=0;e.blockedTime=0;e.steerTime=0;e.avoidCongestion=false
  end
  self:effect('order',x,y,0.65)
  self:toast(#units..' unidades receberam ordens.')
end
function World:cost(kind) return STATS[kind] and STATS[kind].cost or 0 end
function World:canBuild(x,y,kind)
  local st=STATS[kind or 'barracks']
  local radius=(st.size or 46)*0.55
  if x<radius or y<radius or x>self.w*SIZE-radius or y>self.h*SIZE-radius then
    return false
  end
  -- Building footprints must not overlap rocks, forests, troops or other
  -- structures. Previous implementation only checked structure centers.
  for _,o in ipairs(self.obstacles) do
    if distance(x,y,o.x*SIZE,o.y*SIZE)<radius+12 then return false end
  end
  for _,e in ipairs(self.entities) do
    if e.alive and distance(x,y,e.x,e.y)<radius+STATS[e.kind].size*.5 then
      return false
    end
  end
  return true
end
function World:placeBuilding(kind,x,y)
  if not STATS[kind] or (kind~='barracks' and kind~='factory' and kind~='turret') then return false end
  if self.money[1]<self:cost(kind) then self:toast('Creditos insuficientes.');return false end
  x=math.floor(x/SIZE+.5)*SIZE;y=math.floor(y/SIZE+.5)*SIZE
  if not self:canBuild(x,y,kind) then self:toast('Local bloqueado para construcao.');return false end
  self.money[1]=self.money[1]-self:cost(kind)
  self:add(kind,1,x,y);self.buildMode=nil
  self:toast('Edificio construido.')
  return true
end
function World:train(building,kind)
  -- Reject dead, fake, or stale building objects (e.g. from a previous match).
  if not building or not building.alive or not building.building or building.team~=1 then return false end
  local registered=false
  for _,e in ipairs(self.entities) do
    if e==building then registered=true;break end
  end
  if not registered then return false end
  if not ((building.kind=='barracks' and kind=='infantry') or (building.kind=='factory' and kind=='tank')) then return false end
  if self.money[1]<self:cost(kind) then self:toast('Creditos insuficientes.');return false end
  local count=0
  for _,e in ipairs(self.entities) do if e.team==1 and e.alive and not e.building then count=count+1 end end
  local queued=0
  for _,e in ipairs(self.entities) do if e.team==1 and e.alive and e.building then queued=queued+e.queue end end
  if count+queued>=50 then self:toast('Limite de 50 unidades atingido.');return false end
  self.money[1]=self.money[1]-self:cost(kind)
  building.queue=building.queue+1
  building.production=building.production>0 and building.production or (kind=='tank' and 8 or 4)
  self:toast('Unidade adicionada a fila.')
  return true
end
function World:spawn(building,kind)
  for r=2,9 do
    for i=0,11 do
      local a=i*math.pi/6;local x=building.x+math.cos(a)*r*SIZE
      local y=building.y+math.sin(a)*r*SIZE
      -- Check the whole produced unit footprint against terrain, buildings
      -- and ALL living units, not just the destination's center tile.
      local candidate={kind=kind,x=x,y=y}
      if Movement.canOccupy(self,candidate,x,y) then
        return self:add(kind,building.team,x,y)
      end
    end
  end
  return nil
end
function World:targetDistance(e,target)
  local d=distance(e.x,e.y,target.x,target.y)
  -- Use the same effective target geometry for manual orders and auto-attack.
  if target.building then d=d-(STATS[target.kind].size*.42) end
  return d
end
function World:findEntity(id)
  for _,e in ipairs(self.entities) do
    if e.id==id and e.alive then return e end
  end
  return nil
end
function World:nearestEnemy(e,range)
  local best=nil;local bestDist=range or math.huge
  for _,other in ipairs(self.entities) do
    if other.alive and other.team~=e.team then
      local d=self:targetDistance(e,other)
      if d<bestDist then best=other;bestDist=d end
    end
  end
  return best,bestDist
end
function World:navigate(e,x,y,dt)
  local st=STATS[e.kind]
  if not e.path or (e.pathTime or 0)<=0 then
    self:refreshBlocked()
    local sx=math.floor(e.x/SIZE+.5);local sy=math.floor(e.y/SIZE+.5)
    local gx=math.floor(x/SIZE+.5);local gy=math.floor(y/SIZE+.5)
    if e.avoidCongestion then
      -- A temporary traffic grid is used only for path search; stationary
      -- obstacles still come exclusively from refreshBlocked().
      e.path=Path.search(Movement.trafficMap(self,e),sx,sy,gx,gy)
      e.avoidCongestion=false
    end
    if not e.path then
      e.path=Path.search(Movement.clearanceMap(self,e),sx,sy,gx,gy)
    end
    e.pathTime=1.5
  end
  e.pathTime=e.pathTime-dt
  -- nil = unreachable; {} = no remaining waypoints. Neither means that
  -- the unit is entitled to walk directly through an obstacle.
  if not e.path then return false end
  while #e.path>0 do
    local waypoint=e.path[1]
    if distance(e.x,e.y,waypoint.x*SIZE,waypoint.y*SIZE)<1.5 then
      table.remove(e.path,1)
    else break end
  end
  if #e.path==0 then
    local gx=math.floor(x/SIZE+.5);local gy=math.floor(y/SIZE+.5)
    if gx>=1 and gx<=self.w and gy>=1 and gy<=self.h
       and not self.blocked[gy*self.w+gx] then
      -- Finish a free ground order with sub-tile precision.
      local d=distance(e.x,e.y,x,y)
      if d<2 then return true end
    else return true end
  end
  local waypoint=e.path[1]
  local tx,ty=waypoint and waypoint.x*SIZE or x,waypoint and waypoint.y*SIZE or y
  local d=distance(e.x,e.y,tx,ty)
  if d<=0.001 then return true end
  local step=math.min(st.speed*dt,d)
  local moved,steered=Movement.advance(self,e,tx,ty,step)
  if moved then
    e.moving=true
    -- A unit that keeps sidestepping but never gets nearer to a grid
    -- waypoint is in traffic congestion, even though it is technically
    -- changing coordinates. Request a fresh route around occupied tiles.
    local remaining=distance(e.x,e.y,tx,ty)
    local progress=d-remaining
    -- Sidestepping toward a waypoint is useful; do not repeatedly erase
    -- that route. Accumulate time only for lateral/no-progress movement.
    e.steerTime=(steered and progress<math.max(0.05,step*0.12))
      and ((e.steerTime or 0)+dt) or 0
    e.blockedTime=0
    if e.steerTime>=0.4 then
      e.path=nil;e.pathTime=0;e.avoidCongestion=true;e.steerTime=0
    end
    return true
  end
  -- Persistent traffic congestion triggers a route around the occupied
  -- cells. Replan at most once per ~0.5 s to avoid frame-dependent thrash.
  e.steerTime=0
  e.blockedTime=(e.blockedTime or 0)+dt
  if e.blockedTime>=0.5 then
    e.path=nil;e.pathTime=0;e.avoidCongestion=true;e.blockedTime=0
  end
  return false
end
function World:update(dt)
  if self.result then return end
  -- Fixed simulation tick. Rendering frame rate must not control how often
  -- income, movement, construction or attacks are calculated.
  self.tickRemainder=(self.tickRemainder or 0)+math.min(math.max(dt,0),.25)
  local tick=1/30
  local steps=0
  while self.tickRemainder+1e-9>=tick and steps<8 and not self.result do
    self.tickRemainder=self.tickRemainder-tick
    self:_tick(tick)
    steps=steps+1
  end
end
function World:effect(kind,x,y,lifetime)
  self.effects=self.effects or {}
  if #self.effects>=80 then table.remove(self.effects,1) end
  self.effects[#self.effects+1]={kind=kind,x=x,y=y,age=0,duration=lifetime or 0.5}
end
function World:_tick(dt)
  self.effects=self.effects or {}
  for i=#self.effects,1,-1 do
    local fx=self.effects[i]
    fx.age=fx.age+dt
    if fx.age>=fx.duration then table.remove(self.effects,i) end
  end
  self.elapsed=self.elapsed+dt
  self.noticeTimer=math.max(0,self.noticeTimer-dt)
  self.incomeTime=self.incomeTime+dt
  if self.incomeTime>=1 then
    self.incomeTime=self.incomeTime-1
    for team=1,2 do
      local aliveHQ=false
      for _,e in ipairs(self.entities) do if e.alive and e.kind=='hq' and e.team==team then aliveHQ=true end end
      if aliveHQ then self.money[team]=self.money[team]+self.income[team] end
    end
  end
  self.aiTime=self.aiTime+dt
  if self.aiTime>=4 then
    self.aiTime=self.aiTime-4
    local enemyCount=0
    for _,e in ipairs(self.entities) do if e.alive and e.team==2 and not e.building then enemyCount=enemyCount+1 end end
    if enemyCount<42 then
      for _,e in ipairs(self.entities) do
        if e.alive and e.team==2 and e.queue<2 and (e.kind=='factory' or e.kind=='barracks') then
          local kind=e.kind=='barracks' and 'infantry' or 'tank'
          if self.money[2]>=STATS[kind].cost then
            self.money[2]=self.money[2]-STATS[kind].cost
            e.queue=e.queue+1
            e.production=e.production>0 and e.production or (kind=='tank' and 8 or 4)
          end
        end
      end
    end
    -- Enviar tropas inimigas na direcao da base do jogador
    local home
    for _,e in ipairs(self.entities) do if e.alive and e.kind=='hq' and e.team==1 then home=e;break end end
    if home then
      for _,e in ipairs(self.entities) do
        if e.alive and e.team==2 and not e.building and (not e.order or self:random(3)==1) then
          e.order={x=home.x,y=home.y,target=home.id};e.path=nil;e.pathTime=0
        end
      end
    end
  end
  for _,e in ipairs(self.entities) do
    -- A destroyed headquarters decides the match once. Never allow later
    -- entities in this same simulation step to overwrite that result.
    if self.result then break end
    if e.alive then
      e.cooldown=math.max(0,e.cooldown-dt)
      e.animTime=(e.animTime or 0)+dt
      e.moving=false
      local firedThisTick=false
      e.firePulse=math.max(0,(e.firePulse or 0)-dt)
      e.hitPulse=math.max(0,(e.hitPulse or 0)-dt)
      if e.building and e.queue>0 then
        e.production=e.production-dt
        if e.production<=0 then
          local kind=e.kind=='factory' and 'tank' or 'infantry'
          local spawn=self:spawn(e,kind)
          if spawn then
            e.queue=e.queue-1
            e.production=e.queue>0 and (kind=='tank' and 8 or 4) or 0
          else e.production=1 end
        end
      end
      if e.kind=='infantry' or e.kind=='tank' or e.kind=='turret' then
        local st=STATS[e.kind]
        local enemy,d=self:nearestEnemy(e,st.range)
        local manualTarget=nil
        if not e.building and e.order and e.order.manualAttack and e.order.target then
          manualTarget=self:findEntity(e.order.target)
          if not manualTarget or manualTarget.team==e.team then
            -- Never chase the last known coordinates of an already dead enemy.
            e.order=nil
          else
            local manualDist=self:targetDistance(e,manualTarget)
            -- Explicit attack orders take precedence over automatic target
            -- selection, including while the requested target is far away.
            enemy=(manualDist<st.range) and manualTarget or nil
            d=manualDist
          end
        end
        if enemy and e.cooldown==0 then
          enemy.hp=enemy.hp-st.dmg;e.cooldown=st.cooldown
          e.firePulse=0.15
          firedThisTick=true
          if not e.building then
            e.angle=(math.atan2 and math.atan2(enemy.y-e.y,enemy.x-e.x))
              or math.atan(enemy.y-e.y,enemy.x-e.x)
          end
          enemy.hitPulse=0.16
          -- Visual-only events never consume gameplay RNG.
          self:effect('impact',enemy.x,enemy.y,0.22)
          if enemy.hp<=0 then
            enemy.hp=0;enemy.alive=false;self.selected[enemy.id]=nil
            self:effect('explosion',enemy.x,enemy.y,0.55)
            if enemy.building then self:refreshBlocked() end
            if enemy.kind=='hq' then self.result=enemy.team==2 and 'VITORIA' or 'DERROTA' end
          end
        end
        if not e.building and not enemy then
          local o=e.order
          if o then
            local goal=o.target and self:findEntity(o.target) or nil
            if o.target and not goal then
              -- Invalidate a target-based order when the target disappears.
              e.order=nil
              o=nil
            end
            if o then
            local tx=goal and goal.x or o.x
            local ty=goal and goal.y or o.y
            if distance(e.x,e.y,tx,ty)>(goal and st.range*0.8 or 6) then
              local moved=self:navigate(e,tx,ty,dt)
              if moved and not goal and distance(e.x,e.y,tx,ty)<6 then e.order=nil end
            elseif not goal then e.order=nil end
            end -- order still valid
          end
        end
      end
      -- Rendering-only timing: the frame index never affects attack cadence.
      local sprite=(e.team==1 and 'blue_' or 'red_')..e.kind
      Animation.advance(e,dt,firedThisTick,Art.sequenceDuration(sprite,'attack'))
    end
  end
end
function World:drawTerrain(camx,camy,viewH)
  local left=math.max(1,math.floor(camx/SIZE))
  local right=math.min(self.w,math.ceil((camx+240)/SIZE)+1)
  local top=math.max(1,math.floor(camy/SIZE))
  local bottom=math.min(self.h,math.ceil((camy+viewH)/SIZE)+1)
  for y=top,bottom do for x=left,right do
    local sx=(x-1)*SIZE-camx;local sy=(y-1)*SIZE-camy
    Art.draw(self.terrain[y][x],sx,sy,SIZE+0.2,SIZE+0.2)
  end end
end
function World:draw(camx,camy,viewH)
  love.graphics.stencil(function() love.graphics.rectangle("fill",0,26,240,viewH) end,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.push();love.graphics.translate(0,26)
  self:drawTerrain(camx,camy,viewH)
  -- Objects with height (trees, rocks, buildings and troops) share one
  -- ground-Y painter order. Previously obstacles were drawn under *every*
  -- soldier, making troops visible through foreground vegetation.
  local drawable={}
  for i,o in ipairs(self.obstacles) do
    drawable[#drawable+1]={y=o.y*SIZE,order=0,id=i,obstacle=o}
  end
  for _,e in ipairs(self.entities) do
    if e.alive then drawable[#drawable+1]={y=e.y,order=1,id=e.id,entity=e} end
  end
  table.sort(drawable,function(a,b)
    if a.y~=b.y then return a.y<b.y end
    if a.order~=b.order then return a.order<b.order end
    return a.id<b.id
  end)
  for _,object in ipairs(drawable) do
    if object.obstacle then
      local o=object.obstacle
      local x,y=o.x*SIZE-camx,o.y*SIZE-camy
      if x>-45 and y>-45 and x<270 and y<viewH+45 then
        Art.draw(o.typeName,x-19,y-20,38,35)
      end
    else
    local e=object.entity
    local sx,sy=e.x-camx,e.y-camy
    local size=STATS[e.kind].size
    if sx>-80 and sx<320 and sy>-80 and sy<viewH+80 then
      love.graphics.setColor(0,0,0,.23)
      love.graphics.ellipse('fill',sx,sy+size*.28,size*.40,size*.15)
      love.graphics.setColor(1,1,1,1)
      if self.selected[e.id] then
        love.graphics.setColor(.34,1,.25,.85)
        love.graphics.circle('line',sx,sy,size*.6)
        love.graphics.setColor(1,1,1,1)
      end
      local state=e.animationState or Animation.state(e)
      local visualTime=e.animationTime or e.animTime or 0
      local artName=(e.team==1 and 'blue_' or 'red_')..e.kind
      local offset=(e.building or Art.hasSequence(artName,state)) and 0
        or Animation.offset(state,visualTime)
      local opacity=(e.hitPulse or 0)>0 and .67 or 1
      local rotation=e.building and 0 or e.angle
      Art.drawEntity(artName,sx,sy+offset,size,size,rotation,opacity,state,visualTime)
      if (e.firePulse or 0)>0 then
        love.graphics.setColor(1,.75,.2,math.min(1,e.firePulse/.15))
        love.graphics.circle('fill',sx+math.cos(e.angle)*size*.43,
          sy+math.sin(e.angle)*size*.43,2.4)
        love.graphics.setColor(1,1,1,1)
      end
      if e.hp<e.maxhp or self.selected[e.id] then
        local ww=math.max(12,size*.8)
        love.graphics.setColor(.08,.08,.09,.95)
        love.graphics.rectangle('fill',sx-ww/2,sy-size*.7-5,ww,3)
        love.graphics.setColor(e.team==1 and .2 or .95,e.team==1 and .9 or .3,.2,1)
        love.graphics.rectangle('fill',sx-ww/2,sy-size*.7-5,ww*e.hp/e.maxhp,3)
        love.graphics.setColor(1,1,1,1)
      end
    end
    end -- entity object
  end
  for _,fx in ipairs(self.effects or {}) do
    local x,y=fx.x-camx,fx.y-camy
    local p=math.min(1,fx.age/fx.duration)
    if x>-48 and x<288 and y>-48 and y<viewH+48 then
      if fx.kind=='explosion' then
        Art.drawEntity('explosion',x,y,18+24*p,18+24*p,0,1-p,'death',fx.age)
      elseif fx.kind=='impact' then
        love.graphics.setColor(1,.79,.23,(1-p)*.8)
        love.graphics.circle('line',x,y,2+5*p)
      elseif fx.kind=='order' then
        love.graphics.setColor(.3,1,.4,1-p)
        love.graphics.circle('line',x,y,4+8*p)
        love.graphics.line(x-5,y,x+5,y)
        love.graphics.line(x,y-5,x,y+5)
      end
      love.graphics.setColor(1,1,1,1)
    end
  end
  if self.buildMode and self.preview then
    local x,y=self.preview.x-camx,self.preview.y-camy
    local valid=self:canBuild(self.preview.x,self.preview.y,self.buildMode)
      and self.money[1]>=self:cost(self.buildMode)
    local size=STATS[self.buildMode].size
    love.graphics.setColor(valid and .22 or 1, valid and 1 or .2,.25,.73)
    love.graphics.rectangle('line',x-size*.5,y-size*.5,size,size)
    love.graphics.setColor(1,1,1,1)
    Art.drawEntity('blue_'..self.buildMode,x,y,size,size,0,.52,'idle',0)
  end
  love.graphics.pop();love.graphics.setStencilTest()
end
return World
