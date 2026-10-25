local Art = require('src.art')
local Path = require('src.path')
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
local function fcenter(e) return e.x, e.y end
local function deep(value)
  if type(value)~='table' then return value end
  local out={};for k,v in pairs(value) do out[k]=deep(v) end;return out
end
function World.new(mode,level,seed)
  local self=setmetatable({},World)
  self.mode=mode or 'scenario';self.level=level or 1
  self.seed=seed or 731;self.elapsed=0;self.w=46;self.h=38;self.tile=SIZE
  self.money={[1]=900,[2]=850};self.income={[1]=8,[2]=8}
  self.entities={};self.selected={};self.nextId=0;self.result=nil
  self.buildMode=nil;self.notice='';self.noticeTimer=0
  self.camera={x=15,y=108};self.aiTime=0;self.incomeTime=0
  self.terrain={};self.blocked={};self.obstacles={};self.queues={}
  local seedvar=self.seed
  local function rand(n)
    seedvar=(seedvar*1103515245+12345)%2147483647
    return (seedvar%n)+1
  end
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
    building=b,alive=true,cooldown=0,queue=0,production=0,angle=0,order=nil,path=nil}
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
  local n=0
  local target=self:entityAt(x,y)
  for _,e in ipairs(self:selectedList()) do
    if not e.building then
      local goal={x=x,y=y,target=target and target.team~=e.team and target.id or nil}
      e.order=goal;e.path=nil;e.pathTime=0;n=n+1
    end
  end
  if n>0 then self:toast(n..' unidades receberam ordens.') end
end
function World:cost(kind) return STATS[kind] and STATS[kind].cost or 0 end
function World:canBuild(x,y)
  if x<40 or y<40 or x>self.w*SIZE-40 or y>self.h*SIZE-40 then return false end
  for _,e in ipairs(self.entities) do
    if e.alive and e.building and distance(x,y,e.x,e.y)<72 then return false end
  end
  for _,o in ipairs(self.obstacles) do
    if distance(x,y,o.x*SIZE,o.y*SIZE)<32 then return false end
  end
  return true
end
function World:placeBuilding(kind,x,y)
  if not STATS[kind] or (kind~='barracks' and kind~='factory' and kind~='turret') then return false end
  if self.money[1]<self:cost(kind) then self:toast('Creditos insuficientes.');return false end
  if not self:canBuild(x,y) then self:toast('Local bloqueado para construcao.');return false end
  self.money[1]=self.money[1]-self:cost(kind)
  self:add(kind,1,x,y);self.buildMode=nil
  self:toast('Edificio construido.')
  return true
end
function World:train(building,kind)
  if not building or not building.building or building.team~=1 then return false end
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
      local gridx=math.floor(x/SIZE+.5);local gridy=math.floor(y/SIZE+.5)
      if x>0 and x<self.w*SIZE and y>0 and y<self.h*SIZE and not self.blocked[gridy*self.w+gridx] and not self:entityAt(x,y) then
        return self:add(kind,building.team,x,y)
      end
    end
  end
  return nil
end
function World:nearestEnemy(e,range)
  local best=nil;local bestDist=range or math.huge
  for _,other in ipairs(self.entities) do
    if other.alive and other.team~=e.team then
      local d=distance(e.x,e.y,other.x,other.y)
      -- Dano por distancia ate a borda de edificios, nao apenas ao centro.
      if other.building then d=d-(STATS[other.kind].size*.42) end
      if d<bestDist then best=other;bestDist=d end
    end
  end
  return best,bestDist
