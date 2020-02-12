-- title:  pslib
-- author: Viza
-- desc:   An advenced particle system library for the VIC-80
-- script: lua


--==================================================================================--
-- INTRO/DOCS ======================================================================--
--==================================================================================--

--[[

Hi!
First of all, don't be intimidated by the size of the source, it is very 
straightforward to understand (hopefully :) )

pslib is:
- data driven: to create a particle system you fill out a couple of tables, then handle it to pslib
- modular: You only need to include the modules you use in your cart
- easily extendable: Can't achieve the particle system behaviour you imagined? Just write a simple new module

So how it works?

A particle system is consist of 4 main parts:
- emit timer(s) dictate WHEN to emit a particle
- emitter(s) define WHERE to create the particle, and the initial SPEED
- drawfunc(s) know how to DRAW a particle
- affector(s) know how to MOVE a particle

To create a particle system, call make_psystem, and then fill the emittimers, emitters,
drawfuncs, and affectors tables with your parameters. See the SAMPLE PARTICLE SYSTEMS section
below for examples.

After that you need to call update_psystems in your TIC function to... uhm... update the 
particle systems, and draw_ps or draw_psystems to draw them.

These are the basics, but actually there are not much more to it. :)
You can find more information below in the comments about the main functions or modules.

If you have questions, feel free to contact me at:
email: viza@ccatgames, twitter: @viza, web: blog.ccatgames.com

--]]



--==================================================================================--
-- PARTICLE SYSTEM LIBRARY =========================================================--
--==================================================================================--

particle_systems = {}

-- Call this, to create an empty particle system, and then fill the emittimers, emitters,
-- drawfuncs, and affectors tables with your parameters.
function make_psystem(minlife, maxlife, minstartsize, maxstartsize, minendsize, maxendsize)
	local ps = {
	-- global particle system params

	-- if true, automatically deletes the particle system if all of it's particles died
	autoremove = true,

	minlife = minlife,
	maxlife = maxlife,

	minstartsize = minstartsize,
	maxstartsize = maxstartsize,
	minendsize = minendsize,
	maxendsize = maxendsize,

	-- container for the particles
	particles = {},

	-- emittimers dictate when a particle should start
	-- they called every frame, and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	emittimers = {},

	-- emitters must initialize p.x, p.y, p.vx, p.vy
	emitters = {},

	-- every ps needs a drawfunc
	drawfuncs = {},

	-- affectors affect the movement of the particles
	affectors = {},
	}

	table.insert(particle_systems, ps)

	return ps
end

-- Call this to update all particle systems
function update_psystems()
	local timenow = time()
	for key,ps in pairs(particle_systems) do
		update_ps(ps, timenow)
	end
end

