local Catalog=require('src.atlas_catalog')
local Art = { images = {}, animations={},atlasFrames={},atlasImages={},catalog=Catalog }

-- Atlas entries store their original source rectangle and texture quad.
-- Standalone PNGs remain an isolated fallback for incomplete packages
-- or renderers that do not expose LÖVE's Quad API.
local function atlasFrame(name)
  return Art.atlasFrames[name] or Art.images[name]
end

local function loadImage(file)
  if not love.filesystem.getInfo(file) then return nil end
  local ok,image=pcall(love.graphics.newImage,file)
  if not ok then return nil end
  image:setFilter('nearest','nearest')
  return image
end

function Art.load()
  Art.images={};Art.animations={};Art.atlasFrames={};Art.atlasImages={}
  local names={'background','grass','grass2','dirt','dirt2','forest','forest2','rocks',
    'blue_hq','blue_barracks','blue_factory','blue_turret',
    'red_hq','red_barracks','red_factory','red_turret',
    'blue_infantry','red_infantry','blue_tank','red_tank','explosion'}
  for _,name in ipairs(names) do
    Art.images[name]=loadImage('assets/sprites/'..name..'.png')
  end
  -- Verified 1:1 pixel crops. The atlas texture is shared by all sprites
  -- that reference it; no resampling, texture copies or extra drawn sprites.
  local canQuad=type(love.graphics.newQuad)=='function'
  if canQuad then
    for name,region in pairs(Catalog) do
      local path='assets/original/'..region.atlas
      local texture=Art.atlasImages[region.atlas]
      if not texture then
        texture=loadImage(path)
        if texture then Art.atlasImages[region.atlas]=texture end
      end
      if texture then
        local width,height=texture:getDimensions()
        if region.x>=0 and region.y>=0 and region.w>0 and region.h>0
          and region.x+region.w<=width and region.y+region.h<=height then
          local ok,quad=pcall(love.graphics.newQuad,region.x,region.y,
            region.w,region.h,width,height)
          if ok and quad then
            Art.atlasFrames[name]={image=texture,quad=quad,w=region.w,h=region.h}
          end
        end
      end
    end
  end
  -- Optional standalone frames. A modder or asset-restoration pass can add
  -- assets/animations/blue_infantry/walk_01.png, walk_02.png etc. No fake
  -- animation frames are generated or advertised as original artwork.
  for _,name in ipairs({'blue_infantry','red_infantry','blue_tank','red_tank',
      'blue_turret','red_turret','explosion'}) do
    local states={}
    for _,state in ipairs({'idle','walk','attack','death'}) do
      local frames={}
      for i=1,64 do
        local path=string.format('assets/animations/%s/%s_%02d.png',name,state,i)
        local frame=loadImage(path)
        if not frame then break end
        frames[#frames+1]=frame
      end
      if #frames>0 then states[state]=frames end
    end
    Art.animations[name]=states
  end
end

local function drawImage(image,x,y,w,h,angle,alpha)
  if not image then return false end
  local frame=type(image)=='table' and image.image and image.quad and image or nil
  local texture=frame and frame.image or image
  local iw,ih
  if frame then iw,ih=frame.w,frame.h else iw,ih=texture:getDimensions() end
  love.graphics.setColor(1,1,1,alpha or 1)
  if angle and angle~=0 then
    if frame then
      love.graphics.draw(texture,frame.quad,x+w/2,y+h/2,angle,w/iw,h/ih,iw/2,ih/2)
    else
      love.graphics.draw(texture,x+w/2,y+h/2,angle,w/iw,h/ih,iw/2,ih/2)
    end
  else
    if frame then love.graphics.draw(texture,frame.quad,x,y,0,w/iw,h/ih)
    else love.graphics.draw(texture,x,y,0,w/iw,h/ih) end
  end
  love.graphics.setColor(1,1,1,1)
  return true
end

function Art.draw(name,x,y,w,h,angle,alpha)
  if not drawImage(atlasFrame(name),x,y,w,h,angle,alpha) then
    love.graphics.setColor(.6,.6,.6,alpha or 1)
    love.graphics.rectangle('fill',x,y,w,h)
    love.graphics.setColor(1,1,1,1)
  end
end

function Art.fitSize(name,maxW,maxH,state,time,fps)
  local frames=(Art.animations[name] or {})[state or 'idle']
  local image=frames and frames[require('src.animation').frame(time,#frames,fps or 8)] or atlasFrame(name)
  if not image then return maxW,maxH,image end
  local iw,ih
  if type(image)=='table' and image.quad then iw,ih=image.w,image.h
  else iw,ih=image:getDimensions() end
  if iw<=0 or ih<=0 then return maxW,maxH,image end
  local factor=math.min(maxW/iw,maxH/ih)
  return iw*factor,ih*factor,image
end

-- Anchor at the center of the entity's ground tile while preserving the
-- original cropped PNG aspect ratio (unlike the v0.2 square scaling).
function Art.drawEntity(name,cx,cy,maxW,maxH,angle,alpha,state,time)
  local w,h,image=Art.fitSize(name,maxW,maxH,state,time)
  local x,y=cx-w/2,cy-h/2
  if not drawImage(image,x,y,w,h,angle,alpha) then
    love.graphics.setColor(.6,.6,.6,alpha or 1)
    love.graphics.rectangle('fill',x,y,w,h)
    love.graphics.setColor(1,1,1,1)
  end
  return w,h
end
return Art
