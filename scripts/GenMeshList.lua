-----------------------------------------------------------------
--
-----------------------------------------------------------------
function OnApplicationBegin()
	Application.AddPluginButton("t_plugin_gen_mesh","UIGenMeshListShow",GetAndShow)
end

UI = nil
function Get()
	if not (UI) then 
		UI = cUIGenMeshList("1")
		UI.parent = Application.MainMenu
	end 
	return UI
end

function GetAndShow()
	Get():Show(true)
end
-----------------------------------------------------------------
-- UI Class Definition
-----------------------------------------------------------------

Class "cUIGenMeshList" (cUIBase)
function cUIGenMeshList:initialize(id)
	self.inherited[1].initialize(self,id)
end

function cUIGenMeshList:Reinit()
	self.inherited[1].Reinit(self)
	
	-- GroupBox
	self:Gui("Add|GroupBox|x10 y50 w510 h75|%t_unpacked_gamedata_path")

	-- Checkbox 
	self:Gui("Add|CheckBox|x175 w300 h25 %s vUIGenMeshListTag%s|%t_check_textures_in_use",gSettings:GetValue("mesh_list","existing_that_are_used") == "1" and "Checked" or "","existing_that_are_used")
	
	-- Buttons 
	self:Gui("Add|Button|gOnScriptControlAction x485 y80 w30 h20 vUIGenMeshListBrowseInputPath|...")

	self:Gui("Add|Button|gOnScriptControlAction x485 y680 w201 h20 vUIGenMeshListExecute|%t_execute")
	
	-- Editbox 
	self:Gui("Add|Edit|gOnScriptControlAction x25 y80 w450 h20 vUIGenMeshListInputPath|")


	self:Gui("Show|w1024 h720|%t_plugin_gen_mesh")
	
	GuiControl(self.ID,"","UIGenMeshListInputPath", gSettings:GetValue("mesh_list","path") or "")
end

function cUIGenMeshList:OnGuiClose(idx) -- needed because it's registered to callback
	self.inherited[1].OnGuiClose(self,idx)
end 

function cUIGenMeshList:OnScriptControlAction(hwnd,event,info) -- needed because it's registered to callback
	if (hwnd == GuiControlGet(self.ID,"hwnd","UIGenMeshListBrowseInputPath")) then
		local dir = FileSelectFolder("*"..(gSettings:GetValue("mesh_list","path") or ""))
		if (dir and dir ~= "") then
			GuiControl(self.ID,"","UIGenMeshListInputPath",dir)
		end
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIGenMeshListExecute")) then
		self:Gui("Submit|NoHide")
		OnGenerate()
	end
end

