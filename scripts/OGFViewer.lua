--[[

Notes: When using LV functions make sure to switch to GUI ID that has the LV before using commands. For example
I couldn't figure out why LV commands weren't working while in the Modify UI. it's because I had to switch 
to GUI 0.
http://stackoverflow.com/questions/24002210/cannot-update-listview

--]]

local Checks = {}
local clipboard = {}
-----------------------------------------------------------------
-- 
-----------------------------------------------------------------
function OnApplicationBegin()
	Application.AddPluginButton("t_plugin_ogf_viewer","UIOGFViewerShow",GetAndShow)
end

UI = nil
function Get()
	if not (UI) then 
		UI = cUIOGFViewer("1")
		UI.parent = Application.MainMenu
	end 
	return UI
end

function GetAndShow()
	local _ui = Get()
	_ui:Show(true)
	return _ui
end

-----------------------------------------------------------------
-- UI Class Definition
-----------------------------------------------------------------
Class "cUIOGFViewer" (cUIBase)
function cUIOGFViewer:initialize(id)
	self.inherited[1].initialize(self,id)
end

function cUIOGFViewer:Show(bool)
	self.inherited[1].Show(self,bool)
end 

function cUIOGFViewer:Create()
	self.inherited[1].Create(self)
end

function cUIOGFViewer:Reinit()
	self.inherited[1].Reinit(self)
	
	self.ogf = self.ogf or {}
	self.list = self.list or {}
	
	local tabs = {"OGF Editor"}
	
	self:Gui("Add|Tab2|x0 y0 w1024 h720 AltSubmit vUIOGFViewerTab hwndUIOGFViewerTab_H|OGF Editor")
	
	for i=1,#tabs do
		local i_s = tostring(i)
		--if (i == 1) then 
			local filters = table.concat({"All"},"^")
			self:Gui("Tab|%s",Language.translate(tabs[i]))
				self:Gui("Add|Text|x560 y555 w230 h20 cRed|%t_click_to_edit")
				
				-- Checkbox
				self:Gui("Add|CheckBox|x250 y575 w120 h20 %s vUIOGFViewerBrowseRecur%s|%s",gSettings:GetValue("ogf_viewer","check_browse_recur"..i_s,"") == "1" and "Checked" or "",i,"%t_recursive")
				
				-- ListView 
				self:Gui("Add|ListView|gOnScriptControlAction x22 y109 w920 h440 grid cBlack +altsubmit -multi vUIOGFViewerLV%s|",i)
				
				-- GroupBox
				self:Gui("Add|GroupBox|x22 y555 w530 h75|%t_working_directory")
				
				self:Gui("Add|DropDownList|gOnScriptControlAction x22 y69 w320 h30 R40 H300 vUIOGFViewerSection%s|"..filters,i)
				
				-- Buttons 
				self:Gui("Add|Button|gOnScriptControlAction x695 y600 w200 h20 vUIOGFViewerLaunchMeshViewer%s|%t_launch_mesh_viewer",i)
				self:Gui("Add|Button|gOnScriptControlAction x495 y600 w30 h20 vUIOGFViewerBrowsePath%s|...",i)
				self:Gui("Add|Button|gOnScriptControlAction x485 y680 w201 h20 vUIOGFViewerSaveSettings%s|%t_save_settings",i)
				
				-- Editbox 
				self:Gui("Add|Edit|gOnScriptControlAction x30 y600 w450 h20 vUIOGFViewerPath%s|",i)
				
				self:Gui("Add|Text|x400 y50 w200 h20|%t_pattern_matching:")
				self:Gui("Add|Edit|gOnScriptControlAction x400 y69 w150 h20 vUIOGFViewerSearch%s|",i)
				self:Gui("Add|Button|gOnScriptControlAction x555 y69 w20 h20 vUIOGFViewerSearchButton%s|>",i)
				
			GuiControl(self.ID,"","UIOGFViewerPath"..i, gSettings:GetValue("ogf_viewer","path"..i) or "")
		--end
	end
	
	self:Gui("Show|w1024 h720|%t_plugin_ogf_viewer")

	LV("LV_Delete",self.ID)
	empty(self.list)
end

function cUIOGFViewer:OnGuiClose(idx) -- needed because it's registered to callback
	self.inherited[1].OnGuiClose(self,idx)
