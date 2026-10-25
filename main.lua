-- Art of War 2 Lua: playable technical prototype, NOT a bytecode-equivalent port.
local Art=require('src.art')
local UI=require('src.ui')
local World=require('src.world')
local Save=require('src.save')
local screen='menu';local game=nil;local paused=false
local scale,ox,oy=1,0,0
local drag=nil;local gesture=nil
local virtualW,virtualH=240,320
local uiFont
local function touchOnlyPlatform()
  if love.system and love.system.getOS then
    local os=love.system.getOS()
    return os=='Android' or os=='iOS'
  end
  return false
end
local function viewCoords(px,py)
  return (px-ox)/scale,(py-oy)/scale
end
local function mapCoords(x,y)
  return x+game.camera.x,y-26+game.camera.y
end
local function updateScale()
  local w,h=love.graphics.getDimensions()
  scale=math.min(w/virtualW,h/virtualH)
  ox=math.floor((w-virtualW*scale)/2)
  oy=math.floor((h-virtualH*scale)/2)
end
local function cameraClamp()
  if not game then return end
  game.camera.x=math.max(0,math.min(game.camera.x,game.w*16-240))
  game.camera.y=math.max(0,math.min(game.camera.y,game.h*16-230))
end
local function start(mode,level)
  game=World.new(mode,level or 1)
  paused=false;screen='game';cameraClamp()
end
local function currentSelectedBuilding()
  local s=game:selectedList()
  if #s==1 and s[1].building then return s[1] end
  return nil
end
local function act(id)
  if not id then return end
  if id=='menu' or id=='back_to_menu' then screen='menu';paused=false;game=nil
  elseif id=='campaign' then start('campaign',1)
  elseif id=='scenario' then start('scenario',1)
  elseif id=='help' then screen='help'
  elseif id=='load' then
    local loaded,err=Save.read(World)
    if loaded then game=loaded;screen='game';paused=false else print(err) end
  elseif id=='pause' then if game then paused=not paused end
  elseif id=='resume' then paused=false
  elseif id=='restart' then if game then start(game.mode,game.level) end
  elseif id=='save' then if game then local ok,err=Save.write(game);game:toast(ok and 'Jogo salvo.' or tostring(err)) end
  elseif game and not paused and not game.result then
    if id=='build_barracks' then game.buildMode='barracks';game:toast('Escolha um local vazio no mapa.')
    elseif id=='build_factory' then game.buildMode='factory';game:toast('Escolha um local vazio no mapa.')
    elseif id=='build_turret' then game.buildMode='turret';game:toast('Escolha um local vazio no mapa.')
    elseif id=='train_infantry' then game:train(currentSelectedBuilding(),'infantry')
    elseif id=='train_tank' then game:train(currentSelectedBuilding(),'tank')
    elseif id=='cancel' then game:select(nil);game.buildMode=nil end
  end
end
function love.load()
  love.graphics.setDefaultFilter('nearest','nearest')
  uiFont=love.graphics.newFont(10)
  uiFont:setFilter('nearest','nearest');love.graphics.setFont(uiFont)
  Art.load();updateScale()
end
function love.resize() updateScale() end
function love.update(dt)
  if screen=='game' and game then
    if not paused and not game.result then
      local vx,vy=0,0
      if love.keyboard.isDown('left','a') then vx=vx-1 end
      if love.keyboard.isDown('right','d') then vx=vx+1 end
      if love.keyboard.isDown('up','w') then vy=vy-1 end
      if love.keyboard.isDown('down','s') then vy=vy+1 end
      local mod=love.keyboard.isDown('lshift','rshift') and 2 or 1
      game.camera.x=game.camera.x+vx*125*dt*mod
      game.camera.y=game.camera.y+vy*125*dt*mod
      cameraClamp()
      game:update(dt)
    end
  end
end
function love.draw()
  updateScale()
  love.graphics.clear(.02,.03,.05,1)
  love.graphics.push()
  love.graphics.translate(ox,oy);love.graphics.scale(scale)
  love.graphics.setFont(uiFont)
  if screen=='menu' then UI.menu()
  elseif screen=='help' then UI.help()
  elseif screen=='game' and game then
    game:draw(game.camera.x,game.camera.y,230)
    if drag and drag.selecting then
      local x1,y1=drag.x,drag.y
      local x2,y2=drag.currentX,drag.currentY
      love.graphics.setColor(.2,.85,1,.18)
      love.graphics.rectangle('fill',math.min(x1,x2),math.min(y1,y2),math.abs(x1-x2),math.abs(y1-y2))
      love.graphics.setColor(.2,.85,1,1)
      love.graphics.rectangle('line',math.min(x1,x2),math.min(y1,y2),math.abs(x1-x2),math.abs(y1-y2))
      love.graphics.setColor(1,1,1,1)
    end
    UI.hud(game,paused)
  end
  love.graphics.pop()
