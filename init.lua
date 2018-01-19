--experimental code to show humidity and temperature

tempidity = {}
tempidity.hud = {}
local timer = 0

local centigrade = minetest.setting_getbool("tempidity_celsius")
local temp_scale = ""

local mg = ""

local mg_params = minetest.get_mapgen_params()
if mg_params.mgname == "v7" then
   mg = "v7"
end

if mg_params.mgname == "v5" then
	mg = "v5"
end

if mg_params.mgname == "valleys" then
	mg = "valleys"
end

if mg_params.mgname == "carpathian" then
	mg = "carpathian"
end

local tperlin
local hperlin
local np_temp = nil
local np_humid = nil

-- noise vals for default mgv7
if mg == "v7" or mg == "v5" or mg == "valleys" or mg == "carpathian" then
	-- 2D noise for temperature
	tperlin =0 

	-- 2D noise for humidity
	hperlin =0 
end

minetest.register_globalstep(function(dtime)

	--something
	local point = {x=1,y=1,z=1}
	
	--display HUD to each person
	for _,player in ipairs(minetest.get_connected_players()) do
		--common variables
		local pos = vector.round(player:getpos())
		local name = player:get_player_name()
		
		--actual display temp/humidity
		local temperature = 0
		local humidity = 0
		
		if mg == "v7" or mg == "v5" or mg == "valleys" or mg == "carpathian" then
			--get 2d temperature
			local tnoise = minetest.get_perlin(5349, 3, 0.5, 50):get2d({x=pos.x,y=pos.z})

			if centigrade == true then
				temperature = math.floor((25 + tnoise * 50)*100) / 100 -- convert to Celsius
				temp_scale = tostring(temperature) .. " C"
			else
				temperature = ((math.floor((25 + tnoise * 50)*100) / 100) * 1.8) + 32 -- convert to Fahrenheit
				temp_scale = tostring(temperature) .. " F"
			end
			
			--get 2d humidity
			local hnoise = minetest.get_perlin(842, 3, 0.5, 50):get2d({x=pos.x,y=pos.z})
			humidity = math.floor((50 + hnoise * 31.25)*100) / 100 --unit conversion
		else --none of the above. skip calculations
			break --nope.avi
		end		

		--check if a HUD for the player is already set up
		if not tempidity.hud[name] then
			--nope, so make one
			tempidity.hud[name] = {}
			--temperature...
			tempidity.hud[name].TempId = player:hud_add({
				hud_elem_type = "text",
				name = "Temperature",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-176, y=-80},
				direction = 0,
				text = "Temperature: "..temp_scale,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			--humidity...
			tempidity.hud[name].HumidId = player:hud_add({
				hud_elem_type = "text",
				name = "Humidity",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-176, y=-60},
				direction = 0,
				text = "Humidity: "..humidity,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			--store the values to potentially reduce calculations
			tempidity.hud[name].oldTemp = temperature
			tempidity.hud[name].oldHumid = humidity
			return
		--HUD already exists
		--see if temperature is the same here, if not, redraw
		elseif tempidity.hud[name].oldTemp ~= temperature then
			player:hud_change(tempidity.hud[name].TempId, "text",
				"Temperature: "..temp_scale)
			tempidity.hud[name].oldTemp = temperature
		--same for humidity
		elseif tempidity.hud[name].oldHumid ~= humidity then
			player:hud_change(tempidity.hud[name].HumidId, "text",
				"Humidity: "..humidity)
			tempidity.hud[name].oldHumid = humidity
		end
	end
end)

--clear calculations for the HUD of the now non-existant player
minetest.register_on_leaveplayer(function(player)
	tempidity.hud[player:get_player_name()] = nil
end)