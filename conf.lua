function love.conf(t)
  t.identity = 'artofwar2_lua_rebuild'
  t.version = '11.4'
  t.window.title = 'Art of War 2 - Lua Rebuild (Prototipo de engenharia reversa)'
  t.window.width = 480
  t.window.height = 640
  t.window.resizable = true
  t.window.minwidth = 300
  t.window.minheight = 400
  t.window.vsync = 1
  t.modules.physics = false
end
