pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
  start_scene = scene:new()
  game_scene = scene:new()    
  start_scene.root = layer:new({text="start",x=20,y=20})
  game_scene.root = layer:new({text="game",x=20,y=30})      
  start_scene.root:update = function()
    if btn(0) then
      sfx(0)
      active_scene = game_scene
    end
  end
  game_scene.root:update = function()
    hill = {}
    for i=1,34 do
      for j=1,4 do
        add(hill, i)
      end
    end
    random_shuffle(hill)
    if btn(0) then
      sfx(0)
      active_scene = start_scene
    end
  end  
  active_scene = game_scene
  start_scene.active_layer = start_scene.root  
  game_scene.active_layer = game_scene.root  
end
scene = {}
function scene:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.active_layer={}
  return o
end
function scene:update() --?
  self.active_layer:update()
end
function scene:draw()
  cls()
  self.root:draw()
end
layer = {}
function layer:new(o)  
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
function layer:update()
end
function layer:draw()
  print(self.text,x,y)
  if self.children then
    for c in self.children do
      c:draw()
    end
  end
end

-->8
function _update()
  active_scene:update()
end
-->8
function _draw()
  active_scene:draw()
end
-->8
function random_shuffle(a)
  
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400000557514625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001d0612b161340612c20023200112000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001d6452a645236451c6451b6452f6452d6452b645136452b6452b6452a6452865534645266451c6451b6452c64532645366451e6451e6452a63531635386352963526635356352b645226452864536645
010c00000237000000023700000005370000000537000000073700000007370000000737000000073700000008370000000837000000073700000007370000000537000000053700000002370000000237000000
010c00000e073000030000000000326750000000000000000e073000000e073000003267500000000000000000000000000e07300000326750000000000000000e073000000e0730000032675000000000032645
001000003d636176163d636176163d6233d6031760600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000543539625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000543539605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001e54300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 41420304