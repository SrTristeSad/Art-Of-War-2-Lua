-- Tooling-only helpers for documenting atlas rectangles; not original game logic.
local Regions={HEADER='atlas,x,y,width,height,verification\n'}

function Regions.imagePoint(x,y,originX,originY,scale,imageW,imageH,clamp)
  if not scale or scale<=0 or imageW<=0 or imageH<=0 then return nil end
  local px=math.floor((x-originX)/scale)
  local py=math.floor((y-originY)/scale)
  if clamp then
    px=math.max(0,math.min(imageW-1,px))
    py=math.max(0,math.min(imageH-1,py))
  elseif px<0 or py<0 or px>=imageW or py>=imageH then
    return nil
  end
  return px,py
end

-- Inclusive anchor and endpoint: dragging one pixel yields a 1x1 region.
function Regions.rectangle(ax,ay,bx,by)
  if not (ax and ay and bx and by) then return nil end
  local x,y=math.min(ax,bx),math.min(ay,by)
  return {x=x,y=y,w=math.abs(bx-ax)+1,h=math.abs(by-ay)+1}
end

function Regions.validate(atlas,rect,imageW,imageH)
  if type(atlas)~='string' or not atlas:match('^[%w_%.%-]+%.png$') or atlas:find('..',1,true) then return false end
  if type(rect)~='table' then return false end
  for _,k in ipairs({'x','y','w','h'}) do
    local v=rect[k]
    if type(v)~='number' or v~=math.floor(v) then return false end
  end
  return rect.x>=0 and rect.y>=0 and rect.w>0 and rect.h>0
     and rect.x+rect.w<=imageW and rect.y+rect.h<=imageH
end

function Regions.csvRow(atlas,rect,imageW,imageH)
  if not Regions.validate(atlas,rect,imageW,imageH) then return nil,'Regiao invalida' end
  return string.format('%s,%d,%d,%d,%d,unverified\n',atlas,rect.x,rect.y,rect.w,rect.h)
end

return Regions