end
function World:navigate(e,x,y,dt)
  local st=STATS[e.kind]
  if not e.path or #e.path==0 or (e.pathTime or 0)<=0 then
    self:refreshBlocked()
    local sx=math.floor(e.x/SIZE+.5);local sy=math.floor(e.y/SIZE+.5)
    local gx=math.floor(x/SIZE+.5);local gy=math.floor(y/SIZE+.5)
    e.path=Path.search(self,sx,sy,gx,gy)
    e.pathTime=2.3
  end
  e.pathTime=e.pathTime-dt
  local tx,ty=x,y
  if e.path and #e.path>0 then
    local nextCell=e.path[1]
    tx=nextCell.x*SIZE;ty=nextCell.y*SIZE
    if distance(e.x,e.y,tx,ty)<5 then table.remove(e.path,1) end
  end
  local d=distance(e.x,e.y,tx,ty)
  if d>2 then
    -- Nao atravesse rochas, arvores ou edificios. A* replaneja se bloqueado.
    local testX=e.x+(tx-e.x)/d*math.min(st.speed*dt,d)
    local testY=e.y+(ty-e.y)/d*math.min(st.speed*dt,d)
    local cx=math.floor(testX/SIZE+.5)
    local cy=math.floor(testY/SIZE+.5)
    if self.blocked[cy*self.w+cx] then
      e.path=nil;e.pathTime=0
      return
    end
    local angle=math.atan2 and math.atan2(ty-e.y,tx-e.x) or math.atan(ty-e.y,tx-e.x)
    local speed=st.speed*dt
    e.x=e.x+math.cos(angle)*math.min(speed,d)
    e.y=e.y+math.sin(angle)*math.min(speed,d)
    e.angle=angle
  end
end
function World:update(dt)
  if self.result then return end
  dt=math.min(dt,0.08)
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
    self.aiTime=0
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
        if e.alive and e.team==2 and not e.building and (not e.order or self.rand(3)==1) then
          e.order={x=home.x,y=home.y,target=home.id};e.path=nil;e.pathTime=0
        end
      end
    end
  end
  for _,e in ipairs(self.entities) do
    if e.alive then
      e.cooldown=math.max(0,e.cooldown-dt)
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
        if enemy and e.cooldown==0 then
          enemy.hp=enemy.hp-st.dmg;e.cooldown=st.cooldown
          if enemy.hp<=0 then
            enemy.hp=0;enemy.alive=false;self.selected[enemy.id]=nil
            if enemy.kind=='hq' then self.result=enemy.team==2 and 'VITORIA' or 'DERROTA' end
          end
        end
        if not e.building and not enemy then
          local o=e.order
          if o then
            local goal=nil
            if o.target then
              for _,candidate in ipairs(self.entities) do
                if candidate.id==o.target and candidate.alive then goal=candidate;break end
              end
            end
            local tx=goal and goal.x or o.x
            local ty=goal and goal.y or o.y
            if distance(e.x,e.y,tx,ty)>(goal and st.range*0.8 or 6) then
              self:navigate(e,tx,ty,dt)
            elseif not goal then e.order=nil end
          end
        end
      end
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
  for _,o in ipairs(self.obstacles) do
    local x=o.x*SIZE-camx;local y=o.y*SIZE-camy
    if x>-45 and y>-45 and x<270 and y<viewH+45 then
      Art.draw(o.typeName,x-19,y-20,38,35)
    end
  end
end
function World:draw(camx,camy,viewH)
  love.graphics.stencil(function() love.graphics.rectangle("fill",0,26,240,viewH) end,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.push();love.graphics.translate(0,26)
  self:drawTerrain(camx,camy,viewH)
  for _,e in ipairs(self.entities) do
    if e.alive then
      local sx=e.x-camx;local sy=e.y-camy
      local sz=STATS[e.kind].size
      if sx>-80 and sx<320 and sy>-80 and sy<viewH+80 then
        if self.selected[e.id] then
          love.graphics.setColor(.34,1,.25,.8)
          love.graphics.circle('line',sx,sy,sz*.6)
          love.graphics.setColor(1,1,1,1)
        end
        local artName=(e.team==1 and 'blue_' or 'red_')..e.kind
        if e.building then
          Art.draw(artName,sx-sz*.5,sy-sz*.55,sz,sz)
        else
          Art.draw(artName,sx-sz*.5,sy-sz*.5,sz,sz,e.angle)
        end
        if e.hp<e.maxhp or self.selected[e.id] then
          local ww=math.max(12,sz*.8)
          love.graphics.setColor(.08,.08,.09,.95)
          love.graphics.rectangle('fill',sx-ww/2,sy-sz*.7-5,ww,3)
          love.graphics.setColor(e.team==1 and .2 or .95,e.team==1 and .9 or .3,.2,1)
          love.graphics.rectangle('fill',sx-ww/2,sy-sz*.7-5,ww*e.hp/e.maxhp,3)
          love.graphics.setColor(1,1,1,1)
        end
      end
    end
  end
  love.graphics.pop();love.graphics.setStencilTest()
end
return World
