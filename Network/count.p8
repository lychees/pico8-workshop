pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--pico8com
--by neopolita

chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
s2c={} c2s={}
for i=1,95 do
	c=i+31
	s=sub(chars,i,i)
	c2s[c]=s
	s2c[s]=c
end

omsg_queue={}
omsg=nil
imsg=""

function split_str(str,sep)
 astr={} index=0
 for i=1,#str do
 	if (sub(str,i,i)==sep) then
 	 chunk=sub(str,index,i-1)
 	 index=i+1
 		add(astr,chunk)
 	end
 end
 chunk=sub(str,index,#str)
 add(astr,chunk)
 return astr
end

function send_msg(msg)
	add(omsg_queue,msg)
end

function update_msgs()
	update_omsgs()
	update_imsgs()
end

function update_omsgs()
	if (peek(0x5f80)==1) return

	if (omsg==nil and count(omsg_queue)>0) then
		omsg=omsg_queue[1]
		del(omsg_queue,omsg)
	end

	if (omsg!=nil) then
	 poke(0x5f80,1)
		memset(0x5f81,0,63)
		chunk=sub(omsg,0,63)
		for i=1,#chunk do
			poke(0x5f80+i,s2c[sub(chunk,i,i)])
		end
		omsg=sub(omsg,64)
		if (#omsg==0) then
			omsg=nil
			if (#chunk==63) poke(0x5f80,2)
		end
	end
end

function update_imsgs()
	control=peek(0x5fc0)
	if (control==1 or control==2) then
		for i=1,63 do
			char=peek(0x5fc0+i)
			if (char==0) then
				process_input()
				imsg=""
				break
			end
			imsg=imsg..c2s[char]
		end
		if (control==2) then
			process_input()
			imsg=""
		end
		poke(0x5fc0,0)
	end
end

function process_input()
	--process input here
	if (imsg=="left") x-=10
	if (imsg=="right") x+=10
	if (imsg=="up") y-=10
	if (imsg=="down") y+=10
end

function _init()
end

x=64 y=64

function _update60()
 if (btnp(0)) then
		send_msg("left")
	end
	if (btnp(1)) then
		send_msg("right")
	end
	if (btnp(2)) then
		send_msg("up")
	end
	if (btnp(3)) then
		send_msg("down")
	end
 --call on update
	update_msgs()
end

function _draw()
	rectfill(0,0,127,127,1)
	circfill(x,y,7,6)
	color(7)
	cursor(2,2)
	print("pico8com")
	color(6)
	cursor(2,9)
	print(x..":"..y)
end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000210502f050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