-- updates individual particle systems
-- most of the time, you don't have to deal with this, the above function is sufficient
-- but you can call this if you want (for example fast forwarding a particle system before first draw)
function update_ps(ps, timenow)
	for key,et in pairs(ps.emittimers) do
		local keep = et.timerfunc(ps, et.params)
		if (keep==false) then
			table.remove(ps.emittimers, key)
		end
	end

	for key,p in pairs(ps.particles) do
		p.phase = (timenow-p.starttime)/(p.deathtime-p.starttime)

		for key,a in pairs(ps.affectors) do
			a.affectfunc(p, a.params)
		end

		p.x = p.x + p.vx
		p.y = p.y + p.vy

		local dead = false
		if (p.x<0 or p.x>240 or p.y<0 or p.y>136) then
			dead = true
		end

		if (timenow>=p.deathtime) then
			dead = true
		end

		if (dead==true) then
			table.remove(ps.particles, key)
		end
	end

	if (ps.autoremove==true and #ps.particles<=0) then
		local psidx = -1
		for pskey,pps in pairs(particle_systems) do
			if pps==ps then
				table.remove(particle_systems, pskey)
				return
			end
		end
	end
end

-- draw a single particle system
function draw_ps(ps, params)
	for key,df in pairs(ps.drawfuncs) do
		df.drawfunc(ps, df.params)
	end
end

-- draws all particle system
-- This is just a convinience function, you probably want to draw the individual particles,
-- if you want to control the draw order in relation to the other game objects for example
function draw_psystems()
	for key,ps in pairs(particle_systems) do
		draw_ps(ps)
	end
end

-- This need to be called from emitttimers, when they decide it is time to emit a particle
function emit_particle(psystem)
	local p = {}

	local ecount = nil
	local e = psystem.emitters[math.random(#psystem.emitters)]
	e.emitfunc(p, e.params)

	p.phase = 0
	p.starttime = time()
	p.deathtime = time()+frnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize = frnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize = frnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	table.insert(psystem.particles, p)
end

function frnd(max)
	return math.random()*max
end


--================================================================--
-- MODULES =======================================================--
--================================================================--

-- You only need to copy the modules you actually use to your program


-- EMIT TIMERS ==================================================--

-- Spawns a bunch of particles at the same time, then removes itself
-- params:
-- num - the number of particle to spawn
function emittimer_burst(ps, params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end

-- Emits a particle every "speed" time
-- params:
-- speed - time between particle emits
function emittimer_constant(ps, params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime = params.nextemittime + params.speed
	end
	return true
end

-- EMITTERS =====================================================--

-- Emits particles from a single point
-- params:
-- x,y - the coordinates of the point
-- minstartvx, minstartvy and maxstartvx, maxstartvy - the start velocity is randomly chosen between these values
function emitter_point(p, params)
	p.x = params.x
	p.y = params.y

	p.vx = frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- Emits particles from the surface of a rectangle
-- params:
-- minx,miny and maxx, maxy - the corners of the rectangle
-- minstartvx, minstartvy and maxstartvx, maxstartvy - the start velocity is randomly chosen between these values
function emitter_box(p, params)
	p.x = frnd(params.maxx-params.minx)+params.minx
	p.y = frnd(params.maxy-params.miny)+params.miny

	p.vx = frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- AFFECTORS ====================================================--

-- Constant force applied to the particle troughout it's life
-- Think gravity, or wind
-- params: 
-- fx and fy - the force vector
function affect_force(p, params)
	p.vx = p.vx + params.fx
	p.vy = p.vy + params.fy
end

-- A rectangular region, if a particle happens to be in it, apply a constant force to it
-- params: 
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
-- fx and fy - the force vector
function affect_forcezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = p.vx + params.fx
		p.vy = p.vy + params.fy
	end
end

-- A rectangular region, if a particle happens to be in it, the particle stops
-- params: 
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
function affect_stopzone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = 0
		p.vy = 0
	end
end

-- A rectangular region, if a particle cames in contact with it, it bounces back
-- params: 
-- zoneminx, zoneminy and zonemaxx, zonemaxy - the corners of the rectangular area
-- damping - the velocity loss on contact
function affect_bouncezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = -p.vx*params.damping
		p.vy = -p.vy*params.damping
	end
end

-- A point in space which pulls (or pushes) particles in a specified radius around it
-- params:
-- x,y - the coordinates of the affector
-- radius - the size of the affector
-- strength - push/pull force - proportional with the particle distance to the affector coordinates
function affect_attract(p, params)
	if (math.abs(p.x-params.x)+math.abs(p.y-params.y)<params.mradius) then
		p.vx = p.vx + (p.x-params.x)*params.strength
		p.vy = p.vy + (p.y-params.y)*params.strength
	end
end

-- Moves particles around in a sin/cos wave or circulary. Directly modifies the particle position
-- params:
-- speed - the effect speed
-- xstrength, ystrength - the amplituse around the x and y axes
function affect_orbit(p, params)
	params.phase = params.phase + params.speed
	p.x = p.x + math.sin(params.phase)*params.xstrength
	p.y = p.y + math.cos(params.phase)*params.ystrength
end

-- DRAW FUNCS ===================================================--

-- Filled circle particle drawer, the particle animates it's size and color trough it's life
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
-- startsize and endsize is coming from the particle system parameters, not the draw func params!
function draw_ps_fillcirc(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		r = (1-p.phase)*p.startsize+p.phase*p.endsize
		circ(p.x,p.y,r,params.colors[c])
	end
end

-- Single pixel particle, which animates trough the given colors
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
function draw_ps_pixel(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		pix(p.x,p.y,params.colors[c])
	end
end

-- Draws a line between the particle's previous and current position, kind of "motion blur" effect
-- params:
-- colors array - indexes to the palette, the particle goes trough these in order trough it's lifetime
function draw_ps_streak(ps, params)
	for key,p in pairs(ps.particles) do
		c = math.floor(p.phase*#params.colors)+1
		line(p.x,p.y,p.x-p.vx,p.y-p.vy,params.colors[c])
	end
end

-- Animates trough the given frames with the given speed
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_animspr(ps, params)
	params.currframe = params.currframe + params.speed
	if (params.currframe>#params.frames) then
		params.currframe = 1
	end
	for key,p in pairs(ps.particles) do
		-- pal(7,params.colors[math.floor(p.endsize)])
		spr(params.frames[math.floor(params.currframe+p.startsize)%#params.frames],p.x,p.y,0)
	end
	-- pal()
end

-- Maps the given frames to the life of the particle
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_agespr(ps, params)
	for key,p in pairs(ps.particles) do
		local f = math.floor(p.phase*#params.frames)+1
		spr(params.frames[f],p.x,p.y,0)
	end
end

-- Each particle is randomly chosen from the given frames
-- params:
-- frames array - indexes to sprite tiles
function draw_ps_rndspr(ps, params)
	for key,p in pairs(ps.particles) do
		-- pal(7,params.colors[math.floor(p.endsize)])
		spr(params.frames[math.floor(p.startsize)],p.x,p.y,0)
	end
	-- pal()
end


--==================================================================================--
-- SAMPLES PARTICLE SYSTEMS ========================================================--
--==================================================================================--
function make_bubbles_ps()
	local ps = make_psystem(500,3000, 1,9,0.5,0.5)
	
	ps.autoremove = false
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 0.2}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = 0, maxx = 240, miny = 100, maxy= 110, minstartvx = 0, maxstartvx = 0, minstartvy = -1.50, maxstartvy=-0.2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_agespr,
			params = { frames = {16,16,17,17,17,18,18,18,18,18,18,18,18,18,18,19} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_orbit,
			params = { phase = 0, speed = 0.001, xstrength = 0.5, ystrength = 0 }
		}
	)
end

function make_magicsparks_ps(ex,ey)
	local ps = make_psystem(300,1700, 1,5,1,5)
	
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-8, maxx = ex+8, miny = ey-8, maxy= ey+8, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_rndspr,
			params = { frames = {32,33,34,35,36} }
			-- params = { frames = {32,33,34,35,36}, colors = {8,9,11,12,14} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.3 }
		}
	)

end

function make_butterflies_ps(ex,ey)
	local ps = make_psystem(2000,3000, 1,9,1,5)
	
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-16, maxx = ex+16, miny = ey-8, maxy= ey+8, minstartvx = 0, maxstartvx = 0, minstartvy = -1, maxstartvy= -0.5 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_animspr,
			params = { frames = {22,23,24,23}, speed = 0.2, currframe = 1 }
			-- params = { frames = {22,23,24,23}, speed = 0.5, colors = {8,9,11,12,14}, currframe = 1 }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_forcezone,
			params = { fx = -0.05, fy = 0.0, zoneminx = 64, zonemaxx = 127, zoneminy = 64, zonemaxy = 100 }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_forcezone,
			params = { fx = 0.05, fy = 0.0, zoneminx = 0, zonemaxx = 64, zoneminy = 30, zonemaxy = 70 }
		}
	)
end

function make_3dwarp_ps()
	local ps = make_psystem(1000,2000, 1,2,0.5,0.5)
	ps.autoremove = false
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 0.001}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = 118, maxx = 122, miny = 63, maxy= 67, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.affectors, 
		{
			affectfunc = affect_attract,
			params = { x = 120, y = 65, mradius = 64, strength = 0.01 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_streak,
			params = { colors = {2,2,2,2,2,1,1,1,1,1,10,15,1,10,10,10,15,10,10,15,10,15,15} }
		}
	)
end

function make_starfield_ps()
	local ps = make_psystem(4000,6000, 1,2,0.5,0.5)
	ps.autoremove = false
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 0.01}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = 235, maxx = 240, miny = 0, maxy= 136, minstartvx = -2.0, maxstartvx = -0.5, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_pixel,
			params = { colors = {15,10,15,10,15,10,10,15,10,15,15,10,10,15} }
		}
	)
end

function make_waterfall_ps(ex,ey)
	local ps = make_psystem(1500,2000, 1,2,0.5,0.5)
	ps.autoremove = false
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 0.01}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-8, maxx = ex+8, miny = ey, maxy= ey+1, minstartvx = -0.5, maxstartvx = 0.5, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_streak,
			params = { colors = {15,13,2,13,13,2,13,2,2,15,15,15} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.3 }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_bouncezone,
			params = { damping = 0.2, zoneminx = 40, zonemaxx = 200, zoneminy = 100, zonemaxy = 136 }
		}
	)
