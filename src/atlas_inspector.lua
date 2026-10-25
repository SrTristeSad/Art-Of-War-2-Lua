-- Ferramenta de engenharia reversa (F2). Nao integra a interface original.
-- Mostra os PNGs brutos sem modificar os atlas ou criar frames ficticios.
local Inspector={active=false,index=1,zoom=1,files={},cache={},mouseX=nil,mouseY=nil,dragging=nil}
local DIR='assets/original/'
local AREA={x=10,y=43,w=220,h=222}
local function normalizedFilename(a)
  local head,num,tail=a:match('^([%a%d]+_)(%d+)(.*)%.png$')
  return head or a,tonumber(num) or -1,tail or ''
end
local function order(a,b)
  local ah,an,at=normalizedFilename(a)
  local bh,bn,bt=normalizedFilename(b)
  if ah~=bh then return ah<bh end
  if an~=bn then return an<bn end
  return at<bt
end
function Inspector.initialize()
  Inspector.files={};Inspector.cache={};Inspector.index=1;Inspector.zoom=1
  local fs=love.filesystem
  local entries=(fs and fs.getDirectoryItems and fs.getDirectoryItems(DIR)) or {}
  for _,entry in ipairs(entries) do
    if entry:match('%.png$') and fs.getInfo(DIR..entry,'file') then
      Inspector.files[#Inspector.files+1]=entry
    end
  end
  table.sort(Inspector.files,order)
end
function Inspector.toggle()
  if not Inspector.active and #Inspector.files==0 then Inspector.initialize() end
  Inspector.active=not Inspector.active
  Inspector.dragging=nil
end
function Inspector.close() Inspector.active=false;Inspector.dragging=nil end
function Inspector.selectedFile() return Inspector.files[Inspector.index] end
local function currentImage()
  local filename=Inspector.selectedFile()
  if not filename then return nil end
  if Inspector.cache[filename]==nil then
    local ok,img=pcall(love.graphics.newImage,DIR..filename)
    if ok and img then img:setFilter('nearest','nearest');Inspector.cache[filename]=img end
  end
  return Inspector.cache[filename]
end
function Inspector.step(shift)
  if #Inspector.files==0 then return end
  Inspector.index=((Inspector.index-1+shift)%#Inspector.files)+1
  Inspector.zoom=1;Inspector.dragging=nil
end
function Inspector.changeZoom(delta)
  Inspector.zoom=math.max(0.5,math.min(8,Inspector.zoom*(delta>0 and 1.25 or .8)))
end
function Inspector.keypressed(key)
  if key=='escape' or key=='f2' then Inspector.close();return true end
  if key=='right' or key=='d' then Inspector.step(1)
  elseif key=='left' or key=='a' then Inspector.step(-1)
  elseif key=='pageup' then Inspector.step(-10)
  elseif key=='pagedown' then Inspector.step(10)
  elseif key=='home' then Inspector.index=1;Inspector.zoom=1
  elseif key=='end' then Inspector.index=math.max(1,#Inspector.files);Inspector.zoom=1
  elseif key=='+' or key=='=' or key=='kp+' then Inspector.changeZoom(1)
  elseif key=='-' or key=='kp-' then Inspector.changeZoom(-1)
  else return false end
  return true
end
function Inspector.mousepressed(x,y,button)
  if not Inspector.active then return false end
  if button==1 then
    if y>=275 then
      if x<82 then Inspector.step(-1)
      elseif x>=158 then Inspector.step(1)
      else Inspector.zoom=1 end
    elseif x>=AREA.x and x<AREA.x+AREA.w and y>=AREA.y and y<AREA.y+AREA.h then
      Inspector.mouseX,Inspector.mouseY=x,y
    end
  elseif button==2 then Inspector.close() end
  return true
end
function Inspector.mousemoved(x,y)
  Inspector.mouseX,Inspector.mouseY=x,y
end
function Inspector.wheelmoved(y)
  if not Inspector.active then return false end
  if y~=0 then Inspector.changeZoom(y) end
  return true
end
local function write(t,x,y)
  love.graphics.setColor(.93,.97,1,1)
  love.graphics.print(t,x,y)
end
function Inspector.draw()
  if not Inspector.active then return end
  local g=love.graphics
  g.setColor(.015,.035,.06,1);g.rectangle('fill',0,0,240,320)
  g.setColor(.16,.47,.63,1);g.rectangle('fill',0,0,240,2)
  write('INSPECAO ATLAS ORIGINAL - F2',7,7)
  local file=Inspector.selectedFile()
  local image=currentImage()
  write(string.format('%d/%d  %s',Inspector.index,#Inspector.files,file or 'Sem imagens'),7,24)
  -- A chessboard is important: most sprite atlas pixels are transparent.
  for by=0,math.ceil(AREA.h/10)-1 do
    for bx=0,math.ceil(AREA.w/10)-1 do
      local light=(bx+by)%2==0
      g.setColor(light and .25 or .18,light and .29 or .22,light and .32 or .26,1)
      local xx,yy=AREA.x+bx*10,AREA.y+by*10
      g.rectangle('fill',xx,yy,math.min(10,AREA.x+AREA.w-xx),math.min(10,AREA.y+AREA.h-yy))
    end
  end
  if image then
    local iw,ih=image:getDimensions()
    local fit=math.min(AREA.w/iw,AREA.h/ih)
    local scale=fit*Inspector.zoom
    local x=AREA.x+(AREA.w-iw*scale)/2
    local y=AREA.y+(AREA.h-ih*scale)/2
    -- Native atlas size and aspect ratio are retained. Oversized views are clipped.
    g.stencil(function() g.rectangle('fill',AREA.x,AREA.y,AREA.w,AREA.h) end,'replace',1)
    g.setStencilTest('greater',0)
    g.setColor(1,1,1,1);g.draw(image,x,y,0,scale,scale)
    g.setStencilTest()
    local mx,my=Inspector.mouseX,Inspector.mouseY
    if mx and mx>=AREA.x and mx<AREA.x+AREA.w and my>=AREA.y and my<AREA.y+AREA.h then
      local px,py=math.floor((mx-x)/scale),math.floor((my-y)/scale)
      if px>=0 and py>=0 and px<iw and py<ih then
        Inspector.pixelX,Inspector.pixelY=px,py
      else Inspector.pixelX=nil;Inspector.pixelY=nil end
    else Inspector.pixelX=nil;Inspector.pixelY=nil end
    write(string.format('%d x %d px  zoom %.2fx',iw,ih,Inspector.zoom),10,266)
  else
    Inspector.pixelX=nil;Inspector.pixelY=nil
    write('Nenhum PNG original encontrado.',15,147)
  end
  g.setColor(.26,.62,.79,1);g.rectangle('line',AREA.x-.5,AREA.y-.5,AREA.w+1,AREA.h+1)
  g.setColor(.10,.24,.36,1);g.rectangle('fill',8,279,68,21)
  g.rectangle('fill',86,279,68,21);g.rectangle('fill',164,279,68,21)
  write('< ANT',21,285);write('ZOOM 1x',96,285);write('PROX >',174,285)
  write(Inspector.pixelX and ('Pixel: '..Inspector.pixelX..', '..Inspector.pixelY)
     or 'Setas: PNG  |  roda: zoom',8,304)
  g.setColor(1,1,1,1)
end
return Inspector
