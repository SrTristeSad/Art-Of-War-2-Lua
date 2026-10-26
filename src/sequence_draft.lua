-- Pure-data draft recorder. Nothing saved here is enabled as a game animation.
local Regions=require('src.atlas_regions')
local Draft={HEADER='sequence,frame,atlas,x,y,width,height,fps,verification\n'}
local function validId(id)
  return type(id)=='string' and #id>=1 and #id<=64 and id:match('^[%w_%-]+$')
end
function Draft.append(frames,atlas,rect,w,h)
  if type(frames)~='table' or #frames>=64 then return false,'Limite de 64 quadros' end
  if not Regions.validate(atlas,rect,w,h) then return false,'Regiao invalida' end
  frames[#frames+1]={atlas=atlas,x=rect.x,y=rect.y,w=rect.w,h=rect.h}
  return true
end
function Draft.csvRows(id,frames,fps)
  if not validId(id) then return nil,'Identificador invalido' end
  if type(frames)~='table' or #frames==0 or #frames>64 then return nil,'Quantidade de quadros invalida' end
  if type(fps)~='number' or fps~=math.floor(fps) or fps<1 or fps>30 then return nil,'FPS invalido' end
  local rows={}
  for i,fr in ipairs(frames) do
    if not Regions.validate(fr.atlas,fr,100000,100000) then return nil,'Frame invalido' end
    rows[#rows+1]=string.format('%s,%d,%s,%d,%d,%d,%d,%d,unverified\n',
      id,i,fr.atlas,fr.x,fr.y,fr.w,fr.h,fps)
  end
  return table.concat(rows)
end
function Draft.frameIndex(seconds,n,fps)
  if n==0 then return nil end
  return math.floor(math.max(0,seconds or 0)*fps)%n+1
end
return Draft