function OnGenerate()
	local inputpath = ahkGetVar("UIGenMeshListInputPath")
	if (inputpath == nil or inputpath == "") then 
		MsgBox("Incorrect Path!")
		return 
	end 
	
	gSettings:SetValue("mesh_list","path",inputpath)
	gSettings:Save()
		
	local outfile = cIniFile(".\\logs\\mesh_list.txt",true)
	if not (outfile) then 
		MsgBox("failed to create logs\\mesh_list.txt for output")
		return 
	end	
	
	empty(outfile.root)
	
	local texturefile = cIniFile(".\\logs\\texture_list.txt",true)
	if not (texturefile) then 
		MsgBox("failed to create logs\\texture_list.txt for output")
		return 
	end	
	
	empty(texturefile.root)
	
	local bCheckExisting = ahkGetVar("UIGenMeshListTagexisting_that_are_used")
	gSettings:SetValue("mesh_list","existing_that_are_used",bCheckExisting)
	bCheckExisting = bCheckExisting == "1" and true or false
		
	local ignore_paths = {
		["environment"] = true,
		["fog"] = true,
		["weathers"] = true,
		["weather_effects"] = true,
		["ambients"] = true,
		["ambient_channels"] = true,
	}
	local data
	local function on_execute_ltx(path,fname)
		local check_path = trim_directory(path)
		if (ignore_paths[check_path]) then 

		else
			local f = io.open(path.."\\"..fname,"rb")
			if (f) then
				Msg("scanning %s\\%s",path,fname)
				data = f:read("*all")
				f:close()
				if (data) then
					local ext = get_ext(fname)
					if (ext == "xml") then 
						for w in string.gmatch(data,"<visual>([/\\%-_%w]+)</visual>") do
							local visual_key = trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
					else
						for w in string.gmatch(data,"dynamics\\([#/\\%-_%w]+)") do 
							local visual_key = "dynamics\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
						for w in string.gmatch(data,"equipments\\([#/\\%-_%w]+)") do 
							local visual_key = "equipments\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
						for w in string.gmatch(data,"actors\\([#/\\%-_%w]+)") do 
							local visual_key = "actors\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
						for w in string.gmatch(data,"grenadier\\([#/\\%-_%w]+)") do 
							local visual_key = "grenadier\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
						for w in string.gmatch(data,"monsters\\([#/\\%-_%w]+)") do 
							local visual_key = "monsters\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key) and "" or "missing"
							outfile:SetValue("visual",visual_key,missing)
						end
						for w in string.gmatch(data,"([/\\%-_%w]+).ogf") do
							local visual_key = "dynamics\\"..trim(w)..".ogf"
							local missing = file_exists(inputpath.."\\meshes\\"..visual_key)
							if (missing) then
								outfile:SetValue("visual",visual_key,"")
							end
						end
					end
				end
				
			end	
		end
	end 

	recurse_subdirectories_and_execute(inputpath,{"ltx","xml","spawn"},on_execute_ltx)
	
	local function on_execute(path,fname)
		local key = string.gsub(path,inputpath.."\\meshes\\", "")
		
		if not (outfile:KeyExist("visual",key.."\\"..fname)) then 
			Msg("unused:= %s",fname)
			outfile:SetValue("unused",key.."\\"..fname,"")
			--os.execute( strformat([[xcopy /Y "%s\%s" "%s\backup\gamedata\meshes\%s\"]],path,fname,inputpath,key) )
			--local txt = fname:sub(1,-5) .. ".txt"
			--os.execute( strformat([[xcopy /Y "%s\%s" "%s\backup\gamedata\meshes\%s\"]],path,txt,inputpath,key) )
		else 
			outfile:SetValue("existing_that_are_used",key.."\\"..fname,"")
			if (bCheckExisting) then
				local f = io.open(path.."\\"..fname,"rb")
				if (f) then
					data = f:read("*all")
					f:close()
					if (data) then
						local look = {"act","amik","r_pop","sgm","kdm_ammo","artifact","briks","controller","corp","crete","decal","detail","door","ed","effects","fbr","flare","floor","food","fx","glas","glass","glow","grad","grenadier","grnd","hud","internal","intro","item","lights","map","mtl","mutantparts","pfx","prop","roof","shoker_mod","sign","sky","ston","terrain","tile","trees","ui","veh","vehicle","vine","wall","water","wind","wm","wood","wpn"}
						for i=1,#look do 
							for w in string.gmatch(data, look[i].."\\([#/\\%-_%w]+)") do 
								local texture_key = look[i].."\\"..trim(w)..".dds"
								local missing = file_exists(inputpath.."\\textures\\"..texture_key) and "" or "missing"
								texturefile:SetValue("textures_used_by_existing",texture_key,missing)
							end
						end
					end 
				end
			end
		end
	end 

	outfile:Save()
	
	Msg("Generating 'unused' mesh list")
	
	recurse_subdirectories_and_execute(inputpath.."\\meshes",{"ogf"},on_execute)		
	
	outfile:Save()
	texturefile:Save()
	
	Msg("Generate Mesh List:= Finished! see mesh_list.txt!")
end