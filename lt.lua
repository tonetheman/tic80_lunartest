local dt = 0
local pt = 0
local player = nil
local velclamp = 10
local W = 240
local H = 136
local GRAV_FORCE = 9.8

local Player = {}
function Player.new(x,y)
	local self = {}
	self.x = x
	self.y = y
	self.velx= 0
	self.vely = 0

	-- could make these local to update
	-- maybe later
	self.rotation = 90 -- really not needed anymore
	self.angle_radians = math.rad(self.rotation)
	
	self.thrust = 30
	function self:bounds()
		-- bounds check
		if self.x>W then
			self.x = 0
		end
		if self.x<0 then
			self.x = W
		end
		if self.y>H then
			self.y = 0
		end
		if self.y<0 then
			self.y = H
		end		
	end
	function self:set_rotation(degrees)
		self.rotation = degrees
		self.angle_radians = math.rad(self.rotation)
	end
	function self:update(dt)
		self.up = false
		self.down = false
		self.left = false
		self.right = false

		-- move it
		self.x = self.x + self.velx*dt
		self.y = self.y + self.vely*dt
		self:bounds()
		--up
		if btn(0) then
			self.up = true
			self:set_rotation(90)
			local forcex = math.cos(self.angle_radians)*self.thrust*dt
			local forcey = math.sin(self.angle_radians)*self.thrust*dt
			self.velx = self.velx - forcex
			self.vely = self.vely - forcey
		end
		--down
		if btn(1) then
			self.down = true
			self:set_rotation(90)
			local forcex = math.cos(self.angle_radians)*self.thrust*dt
			local forcey = math.sin(self.angle_radians)*self.thrust*dt
			self.velx = self.velx + forcex
			self.vely = self.vely + forcey
		end
		-- left
		if btn(2) then
			self.left = true
			self:set_rotation(180)
			local forcex = math.cos(self.angle_radians)*self.thrust*dt
			local forcey = math.sin(self.angle_radians)*self.thrust*dt
			self.velx = self.velx + forcex
			self.vely = self.vely + forcey
		end
		-- right
		if btn(3) then
			self.right = true
			self:set_rotation(180)
			local forcex = math.cos(self.angle_radians)*self.thrust*dt
			local forcey = math.sin(self.angle_radians)*self.thrust*dt
			self.velx = self.velx - forcex
			self.vely = self.vely - forcey
		end

		-- apply grav no matter what
		self.vely = self.vely + GRAV_FORCE*dt

		-- clamp velocity
		if self.velx > velclamp then
			self.velx = velclamp
		end
		if self.vely > velclamp then
			self.vely = velclamp
		end
	end
	function self:draw()
		local sprnum = 0
		local msg = ""
		if self.up then
			sprnum = 2
			msg = "up"
		elseif self.down then
			sprnum = 4
			msg = "down"
		elseif self.left then
			sprnum = 8
			msg = "left"
		elseif self.right then
			sprnum = 6
			msg = "right"
		else
			sprnum = 0
			-- neutral
		end
		spr(sprnum,self.x,self.y,
		-1, -- color key
		1, -- scale
		0, -- flip
		0, -- rotate
		2,2) -- width and height
		print(msg)
	end
	return self
end
function update(dt)
	player:update(dt)
end
function draw()
	cls(0)
	player:draw()
end
function init()
	player = Player.new(100,100)
end
init()
function TIC()
    -- calculate delta time
    dt=time()-pt
	pt=time()
	-- trace(tostring(dt))
	update(dt/1000)
	draw()
end
-- <TILES>
-- 000:00000000000000000000000a000000aa00000aaa00000aaa00000aaa0000aaaa
-- 001:0000000000000000a0000000aa000000aaa00000aaa00000aaa00000aaaa0000
-- 002:00000000000000000000000a000000aa00000aaa00000aaa00000aaa0000aaaa
-- 003:0000000000000000a0000000aa000000aaa00000aaa00000aaa00000aaaa0000
-- 004:00000000000000000000000a000000aa00000eaa00000eaa00000aaa0000aaaa
-- 005:0000000000000000a0000000aa000000aae00000aae00000aaa00000aaaa0000
-- 006:00000000000000000000000a000000aa00000aaa00000aaa00000aaa0000eeaa
-- 007:0000000000000000a0000000aa000000aaa00000aaa00000aaa00000aaaa0000
-- 008:00000000000000000000000a000000aa00000aaa00000aaa00000aaa0000aaaa
-- 009:0000000000000000a0000000aa000000aaa00000aaa00000aaa00000aaee0000
-- 016:0000aaaa0000aaaa0000aaaa0000aaaa000aaaaa00aaaaaaaaaaaaaaaaaaaaaa
-- 017:aaaa0000aaaa0000aaaa0000aaaa0000aaaaa000aaaaaa00aaaaaaaaaaaaaaaa
-- 018:0000aaaa0000aaaa0000aaaa0000aaaa000aaaaa00aaaaaaaaaaaaaaaaaaaee6
-- 019:aaaa0000aaaa0000aaaa0000aaaa0000aaaaa000aaaaaa00aaaaaaaa6eeaaaaa
-- 020:0000aaaa0000aaaa0000aaaa0000aaaa000aaaaa00aaaaaaaaaaaaaaaaaaaaaa
-- 021:aaaa0000aaaa0000aaaa0000aaaa0000aaaaa000aaaaaa00aaaaaaaaaaaaaaaa
-- 022:0000aaaa0000aaaa0000aaaa0000aaaa000aaaaa00aaaaaaaaaaaaaaaaaaaaaa
-- 023:aaaa0000aaaa0000aaaa0000aaaa0000aaaaa000aaaaaa00aaaaaaaaaaaaaaaa
-- 024:0000aaaa0000aaaa0000aaaa0000aaaa000aaaaa00aaaaaaaaaaaaaaaaaaaaaa
-- 025:aaaa0000aaaa0000aaaa0000aaaa0000aaaaa000aaaaaa00aaaaaaaaaaaaaaaa
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

