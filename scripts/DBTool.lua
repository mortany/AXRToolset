local DBChecks = {"ai","anims","configs","scripts","xr","shaders","spawns","levels","sounds","textures","meshes"}
-----------------------------------------------------------------
-- 
-----------------------------------------------------------------
function OnApplicationBegin()
	Application.AddPluginButton("t_plugin_db_tool","UICoCDBToolShow",GetAndShow)
end

UI = nil
function Get()
	if not (UI) then 
		UI = cUICoCDBTool("1")
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

Class "cUICoCDBTool" (cUIBase)
function cUICoCDBTool:initialize(id)
	self.inherited[1].initialize(self,id)
end

function cUICoCDBTool:Reinit()
	self.inherited[1].Reinit(self)
	
	self:Gui("Add|Tab2|x0 y0 w1024 h720 AltSubmit vUICoCDBToolTab|%t_unpacker^%t_repacker 1^%t_repacker 2^%t_repacker 3^%t_repacker 4^%t_repacker 5^%t_repacker 6^%t_repacker 7^%t_repacker 8^%t_repacker 9^%t_repacker 10")
	self:Gui("Tab|%t_unpacker")
		-- GroupBox
		self:Gui("Add|GroupBox|x10 y50 w510 h75|%t_input_path")
		self:Gui("Add|GroupBox|x10 y150 w510 h75|%t_output_path")
		
		self:Gui("Add|CheckBox|x200 y58 w120 h20 %s vUICoCDBToolBrowseRecur|%s",gSettings:GetValue("dbtool","check_browse_recur","") == "1" and "Checked" or "","%t_recursive")
		
		-- Buttons 
		self:Gui("Add|Button|gOnScriptControlAction x485 y80 w30 h20 vUICoCDBToolBrowseInputPath|...")
		self:Gui("Add|Button|gOnScriptControlAction x485 y180 w30 h20 vUICoCDBToolBrowseOutputPath|...")
		self:Gui("Add|Button|gOnScriptControlAction x485 y655 w201 h20 vUICoCDBToolSaveSettings0|%t_save_settings")	
		self:Gui("Add|Button|gOnScriptControlAction x485 y680 w201 h20 vUICoCDBToolExecute|%t_execute")		
		
		-- Editbox 
		self:Gui("Add|Edit|gOnScriptControlAction x25 y80 w450 h20 vUICoCDBToolInputPath|")
		self:Gui("Add|Edit|gOnScriptControlAction x25 y180 w450 h20 vUICoCDBToolOutputPath|")
		
	GuiControl(self.ID,"","UICoCDBToolInputPath", gSettings:GetValue("dbtool","unpack_input_path") or "")
	GuiControl(self.ID,"","UICoCDBToolOutputPath", gSettings:GetValue("dbtool","unpack_output_path") or "")
	
	for n=1,10 do
		self:Gui("Tab|%t_repacker "..n)
			-- GroupBox
			self:Gui("Add|GroupBox|x10 y50 w510 h75|%t_unpacked_gamedata_path")
			self:Gui("Add|GroupBox|x10 y150 w510 h75|%t_output_path")
			self:Gui("Add|GroupBox|x10 y230 w510 h275|%t_compress_options")
			
			y = 245
			table.sort(DBChecks)
			for i=1,#DBChecks do
				self:Gui("Add|CheckBox|x50 y%s w100 h22 %s vUICoCDBToolCheck%s%s|%s",y,gSettings:GetValue("dbtool","check_"..DBChecks[i]..n) == "1" and "Checked" or "",DBChecks[i],n,DBChecks[i])
				y = y + 20
			end
			
			-- Buttons 
			self:Gui("Add|Button|gOnScriptControlAction x485 y80 w30 h20 vUICoCDBToolBrowseInputPath%s|...",n)
			self:Gui("Add|Button|gOnScriptControlAction x485 y180 w30 h20 vUICoCDBToolBrowseOutputPath%s|...",n)
			self:Gui("Add|Button|gOnScriptControlAction x485 y655 w201 h20 vUICoCDBToolSaveSettings%s|%t_save_settings",n)
			self:Gui("Add|Button|gOnScriptControlAction x485 y680 w201 h20 vUICoCDBToolExecute%s|%t_execute",n)
			
			-- Editbox 
			self:Gui("Add|Edit|gOnScriptControlAction x25 y80 w450 h20 vUICoCDBToolInputPath%s|",n)
			self:Gui("Add|Edit|gOnScriptControlAction x25 y180 w450 h20 vUICoCDBToolOutputPath%s|",n)
		
		GuiControl(self.ID,"","UICoCDBToolInputPath"..n, gSettings:GetValue("dbtool","path"..n) or "")
		GuiControl(self.ID,"","UICoCDBToolOutputPath"..n, gSettings:GetValue("dbtool","output_path"..n) or "")
	end
	self:Gui("Show|w1024 h720|%t_plugin_db_tool")
