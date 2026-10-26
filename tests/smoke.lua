-- Mock de APIs LÖVE para validar em Lua puro a abertura das telas e eventos.
-- Execute em um runtime Lua 5.4+ com cwd na raiz do projeto.
local font={getWidth=function(_,s) return #tostring(s)*6 end, getHeight=function() return 11 end,setFilter=function()end}
local graphics={newFont=function()return font end,getFont=function()return font end,getDimensions=function()return 480,640 end}
setmetatable(graphics,{__index=function(_,name) return function(...) end end})
local saveData
love={
 graphics=graphics,
 filesystem={getInfo=function()return saveData and {} or nil end,write=function(_,data)saveData=data;return true end,read=function()return saveData end},
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
