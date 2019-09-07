pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--mahjong demo
--by bab_b
cycle_length = 48
dice_roll_sprites={123,124,125,126}
dice_sprites={93,94,95,109,110,111}
menu_hand={0,0,0,1,2,3,4,5,6,7,8,8,8}
sine24perd={0,0,1,1,1,2,3,4,4,5,5,5,5,5,4,4,3,2,1,1,1,0,0,0}
wall_being_built=false
wall_starting_point=1
current_player = 0 -- 0 thru 3
first_dealer = 0
next_tile_in_wall=1
draw_animation_length=24 --frames

--fix sprite transparency
palt(0, false)
palt(13, true)

--tile object stuff, wall drawing stuff
--tile class and class functions
tile = {suit=0,value=0,base_sprite_id=0}
--constructor
function tile:new(o,suit,value,base_sprite_id)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  self.suit=suit
  self.value=value
  self.base_sprite_id=base_sprite_id
  self.dora_indicator_1=false
  self.dora_indicator_2=false
  self.dora_indicator_3=false
  self.dora_indicator_4=false
  self.raw_index=0
  self.x=0
  self.y=0
  return o
end

function tile.get_flat_id(self)
 if self.suit > 2 then
  return self.base_sprite_id+16
 else
  return self.base_sprite_id+48
 end
end

function tile.get_ccw_id(self)
 if self.suit > 2 then
  return self.base_sprite_id + 32
 else
  return self.base_sprite_id + 96
 end
end

function tile.get_180_id(self)
 if self.suit > 2 then
  return self.base_sprite_id + 64
 else
  return self.base_sprite_id + 192
 end
end

function tile.get_cw_id(self)
 if self.suit > 2 then
  return self.base_sprite_id + 48
 else
  return self.base_sprite_id + 144
 end
end

function tile.discard_sprite(self, player_id)
 if player_id==0 then
  return self:get_flat_id()
 elseif player_id==1 then
  return self:get_ccw_id()
 elseif player_id==2 then
  return self:get_180_id()
 else
  return self:get_cw_id()
 end
end

function tile.is_honor(self)
 return self.suit>2
end

function tile.is_terminal(self)
 return (self.value==1 or self.value==9) and self.suit<3
end

--create all 136 tiles and add them to table all_tiles

--these sprite sheet ids should correspond to the tiles in order
function yield_base_sprite_id(i)
 if i < 9 then
  return i
 elseif i < 18 then
  return i + 7
 elseif i < 27 then
  return i + 14
 else
  return i - 18
 end
end

all_tiles={}

--man=0 pin=1 sou=2 winds=3 dragons=4
--ton,nan,xia,pei=1,2,3,4
--haku,hatsu,chun=1,2,3
for suit=0, 2 do
 for value=1,9 do
  local temp_base_sprite_id = yield_base_sprite_id(value-1+suit*9)
  for i=0, 3 do
   new_tile=tile:new()
   new_tile.suit=suit
   new_tile.value=value
   new_tile.base_sprite_id=temp_base_sprite_id
   add(all_tiles, new_tile)
  end
 end
end
for value=1,4 do
 temp_base_sprite_id = yield_base_sprite_id(26+value)
 for i=0, 3 do
  new_tile=tile:new()
  new_tile.suit=3
  new_tile.value=value
  new_tile.base_sprite_id=temp_base_sprite_id
  add(all_tiles, new_tile)
 end
end
for value=1,3 do
 temp_base_sprite_id = yield_base_sprite_id(30+value)
 for i=0, 3 do
  new_tile=tile:new()
  new_tile.suit=4
  new_tile.value=value
  new_tile.base_sprite_id=temp_base_sprite_id
  add(all_tiles, new_tile)
 end
end

for i=1, #all_tiles do
  local suit = all_tiles[i].suit
  all_tiles[i].raw_index = 0
  if suit == 4 then 
    all_tiles[i].raw_index += 4
    suit -= 1
  end
  all_tiles[i].raw_index += all_tiles[i].value+suit*9
end


wall_top = {}
wall_right = {}
wall_bottom = {}
wall_left = {}

wall = {wall_top, wall_right, wall_bottom, wall_left}
function tile_at(idx)
 idx = 1+(idx + wall_starting_point - 2)%136 
 if idx>34 then
  if idx>68 then
   if idx>102 then
    return wall_left[idx-102]
   else
    return wall_bottom[idx-68]
   end
  else
   return wall_right[idx-34]
  end
 else
  return wall_top[idx]
 end
end

--deletes tile from wall, returns tile, sprite id, tilex, tiley
function retrieve_next_tile()
 local idx = 1+(next_tile_in_wall + wall_starting_point - 2)%136
 local x, y = 0, 0
 next_tile_in_wall +=1
 local temptile = {}
 if idx>34 then
  if idx>68 then
   if idx>102 then
    temptile = wall_left[idx-102]
    wall_left[idx-102] = nil
    y = 109-flr(5*((idx-102)/2))
    if idx%2==1 then
     y-=4
    end
    return temptile, 241, 10, y
   else
    temptile = wall_bottom[idx-68]
    wall_bottom[idx-68] = nil
    x=115-flr(6*((idx-68)/2))
    if idx%2==1 then
     y=110
    else
     y=107
    end
    return temptile, 240, x, y
   end
  else
   temptile = wall_right[idx-34]
   wall_right[idx-34] = nil
    y = 19+flr(5*((idx-34)/2))
    if idx%2==1 then
     y-=4
    end
   return temptile, 241, 110, y
  end
 else
  temptile = wall_top[idx]
  wall_top[idx] = nil
  x=7+flr(6*((idx)/2))
  if idx%2==1 then
   y=14
  else
   y=11
  end
  return temptile, 240, x, y
 end
end

function draw_wall()
 local keep_searching_left = true
 local keep_searching_right = true
 ----lower layer of walls----
 for i=2,34,2 do
  --top wall
  if wall_top[i] != nil then
   spr(240,7+(3*i),14)
  end
  --left wall
  if keep_searching_left then
   if wall_left[36-i] != nil then
    spr(241, 10, 19+5*(i/2))


   -- keep_searching_left = false or wall_being_built
   end
  end
  
  --right wall
  if keep_searching_right then
   if wall_right[i] != nil then
     if wall_right[i-1] == nil then
      spr(241,108,19+5*(i/2))
      keep_searching_right=false or wall_being_built
     end
     if i<34 and wall_right[i+1] == nil then
      spr(241,110,19+5*(i/2))
     end
   end
  end
  --bottom wall
  if wall_bottom[i] != nil then
   spr(240,115-(3*i),110)
  end
 end
 if wall_right[34] != nil and wall_right[33] != nil then
  spr(241,110,103)
 end

 ----upper layer of walls----
 for i=1,33,2 do
  --top wall
  local sp_id_vert=240
  local sp_id_horiz=241
  if wall_top[i] != nil then
   if wall_top[i].dora_indicator_1 or wall_top[i].dora_indicator_2 
     or wall_top[i].dora_indicator_3 or wall_top[i].dora_indicator_4 then
    spr(wall_top[i]:get_flat_id(),13+(3*(i-1)),11)
   else
    spr(240,13+(3*(i-1)),11)
   end
  end
  -- left wall
  if wall_left[34-i] != nil then
   if wall_left[34-i].dora_indicator_1 or wall_left[34-i].dora_indicator_2 
     or wall_left[34-i].dora_indicator_3 or wall_left[34-i].dora_indicator_4 then
    spr(wall_left[34-i]:get_ccw_id(), 10, 20+(5*((i-1)/2)))
   else
    spr(241, 10, 20+(5*((i-1)/2)))
   end
  end
  -- right wall
  if wall_right[i] != nil then
   if wall_right[i].dora_indicator_1 or wall_right[i].dora_indicator_2 
     or wall_right[i].dora_indicator_3 or wall_right[i].dora_indicator_4 then
    spr(wall_right[i]:get_cw_id(), 110, 20+(5*((i-1)/2)))
   else
    spr(241, 110, 20+(5*((i-1)/2)))
   end
  end
  --bottom wall
  if wall_bottom[i] != nil then
   if wall_bottom[i].dora_indicator_1 or wall_bottom[i].dora_indicator_2 
     or wall_bottom[i].dora_indicator_3 or wall_bottom[i].dora_indicator_4 then
    spr(wall_bottom[i]:get_180_id(),109-(3*(i-1)),107)
   else
    spr(240,109-(3*(i-1)),107)
   end
  end
 end
 if wall_bottom[2] != nil then
  spr(240,109,110)
 end
 if wall_bottom[1] != nil then
  if wall_bottom[1].dora_indicator_1 or wall_bottom[1].dora_indicator_2 
    or wall_bottom[1].dora_indicator_3 or wall_bottom[1].dora_indicator_4 then
   spr(wall_bottom[1]:get_180_id(),109,107)
  else
   spr(240,109,107)
  end
 end