end 

function cUIOGFViewer:OnScriptControlAction(hwnd,event,info) -- needed because it's registered to callback
	self.inherited[1].OnScriptControlAction(self,hwnd,event,info)
	local tab = ahkGetVar("UIOGFViewerTab") or "1"
	
	if (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerLV"..tab)) then
		local selected = ahkGetVar("UIOGFViewerSection"..tab)
		if (selected == nil or selected == "") then 
			return 
		end
		if (event and string.lower(event) == "rightclick") then
			LVTop(self.ID,"UIOGFViewerLV"..tab)
			local row = LVGetNext(self.ID,"0","UIOGFViewerLV"..tab)
			local txt = LVGetText(self.ID,row,"2")
			--Msg("event=%s LVGetNext=%s txt=%s",event,LVGetNext(self.ID,"0","UIOGFViewerLV"..tab),txt)
			if (txt and txt ~= "" and not self.listItemSelected) then 
				self.listItemSelected = txt
				GetAndShowModify(tab).modify_row = row
			end
		end
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerSection"..tab)) then
		if (self.ogf) then 
			self.ogf = {}
		end
		self:FillListView(tab)
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerSearchButton"..tab)) then 
		local selected = trim(ahkGetVar("UIOGFViewerSearch"..tab))
		if (selected and selected ~= "") then
			gSettings:SetValue("ogf_viewer","path"..tab,ahkGetVar("UIOGFViewerPath"..tab))
			gSettings:SetValue("ogf_viewer","check_browse_recur"..tab,ahkGetVar("UIOGFViewerBrowseRecur"..tab))
			gSettings:Save()
			
			if (self.ogf) then 
				self.ogf = {}
			end
			self:FillListView(tab)
		end
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerBrowsePath"..tab)) then
		local dir = FileSelectFolder("*"..(gSettings:GetValue("ogf_viewer","path"..tab) or ""))
		if (dir and dir ~= "") then
			GuiControl(self.ID,"","UIOGFViewerPath"..tab,dir)
		end
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerSaveSettings"..tab)) then
		local path = ahkGetVar("UIOGFViewerPath"..tab)
		if (path and path ~= "") then
			gSettings:SetValue("ogf_viewer","path"..tab,path)
		end
		gSettings:SetValue("ogf_viewer","check_browse_recur"..tab,ahkGetVar("UIOGFViewerBrowseRecur"..tab))
		gSettings:Save()
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerExecute"..tab)) then
		self:Gui("Submit|NoHide")
		if (self["ActionExecute"..tab]) then
			self["ActionExecute"..tab](self,tab)
		else 
			Msg("cUIOGFViewer:%s doesn't exist!","ActionExecute"..tab)
		end
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerLaunchMeshViewer"..tab)) then	
		local working_directory = ahkGetVar("A_WorkingDir")..[[\bin\OGFViewer\]]
		RunWait(working_directory.."OGFViewer.exe", working_directory)
	end
end

function cUIOGFViewer:Gui(...)
	self.inherited[1].Gui(self,...)
end

function get_relative_path(str,path)
	return trim(string.sub(path,str:len()+1))
end

_INACTION = nil

function cUIOGFViewer:FillListView(tab)
	LVTop(self.ID,"UIOGFViewerLV"..tab)
	LV("LV_Delete",self.ID)
	
	empty(self.list)

	local selected = trim(ahkGetVar("UIOGFViewerSection"..tab))
	if (selected == nil or selected == "") then 
		return Msg("FillListView error selected is %s",selected)
	end
	
	local dir = ahkGetVar("UIOGFViewerPath"..tab)
	if (dir == nil or dir == "") then
		return MsgBox("Please select a valid working directory")
	end
	
	gSettings:SetValue("ogf_viewer","check_browse_recur"..tab,ahkGetVar("UIOGFViewerBrowseRecur"..tab))
	
	for i=1,200 do 
		LV("LV_DeleteCol",self.ID,"1")
	end
			
	self["FillListView"..tab](self,tab,selected,dir,skip)
	
	LV("LV_ModifyCol",self.ID,"1","Sort CaseLocale")
	LV("LV_ModifyCol",self.ID,"1","AutoHdr")

	for i=1,200 do
		LV("LV_ModifyCol",self.ID,tostring(i+1),"AutoHdr")
	end
end

function cUIOGFViewer:FillListView1(tab,selected,dir,skip)
	local fields = {"filename","path"}
	for i=1,#fields do 
		LV("LV_InsertCol",self.ID,tostring(i),"",fields[i])
	end

	LV("LV_ModifyCol",self.ID,"1","AutoHdr")
	
	local search_str = trim(ahkGetVar("UIOGFViewerSearch"..tab))
	local function on_execute(path,fname)
		if (search_str == nil or search_str == "" or fname:match(search_str)) then
			self.list[path.."\\"..fname] = true
		end
	end
	
	file_for_each(dir,{"ogf","object"},on_execute,ahkGetVar("UIOGFViewerBrowseRecur"..tab) ~= "1")
	
	for k,v in pairs(self.list) do
		LV("LV_ADD",self.ID,"",trim_directory(k),k)
	end
end
-----------------------------------------------------------------
-- Modify UI
-----------------------------------------------------------------
UI2 = nil
UI3 = nil
function GetModify(tab)
	if (tab == "1") then
		if not (UI2) then 
			UI2 = cUIOGFViewerModify("2")
		end
		return UI2
	end
end

function GetAndShowModify(tab)
	local _ui = GetModify(tab)
	_ui:Show(true)
	return _ui
end
-----------------------------------------------------------------
-- UI Modify Class Definition
-----------------------------------------------------------------
--------------------------------------------------------------------------
-- Modify2 (tab3)
--------------------------------------------------------------------------
Class "cUIOGFViewerModify" (cUIBase)
function cUIOGFViewerModify:initialize(id)
	self.inherited[1].initialize(self,id)
end

function cUIOGFViewerModify:Show(bool)
	self.inherited[1].Show(self,bool)
end 

function cUIOGFViewerModify:Create()
	self.inherited[1].Create(self)
end

function cUIOGFViewerModify:Reinit()
	self.inherited[1].Reinit(self)
	
	--self:Gui("+AlwaysonTop")
	self:Gui("Font|s10|Verdana")
	
	local wnd = Get()
	if (wnd.listItemSelected == nil) then 
		return Msgbox("An error has occured. listItemSelected = nil!")
	end
	
	local full_path = wnd.listItemSelected
	if not (wnd.list[full_path]) then 
		return
	end
	
	self:Gui("Add|Text|w1000 h30 center|%s",trim_directory(full_path))
	local ext = get_ext(full_path)
	if (ext == "ogf") then
		self:process_ogf(full_path)
	elseif (ext == "object") then 
		self:process_eobj(full_path)
	end
	
 	self:Gui("Add|Button|gOnScriptControlAction x12 default vUIOGFViewerModifyAccept2|%t_accept")
	self:Gui("Add|Button|gOnScriptControlAction x+4 vUIOGFViewerModifyCancel2|%t_cancel")
	--self:Gui("+Resize +MaxSize1000x800 +0x200000")
	self:Gui("Show|center|%t_edit_values")
	self:Gui("Default")
end

function cUIOGFViewerModify:OnGuiClose(idx) -- needed because it's registered to callback
	self.inherited[1].OnGuiClose(self,idx)
end 

function cUIOGFViewerModify:Destroy()
	self.inherited[1].Destroy(self)
	
	Get().listItemSelected = nil 
end

function cUIOGFViewerModify:OnScriptControlAction(hwnd,event,info) -- needed because it's registered to callback
	self.inherited[1].OnScriptControlAction(self,hwnd,event,info)
	local tab = ahkGetVar("UIOGFViewerTab") or "1"
		
	if (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerModifyAccept2")) then
		local wnd = Get()
		local fname = wnd.listItemSelected
		local ogf = wnd.ogf[fname]
		if not (ogf) then 
			Msg("ogf is nil %s",fname)
			return
		end
		
		local ext = get_ext(fname)
		
		if (ext == "ogf") then
			local val
			for _,field in ipairs({"motion_refs","motion_refs2","lod_path","userdata"}) do
				val = ahkGetVar("UIOGFViewerModifyEdit2"..field)
				if (field == "motion_refs2" or field == "bones") then 
					ogf[field] = val ~= "" and str_explode(val,",") or {}
				else
					ogf[field] = trim(val)
				end
			end

			for _,field in ipairs({"texture","shader"}) do
				if (ogf.children) then
					for i,child in ipairs(ogf.children) do 
						val = ahkGetVar("UIOGFViewerModifyEdit2_child"..i.."_"..field)
						if (val and val ~= "") then
							child[field] = trim(val)
						end
					end
				end
			end
		elseif (ext == "object") then 
		
		end
		
		ogf:save()
		
		LVTop(wnd.ID,"UIOGFViewerLV"..tab)
		LV("LV_Modify",wnd.ID,self.modify_row,"",trim_directory(wnd.listItemSelected))
		
		self:Show(false)
	elseif (hwnd == GuiControlGet(self.ID,"hwnd","UIOGFViewerModifyCancel2")) then
		self:Show(false)
	end
end

function cUIOGFViewerModify:Gui(...)
	self.inherited[1].Gui(self,...)
end

function cUIOGFViewerModify:process_ogf(full_path)
	local wnd = Get()
	wnd.ogf[full_path] = wnd.ogf[full_path] or cOGF(full_path)

	if not (wnd.ogf[full_path]) then
		Msg("failed to load %s",full_path)
		return
	end 

	local params = wnd.ogf[full_path]:params()
	
	self:Gui("Add|Text|x5 y35 w700 h30|Source: %s",params.source_file)
	self:Gui("Add|Text|x5 y65 w700 h30|Build: %s",params.build_name)
	self:Gui("Add|Text|x5 y95 w700 h30|Created by: %s",params.create_name)
	self:Gui("Add|Text|x5 y125 w700 h30|Modified by:%s",params.modif_name)

	local y = 125+35
	for _,field in ipairs({"motion_refs","motion_refs2","lod_path","userdata","bones"}) do
		if (params[field]) then
			self:Gui("Add|Text|x5 y%s w300 h30|Skeleton %s",y,field)
			if (field == "userdata") then
				self:Gui("Add|Edit|x200 y%s w800 h30 vUIOGFViewerModifyEdit2%s|%s",y,field,params[field] or "")
			else
				self:Gui("Add|Edit|x200 y%s w800 h30 vUIOGFViewerModifyEdit2%s|%s",y,field,params[field] or "")
			end
			y = y + 30
		end
	end
	
	-- children
	for _,field in ipairs({"texture","shader"}) do
		if (wnd.ogf[full_path].children) then
			for i,child in ipairs(wnd.ogf[full_path].children) do 
				local child_params = child:params()
				if (child_params[field]) then
					self:Gui("Add|Text|x5 y%s w300 h30|Mesh%s %s",y,i,field)
					if (field == "userdata") then
						self:Gui("Add|Edit|x200 y%s w800 h30 vUIOGFViewerModifyEdit2_child%s_%s|%s",y,i,field,child_params[field])
					else
						self:Gui("Add|Edit|x200 y%s w800 h30 vUIOGFViewerModifyEdit2_child%s_%s|%s",y,i,field,child_params[field])
					end
					y = y + 30
				end
			end
		end
	end
end

function cUIOGFViewerModify:process_eobj(full_path)
	local wnd = Get()
	
	wnd.ogf[full_path] = wnd.ogf[full_path] or cEObject(full_path)
	if not (wnd.ogf[full_path]) then
		Msg("failed to load %s",full_path)
		return
	end 
	
	local obj = wnd.ogf[full_path]
	
	self:Gui("Add|Text|x5 y5 w700 h30|Surfaces: %s",obj.params.surfaces and #obj.params.surfaces or 0)
	local y = 35
	local x = 5
	for field,v in spairs(obj.params) do 
		if (field == "surfaces") then 
			for i,t in ipairs(v) do
				for kk,vv in spairs(t) do
					if (type(vv) == "number") then 
						w = 50
					else 
						w = 200
					end 
					self:Gui("Add|Edit|x%s y%s w%s h30 vUIOGFViewerModifyEdit2%s%s|%s",x,y,w,kk,i,vv or "")
					x = x + w
				end
				x = 5
				y = y + 35
			end
		else
			x = 5
			self:Gui("Add|Edit|x5 y%s w1000 h30 vUIOGFViewerModifyEdit2%s|%s",y,field,v or "")
			y = y + 35
		end
	end
end