end

function make_blood_ps(ex,ey)
	local ps = make_psystem(2000,3000, 1,2,0.5,0.5)
	
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 30}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = 1, maxstartvx = 3, minstartvy = -3, maxstartvy=-2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_pixel,
			params = { colors = {6} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.15 }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_stopzone,
			params = { zoneminx = 0, zonemaxx = 240, zoneminy = 100, zonemaxy = 127 }
		}
	)
end

function make_sparks_ps(ex,ey)
	local ps = make_psystem(300,700, 1,2, 0.5,0.5)

	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {15,14,12,9,4,3} }
		}
	)
	table.insert(ps.affectors,
		{
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.3 }
		}
	)
end

function make_explosparks_ps(ex,ey)
	local ps = make_psystem(300,700, 1,2,0.5,0.5)
	
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 10}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -1.5, maxstartvy=1.5 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_pixel,
			params = { colors = {12,10,1,4,1,2} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.1 }
		}
	)
end

function make_explosion_ps(ex,ey)
	local ps = make_psystem(100,500, 9,14,1,3)
	
	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 4 }
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-4, maxx = ex+4, miny = ey-4, maxy= ey+4, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {15,0,14,9,9,4} }
		}
	)
end

function make_smoke_ps(ex,ey)
	local ps = make_psystem(200,2000, 1,3, 6,9)
	
	ps.autoremove = false

	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 200}
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-4, maxx = ex+4, miny = ey, maxy= ey+2, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {1,3,2} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0.003, fy = -0.009 }
		}
	)