end

player_hand={}
right_hand={}
top_hand={}
left_hand={}

hands={player_hand, right_hand, top_hand, left_hand}

cpu={}
player={}

function sort_hand(hand)
 for i=1,#hand do
    local j = i
    --while j > 1 and (hand[j-1].suit > hand[j].suit or (hand[j-1].suit == hand[j].suit and hand[j-1].value > hand[j].value)) do
    while j > 1 and hand[j-1].raw_index < hand[j].raw_index do
      hand[j],hand[j-1] = hand[j-1],hand[j]
      j = j - 1
    end
  end
end

function get_coords_in_hand(hand, idx) --x, y
 local x,y,offset=0,0,0
 if idx==14 then
  offset=2
 end
 if hand==player_hand then
  x=19+(6*idx)+offset
  y=120
 elseif hand==right_hand then
  x=120
  y=95-(5*idx)-offset
 elseif hand==top_hand then
  x=103-(6*idx)-offset
  y=2
 else
  x=3
  y=25+(5*idx)+offset
 end
 return x, y
end

function remove_from_hand(hand, idx) --returns tile
 local temptile=hand[idx]
 local handsize=#hand
 hand[idx]=nil
 printh("-------")
 printh("#hand: "..#hand)
 printh("idx: "..idx)
 for i=idx, handsize-1 do --remove empty space
  hand[i],hand[i+1]=hand[i+1],hand[i]
  printh("scoot"..i)
 end
 return temptile
end

player_pile={}
right_pile={}
top_pile={}
left_pile={}

piles={player_pile, right_pile, top_pile, left_pile}

--shuffles table all_tiles
function shuffle_tiles()
 for i = 1, 136, 1 do
  j=flr(rnd(136-i+1))+i
  all_tiles[i], all_tiles[j] = all_tiles[j], all_tiles[i]
 end
end

function build_wall()
 next_tile_in_wall = 1
 wall_being_built = true
 shuffle_tiles()
 --sfx(2)
 --wait(90)
 --wall building animation
 local tiles_idx = 1
 for i=34,2, -2 do
  for j=0,-1,-1 do
   for wl in all(wall) do
    wl[i+j]=all_tiles[tiles_idx]
    tiles_idx += 1
   end
   --[[
   draw_table()
   draw_wall()
   flip()
   sfx(0)
   wait(1)
   --]]
  end
 end
 wall_being_built = false --go back to drawing walls the more efficient way
 --[[
 draw_table()
 draw_wall()
 flip()
 wait(8)
 for yd=0, 35, 5 do
  rectfill(30,65-yd,99,64+yd,0)
  rectfill(29,64-yd,98,63+yd,2)
  flip()
 end
 --]]
 local d1_val=flr(rnd(6))+1
 local d2_val=flr(rnd(6))+1
 --[[
 wait(3)
 --dice roll animation
 sfx(5)
 local d1_x=29
 local d1_y=70
 local d1_y_frame=1
 local d1_xvel=3.1
 local d1_xdecel= -.12
 local d2_x=25
 local d2_y=73
 local d2_y_frame=3
 local d2_xvel=3
 local d2_xdecel= -.08
 local y_table = {2,2,3,3,3,3,2,2,1,0,1,1,2,2,2,1,1,0}
 clip(29,29,69,69)
 while(d2_xvel>0) do
  rectfill(29,29,98,98,2)
  line(d1_x,d1_y+1,d1_x+1,d1_y+1,1)
  spr(dice_roll_sprites[1+d1_y_frame%4],d1_x,d1_y-y_table[d1_y_frame])
  line(d2_x,d2_y+1,d2_x+1,d2_y+1,1)
  spr(dice_roll_sprites[1+d2_y_frame%4],d2_x,d2_y-y_table[d2_y_frame])
  flip()
  d1_x = flr(d1_x + d1_xvel)
  d2_x = flr(d2_x + d2_xvel)
  if d1_xvel<1 then
   d1_xvel=0
  else
   d1_xvel += d1_xdecel
  end
  d2_xvel += d2_xdecel
  if d1_y_frame<#y_table then
   d1_y_frame += 1
  end
  if d2_y_frame<#y_table then
   d2_y_frame +=1
  end
 end
 clip()
 wait(20)
 rectfill(29,29,98,98,2)
 rectfill(49,60,55,66,1)
 rectfill(69,64,75,70,1)
 spr(dice_sprites[d1_val],50,58)
 spr(dice_sprites[d2_val],70,62)
 wait(60)
 for yd=35, 0, -5 do
  draw_table()
  rectfill(30,65-yd,99,64+yd,0)
  rectfill(29,64-yd,98,63+yd,2)
  clip(30,65-yd,70,yd*2)
  rectfill(49,60,55,66,1)
  rectfill(69,64,75,70,1)
  spr(dice_sprites[d1_val],50,58)
  spr(dice_sprites[d2_val],70,62)
  clip()
  draw_wall()
  flip()
 end
 --]]
 draw_table()
 draw_wall()
 wait(8)
 wall_starting_point=1-(34*(1+current_player+d1_val+d2_val))+(2*(d1_val+d2_val))
 --flip dora indicator
 tile_at(-5).dora_indicator_1=true
 draw_wall()
 sfx(6)
 flip()
 --wait(6)
 --deal hands
 for i=1, 4 do
  for p=0, 3 do
   local chunk = {}
   local hand_idx=1+(p+current_player)%4
   local fullchunk=3
   if i==4 then
    fullchunk=0
   end
   for j=0,fullchunk do
    local temptile, sprite_id, x, y = retrieve_next_tile()
    local target_x, target_y, xvel, yvel = 0,0,0,0
    target_x, target_y = get_coords_in_hand(hands[hand_idx], j+#hands[hand_idx]+1)
    xvel=(target_x-x)/draw_animation_length
    yvel=(target_y-y)/draw_animation_length
    add(chunk, {temptile, sprite_id, x, y,target_x,target_y,xvel, yvel})
   end
   for frame=1, draw_animation_length do
    draw_table()
    draw_wall()
    draw_hands()
    for t in all(chunk) do
     spr(t[2], t[3], t[4])
    end
    flip()
    for t in all(chunk) do
     t[3]+=t[7]
     t[4]+=t[8]
    end
   end
   sfx(0)
   for t in all(chunk) do
    add(hands[hand_idx],t[1])
   end
  end
 end
 draw_table()
 draw_wall()
 draw_hands()
 flip()
 wait(5)
 clip(0, 119, 128, 30)
 draw_table()
 for x=25, 97, 6 do
  spr(240, x, 120)
 end
 sfx(6)
 flip()
 sort_hand(player_hand)
 wait(12)
 clip()
 draw_table()
 draw_wall()
 draw_hands()
 sfx(6)
 wait(5)
end

function handle_menu()
 if cursor_flash and (timer == 0) then
  menu = false
  music(-1)
  new_round_init = true
 elseif btn(4) and not cursor_flash then
  sfx(1)
  cursor_flash = true
  timer = 60
 end
end

--[[
function draw_menu()
 rectfill(0,0,128,128,3)
 for x=-24, 120, 8 do
  line(x+(cycle % 24),0,x+24+(cycle % 24),128,11)
  line(128-x-(cycle % 24),0, 104-x-(cycle % 24),128, 11)
 end
 circfill(64,64,52, 2)
 circfill(64,64,50,0)
 --circfill(64,64,50,1)
 --circfill(64,64,40,0)
 print("pico-riichi", 43, 25, 8)
 print("by @babylon_brooks", 29, 32, 9)
 print("press 'z' to select", 28, 90, 9)
 print("new game", 50, 60, 7)
 if not cursor_flash then
  spr(90, 42, 58)
 elseif (cycle % 4) == 0 then
  spr(90, 42, 58)
 end
 --draw animated yakuman
 for k, s in pairs(menu_hand) do
  spr(s, 20+(6*k), 78-(sine24perd[((k+cycle)%24)+1]))
 end
end
]]--

function draw_hands(flashing, highlight)
 local x,y = 0,0
 for i=1, 14 do
  local yoffset=0
  if player_hand[i] != nil then
   x,y=get_coords_in_hand(player_hand, i)
   if i==highlight then
    yoffset=1
   end
   if flashing and i==highlight then
    pal(6,7)
    pal(4,7)
   end
   spr(player_hand[i].base_sprite_id,x,y-yoffset)
   pal(6,6)
   pal(4,4)
   yoffset=0
  end
  if top_hand[15-i] != nil then
   x,y=get_coords_in_hand(top_hand,15-i)
   spr(242,x,y)
  end
  if right_hand[15-i] != nil then
   x,y=get_coords_in_hand(right_hand,15-i)
   spr(244, x,y)
  end
  if left_hand[i] != nil then
   x,y=get_coords_in_hand(left_hand,i)
   spr(243, x,y)
   if left_hand[i+1] == nil then
    spr(172,3,33+(i*5))
   end
  end
 end
 if right_hand[1] != nil then
  spr(171, 120, 98)
 end
end

function get_coords_in_pile(pile,idx)
 idx-=1
 local row,col,x,y=0,0,0,0
 if idx>17 then
  row=2
  col=idx-12
 else
  row=flr(idx/6)
  col=idx%6
 end
 if pile==player_pile then
  x=46+(6*col)
  y=82+(6*row)
 elseif pile==right_pile then
  x=82+(8*row)
  y=72-(5*col)
 elseif pile==top_pile then
  x=76-(6*col)
  y=38-(6*row)
 else
  x=38-(8*row)
  y=47+(5*col)
 end
 return x,y
end

function draw_discards()
 local iter=max(max(#player_pile,#right_pile),max(#top_pile,#left_pile))
 for i=1, iter do
  if player_pile[i] != nil then
   spr(player_pile[i]:get_flat_id(), get_coords_in_pile(player_pile,i))
  end
  if right_pile[iter+1-i] != nil then
   spr(right_pile[iter+1-i]:get_ccw_id(), get_coords_in_pile(right_pile,iter+1-i))
  end
  if top_pile[iter+1-i] != nil then
   spr(top_pile[iter+1-i]:get_180_id(), get_coords_in_pile(top_pile,iter+1-i))
  end
  if left_pile[i] != nil then
   spr(left_pile[i]:get_cw_id(), get_coords_in_pile(left_pile,i))
  end
 end
end

function move_tile(sprite_id, x, y, target_x, target_y)
 local xvel=(target_x-x)/draw_animation_length
 local yvel=(target_y-y)/draw_animation_length
 for frame=1, draw_animation_length do
  draw_table()
  draw_wall()
  draw_discards()
  draw_hands()
  spr(sprite_id,flr(x),flr(y))
  flip()
  x+=xvel
  y+=yvel
 end
end

function draw_table()
 --draw table
 rectfill(0,0,128,64,11)
 rectfill(0,64,128,128,3)
 map(0, 3, 0, 26, 16, 9)
 rectfill(48,48,79,79,5)
 spr(187, 40, 40)
 spr(189, 80, 40)
 spr(219, 40, 80)
 spr(221, 80, 80)
 --middle plate borders
 for x=48, 72, 8 do
 	spr(188, x, 40)
 	spr(220, x, 80)
 end
 for y=48, 72, 8 do
 	spr(203, 40, y)
 	spr(205, 80, y)
 end
 --draw dealer chip
 if first_dealer==0 then
  spr(139, 119, 110)
 elseif first_dealer == 1 then
  spr(140,110,1)
 elseif first_dealer == 2 then
  spr(142,1,11)
 else
  spr(141, 10, 119)
 end
end

function wait(frames)
 for i=1, frames do
  flip()
 end
end


--begin game
count = {}
fuuro = {}
divide_result = {}
divide_results = {}

function debug()
  flip()
  options = {"ok"}
  claim()
end

function chii()
end

function pon(h)  
  local c = 0
  local x = active_tile.x
  local y = active_tile.y
  --local xx, yy = get_coords_in_hand(player_hand, 14-c)
  local xx, yy = get_coords_in_hand(player_hand, #player_hand+1)
  --xx += 10
  move_tile(active_tile:get_flat_id(),x,y,xx,yy)  
  for i=1,#left_hand do 
    if left_hand[i] == active_tile then
      remove_from_hand(left_hand, i)
    end
  end
  for i=1,#right_hand do 
    if right_hand[i] == active_tile then
      remove_from_hand(right_hand, i)
    end
  end
  for i=1,#top_hand do 
    if top_hand[i] == active_tile then
      remove_from_hand(top_hand, i)
    end
  end
  debug()
  --[[
  c += 1
  for i=1,#player_hand do
    if player_hand[i] ~= nil and player_hand[i].raw_index == h then
      temptile=remove_from_hand(player_hand, i)
      count[player_hand[i].raw_index] -= 1            
      x, y = get_coords_in_hand(player_hand,i)
      xx, yy = get_coords_in_hand(player_hand,14-c)
      xx += 10
      c += 1
      move_tile(player_hand[i]:get_flat_id(),x,y,xx,yy)
      if (c == 3) break;
    end
  end
  sort_hand(player_hand)
  --]]
end

function any_shuntsu_start_with(h) 
  if h == nil then
    return false
  end
  for i=0,2 do
    if i*9+1 <= h and h <= i*9+7 then
      ok = true
      break
    end
  end
  return ok and count[h] ~= nil and count[h] >= 1 and count[h+1] ~= nil and count[h+1] >= 1 and count[h+2] ~= nil and count[h+2] >= 1
end

function any_shuntsu(h)
  if h == nil or h > 27 then
    return false
  end
  if (any_shuntsu_start_with(h)) return true 
  if (h ~= 1 and h ~= 10 and h ~= 19) then
    if (any_shuntsu_start_with(h-1)) return true 
    if (h ~= 2 and h ~= 11 and h ~= 20) then
      if (any_shuntsu_start_with(h-2)) return true 
    end
  end  
end

function any_koutsu(h)
  if h == nil or count[h] == nil then 
    return false 
  end 
  return count[h] >= 3
end

function shuntsu_dfs(h)
  local ok = false
  if h == nil then 
    return false
  end
  if any_shuntsu_start_with(h) then
    count[h] -= 1
    count[h+1] -= 1
    count[h+2] -= 1
    add(divide_result, {h,h+1,h+2})
    mentsu_dfs(count, h)
    del(divide_result, {h,h+1,h+2})
    count[h+2] += 1
    count[h+1] += 1
    count[h] += 1
  end
end

function koutsu_dfs(h)
  if any_koutsu(h) then    
    count[h] -= 3
    add(divide_result, {h,h,h})
    mentsu_dfs(count)
    del(divide_result, {h,h,h})
    count[h] += 3
  end 
end

function mentsu_dfs()  
  for i, v in pairs(count) do     
    if v >= 1 then
      koutsu_dfs(i)
      shuntsu_dfs(i)
      return
    end
  end
  -- Succuess
  add(divide_results, divide_results)
end

function is_agari()
  divide_results = {}  
  divide_result = {}
  -- jantou, 11  
  for i, v in pairs(count) do 
    if v >= 2 then
      v -= 2
      add(divide_result, {v,v})
      mentsu_dfs() 
      del(divide_result, {v,v})
      v += 2
    end
  end
  -- return #divide_results > 0
  if #divide_results > 0 then
    return true
  end
end

function sub_claim(type, options)  
end

options = {}
active_tile = nil
function claim()
  if options==nil or #options==0 then
    return
  end

  cls()
  sfx(1)  
  local selection = 1
  local flashing = 1
  while true do
    draw_table()
    draw_wall()
    draw_discards()
    draw_hands()
    for i=1, #options do
      print(options[i], 100, 116-8*i, 0)
    end
    spr(90, 90, 116-8*selection-2)
    if btnp(2) then
      if selection < #options then
        selection = selection + 1
        sfx(7)
      end
    elseif btnp(3) then
      if selection > 1 then 
        selection = selection - 1
        sfx(7)
      end
    elseif btnp(4) then
      sfx(9)
      if options[selection] == "pon" then 
        pon(active_tile.raw_index)
      elseif options[selection] == "chii" then 
        chii() 
      elseif options[selection] == "riichi" then 
      end
      break
    elseif btnp(5) then 
      sfx(8)
      break
    end
    flip()
  end
  options = {}
end

function your_turn()
  local temptile, sprite_id, x, y = retrieve_next_tile()
  local target_x, target_y = get_coords_in_hand(player_hand, #player_hand+1)
  move_tile(sprite_id, x, y, target_x, target_y)
  add(player_hand, temptile)
  if (count[temptile.raw_index] == nil) count[temptile.raw_index] = 0  
  count[temptile.raw_index] += 1
  sfx(0)
  draw_table()
  draw_wall()
  draw_discards()
  draw_hands()
  flip()
  local selection, offset, discard_idx = 14, 2, nil
  flashing=true
  clip(0,110,127,18)
  active_tile = temptile
  if is_agari(player_hand) then
    add(options, "tsumo")
  end
  claim()
  while not discard_idx do
    if selection == 14 then
      offset = 2
    else
      offset = 0
    end
    draw_table()
    draw_wall()
    draw_discards()
    draw_hands(flashing, selection)
    spr(204, 18+(6*selection)+offset, 111)
    flip()
    flashing = not flashing
    if btnp(0) then
      selection = 1+(selection-2)%14
      sfx(7)
    elseif btnp(1) then
      selection = 1+(selection)%14
      sfx(7)
    elseif btnp(4) then
      sfx(8)
      discard_idx=selection
    end
  end
  clip()
  temptile=remove_from_hand(player_hand, discard_idx)
  count[temptile.raw_index] -= 1
  sort_hand(player_hand)
  x,y=get_coords_in_hand(player_hand,discard_idx)
  target_x,target_y=get_coords_in_pile(player_pile,#player_pile+1)
  move_tile(temptile:get_flat_id(), x,y,target_x,target_y)
  add(player_pile, temptile)
end

function my_turn()
  local target_x, target_y = 0, 0
  local current_hand=hands[current_player+1]
  local current_pile=piles[current_player+1]
  local temptile, sprite_id, x, y = retrieve_next_tile()
  local target_x,target_y=get_coords_in_hand(current_hand, #current_hand+1)
  move_tile(sprite_id, x,y, target_x, target_y)
  add(current_hand, temptile)
  sfx(0)
  draw_table()
  draw_wall()
  draw_discards()
  draw_hands()
  -- wait(6)
  local discard_idx=1+flr(rnd(#current_hand))
  temptile=remove_from_hand(current_hand, discard_idx)
  temptile.x = x
  temptile.y = y
  if count[temptile.raw_index] == nil then 
    count[temptile.raw_index] = 0
  end
  count[temptile.raw_index] += 1  
  if any_shuntsu(temptile.raw_index) then
    add(options, "chii")
  end
  --if any_koutsu(temptile.raw_index) then
  if true then
    add(options, "pon")
  end
  count[temptile.raw_index] -= 1
  sort_hand(current_hand)  
  x,y=get_coords_in_hand(current_hand,discard_idx)
  target_x,target_y=get_coords_in_pile(current_pile,#current_pile+1)
  move_tile(temptile:discard_sprite(current_player),x,y,target_x,target_y)
  add(current_pile, temptile)  
  temptile.x = target_x 
  temptile.y = target_y
  active_tile = temptile
  claim()
end

function _init()  
  cls()
  current_player = flr(rnd(4))
  first_dealer = current_player
  -- draw_table()
  flip()
  -- wait(15)
  build_wall()

  for i, v in pairs(player_hand) do    
    if count[v.raw_index] == nil then 
      count[v.raw_index] = 0
    end
    count[v.raw_index] += 1
  end  

  while not round_over do  
    if current_player == 0 then
      your_turn()    
    else
      my_turn()
    end
    sfx(6)
    draw_table()
    draw_wall()
    draw_discards()
    draw_hands()    
    flip()
    current_player=(current_player+1)%4
    if tile_at(-14) == nil then
      round_over = true
    end
  end
  
  while true do
  end
end

__gfx__
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd
777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd
666666dd660566dd660566dd600006dd660606dd660666dd660606dd660066dd600066dd660666dd660666dd000056dd606066dd666666dd63b636dd668666dd
600056dd666666dd666666dd060605dd660066dd600056dd600566dd606066dd606066dd000006dd000006dd606066dd006066dd666666dd666366dd6888e6dd
666666dd600056dd660566dd605056dd660606dd660566dd060666dd656656dd656065dd550556dd605066dd000006dd606066dd666666dd6633b6dd686e66dd
666666dd666666dd600056dd666666dd605056dd606656dd665056dd566666dd566056dd600066dd056506dd056506dd056066dd666666dd633366dd668666dd
668866dd668866dd668866dd668866dd668865dd668866dd668866dd668866dd668866dd060606dd060606dd066606dd656056dd666666dd66b6b6dd66e666dd
688286dd688286dd688286dd688286dd688286dd688286dd688286dd688286dd688286dd060656dd560506dd006056dd666666dd666666dd666666dd666666dd
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd670777dd670777dd000057dd607077dd677777dd63b737dd678777dd
777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd000007dd000007dd707077dd007077dd777777dd777377dd7888e7dd
666666dd661166dd116666dd116611dd116611dd116116dd111166dd116116dd111111dd550557dd705077dd000007dd707077dd777777dd7733b7dd787e77dd
661166dd661c66dd1c6666dd1c661cdd1c661cdd1c61c6dd1c1c11dd1c61c6dd1c1c1cdd700077dd057507dd057507dd057077dd777777dd733377dd778777dd
6188c6dd666666dd668866dd666666dd668866dd886886dd88661cdd2c62c6dd888888dd070707dd070707dd077707dd757057dd777777dd77b7b7dd77e777dd
618ec6dd661166dd668e66dd666666dd668e66dd8e68e6dd8e668edd1c61c6dd8e8e8edd070757dd570507dd007057dd777777dd777777dd777777dd777777dd
66cc66dd661c66dd666611dd116611dd116611dd886886dd886688dd116116dd111111dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd
666666dd666666dd66661cdd1c661cdd1c661cdd8e68e6dd8e668edd1c61c6dd1c1c1cdd544444dd544444dd544444dd544444dd544444dd544444dd544444dd
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd777777dd670570576707000765700057677775776777777767777777677e7777
63b3b6dd663666dd663666dd636636dd636636dd363636dd668666dd36b363dd368636dd77050777770057577000570770000077777777777737b7b77778e777
3b003bdd66b666dd66b666dd6b66b6dd6b66b6ddb6b6b6dd66e666ddb366bbddb6e6b6dd700000077005700770707777777777777777777777733377778878e7
b30093dd666666dd666666dd666666dd668666dd666666dd363636dd666666dd368636dd770507777700577770005707700055777777777777b733b777788777
6b3b36dd663666dd636636dd636636dd63e636dd363636ddb6b6b6dd3366b3ddb6e6b6dd77057007770700577070000777070777777777777737737777777777
636366dd663666dd636636dd636636dd636636dd363636dd363636dd36b363dd368636dd66666666666666666666666666666666666666666666666666666666
606066dd66b666dd6b66b6dd6b66b6dd6b66b6ddb6b6b6ddb6b6b6ddb6666bddb6e6b6dd54444444544444445444444454444444544444445444444454444444
677777dd670577dd670577dd600007dd670707dd670777dd670707dd670077dd600077dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
700057dd777777dd777777dd070705dd770077dd700057dd700577dd707077dd707077dd60075077650070776000070767707077677777776737737767777777
777777dd700057dd770577dd705057dd770707dd770577dd070777dd757757dd757075dd77705077777500777075000777550007777777777b337b7777788777
777777dd777777dd700057dd777777dd705057dd707757dd775057dd577777dd577057dd7000000770075007777707077777777777777777773337777e878877
778877dd778877dd778877dd778877dd778875dd778877dd778877dd778877dd778877dd77705077757500777075000777000007777777777b7b7377777e8777
788287dd788287dd788287dd788287dd788287dd788287dd788287dd788287dd788287dd7507507770007077750007577757777777777777777777777777e777
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd66666666666666666666666666666666666666666666666666666666
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd44444444444444444444444444444444444444444444444444444444
677777dd671177dd117777dd117711dd117711dd117117dd111177dd117117dd111111dd657070dd605075dd650700dd677777dd677777dd677777dd677777dd
771177dd771c77dd1c7777dd1c771cdd1c771cdd1c71c7dd1c1c11dd1c71c7dd1c1c1cdd707070dd707070dd707770dd750757dd777777dd7b7b77dd777e77dd
7188c7dd777777dd778877dd777777dd778877dd887887dd88771cdd2c72c7dd888888dd770007dd705750dd705750dd770750dd777777dd773337dd777877dd
718ec7dd771177dd778e77dd777777dd778e77dd8e78e7dd8e778edd1c71c7dd8e8e8edd755055dd770507dd700000dd770707dd777777dd7b3377dd77e787dd
77cc77dd771c77dd777711dd117711dd117711dd887887dd887788dd117117dd111111dd700000dd700000dd770707dd770700dd777777dd773777dd7e8887dd
777777dd777777dd77771cdd1c771cdd1c771cdd8e78e7dd8e778edd1c71c7dd1c1c1cdd777077dd777077dd750000dd770707dd777777dd737b37dd777877dd
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd
63b3b7dd673777dd673777dd637737dd637737dd373737dd678777dd37b373dd378737dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
3b003bdd77b777dd77b777dd7b77b7dd7b77b7ddb7b7b7dd77e777ddb377bbddb7e7b7ddd70d7070dddddddddddddddddddddddd6677776d6677776d6677776d
b30093dd777777dd777777dd777777dd778777dd777777dd373737dd777777dd378737dd770d770dddddedddd677ddddd677dddd6777777d6777707d6777707d
7b3b37dd773777dd737737dd737737dd73e737dd373737ddb7b7b7dd3377b3ddb7e7b7dd070d70dddddd88ddd677ddddd677dddd6778877d6777777d6777777d
737377dd773777dd737737dd737737dd737737dd373737dd373737dd37b373dd378737ddd70d70dddddd882dd6777dddd6777ddd6778877d6777777d6770777d
707077dd77b777dd7b77b7dd7b77b7dd7b77b7ddb7b7b7ddb7b7b7ddb7777bddb7e7b7dd770d7070dddd82ddd6777dddd6770ddd6777777d6707777d6777777d
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd070d0770dddd2ddddd677ddddd077ddd6677776d6677776d6077776d
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444ddd0ddd00ddddddddddd68e7dddd6770dd5666666d5666666d5666666d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbbbbbbbbbbbbbbbbdd6887dddd0777dddddddddddddddddddddddddd
677777776777777767777777600577776777757767777777607757776775777767775777bbbbbbbbbbbbbbbbddd677ddddd670dd6677776d6077706d6607706d
775777877775778777775787707077877070578777575787775707877007778770000787bbbb3bbbbbb3bbbbddd6777dddd0777d6707707d6777777d6777777d
770778277570782775750827700578277707082777057827700058277077782770777827b3bbbb3bb3bbbb3bddd6777dddd6777d6777777d6770777d6707707d
770778877070788770700887707078877000588770007887770778877705788770057887bbbbbbbbbbbbbbbbdddd677ddddd677d6777777d6777777d6777777d
770777877770778777770787770777877777078777070787777077877777578777775787bbbbbbbbbbbbbbbbdddd677ddddd677d6707707d6077707d6707707d
666666666666666666666666666666666666666666666666666666666666666666666666bbb3bbbbbbbb3bbbdddddddddddddddd6677776d6677776d6677776d
544444445444444454444444544444445444444454444444544444445444444454444444bbbbbb3bb3bbbbbbdddddddddddddddd5666666d5666666d5666666d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddb3bbbbbbbbbbbb3b77dddddd67dddddd76dddddd65dddddddddddddd
67777777677777776777777761c771c761c771c761c8e8e7671ce8e761ccc1c761c8e1c7bbbb3bbbbbb3bbbb76dddddd56dddddd66dddddd76dddddddd70d70d
777cc77777777777777771c771177117711771177118888771c188877112111771c8e1c7bb3bbbb33bbbb3bbdddddddddddddddddddddddddddddddddd70d70d
7718ec7771c71c777778e117777777777778e777777777777117777777777777711881173bbbbbbbbbbbbbb3dddddddddddddddddddddddddddddddddd70d70d
77188c777117117771c8877771c771c771c881c771c8e8e771c8e8e771ccc1c771c8e1c7bbbb3b3bb3b3bbbbdddddddddddddddddddddddddddddddddd0dd70d
777117777777777771177777711771177117711771188887711888877112111771188117bb3bbbbbbbbbb3bbdddddddddddddddddddddddddddddddddddd70dd
6666666666666666666666666666666666666666666666666666666666666666666666663bbbb3bbbb3bbbb3ddddddddddddddddddddddddddddddddddd70ddd
544444445444444454444444544444445444444454444444544444445444444454444444bbb3bbb33bbb3bbbddddddddddddddddddddddddddddddddddd0dddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbb3bbbbbbbbbb3bbda90999dddddddddddddddddda09090ddddddddd
6b39377767777777677733b763b733b763b733b763b733b76773b3b763b733b763b3b3b73bbb3b3bb3b3bbb3d005009da900990000990099d909090dddd70ddd
7300b30777777777777777777777777777777777777777777777777777b7b77777777777bb3bbbbbbbbbb3bbd055509d9905909999095099d990009dd7777770
7b00377773b733b773b77777777777777778e77773b733b778e3b3b77b777b7778e8e8e7bbbbb3b33b3bbbbbd990999d9055000000005509d999099dd0070070
73b3b30777777777777733b773b733b773b733b7777777777777777777373777777777773b3b3bbbbbb3b3b3d900099d9905909999095099d905550dddd7dd70
773b77777777777777777777777777777777777773b733b77773b3b773b733b773b3b3b7bbbbb3b33b3bbbbbd090909d9900990000990099d900500ddd70d70d
666666666666666666666666666666666666666666666666666666666666666666666666b3b3bbbbbbbb3b3bd090909d8888888888888888d999099dd70d70dd
5444444454444444544444445444444454444444544444445444444454444444544444443b3bb3b33b3bb3b3d888888dddddddddddddddddd888888dd0dd0ddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbbb3bb3bb3bb3bbbda90999dddddddddddddddddda95095dddd7070d
677777776777777767777777677770776770777767777777677707776775777767757777b3bb3bbbbbb3bb3bd000009da909000950009099d909090dddd700dd
7877707778770777787077777877070778750007787070777877707778775077787750073b3bb3b33b3bb3b3d905099d9900599599950099d909990d77777770
788770777887070778800707788750077880707778870007788500077887770778877707b3bb3b3bb3b3bb3bd059509d9005990000995009d905950d0007000d
728770777287075772805757728707077285070772875077728075777287700772800007bb3b3bb33bb3b3bbd099909d9900599959950099d990509dd707070d
7877757778775777787577777877500778577777787575777875770778775777787577773bb3b3bbbb3b3bb3d090909d9909000590009099d900000dd707070d
6666666666666666666666666666666666666666666666666666666666666666666666663b3b3bb33bb3b3b3d590599d8888888888888888d999099d70d70d70
544444445444444454444444544444445444444454444444544444445444444454444444b3b3bb3bb3bb3b3bd888888dddddddddddddddddd888888d0dd0dd0d
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbb3b33b33b33b3bb56666ddd66665dddddd70dddddd70dddd7777770
6777777767777777677777776117711761177117688881176888811761112117611881173bb3bb3bb3bb3bb356666ddd66665dddd777770dd777770dd070700d
7771177777777777777771177c177c177c188c177e8e8c177e8e8c177c1ccc177c1e8c17b33bb3b33b3bb33b56666ddd66665dddd766670dd07670ddd7777770
77c881777711711777788c1777777777777e8777777777777777711777777777711881173bb33b3bb3b33bb3ddddddddddddddddd777770dd707070d70707007
77ce817777c17c17711e877771177117711771177888811778881c17711121177c1e8c17b33bb3b33b3bb33bddddddddddddddddd00700ddd707070d70700707
777cc777777777777c1777777c177c177c177c177e8e8c177e8ec1777c1ccc177c1e8c173bb33b3bb3b33bb3dddddddddddddddddd7770ddd70dd70d700dd0d7
666666666666666666666666666666666666666666666666666666666666666666666666b33bb3b33b3bb33bddddddddddddddddd707070dd707070d77777777
54444444544444445444444454444444544444445444444454444444544444445444444433b333b33b333b33ddddddddddddddddd707070dd0dd70dd70000007
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddbb3bb3b33b3bb3bbdddddddddddddddddddddddddddddd70dddddddd
6777b37767777777677777776b337b376b337b376b337b376b3b37776b337b376b3b3b3733b33b3bb3b33b33ddddddddddddddddddddddddd777770ddddddddd
703b3b37777777777b33777777777777777e8777777777777777777777737377777777773b33b3b33b3b33b3ddddddddddddddddddddddddd00070dddddddddd
777300b77b337b3777777b3777777777777777777b337b377b3b3e8777b777b77e8e8e873b3b3b3333b3b3b3ddddddddddddddddddddddddd7777770d7777770
703b003777777777777777777b337b377b337b377777777777777777777b7b7777777777b33b33b33b33b33bddddddddddddddddddddddddd000700dd000000d
777393b7777777777b33777777777777777777777b337b377b3b37777b337b377b3b3b373b33b33bb33b33b3dddddddddddddddddddddddddddd70dddddddddd
666666666666666666666666666666666666666666666666666666666666666666666666b33b33b33b33b33bdddddd1cccccccccccddddddd7770ddddddddddd
44444444444444444444444444444444444444444444444444444444444444444444444433b33b3333b33b33dddddd16555555556cddddddd000dddddddddddd
682887dd682887dd682887dd682887dd682887dd682887dd682887dd682887dd682887dd3b3b33b33b33b3b3dddddd15dddddddd5cdddddddddddddddddddddd
778877dd778877dd778877dd778877dd578877dd778877dd778877dd778877dd778877dd3333b33bb33b3333dddddd15dddddddd5cddddddd7777770d77ddd70
777777dd777777dd750007dd777777dd750507dd757707dd750577dd777775dd750775ddb3b33b3333b33b3bdddddd15dddddddd5cddddddd7000070d0070d70
777777dd750007dd775077dd750507dd707077dd775077dd777070dd757757dd570757dd333b33b33b33b333dddddd15dddddddd5cddddddd70ddd70ddd0dd70
750007dd777777dd777777dd507070dd770077dd750007dd775007dd770707dd770707dd3b333b3333b333b3dddddd15d7aaaa9d5cddddddd70ddd70ddddd770
777777dd775077dd775077dd700007dd707077dd777077dd707077dd770077dd770007dd33b3333bb3333b33dddddd15ddaaa9dd5cddddddd7777770dddd770d
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666ddb33b3b3333b3b33bdddddd15ddda9ddd5cddddddd0000000777770dd
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd3333333333333333dddddd15dddddddd5cdddddddddddddd00000ddd
677777dd677777ddc17777ddc177c1ddc177c1dd6e87e8dde877e8dd6c17c1ddc1c1c1dd3b3b3b3bb3b3b3b3dddddd16555555556cdddddddd70dddddddddddd
77cc77dd77c177dd117777dd117711dd117711dd788788dd887788dd711711dd111111dd3333333333333333dddddd111111111111dddddddd70dd70d7777770
7ce817dd771177dd77e877dd777777dd77e877dd7e87e8dde877e8dd7c17c1dde8e8e8dd33b33b3333b33b33dddddddddddddddddddddddd70d70d70d007000d
7c8817dd777777dd778877dd777777dd778877dd788788ddc17788dd7c27c2dd888888ddb33333333333333bdddddddddddddddddddddddd70d0dd70ddd7dddd
771177dd77c177dd7777c1ddc177c1ddc177c1dd7c17c1dd11c1c1dd7c17c1ddc1c1c1dd33b3b33bb33b3b33ddddddddddddddddddddddddd70dd770d7777770
777777dd771177dd777711dd117711dd117711dd711711dd771111dd711711dd111111dd3333333333333333ddddddddddddddddddddddddd0dd770dd007000d
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd33333b3333b33333dddddddddddddddddddddddd777770ddddd67770
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd33b3333333333b33dddddddddddddddddddddddd00000ddddddd000d
670707dd677b77dd6b77b7dd6b77b7dd6b77b7dd6b7b7bdd6b7b7bddb7777bdd6b7e7bdd3b333333333333b3ddddddddddd90dddddd9dddddddddddddddddddd
773737dd777377dd737737dd737737dd737737dd737373dd737373dd373b73dd737873dd33333b3333b33333dddeeeee9999999099999990dddddddddddddddd
73b3b7dd777377dd737737dd737737dd737e37dd737373dd7b7b7bdd3b7733dd7b7e7bdd3333333333333333ddde00000009000d0009000dd9dddddddd99990d
39003bdd777777dd777777dd777777dd777877dd777777dd737373dd777777dd737873dd333b33333333b333dddeddddd999990dd99999ddd9999990dd0000dd
b300b3dd777b77dd777b77dd7b77b7dd7b77b7dd7b7b7bdd777e77ddbb773bdd7b7e7bdd333333b33b333333deeeeeddd959590d90909090d000000dd9999990
7b3b37dd777377dd777377dd737737dd737737dd737373dd777877dd373b73dd737873dd3333333333333333ddeee0ddd999990d90090d90ddddddddd000000d
666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd666666dd3b333333333333b3ddde0dddd009000d90999090dddddddddddddddd
544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd544444dd333b33333333b333dddddddddd9990dd90090d90dddddddddddddddd
544444dddddddddd666667dd67774ddd46777dddddddddddddddddddddddddddddd68ddddddddddddddddddddddddddddd999ddd90999090dddddddddddddddd
544444dd54444444666666dd77774ddd47777dddddddddddddddddddddd67dddddd67dddddddedddddddddddddddddddd90909dd90d90d90dd99990dd999990d
544444dd54444444544444dd77774ddd47777dddddddddddddddddddddd67dddddd67ddddddeeedddde0dddddddddeddd90909dd90d0dd90dd0000dd90909090
544444dd54444444544444dd77774ddd47777dddd77777788777777dddd67dddddd67dddddeeeeeddee0dddddddddeed90d90d900ddd990ddd99990d90909090
544444dd54444444544444dd77774ddd47777dddd66666666666666dddd67dddddd67ddddd00e00deeeeeeeeeeeeeeee0dd00d00dddd00dddd0000dd90999090
544444dd55555555544444dd66665ddd56666dddddddddddddddddddddd67dddddd67ddddddde0dddee0000000000ee0ddddddddddddddddd999999099000990
666666dd66666666544444dd66665ddd56666dddddddddddddddddddddd67dddddd67dddeeeee0dddde0ddddddddde0dddddddddddddddddd000000d00ddd00d
666666dd66666666544444dd66665ddd56666dddddddddddddddddddddd68ddddddddddd000000ddddddddddddddd0dddddddddddddddddddddddddddddddddd
__label__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb666667666667666667666667666667666667666667666667666667666667666667666667666667bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666666666666666666666666666666666666666666666666666666666666666bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb544444544444544444544444544444544444544444544444544444544444544444544444544444bbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb682887682887bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb778877778877bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb3bbbbbbb3bbbbbbbb3bbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbb3bbbbbb3bb757707757707bb3bbbbbb3bbbbbbbb3bbbbbb3bbbbbbbb3bbbbbb3bbbb
b3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb775077775077bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3b
bbb67774bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb750007750007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb46777bbb
bbb77774bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777077777077bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb47777bbb
bbb77774bbbb3bbbbbb3bbbbbbbb3bbbbbbb3bbbbbbb3bc177776b77b76828876828876b7b7b682887b3bbbbbbbb3bbbbbb3bbbbbbbb3bbbbbb3bbbb47777bbb
b3b77774b3bbbbbbbbbbbb3bb3bbbbbbb3bbbbbbb3bbbb117777737737778877778877737373778877bbbb3bb3bbbbbbbbbbbb3bb3bbbbbbbbbbbb3b47777bbb
bbb77774b3bbbbbbbbbbbb3bbbbbbb3bb3bbbbbbbbbbbb77e8777377377777757777757b7b7b757707bbbb3bbbbbbb3bb3bbbbbbbbbbbb3bb3bbbbbb47777bbb
bbb67774bbbb3bbbbbb3bbbbbbb3bbbbbbbb3bbbbbb3bb778877777777757757757757737373775077b3bbbbbbb3bbbbbbbb3bbbbbb3bbbbbbbb3bbb46777bbb
3bb77774bb3bbbb33bbbb3bb3bbbb3bbbb3bbbb33bbbb37777c17b77b7770707770707777e77750007bbb3bb3bbbb3bbbb3bbbb33bbbb3bbbb3bbbb347777bb3
bbb777743bbbbbbbbbbbbbb3bbbbbbb33bbbbbbbbbbbbb777711737737770077770077777877777077bbbbb3bbbbbbb33bbbbbbbbbbbbbb33bbbbbbb47777bbb
b3b77774bbbb3b3bb3b3bbbbb3b3bbbbbbbb3b3bb3b3bb677777c177776b7b7b677777682887682887b3bbbbb3b3bbbbbbbb3b3bb3b3bbbbbbbb3b3b47777b3b
bbb77774bb3bbbbbbbbbb3bbbbbbb3bbbb3bbbbbbbbbb3777777117777737373750757778877778877bbb3bbbbbbb3bbbb3bbbbbbbbbb3bbbb3bbbbb47777bbb
bb3677743bbbb3bbbb3bbbb3bb3bbbb33bbbb3bbbb3bbb77777777e8777373737707507777757577073bbbb3bb3bbbb33bbbb3bbbb3bbbb33bbbb3bb467773bb
3bb77774bbb3bbb33bbb3bbb3bbb3bbbbbb3bbb33bbb3b777777778877777777770707757757775077bb3bbb3bbb3bbbbbb3bbb33bbb3bbbbbb3bbb347777bb3
bb377774bbbbb3bbbb3bbbbbbb3bbbbbbbbbb3bbbbbbb37777777777c17b7b7b7707007707077500073bbbbbbbbbb3bbbbbbb3bbbb3bbbbbbb3bbbbb477773bb
3bb77774b3b3bbb33bbb3b3b3bbb3b3bb3b3bbb3b3b3bb777777777711737373770707770077777077bb3b3bb3b3bbb3b3b3bbb33bbb3b3b3bbb3b3b47777bb3
bb377774bbbbb3bbbb3bbbbbbb3bbbbbbbbbb3bbbbbbb36666666666666666666666666666666666663bbbbbbbbbb3bbbbbbb3bbbb3bbbbbbb3bbbbb477773bb
bbb677743b3bbbbbbbbbb3b3bbbbb3b33b3bbbbb3b3bbb544444544444544444544444544444544444bbb3b33b3bbbbb3b3bbbbbbbbbb3b3bbbbb3b346777bbb
3b377774bbb3b3b33b3b3bbb3b3b3bbbbbb3b3b3bbb3b31ccccccccccccccccccccccccccccccccccc3b3bbbbbb3b3b3bbb3b3b33b3b3bbb3b3b3bbb477773b3
bbb777743b3bbbbbbbbbb3b3bbbbb3b33b3bbbbb3b3bbb16555555555555555555555555555555556cbbb3b33b3bbbbb3b3bbbbbbbbbb3b3bbbbb3b347777bbb
b3b77774bbbb3b3bb3b3bb67777777600007076777777715555555555555555555555555555555555c6775777763b733b7bb3b3bb3b3bbbbb3b3bbbb47777b3b
3b3777743b3bb3b33b3bb377711777707500077870777715555555555555555555555555555555555c70077787777777773bb3b33b3bb3b33b3bb3b3477773b3
b3b67774bbb3bb3bb3bb3b77c88177777707077880070715555555555555555555555555555555555c707778277778e777bb3bbbb3bb3bbbbbb3bb3b46777bbb
bbb77774b3bb3bbbbbb3bb77ce8177707500077280575715555555555555555555555555555555555c7705788773b733b7b3bb3bbbb3bb3bb3bb3bbb47777b3b
3b3777743b3bb3b33b3bb3777cc777750007577875777715555555555555555555555555555555555c77775787777777773bb3b33b3bb3b33b3bb3b3477773b3
b3b77774b3bb3b3bb3b3bb67777777677777776770777715555555555555555555555555555555555c6707000763b733b7b3bb3bb3b3bb3bb3bb3b3b47777b3b
3bb77774bb3b3bb33bb3b377777777777777777875000715555555555555555555555555555555555c7700575777b7b777b3b3bb3bb3b3bbbb3b3bb3477773bb
bb3677743bb3b3bbbb3b3b77117117777777777880707715555555555555555555555555555555555c700570077b777b773b3bb3bb3b3bb33bb3b3bb46777bb3
3bb777743b3b3bb33bb3b377c17c17777777777285070715555555555555555555555555555555555c7700577777373777b3b3b33bb3b3b33b3b3bb3477773b3
b3b77774b3b3bb3bb3bb3b77777777777777777857777715555555555555555555555555555555555c7707005773b733b7bb3b3bb3bb3b3bb3b3bb3b47777b3b
bb3777743b33b3bbbb3b3366666666677777776888811715555555555555555555555555555555555c61c771c76773b3b733b3bb3b33b3bbbb3b33b3477773bb
3bb77774b3bb3bb33bb3bb54444444777777777e8e8c1715555555555555555555555555555555555c7117711777777777bb3bb3b3bb3bb33bb3bb3b47777bb3
b33677743b3bb33bb33bb3b3b33bb37b337b377777777715555555555555555555555555555555555c7777777778e3b3b73bb33b3b3bb33bb33bb3b34677733b
3bb77774b3b33bb33bb33b3b3bb33b777777777888811715555555555555555555555555555555555c71c771c777777777b33bb3b3b33bb33bb33b3b47777bb3
b33777743b3bb33bb33bb3b3b33bb3777777777e8e8c1715555555555555555555555555555555555c711771177773b3b73bb33b3b3bb33bb33bb3b34777733b
3bb77774b3b33bb33bb33b3b3bb33b688881176111211715555555555555555555555555555555555c6777777767777777b33bb3b3b33bb33bb33b3b47777bb3
b33777743b3bb33bb33bb3b3b33bb37e8e8c177c1ccc1715555555555555555555555555555555555c77777777777777773bb33b3b3bb33bb33bb3b34777733b
33b677743b333b3333b333b333b333777771177777777715555555555555555555555555555555555c73b733b773b733b7333b333b333b3333b333b346777b33
bb3777743b3bb3bbbb3bb3b3bb3bb378881c177111211715555555555555555555555555555555555c77777777777777773bb3bbbb3bb3b3bb3bb3b3477773bb
33b77774b3b33b3333b33b3b33b33b7e8ec1777c1ccc1715555555555555555555555555555555555c7777777777777777b33b3333b33b3b33b33b3b47777b33
3b3777743b3b33b33b33b3b33b33b3677777776777777715555555555555555555555555555555555c677e77776707000763b733b733b3b33b33b3b3477773b3
3b37777433b3b3b33b3b3b333b3b3b787077777b33777715555555555555555555555555555555555c7778e77777005757777777773b3b333b3b3b33477773b3
b33677743b33b33bb33b33b3b33b337880070777777b3715555555555555555555555555555555555c778878e77005700773b733b73b33b3b33b33b34677733b
3b377774b33b33b33b33b33b3b33b3728057577777777715555555555555555555555555555555555c77788777770057777777777733b33b3b33b33b477773b3
b33777743b33b33bb33b33b3b33b33787577777b33777715555555555555555555555555555555555c777777777707005773b733b73b33b3b33b33b34777733b
33b7777433b33b3333b33b3333b33b6777b3776770707715555555555555555555555555555555555c60057777657000576b393777b33b3333b33b3347777b33
3b3777743b3b33b33b33b3b33b3b33703b3b377755000715555555555555555555555555555555555c70707787700057077300b30733b3b33b33b3b3477773b3
b33677743333b33bb33b33333333b3777300b77777777715555555555555555555555555555555555c70057827707077777b0037773b3333b33b33334677733b
33b77774b3b33b3333b33b3bb3b33b703b00377700000715555555555555555555555555555555555c707078877000570773b3b307b33b3b33b33b3b47777b33
3b377774333b33b33b33b333333b33777393b77757777715555555555555555555555555555555555c7707778770700007773b777733b3333b33b333477773b3
33b777743b333b3333b333b33b333b666666666666666615555555555555555555555555555555555c666666666666666666666666b333b333b333b347777b33
b337777433b3333bb3333b3333b333444444444444444415555555555555555555555555555555555c544444445444444454444444333b33b3333b334777733b
33b67774b33b3b3333b3b33bb33b3b33b33b3b3333b3b316555555555555555555555555555555556cb3b33b33b3b33bb33b3b3333b3b33b33b3b33b46777b33
33377774333333333333333333333333333333333333331111111111111111111111111111111111113333333333333333333333333333333333333347777333
3b377774b3b3b3b33b3b3b3bb3b3b3b33b3b3b3bb3b3b360707763b737670707600077111111111111b3b3b33b3b3b3b3b3b3b3bb3b3b3b3b3b3b3b347777b3b
33377774333333333333333333333333333333333333330070777773777005777070771c1c1c1c1c1c3333333333333333333333333333333333333347777333
33b7777433b33b3333b33b3333b33b3333b33b3333b33b7070777733b7070777757075888888888888b33b3333b33b3333b33b3333b33b3333b33b3347777b33
b33677743333333bb33333333333333bb33333333333330570777333777750575770578e8e8e8e8e8e33333bb3333333b33333333333333b3333333b46777333
33b77774b354444444b3b33bb33b3b3333b3b33bb33b3b75705777b7b77788777788771111111111113b3b3333b3b33b33b3b33bb33b3b33b33b3b334777733b
33377774335444444433333333333333333333333333337777777777777882877882871c1c1c1c1c1c3333333333333333333333333333333333333347777333
333777743354444444333b3333b3333333333b3333b33367057767077711711763b3b7670707607077b3333333333b3333333b3333b3333333b3333347777b33
33b777743354444444b3333333333b3333b3333333333b7777770000071c71c73b003b770077007077333b3333b3333333b3333333333b3333333b3347777333
3b36777433555555553333b33b333333333333b33b33337705775505572c72c7b300937707077070773333b3333333b33b333333333333b33b333333467773b3
333777743354444444b3333333333b3333b3333333333b7000577000771c71c77b3b37705057057077b3333333b3333333333b3333b3333333333b3347777333
33377774335444444433333333333333333333333333337788770707071171177373777788757570573333333333333333333333333333333333333347777333
33377774335444444433b333333b33333333b333333b337882870707571c71c770707778828777777733b3333333b333333b33333333b333333b333347777333
333777743b54444444333333333333b33b3333333333336707070000576666666666666666666666663333333b333333333333b33b333333333333b347777333
33366665335555555533333333333333333333333333337005777070775444445444445444445444443333333333333333333333333333333333333356666333
3b36666533677777773333b33b333333333333b33b3333070777000007333333333333b3333333b3333333b3333333b33b333333333333b33b333333566663b3
33366665337775778733b333333b33333333b333333b337750570575073b33333333b3333333b3333333b3333333b333333b33333333b333333b333356666333
33366665337570782733333333333333333333333333337788770777073333333333333333333333333333333333333333333333333333333333333356666333
33366665337070788733333333333333333333333333337882870070573333333333333333333333333333333333333333333333333333333333333356666333
33366665337770778733333333333333333333333333336666666666663333333333333333333333333333333333333333333333333333333333333356666333
33333333335444444433333333333333333333333333335444445444443333333333333333333333333333333333333333333333333333333333333333333333
33333333335444444433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333335444444433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333335444444433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333335555555533333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333336666666633333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333336665444445444445444445444445444445444445444445444445444443333333333333333333333333333333333333333333333333333333333333
33333333335445444445444445444445444445444445444445444445444445444443333333333333333333333333333333333333333333333333333333333333
33333333335555444445444445444445444445444445444445444445444445444443333333333333333333333333333333333333333333333333333333333333
333333333366654444454444454444454444454444454444454444454444454444454444433333333333333333333333333333333333333333333333a9099933
33333333336665444445444445444445444445444445444445444445444445444445444443333333333333333333333333333333333333333333333300500933
33333333333335444445444445444445444445444445444445444445444445444445444443333333333333333333333333333333333333333333333305550933
33333333333336666666666666666666666666666666666666666666666666666665444443333333333333333333333333333333333333333333333399099933
33333333333336666666666666666666666666666666666666666666666666666665444443333333333333333333333333333333333333333333333390009933
3333333333333544444544444544444544444544444544444544444544444544444544444333333333333333333333333333333337aaaa933333333309090933
3333333333333666666666666666666666666666666666666666666666666666666666666333333333333333333333333333333333aaa93333333333f9f90933
33333333333336666666666666666666666666666666666666666666666666666666666663333333333333333333333333333333333a93333333333388888833
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333357777733333333333333333
33333333333333333333333335444445444445444445444445444445444445444445444445444445444445444445444445444443377777733333333333333333
33333333333333333333333337777777777777777777777777777777777777777777777777777777777777777777777777777773377377733333333333333333
333333333333333333333333311661111661111116666366666366663663663663663663666866636b3633686366686666686663377b77733333333333333333
33333333333333333333333331c661c1c661c1c1c1166b66666b6666b66b66b66b66b66b666e666b366bbb6e6b66888e66888e63377777733333333333333333
333333333333333333333333366886666886688661c666666666666666666668666668666363636666666368636686e66686e663373773733333333333333333
3333333333333333333333333668e66668e668e668e63663663663663663663e63663e636b6b6b63366b3b6e6b66686666686663373773733333333333333333
333333333333333333333333311661111661188668863663663663663663663663663663636363636b36336863666e66666e666337b77b733333333333333333
33333333333333333333333331c661c1c661c8e668e6b66b66b66b66b66b66b66b66b66b6b6b6b6b6666bb6e6b66666666666663333333333333333333333333

__map__
5959595959595959595959595959595900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5959595959595959595959595959595900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5959595959595959595959595959595900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a6a696a6a6a6a696a69696a696a696a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a797a7a797a7a797a797a7a797a797900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
898a89898a8a898a898a898a8a89898a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a999a99999acccccccc9a9a9a9a999a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9aaa9a9aaaacccccccca9a9aaaaa9aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b9bab9b9b9b9ccccccccb9b9bab9b9ba00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cac9cac9c9cacccccccccacac9cacac900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dad9dad9dad9dad9dadad9d9dadad900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e9eaeae9eae9eae9eaeaeaeae9eae9ea00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