end

function cUICoCDBTool:OnGuiClose(idx) -- needed because it's registered to callback
	self.inherited[1].OnGuiClose(self,idx)
end 

function cUICoCDBTool:OnScriptControlAction(hwnd,event,info) -- needed because it's registered to callback
	self.inherited[1].OnScriptControlAction(self,hwnd,event,info)
	local tab = ahkGetVar("UICoCDBToolTab") or "1"
	
	if (tab == "1") then 
		if (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolBrowseInputPath")) then
			local dir = FileSelectFolder("*"..(gSettings:GetValue("dbtool","unpack_input_path") or ""))
			if (dir and dir ~= "") then
				GuiControl(self.ID,"","UICoCDBToolInputPath",dir)
			end
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolBrowseOutputPath")) then 
			local dir = FileSelectFolder("*"..(gSettings:GetValue("dbtool","unpack_output_path") or ""))
			if (dir and dir ~= "") then
				GuiControl(self.ID,"","UICoCDBToolOutputPath",dir)
			end
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolExecute")) then
			ActionUnpack()
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolSaveSettings0")) then
			local input_path = ahkGetVar("UICoCDBToolInputPath")
			local output_path = ahkGetVar("UICoCDBToolOutputPath")
			
			gSettings:SetValue("dbtool","unpack_input_path",input_path)
			gSettings:SetValue("dbtool","unpack_output_path",output_path)
			gSettings:Save()
		end
	else 
		tab = tostring(tonumber(tab) - 1)
		if (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolBrowseInputPath"..tab)) then
			local dir = FileSelectFolder("*"..(gSettings:GetValue("dbtool","path"..tab) or ""))
			if (dir and dir ~= "") then
				GuiControl(self.ID,"","UICoCDBToolInputPath"..tab,dir)
			end
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolBrowseOutputPath"..tab)) then 
			local dir = FileSelectFolder("*"..(gSettings:GetValue("dbtool","output_path"..tab) or ""))
			if (dir and dir ~= "") then
				GuiControl(self.ID,"","UICoCDBToolOutputPath"..tab,dir)
			end
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolExecute"..tab)) then
			ActionSubmit(tab)
		elseif (hwnd == GuiControlGet(self.ID,"hwnd","UICoCDBToolSaveSettings"..tab)) then
			local input_path = ahkGetVar("UICoCDBToolInputPath"..tab)
			local output_path = ahkGetVar("UICoCDBToolOutputPath"..tab)
			
			for i=1,#DBChecks do 
				local bool = ahkGetVar("UICoCDBToolCheck"..DBChecks[i]..tab)
				gSettings:SetValue("dbtool","check_"..DBChecks[i]..tab,bool)
			end
			
			gSettings:SetValue("dbtool","check_browse_recur",ahkGetVar("UICoCDBToolBrowseRecur"))
			gSettings:SetValue("dbtool","path"..tab,input_path or "")
			gSettings:SetValue("dbtool","output_path"..tab,output_path or "")
			gSettings:Save()
		end
	end
end

_INACTION = nil
function ActionSubmit(tab)
	if (_INACTION) then 
		MsgBox("Already performing an action")
		return 
	end 
	
	local input_path = ahkGetVar("UICoCDBToolInputPath"..tab)
	if (input_path == nil or input_path == "") then 
		MsgBox("Incorrect Path!")
		return 
	end 
	
	local output_path = ahkGetVar("UICoCDBToolOutputPath"..tab)
	if (output_path == nil or output_path == "") then 
		MsgBox("Incorrect Output Path!")
		return 
	end 	
	
	_INACTION = true
	
	for i=1,#DBChecks do 
		local bool = ahkGetVar("UICoCDBToolCheck"..DBChecks[i]..tab)
		gSettings:SetValue("dbtool","check_"..DBChecks[i]..tab,bool)
	end
	
	gSettings:SetValue("dbtool","check_browse_recur",ahkGetVar("UICoCDBToolBrowseRecur"))
	gSettings:SetValue("dbtool","path"..tab,input_path)
	gSettings:SetValue("dbtool","output_path"..tab,output_path)
	gSettings:Save()
	
	if not (directory_exists(output_path)) then
		os.execute('MD "'..output_path..'"')
	end
	
	local config_dir = ahkGetVar("A_WorkingDir")..[[\configs\compress\]]
	local working_directory = ahkGetVar("A_WorkingDir")..[[\bin\]]
	local cp = working_directory.."xrCompress.exe"
	local dir = trim_directory(input_path)
	local parent_dir = get_path(input_path)
	
	Msg("DB Tool:= working...")
	
	local compress = {"ai","anims","configs","scripts","xr","shaders","spawns","textures","meshes","sounds"}
	
	-- create compress_*.ltx for levels
	local level_directories = {}
	local function generate_level_options1(path,dir)
		level_directories[dir] = true
	end 
	local function generate_level_options2(dir)
		local data = strformat([[
[header]
auto_load = true
level_name = single ; former level name, now can be mod name
level_ver = 1.0 ; former level version, now can be mod version
entry_point = $fs_root$\gamedata\ ; do not change !
creator = "Team EPIC" ; creator's name
link = "forum.epicstalker.com" ; creator's link

[options] ; exclude files from compression with such extension
exclude_exts = *.ncb,*.sln,*.vcproj,*.old,*.rc,*.scc,*.vssscc,*.bmp,*.exe,*.db,*.bak*,*.bmp,*.smf,*.uvm,*.prj,*.tga,*.txt,*.rtf,*.doc,*.log,*.~*,*.rar,*.sfk

[include_folders]
levels\%s\ = true
]],dir)
		local output_file = io.open(config_dir.."compress_levels_"..dir..".ltx","wb+")
		if (output_file) then
			output_file:write(data)
			output_file:close()
		end	
	end
	
	if (gSettings:GetValue("dbtool","check_levels"..tab) == "1") then
		directory_for_each(input_path.."\\levels",generate_level_options1)
		for k,v in pairs(level_directories) do 
			generate_level_options2(k)
		end
	end
		
	local outdir = {	
		["ai"] = "config",
		["anims"] = "config",
		["scripts"] = "config",
		["xr"] = "config",
		["configs"] = "config",
		["spawns"] = "config",
		["shaders"] = "config",
		["meshes"] = "resource",
		["sounds"] = "sound",
		["textures"] = "resource"
	}
	
	local function remove_pack(node,file,fullpath)
		os.remove(fullpath)
	end
	lfs_ignore_exact_ext_match = true
	file_for_each(parent_dir, {"pack_#"}, remove_pack, true)
	lfs_ignore_exact_ext_match = false
	
	local check_clear_out = {}
	
	local function create_output(name,out, prefix)
		local pltx = prefix and "compress_"..prefix.."_"..name..".ltx" or "compress_"..name..".ltx"
		RunWait( strformat([["%s" "%s" -ltx %s]],cp,input_path,pltx), config_dir )

		lfs.mkdir(out)
		
		if not check_clear_out[name] then
			local function remove_db(node,file,fullpath)
				if string.find(file, name) then
					os.remove(fullpath)
				end
			end
			lfs_ignore_exact_ext_match = true
			file_for_each(out, {"db"}, remove_db, true)
			lfs_ignore_exact_ext_match = false
			check_clear_out[name] = true
		end
		
		local db_id = 0
		local function rename_pack_in_db(node,file,fullpath)
			os.rename(fullpath, out.."\\"..name..".db"..db_id)
			db_id = db_id + 1
		end
		if (file_exists(parent_dir.."\\"..dir..".pack_#1")) then
			lfs_ignore_exact_ext_match = true
			file_for_each(parent_dir, {"pack_#"}, rename_pack_in_db, true)
			lfs_ignore_exact_ext_match = false
		else
			os.rename(parent_dir.."\\"..dir..".pack_#0",out.."\\"..name..".db")
		end
	end 
	
	Sleep(1000)
	
	table.sort(compress)
	
	for i=1,#compress do 
		local chk = gSettings:GetValue("dbtool","check_"..compress[i]..tab)
		if (chk == nil or chk == "1") then
			create_output(compress[i],outdir[compress[i]] and output_path.."\\"..outdir[compress[i]] or output_path)
		end
	end
	
	if (gSettings:GetValue("dbtool","check_levels"..tab) == "1") then
		for k,v in spairs(level_directories) do 
			create_output(k,output_path.."\\maps","levels")
		end
	end
	
	Msg("\nDB Tool:= Finished!")
	
	_INACTION = false
end


function ActionUnpack()
	if (_INACTION) then 
		MsgBox("Already performing an action")
		return 
	end 
	
	local input_path = ahkGetVar("UICoCDBToolInputPath")
	if (input_path == nil or input_path == "") then 
		MsgBox("Incorrect Path!")
		return 
	end 
	
	local output_path = ahkGetVar("UICoCDBToolOutputPath")
	if (output_path == nil or output_path == "") then 
		MsgBox("Incorrect Output Path!")
		return 
	end 	
	
	_INACTION = true
	
	gSettings:SetValue("dbtool","unpack_input_path",input_path)
	gSettings:SetValue("dbtool","unpack_output_path",output_path)
	gSettings:Save()
	
	if not (directory_exists(output_path)) then
		os.execute('MD "'..output_path..'"')
	end
	
	local working_directory = ahkGetVar("A_WorkingDir")..[[\bin\]]
	local cp = working_directory .. "converter.exe"
	
	local patches = {}
	local function on_execute(path,fname)
		--Msg("%s\\%s",path,fname)
		if (string.find(fname,"patch")) then -- do patches last!
			table.insert(patches,path.."\\"..fname)
		else
			-- Run(target,working_directory)
			-- converter.exe -unpack -xdb %%f -dir .\unpacked
			RunWait( strformat([["%s" -unpack -xdb "%s" -dir "%s"]],cp,path.."\\"..fname,output_path), working_directory )
			Msg("unpacked %s",fname)
		end
	end 
	
	Msg("DB Tool:= Unpacking...")
	
	file_for_each(input_path,{"db"},on_execute,ahkGetVar("UICoCDBToolBrowseRecur") ~= "1")
	
	table.sort(patches)
	
	for i=1,#patches do 
		RunWait( strformat([["%s" -unpack -xdb "%s" -dir "%s"]],cp,patches[i],output_path), working_directory )
		Msg("unpacked %s", trim_directory(patches[i]))
	end
	
	Msg("DB Tool:= Unpacking Finished!")
	
	_INACTION = false
end