end

function make_explosmoke_ps(ex,ey)
	local ps = make_psystem(1500,2000, 5,8, 17,18)

	table.insert(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 1 }
		}
	)
	table.insert(ps.emitters, 
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {2} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0.003, fy = -0.01 }
		}
	)
end

--==================================================================================--
-- DEMOS ===========================================================================--
--==================================================================================--

function sparks_demo()
	make_sparks_ps(frnd(220)+10,frnd(116)+10)
end

function explo_demo()
	make_explosion_ps(frnd(220)+10,frnd(116)+10)
end

function richexplo_demo()
	local rx = frnd(220)+10
	local ry = frnd(116)+10
	make_explosmoke_ps(rx,ry)
	make_explosparks_ps(rx,ry)
	make_explosion_ps(rx,ry)
end

function blood_demo()
	make_blood_ps(frnd(64),frnd(90)+10)
end

function smoke_demo()
	make_smoke_ps(frnd(220)+10,frnd(90)+10)
end

function waterfall_demo()
	make_waterfall_ps(frnd(220)+10,frnd(50)+10)
end

function starfield_demo()
	make_starfield_ps()
end

function warp_demo()
	make_3dwarp_ps()
end

function magicsparks_demo()
	make_magicsparks_ps(frnd(220)+10,frnd(116)+10)
end

function butterflies_demo()
	make_butterflies_ps(frnd(220)+10,frnd(54)+64)
end

function bubbles_demo()
	make_bubbles_ps()
end

demos = {
	{name = "sparks", desc = "", createfunc = sparks_demo },
	{name = "explosion", desc = "", createfunc = explo_demo },
	{name = "rich explosion", createfunc = richexplo_demo, desc = "multiple particle systems" },
	{name = "blood", createfunc = blood_demo, desc = "stopzone affector" },
	{name = "smoke", createfunc = smoke_demo, desc = "continuos particle system" },
	{name = "waterfall", createfunc = waterfall_demo, desc = "streak draw bouncezone affector" },
	{name = "starfield", createfunc = starfield_demo, desc = "" },
	{name = "3d warp", createfunc = warp_demo, desc = "attract affector" },
	{name = "magic sparks", createfunc = magicsparks_demo, desc = "rndspr" },
	{name = "bubbles", createfunc = bubbles_demo, desc = "agespr, orbit affector" },
	{name = "butterflies", createfunc = butterflies_demo, desc = "animspr, forcezone affector" },
}
currdemo = 1