end
local function pointerDown(px,py,button,touch)
  local x,y=viewCoords(px,py)
  if x<0 or y<0 or x>=240 or y>=320 then return end
  local id,hit=UI.hit(x,y)
  if hit then act(id);return end
  if screen~='game' or paused or game.result then return end
  if x<60 and y>=260 then
    game.camera.x=(x-4)/54*game.w*16-120
    game.camera.y=(y-262)/52*game.h*16-115
    cameraClamp();return
  end
  if y<26 or y>=256 then return end
  local wx,wy=mapCoords(x,y)
  if button==2 then game:moveSelected(wx,wy);return end
  if button==3 then drag={panning=true,x=x,y=y};return end
  if game.buildMode then
    game:placeBuilding(game.buildMode,wx,wy)
    return
  end
  drag={x=x,y=y,currentX=x,currentY=y,worldX=wx,worldY=wy,selecting=false,touch=touch}
end
local function pointerMove(px,py)
  if not drag or not game then return end
  local x,y=viewCoords(px,py)
  if drag.panning then
    game.camera.x=game.camera.x-(x-drag.x)
    game.camera.y=game.camera.y-(y-drag.y)
    drag.x=x;drag.y=y;cameraClamp()
  elseif drag.touch then
    local dx,dy=x-drag.currentX,y-drag.currentY
    if math.abs(x-drag.x)+math.abs(y-drag.y)>9 then drag.panning=true end
    if drag.panning then game.camera.x=game.camera.x-dx;game.camera.y=game.camera.y-dy;cameraClamp() end
    drag.currentX=x;drag.currentY=y
  else
    drag.currentX=x;drag.currentY=y
    drag.selecting=math.abs(x-drag.x)+math.abs(y-drag.y)>8
  end
end
local function pointerUp(px,py,button)
  if not drag or not game then return end
  if drag.panning then drag=nil;return end
  local x,y=viewCoords(px,py)
  if drag.selecting then
    local x1,y1=mapCoords(drag.x,drag.y)
    local x2,y2=mapCoords(x,y)
    game:selectBox(x1,y1,x2,y2,love.keyboard.isDown('lshift','rshift'))
  else
    local wx,wy=mapCoords(x,y)
    local e=game:entityAt(wx,wy)
    if e and e.team==1 then
      game:select(e,love.keyboard.isDown('lshift','rshift'))
    elseif next(game.selected) then
      game:moveSelected(wx,wy)
    else
      game:select(nil)
    end
  end
  drag=nil
end
function love.mousepressed(x,y,button)
  if touchOnlyPlatform() then return end
  pointerDown(x,y,button,false)
end
function love.mousemoved(x,y)
  if touchOnlyPlatform() then return end
  pointerMove(x,y)
end
function love.mousereleased(x,y,button)
  if touchOnlyPlatform() then return end
  pointerUp(x,y,button)
end
function love.wheelmoved(x,y)
  if screen=='game' and game and not paused then
    game.camera.y=game.camera.y-y*32;game.camera.x=game.camera.x-x*32
    cameraClamp()
  end
end
function love.touchpressed(id,x,y)
  if gesture and gesture.id~=id then return end
  gesture={id=id}
  pointerDown(x,y,1,true)
end
function love.touchmoved(id,x,y)
  if gesture and gesture.id==id then pointerMove(x,y) end
end
function love.touchreleased(id,x,y)
  if gesture and gesture.id==id then pointerUp(x,y,1);gesture=nil end
end
function love.keypressed(key)
  if key=='escape' then
    if screen=='help' then screen='menu'
    elseif screen=='game' and game then
      if game.buildMode then game.buildMode=nil
      elseif game.result then screen='menu';game=nil
      else paused=not paused end
    else love.event.quit() end
  elseif key=='f5' and game then act('save')
  elseif key=='f9' then act('load')
  elseif key=='space' and game then paused=not paused
  elseif screen=='game' and game and not paused and not game.result then
    if key=='q' then act('build_barracks')
    elseif key=='e' then act('build_factory')
    elseif key=='t' then act('build_turret')
    elseif key=='i' then act('train_infantry')
    elseif key=='k' then act('train_tank')
    elseif key=='delete' then game:select(nil) end
  end
end
