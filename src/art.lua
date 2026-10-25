local Art = { images = {} }

function Art.load()
  local names = {'background','grass','grass2','dirt','dirt2','forest','forest2','rocks',
    'blue_hq','blue_barracks','blue_factory','blue_turret',
    'red_hq','red_barracks','red_factory','red_turret',
    'blue_infantry','red_infantry','blue_tank','red_tank','explosion'}
  for _, name in ipairs(names) do
    local file = 'assets/sprites/' .. name .. '.png'
    if love.filesystem.getInfo(file) then
      local ok, im = pcall(love.graphics.newImage, file)
      if ok then
        im:setFilter('nearest', 'nearest')
        Art.images[name] = im
      end
    end
  end
end

function Art.draw(name, x, y, w, h, angle, alpha)
  local img = Art.images[name]
  if not img then
    love.graphics.setColor(0.6, 0.6, 0.6, alpha or 1)
    love.graphics.rectangle('fill', x, y, w, h)
    love.graphics.setColor(1,1,1,1)
    return
  end
  local iw, ih = img:getDimensions()
  love.graphics.setColor(1,1,1,alpha or 1)
  if angle and angle ~= 0 then
    love.graphics.draw(img, x+w/2,y+h/2,angle,w/iw,h/ih,iw/2,ih/2)
  else
    love.graphics.draw(img,x,y,0,w/iw,h/ih)
  end
  love.graphics.setColor(1,1,1,1)
end
return Art