--==================================================================================--
-- INIT ============================================================================--
--==================================================================================--

function deleteallps()
	for key,ps in pairs(particle_systems) do
		particle_systems[key] = nil
	end
end

demos[currdemo].createfunc()

function TIC()
	
	if btnp(3) then
		currdemo = currdemo + 1
		if (currdemo>#demos) then
		 	currdemo = 1
		 end 
		 deleteallps()
		 demos[currdemo].createfunc()
	end
	if btnp(2) then
		currdemo = currdemo - 1
		if (currdemo<=0) then
		 	currdemo = #demos
		 end 
		 deleteallps()
		 demos[currdemo].createfunc()
	end
	if btnp(5) then
		demos[currdemo].createfunc()
	end

	update_psystems()
	
	cls(0)
	
	draw_psystems()

	print(demos[currdemo].name,0,0,7)
	print(demos[currdemo].desc,0,8,7)
	print("left/right to change demo", 0, 112, 5)
	print("x to spawn particle system",0,120,5)

end
-- <TILES>
-- 016:0000000000000000000000000002200000022000000000000000000000000000
-- 017:0000000000000000000220000028020000200200000220000000000000000000
-- 018:00000000000dd00000df0d000df000800d00008000d008000008800000000000
-- 019:d00000000d00000000d00d000000d00000d000000d00d00000000d0000000000
-- 022:0000000066666600066666070066607000777700000000000000000000000000
-- 023:0000000000000000666666070066607000777700000000000000000000000000
-- 024:0000000000000000000000070000007066666600006660000000000000000000
-- 032:0000000000000000000e000000efe000000e0000000000000000000000000000
-- 033:000000000002000000282000028d820000282000000200000000000000000000
-- 034:000000000000000000100010000606000000c000000606000010001000000000
-- 035:00050000050b0500005b50005bbfbb50005b5000050b05000005000000000000
-- </TILES>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

-- <COVER>
-- 000:f4d000007494648373160f0088003b000041c0c14442430343d6e4a4e458c4034356420d648457171695d7ec2dd7c258591ad6aac22daa99d62cacad4de5edee6dc2000000000f0088000040ff018c94badb87aaccb7ede58e18269f998a546ac6bceaea807cddc47d77967ecbbb7f49f10102c121d8724a257e3451b7f4064973d5a2ba797842a6b28740e4baa4c142b97c768977100f264080033fc7c43dfe54d25d25858bf207d01737675877668543b2d7b0f0b0e7311000e000100727293287479878d448f2c70951e0f04900206000aa12d913ead20be9166821b6d651107a99c00a462b62d0d00c3b2312a7a8219959f74160fc606aaacaa9c946d0a54c5c5d88313d81cbabbc99dc8688add18db5bd658e835721dbc1fd593150d78b71eedabf81d0a1ce698ba18ed655681721eb90815af63989f70f20e09e7fe01a50b81fa0c5a745e6d9532380ff0105498be0991b906293451a790532201420a3a7ca52664eca49631306197ac62c5ac76eab1d4295125258498c2763411c27249a892376a0d9a44d2025e0a749605e03e4e83d8a00d75a0da518cab03a82d422bcaf1d4cf431858899d0b5515ad5ba77bcc0de01860985599c6f2bbba95cea9c9b2554cbdfb948b20eb63cae2adc0a74bc1e6be67c2c5f0bc69e21169d427a870695f2099c883e27e7cf99d6dde064943ec2afa857d402d9d3b29f7ff017f8ba3b5c8bef5d22081dcdb53814c479894e46900cf2b06320bc8b6661ae6937809ebb4c37ac2df6c39a281917804e70b978057210103f88445da703aeb1b4353fba5446275addd7bab3fd156879ffd6471d6f9490c35f4a0ae4769e750603de1e76440800096516e50d5085f5e2198507fdd79c1f0819c212d6600ec774dd5b6d40ad901b2606ec814c1e281f073340a7b1e12fc5969755671223d2e187255090a7002695715e08326676c7761268922096ad213c5144d4705e5888e990d9d30bf1f02ccb372a770d9676914414ae6938200346999129942a062576bc8d0166909d118668c77c867c2a409625512085e39f5f067862c46e5e1a97ea78c8f7a6a72e42a4e720a69e1a205907b085d79750f5b0a7027d91c0ce10009270df53682800ca6badae86efc58f7a5086e497b96ac0db168aa70b6d3406f7772aa11aaae69baea6f0ffc394a9994140acbeffa922032e84ea6187adcd697e9893beb4a545a61498a72f56ce8bfa62a4b24769a99256597b64b4de948c854b4ec8f145a1259a7a6c2a819bcfa1b220f851af9cbd15bee3bb105821250b9e574140099c3c19a629fe5a3c6d6f54fb8179b851005ae39f7a7bcb525549208033c7147448ae9e032a8cd313bd4c792cc62302917dc7c6c6dde27e135c8ea5ae17e8c7000c64ac3463c17ada58501237b7b43d2918dc05b75f227ca33169227c2be3b1ead8514f14471d882d04f1394144d667960070b2b62bedafc8476a2a432c1987e090a56b9d05be15a20a0270cd3b49dca01f349cf6bd2feaeba4ef7281ed15bed527da91aecf1bd063de0b0369163c9993ff79a8bdd8a03e0573b95f5d7962b51e30297ab3301ed015ec1c7d909c819e698ed3c3e19df938e53fad3a70c621a9ce13baa3ee5287a54a6e64f502aa237bfe5abbdccbb555ae0c1caab3cf47f58f574a6d9d65202c3704bf4fcfee65f9e2934e943441e3706d67ae6e5b8d6a74322fdea8f3e36cdb3257767bc3f5aa7fa337982c2642030c7ade02e7302f51386827fbc85afac4011ef1aeee211cb4dc0a27f48e4550ca5a0cc40c12a080c5452fa21f5ab08ad0a577bbf9528f5f0cf8940fa60935f91809020cd5935c3423a048200314b3124e6ac3a08a453a6f092c602b05859e22d10ecf466167d3de205a835050214f14a7951b905db74da7ad66b232ff2ef0983bae956d2c4bc9ed01fa40254b259d82702cb2aa00b1f21e953d005cf320971bf562c032fc25745be326d840cabd854c260044d9090c35f03a392f848440d28b7cf30199327c4b8dca5e0c0ee874ca04915b3d6bfd9f1dc82024c51e8a3948516786565f0108225215721445c0c5fe96f0ba8e8c1303c521393eac32f6aa7810f8de2d25be38bdc86563bc112a2e49d0bdf8b7c598d195ab74008f28f0e23797e2aed132c830b06e5149798cbbd2fab988a02684429918219c10a94107fcd27a9a131d953fa9a9cf3a025c82acaf1780592eb366d36c1a8c57cf38c971b895268d97c2a51911b6203f39152b9258da192f02e14034bac165c4564cf0ff40005410c276040da86c3f36a9c236fe4f9191ce5343999c494cba8c50e0c7a206c94c9d067436502da4ae1bc608a8201ee10b384dc22d72d991799252667be8270bf7853b92255f9c1379520d44135ec0131f8190789b433a032bf1b33e972ceaa84ba5a792f111b7096c15a54b8824564e20d3733577e9b230cb4202a2049b33a12012a8c1c910139e411d95aa23e7b2321c9072243bdaab5f3aef8faaf40490aa4e080822e00708d0140655f94e2421b34692a41d034c7865bc0bc2aeb185df894d5ce7aa75c5bb1441775988c5aa290874508443593d9bfc2e234ac551d194d4b5636c6459ca39d41413ffaaac2e20625587aa32c5f700a5eb5e676506ff0de0a3b7b7add6a112fa8cc2ca52aaa4046565693b51374d406e8ccd96226b6af7a8e25717a5d5bba05a2bf34a8290fd7d8185a8009b4c2bda11fda78d4f69699a69d6f2c666607bd08559f9ca400ff4572c5c5f4877dacebbf1d4dda2255f608709eedfdec79bbc7d5424c09485df61937a03eb90bb3ba73b49e6362099f5ee14102abfcd0e8013ba0af2588be97e1cbdb59b877a8e6a81c6ffa0202cc7ae8148062a723aabceb4d4aafd0dd74b1c011f17c612c1ac058b87ca7e9510f5b6775699a59b85e46cd2f83ac5bc9236876830e192199acd6c425b6f9940e0104f21bffd2d956b10e1d4d6882dcf8510f94325279559c5d48d63060fb2e7385b3bffc51fce9a607d18c2c62344e6642850164e99548a3f6577aecab56fa74793745850b898c804ec159155ac5d4a5889966500010680c3650f5839a796f3ff66dcb52ac69027d7f5a4684329b7624281fc566ea0f47b5d6b602b57b093f3467791fbdcae6ddb8e79838ba5bb8defda41c0c57473aa0e31aaada7fc239398ab176aa73d1b6c6b5ac2c5682910307d22a61793799acd842c21253509d8c6c509e603aa75bdde0763a0be4db4c491350e1de1fe6b2d9607289ebf1e920057c35dd7c46773c58480fca6575b052c701fa1500de2110bb1ef07d7f35d302170ba5b0d721da525b1cda7ec03fa83e9899246075ef0e476eb60752fabe841988760482895ffe7cc0a76c9e9dbbe96d2a80d1fe27110e0a06bf6d6d1e6270281d70dd2fe4b56fc9f2f3ab3490bdce41020f9e386b8955aae0b6f49adfcbd27eab0cf28e4b6759a3f3d89447da3ec01742c5d10c83fdabe3da518656bccf60407ec6aa31d83e3ddebfabe2fc769d7dd5677bf5c39d287fca384e77add0cc6b3b777ea1ad91fff0fa45417ee7559f4effc6f4ab7a653fc0f9d24ddccf958fc7e7802a77cf3d2be835fa4f91dc7272d57dd2faa79f1cd39a09468ffdb87fc481cce1805bfcdd7146d215912a03341c60bf5e1376a1218d774e0bd73900009bc76e70817ff44e02437abb18a20146dc8b9cef67e6c1b70ff2e590dc72fb7bceff9b2ab6370f1f6ffdb45101f3422b1400c26f62f77f96ec7275c57147d27525e93cf75d6161350d95e43977f60de4d20466097dd70b5cb1de3215411f30f405659871071059371081e79b3900b289000b7651da28a32002b1c864a10d4338538996538638238ca2c35052fb7212154dd6dd3667116a07f56518924c28c28e281a5c38c38876a388a3f00d38d38458138358f48c86fd7f082283d71c7f562e6702527f95b48b48d48375b580d42c0c688d0ca2e68b68638c86378876c68c586b6fd3428916c47348e10257418948f93668668d48696da2678f93d68ea2696c68968ac21381873575060681766d5961557da2388768bf22157e7e75d88f68f68478d18375270d086ffb6408d56d20254bb7e81a17430d97ac7977998a98b28868404b776a8425b08968147fb4862e45f38903e20248497856618bf24c2d37a285b8b28991e287c6ec76474d3eb5272177640ca8573ab22b6406d37ea2dc8900276908d20e28cd6598aa8fa8528f44cd87d8912af6da24004000e85518e0c50c468a78c8d78457a381f82f85b84f87646d7f58766209bf8cf81f8ff8441bf70c79e8e57817609fd8909421b09509d097a7f260b12b1119668571a511e11631f3328f577e88e86197b7200388d19543408630bd32105c8298ae8a16620c19a292817c36102292f6698339fa1a782c8428e29168d39c39e39f09d02a23b93548449f08649de82c49a72ff39159e490e6a824627a6549359d49750c62d59e59f59069169269369469569669769869969a69b69c69d69e69f69369459279379479579679779879979a79b79c79679700f79089f79510189189210589710489289000989a89d79e89101c89700389c89689089810499b89899f89b993b0789599599e990a92997996993101a9d89c999a94607a93a99893998a9fa93a92a94100b9aa96b9640ca96a94894b95a9889db9999ea97b92c9a409b92a98a91a91b9cb91c93c9cc9d301994a95a98c9ac92b90c94d95b9dc98d9820fc9eb91d9fb99c9ab97c94d99d93e95202d96c91e9bd9899bd94e9ce95e9ed90e9ca99e91c9be9de95f96f97f98f99f9af9b40f96f911000b3
-- </COVER>

