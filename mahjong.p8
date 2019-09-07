pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
  start_scene = scene:new()
  game_scene = scene:new()    
  start_scene.root = layer:new({text="start",x=20,y=20})
  game_scene.root = layer:new({text="game",x=-20,y=30})      
  start_scene.root.update = function()
    if btn(0) then
      sfx(0)
      active_scene = game_scene
    end
  end
  game_scene.root.update = function(self)
    local hill = {}   
    local o = 0
    for i=1,34 do
      for j=1,4 do
        add(hill, i)
      end
    end
    random_shuffle(hill)
    local p1 = player:new() 
    local p2 = player:new()
    hill.i = 1
    p1:init(hill)
    p2:init(hill)
    p1.hand.draw = function(self) 
      for i=1,#self do
        suit, order = parse_tile(self[i])        
        print(order,10+4*i,100,7)
        print(suit,10+4*i,100+6,7)      
      end      
    end    
    p2.hand.draw = function(self)
      for i=1,#self do
        print('-',10+4*i,10)
      end
    end
    self.children = {}
    add(self.children, p1.hand)
    add(self.children, p2.hand)

    self.player_turn = function(self)
      p1:draw_a_tile()
      self.update = self.player_select_tile_to_discard    
    end

    self.player_select_tile_to_discard = function(self)
      if btn(0) then
        sfx(0)
        p1:discard(14)
        self.update = self.cpu_turn
      end
    end
    
    self.cpu_turn = function(self)
      p2:draw_a_tile()
      self.update = self.cpu_select_tile_to_discard         
    end

    self.cpu_select_tile_to_discard = function(self)
      if btn(0) then
        sfx(0)
        p2:discard(14)
        self.update = self.player_turn
      end
    end

    self.update = self.player_turn 
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
  --[[
  for a to all(self.animations) do
    a.timer -= 1
    a.target.x += a.dx
    a.target.y += a.dy
    if a.timer == 0 then      
    end
  end
  --]]
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
    for c in all(self.children) do
      c:draw()
    end
  end
end
-->8
function _update()
  active_scene:update()
end
player = {}
function player:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self  
  o.hand = {}
  o.river = {}
  o.fuuro = {}
  return o
end
function player:init(hill)  
  for i=1,13 do
    add(self.hand,hill[hill.i])
    hill.i+=1
  end
  self.hill = hill
  sort(self.hand)
end
function player:draw_a_tile()
  local h = self.hill
  local t = h[h.i]
  h.i += 1
  add(self.hand, t)
end
function player:discard(i)
  local h = self.hand
  local t = h[i]
  h[i] = h[#h]
  h[#h] = nil
  sort(h)
end
-->8
function _draw()
  active_scene:draw()
end
-->8
function sort(a)
 for i=1,#a do
    local j = i
    while j > 1 and a[j-1] > a[j] do
      a[j],a[j-1]=a[j-1],a[j]
      j -= 1
    end
  end
end
function random_shuffle(a)
 for i=1,#a do
  j=flr(rnd(#a-i+1))+i
  a[i],a[j] = a[j],a[i]
 end 
end
function parse_tile(x)
  if x <= 27 then 
    x -= 1
    local s = {"m","p","s"}
    return s[1+flr(x/9)],1+x%9
  end
  x -= 27
  local s = {"e","s","w","n","w","f","z"}  
  return 'z', s[x]
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

