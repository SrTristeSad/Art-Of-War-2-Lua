-- Ferramenta de engenharia reversa (F2). Nao integra a interface original.
-- Mostra os PNGs brutos sem modificar os atlas ou criar frames ficticios.
local Regions=require('src.atlas_regions')
local Catalog=require('src.atlas_catalog')
local Draft=require('src.sequence_draft')
local Candidates=require('src.atlas_candidates')
local Compare=require('src.atlas_compare')
local Inspector={active=false,index=1,zoom=1,files={},cache={},mouseX=nil,mouseY=nil,dragging=nil,selection=nil,message=nil,showVerified=true,showCandidates=false,reviewOnly=true,candidateIndex=0,previewFrames={},previewTime=0,previewPlaying=false,previewFPS=8,exportCount=0,pinnedFrame=nil}
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
  Inspector.selection=nil;Inspector.message=nil;Inspector.dragging=nil;Inspector.candidateIndex=0
  Inspector.previewFrames={};Inspector.previewTime=0;Inspector.previewPlaying=false;Inspector.previewFPS=8
  Inspector.pinnedFrame=nil
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
  Inspector.zoom=1;Inspector.dragging=nil;Inspector.selection=nil;Inspector.message=nil;Inspector.candidateIndex=0
end
-- Suggested alpha components are unverified. They never become active sprites.
-- Keep the original indices stable even when only review-priority boxes are shown.
function Inspector.visibleCandidateIndices()
  local boxes=Candidates[Inspector.selectedFile()] or {}
  local result={}
  for index,box in ipairs(boxes) do
    if not Inspector.reviewOnly or box.priority=='review' then
      result[#result+1]=index
    end
  end
  return result
end
function Inspector.nextCandidate(direction)
  local boxes=Candidates[Inspector.selectedFile()] or {}
  local indices=Inspector.visibleCandidateIndices()
  if #indices==0 then Inspector.message='Sem candidatos no filtro';return false end
  local position=0
  for i,index in ipairs(indices) do
    if index==Inspector.candidateIndex then position=i;break end
  end
  local offset=direction and (direction<0 and -1 or 1) or 1
  if position==0 and offset<0 then position=1 end
  local nextIndex=indices[((position-1+offset)%#indices)+1]
  Inspector.candidateIndex=nextIndex
  local box=boxes[nextIndex]
  Inspector.selection={x=box.x,y=box.y,w=box.w,h=box.h}
  Inspector.message=string.format('Regiao %d/%d %s (nao verif.)',nextIndex,#boxes,box.reason or '')
  return true
end
function Inspector.changeZoom(delta)
  Inspector.zoom=math.max(0.5,math.min(8,Inspector.zoom*(delta>0 and 1.25 or .8)))
end
-- Keep the crop in source-image pixel coordinates; zoom must not affect it.
local function imagePlacement()
  local image=currentImage()
  if not image then return nil end
  local iw,ih=image:getDimensions()
  if iw<=0 or ih<=0 then return nil end
  local fit=math.min(AREA.w/iw,AREA.h/ih)
  local scale=fit*Inspector.zoom
  return AREA.x+(AREA.w-iw*scale)/2,AREA.y+(AREA.h-ih*scale)/2,scale,iw,ih
end
local function sourcePixel(x,y,clamp)
  local ix,iy,scale,iw,ih=imagePlacement()
  if not ix or not clamp and (x<AREA.x or x>=AREA.x+AREA.w or y<AREA.y or y>=AREA.y+AREA.h) then return nil end
  return Regions.imagePoint(x,y,ix,iy,scale,iw,ih,clamp)
end
function Inspector.saveSelection()
  local r=Inspector.selection
  local _,_,_,iw,ih=imagePlacement()
  local row,err=Regions.csvRow(Inspector.selectedFile(),r,iw or 0,ih or 0)
  if not row then Inspector.message=err;return false end
  local fs=love.filesystem
  local path='atlas_regions.csv'
  local exists=fs.getInfo(path,'file')
  local previous=exists and fs.read(path) or nil
  if exists and previous==nil then
    Inspector.message='Falha ao ler CSV existente';return false
  end
  if not exists then previous=Regions.HEADER end
  -- Do not create a malformed second header or truncate pre-existing data on read errors.
  if previous:sub(1,#Regions.HEADER)~=Regions.HEADER then
    Inspector.message='CSV existente invalido';return false
  end
  local ok,writeErr=fs.write(path,previous..row)
  Inspector.message=ok and ('Regiao registrada em '..path) or tostring(writeErr or 'Erro ao salvar')
  return not not ok
end
-- Pin a source rectangle for side-by-side comparison, including across atlas files.
-- Pinning never certifies a frame or changes an animation manifest.
function Inspector.pinSelection()
  local _,_,_,iw,ih=imagePlacement()
  local frame,err=Compare.capture(Inspector.selectedFile(),Inspector.selection,iw or 0,ih or 0)
  if not frame then Inspector.message=err;return false end
  Inspector.pinnedFrame=frame
  Inspector.message='Referencia fixada (H); L libera'
  return true
end
function Inspector.clearPinned()
  Inspector.pinnedFrame=nil
  Inspector.message='Referencia liberada'
end
-- Engineering-only animation candidate tool: never marks original frame order as verified.
function Inspector.addFrame()
  local file=Inspector.selectedFile()
  local _,_,_,iw,ih=imagePlacement()
  local ok,err=Draft.append(Inspector.previewFrames,file,Inspector.selection,iw or 0,ih or 0)
  if not ok then Inspector.message=err;return false end
  Inspector.previewTime=0
  Inspector.message='Quadro candidato '..#Inspector.previewFrames..'/64 registrado'
  return true
end
function Inspector.exportDraft()
  local fs=love.filesystem
  local previous=fs.getInfo('atlas_sequences_candidates.csv','file')
    and fs.read('atlas_sequences_candidates.csv') or nil
  if fs.getInfo('atlas_sequences_candidates.csv','file') and previous==nil then
    Inspector.message='Nao foi possivel ler CSV';return false
  end
  if previous==nil then previous=Draft.HEADER end
  if previous:sub(1,#Draft.HEADER)~=Draft.HEADER or #previous>1000000 then
    Inspector.message='CSV invalido ou muito grande';return false
  end
  local nextNumber=0
  for id in previous:gmatch('draft_(%d+)') do
    nextNumber=math.max(nextNumber,tonumber(id) or 0)
  end
  local rows,err=Draft.csvRows(string.format('draft_%04d',nextNumber+1),
    Inspector.previewFrames,Inspector.previewFPS)
  if not rows then Inspector.message=err;return false end
  local ok,msg=fs.write('atlas_sequences_candidates.csv',previous..rows)
  Inspector.message=ok and ('Rascunho '..(nextNumber+1)..' exportado (nao verificado)')
    or tostring(msg or 'Falha ao escrever CSV')
  return not not ok
end
function Inspector.update(dt)
  if Inspector.active and Inspector.previewPlaying and #Inspector.previewFrames>0 then
    Inspector.previewTime=Inspector.previewTime+math.min(math.max(0,dt or 0),.25)
    if Inspector.previewTime>10000 then Inspector.previewTime=Inspector.previewTime%1 end
  end
end
function Inspector.mousereleased(x,y,button)
  if not Inspector.active or button~=1 or not Inspector.dragging then return false end
  local px,py=sourcePixel(x,y,true)
  if px then Inspector.selection=Regions.rectangle(Inspector.dragging.x,Inspector.dragging.y,px,py) end
  Inspector.dragging=nil
  return true
end
function Inspector.keypressed(key)
  if key=='escape' or key=='f2' then Inspector.close();return true end
  if key=='right' or key=='d' then Inspector.step(1)
  elseif key=='left' or key=='a' then Inspector.step(-1)
  elseif key=='pageup' then Inspector.step(-10)
  elseif key=='pagedown' then Inspector.step(10)
  elseif key=='home' then Inspector.index=1;Inspector.zoom=1;Inspector.selection=nil;Inspector.dragging=nil
  elseif key=='end' then Inspector.index=math.max(1,#Inspector.files);Inspector.zoom=1;Inspector.selection=nil;Inspector.dragging=nil
  elseif key=='v' then Inspector.showVerified=not Inspector.showVerified
  elseif key=='b' then Inspector.showCandidates=not Inspector.showCandidates
  elseif key=='j' then Inspector.reviewOnly=not Inspector.reviewOnly;Inspector.candidateIndex=0;Inspector.selection=nil;Inspector.message=Inspector.reviewOnly and 'Filtro: revisao prioritaria' or 'Filtro: todas as regioes'
  elseif key=='n' then Inspector.nextCandidate(1)
  elseif key=='m' then Inspector.nextCandidate(-1)
  elseif key=='h' then Inspector.pinSelection()
  elseif key=='l' then Inspector.clearPinned()
  elseif key=='g' then Inspector.addFrame()
  elseif key=='p' then Inspector.previewPlaying=not Inspector.previewPlaying;Inspector.previewTime=0
  elseif key=='f' then Inspector.previewFPS=Inspector.previewFPS%16+1;Inspector.previewTime=0
  elseif key=='x' then Inspector.previewFrames={};Inspector.previewTime=0;Inspector.previewPlaying=false;Inspector.message='Sequencia candidata limpa'
  elseif key=='e' then Inspector.exportDraft()
  elseif key=='s' then Inspector.saveSelection()
  elseif key=='c' then Inspector.selection=nil;Inspector.dragging=nil;Inspector.message=nil
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
      local px,py=sourcePixel(x,y,false)
      if px then
        Inspector.dragging={x=px,y=py}
        Inspector.selection=Regions.rectangle(px,py,px,py)
        Inspector.candidateIndex=0
        Inspector.message=nil
      end
    end
  elseif button==2 then Inspector.close() end
  return true
end
function Inspector.mousemoved(x,y)
  Inspector.mouseX,Inspector.mouseY=x,y
  if Inspector.dragging then
    local px,py=sourcePixel(x,y,true)
    if px then Inspector.selection=Regions.rectangle(Inspector.dragging.x,Inspector.dragging.y,px,py) end
  end
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
    local x,y,scale,iw,ih=imagePlacement()
    -- Native atlas size and aspect ratio are retained. Oversized views are clipped.
    g.stencil(function() g.rectangle('fill',AREA.x,AREA.y,AREA.w,AREA.h) end,'replace',1)
    g.setStencilTest('greater',0)
    g.setColor(1,1,1,1);g.draw(image,x,y,0,scale,scale)
    if Inspector.showVerified then
      for _,record in pairs(Catalog) do
        if record.atlas==file then
          g.setColor(.47,1,.28,.95)
          g.rectangle('line',x+record.x*scale,y+record.y*scale,
            record.w*scale,record.h*scale)
        end
      end
    end
    -- Orange candidate boxes represent connected opaque components only.
    if Inspector.showCandidates then
      for i,candidate in ipairs(Candidates[file] or {}) do
        local focused=i==Inspector.candidateIndex
        if not Inspector.reviewOnly or candidate.priority=='review' then
          if candidate.priority=='low' then g.setColor(.65,.66,.68,focused and 1 or .38)
          else g.setColor(1,focused and .9 or .58,.15,focused and 1 or .65) end
          g.rectangle('line',x+candidate.x*scale,y+candidate.y*scale,
          candidate.w*scale,candidate.h*scale)
        end
      end
    end
    if Inspector.selection then
      local r=Inspector.selection
      g.setColor(.1,.9,.98,.20)
      g.rectangle('fill',x+r.x*scale,y+r.y*scale,r.w*scale,r.h*scale)
      g.setColor(.2,1,1,1)
      g.rectangle('line',x+r.x*scale,y+r.y*scale,r.w*scale,r.h*scale)
    end
    g.setStencilTest()
    -- Play a selected sequence on a fixed-size developer-only preview surface.
    -- Source image data is read through the same cache; no pixels are rewritten.
    if #Inspector.previewFrames>0 then
      local fi=Draft.frameIndex(Inspector.previewTime,#Inspector.previewFrames,Inspector.previewFPS)
      local frame=Inspector.previewFrames[fi]
      local source=Inspector.cache[frame.atlas]
      if not source then
        local ok,loaded=pcall(g.newImage,DIR..frame.atlas)
        if ok and loaded then loaded:setFilter('nearest','nearest');source=loaded
          Inspector.cache[frame.atlas]=loaded end
      end
      g.setColor(.015,.035,.055,.95);g.rectangle('fill',160,193,69,69)
      if source and type(g.newQuad)=='function' then
        local iw,ih=source:getDimensions()
        if Regions.validate(frame.atlas,frame,iw,ih) then
          local q=g.newQuad(frame.x,frame.y,frame.w,frame.h,iw,ih)
          local zoom=math.min(58/frame.w,52/frame.h)
          local dw,dh=frame.w*zoom,frame.h*zoom
          g.setColor(1,1,1,1)
          g.draw(source,q,194-dw/2,218-dh/2,0,zoom,zoom)
        end
      end
      g.setColor(.5,.95,.65,1)
      g.rectangle('line',160,193,69,69)
      write(string.format('%d/%d %d fps',fi,#Inspector.previewFrames,Inspector.previewFPS),162,250)
    end
    -- Compare a pinned crop with the currently selected region. Both are
    -- rendered with nearest-neighbor Quads; clipping keeps them inside the UI.
    if Inspector.pinnedFrame then
      local function tile(frame,tx,label)
        local ty=176
        g.setColor(.02,.04,.07,.96);g.rectangle('fill',tx,ty,105,87)
        g.setColor(.40,.74,.86,1);g.rectangle('line',tx,ty,105,87)
        write(label,tx+3,ty+2)
        if not frame then write('Sem selecao',tx+4,ty+36);return end
        local source=Inspector.cache[frame.atlas]
        if not source then
          local ok,loaded=pcall(g.newImage,DIR..frame.atlas)
          if ok and loaded then loaded:setFilter('nearest','nearest')
            source=loaded;Inspector.cache[frame.atlas]=loaded end
        end
        if source and Compare.fits(frame,source) and type(g.newQuad)=='function' then
          local iw,ih=source:getDimensions()
          local quad=g.newQuad(frame.x,frame.y,frame.w,frame.h,iw,ih)
          local scale=Compare.scale(frame,94,57)
          g.setColor(1,1,1,1)
          g.draw(source,quad,tx+52.5-frame.w*scale/2,
            ty+39-frame.h*scale/2,0,scale,scale)
        else write('Sem imagem',tx+4,ty+36) end
        write(string.format('%dx%d',frame.w,frame.h),tx+4,ty+73)
      end
      local candidate=nil
      if Inspector.selection then
        candidate=Compare.capture(file,Inspector.selection,iw,ih)
      end
      tile(Inspector.pinnedFrame,12,'H:referencia')
      tile(candidate,123,'Atual / L:limpar')
    end
    local mx,my=Inspector.mouseX,Inspector.mouseY
    if mx and mx>=AREA.x and mx<AREA.x+AREA.w and my>=AREA.y and my<AREA.y+AREA.h then
      local px,py=sourcePixel(mx,my,false)
      if px then
        Inspector.pixelX,Inspector.pixelY=px,py
      else Inspector.pixelX=nil;Inspector.pixelY=nil end
    else Inspector.pixelX=nil;Inspector.pixelY=nil end
    if not Inspector.message then write(string.format('%d x %d px  zoom %.2fx',iw,ih,Inspector.zoom),10,266) end
  else
    Inspector.pixelX=nil;Inspector.pixelY=nil
    write('Nenhum PNG original encontrado.',15,147)
  end
  g.setColor(.26,.62,.79,1);g.rectangle('line',AREA.x-.5,AREA.y-.5,AREA.w+1,AREA.h+1)
  g.setColor(.10,.24,.36,1);g.rectangle('fill',8,279,68,21)
  g.rectangle('fill',86,279,68,21);g.rectangle('fill',164,279,68,21)
  write('< ANT',21,285);write('ZOOM 1x',96,285);write('PROX >',174,285)
  local r=Inspector.selection
  local info=r and string.format('%d,%d  %dx%d  S:salvar C:limpar',r.x,r.y,r.w,r.h)
    or (Inspector.pixelX and ('Pixel: '..Inspector.pixelX..', '..Inspector.pixelY) or 'N/M:regiao J:filtro H:fixar L:liberar')
  if not r and Inspector.pixelX then
    for name,record in pairs(Catalog) do
      if record.atlas==file and Inspector.pixelX>=record.x and Inspector.pixelY>=record.y
        and Inspector.pixelX<record.x+record.w and Inspector.pixelY<record.y+record.h then
        info=name..' (pixel-exact)'
        break
      end
    end
  end
  write(info,8,304)
  if #Inspector.previewFrames>0 then
    write('G:+ P:play F:fps X:limpar E:CSV',7,15)
  end
  if Inspector.message then write(Inspector.message:sub(1,39),8,267)
  elseif not image then -- empty source
  else
    local count=0
    for _,entry in pairs(Catalog) do if entry.atlas==file then count=count+1 end end
    write(string.format('V:%d B:%d J:%d %s',count,#(Candidates[file] or {}),
      #Inspector.visibleCandidateIndices(),Inspector.reviewOnly and 'revisao' or 'todos'),8,267)
  end
  g.setColor(1,1,1,1)
end
return Inspector
