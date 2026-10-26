-- Mock de APIs LÖVE para validar em Lua puro a abertura das telas e eventos.
-- Execute em um runtime Lua 5.4+ com cwd na raiz do projeto.
local font={getWidth=function(_,s) return #tostring(s)*6 end, getHeight=function() return 11 end,setFilter=function()end}
local graphics={newFont=function()return font end,getFont=function()return font end,getDimensions=function()return 480,640 end}
setmetatable(graphics,{__index=function(_,name) return function(...) end end})
local saveData
love={
 graphics=graphics,
 filesystem={getInfo=function(path)return path=='save.lua' and saveData and {} or nil end,
  write=function(_,data)saveData=data;return true end,
  read=function(path)
    if path:match('^missions/') then
      local f=io.open(path,'rb')
      if not f then return nil end
      local data=f:read('*a');f:close();return data
    end
    return path=='save.lua' and saveData or nil
  end},
 keyboard={isDown=function()return false end},
 event={quit=function()end},
}
package.path='./?.lua;./?/init.lua;'..package.path
require('main')
love.load();love.draw()
-- F2 also works on the menu (there is no World instance yet).
local Inspector=require('src.atlas_inspector')
love.keypressed('f2')
assert(Inspector.active,'inspector did not open from the menu')
love.mousemoved(200,200)
assert(Inspector.mouseX==100 and Inspector.mouseY==100,'menu pointer not sent to inspector')
love.mousereleased(200,200,1)
love.keypressed('f2')
assert(not Inspector.active,'inspector did not close from the menu')
-- Menu exposes the second experimental map, not a hidden debug command.
local UI=require('src.ui')
local name,hit=UI.hit(100,222)
assert(hit and name=='operations_map','staged mission menu button is missing')
-- Use the new mission through actual menu action and render its HUD.
local Mission=require('src.mission')
local originalLoad=Mission.load
local opened
Mission.load=function(id) opened=id; return originalLoad(id) end
love.mousepressed(200,444,1);love.mousereleased(200,444,1)
assert(opened=='training_operations','operation map did not use correct mission ID')
love.update(.05);love.draw()
love.keypressed('f5')
love.keypressed('f9')
love.keypressed('escape') -- pause
love.keypressed('escape') -- unpause
love.keypressed('escape') -- pause
love.draw()
-- Return to menu through the existing button.
love.mousepressed(230,400,1);love.mousereleased(230,400,1)
love.draw()
-- Botao 'campanha' do menu, em coordenadas fisicas 2x.
love.mousepressed(160,290,1);love.mousereleased(160,290,1)
for i=1,40 do love.update(.05) end
love.draw()
love.mousepressed(200,320,1);love.mousereleased(200,320,1)
love.mousepressed(320,410,2)
love.update(.05);love.draw()
love.keypressed('f5')
love.keypressed('f9')
love.keypressed('escape');love.draw()
love.keypressed('escape');love.draw()
print('LOVE UI MOCK PASSED')
