-- Developer-only inspection: two arbitrary rectangles are NOT necessarily
-- two original animation frames. No pixel data or game state is modified.
local Regions=require('src.atlas_regions')
local Compare={}

function Compare.capture(atlas,region,width,height)
  if type(atlas)~='string' or not atlas:match('^[%w_.%-]+%.png$') then
    return nil,'Atlas invalido'
  end
  if not Regions.validate(atlas,region,width,height) then
    return nil,'Selecione uma regiao valida'
  end
  return {atlas=atlas,x=region.x,y=region.y,w=region.w,h=region.h,
    verified=false}
end

function Compare.fits(frame, image)
  if not frame or not image or type(image.getDimensions)~='function' then return false end
  local iw,ih=image:getDimensions()
  return Regions.validate(frame.atlas,frame,iw,ih)
end

function Compare.scale(frame,boxWidth,boxHeight)
  if not frame or not frame.w or not frame.h or frame.w<=0 or frame.h<=0 then return nil end
  if type(boxWidth)~='number' or type(boxHeight)~='number' or boxWidth<=0 or boxHeight<=0 then return nil end
  return math.min(boxWidth/frame.w,boxHeight/frame.h)
end

function Compare.identicalRegion(a,b)
  return a and b and a.atlas==b.atlas and a.x==b.x and a.y==b.y
      and a.w==b.w and a.h==b.h or false
end

return Compare
