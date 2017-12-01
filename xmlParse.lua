-- local zrPrint = require("ZrPrint")
local xml = require("xmlSimple")

local xmlParse = {}

xmlParse.isParsePackage = false;
xmlParse.PATH = "input"

function xmlParse:changePackage()
	xml.isPackage = xmlParse.isParsePackage
end

function xmlParse:getPropsTable(v_node)
	local propTable = {}
	local indexName = nil
	
	if "table" == type(v_node) and v_node.name and v_node:name() then
		
		local propArray = v_node:properties()
		local propArrayNumber = v_node:numProperties()
		if "displayList" == v_node:name() then
			v_node:setName("Children")
		else
			propTable["@prop"] = v_node:name()
		end
		-- propTable["@prop"] = v_node:name()
		propTable["plus"] = v_node["@plus"]
		indexName = v_node:name()
		
		for i = 1, propArrayNumber do
			local propName = propArray[i].name
			local propValue = v_node["@" .. propName]
			if "size" == propName then
				local b,e,xValue,yValue = string.find(propValue,"(%g+),(%g+)")
				propTable["width"] = xValue
				propTable["height"] = yValue
			elseif "xy" == propName then
				local b,e,xValue,yValue = string.find(propValue,"(%g+),(%g+)")
				propTable["x"] = xValue
				propTable["y"] = yValue
			else
				propTable[propName] = propValue
			end
			if xmlParse.isParsePackage then
				if propName == "id" then
					indexName = propValue
				end
			else
				if propName == "name" then
					indexName = propValue
				end
				
			end
		end
		
	else
		error("getPropsTable parameter has somethings wrong")
	end
	
	return indexName, propTable
end
--深度遍历 整合属性
function xmlParse:dfsTravers(node, saveData)
	
	for k, v_node in pairs(node) do
		if "table" == type(v_node) and v_node.name and v_node:name() then
			
			local tmpIndex,tmpProps
			tmpIndex, tmpProps = self:getPropsTable(v_node);
			if tmpIndex and tmpProps and "table" == type(tmpProps) then
				
				saveData[tmpIndex] = tmpProps
				self:dfsTravers(v_node, saveData[tmpIndex])
			else
				error(" getPropsTable function return nil ")
			end
		elseif "table" == type(v_node) and #v_node >= 1 then
			if k ~= "___children" and k ~= "___props" then
				-- saveData[k] = {} 
				self:dfsTravers(v_node, saveData)
				
			end
		end
	end
	
end

--Get Lua Table form xmldata which base on path and name
function xmlParse:XmlPathToLuaTb(xmlName)
	local XmlData = xml:loadFile(xmlName)
	local LuaData = {}
	self:dfsTravers(XmlData, LuaData)
	
	return LuaData
end	

function xmlParse:FromSrcToPathInfo(infoTb,SRC)
	local tmpInfo = infoTb[SRC]
	if not tmpInfo then
		error("FromSrcToPathInfo parameter has something wrong")
	end
	return tmpInfo
end

function xmlParse:FromSrcToTb(infoTb,SRC)

	local tmpInfo = self:FromSrcToPathInfo(infoTb,SRC)
	local FullPath = xmlParse.PATH .. tmpInfo.path .. tmpInfo.name
	if string.find(FullPath, ".xml") then
		local LuaFormXml = {}
		
		LuaFormXml = self:XmlPathToLuaTb(FullPath)
		return LuaFormXml
	else
		return nil
	end
end

--在package总的列表中获得下一个xml信息并封装到@next
function xmlParse:FindSubTb(HeadTable)

	for k,v_table in pairs(HeadTable) do
		if "table" == type(v_table) then
			if v_table["src"] then
			
				local PackageInfo = self:FromSrcToPathInfo(UseInfo,v_table["src"])
				if not string.find(PackageInfo.name, ".xml") then
					v_table["path"] = PackageInfo.path .. PackageInfo.name
					for k,v in pairs(PackageInfo) do
						if "@prop" == k and v_table["@prop"] ~= v then
							error("xmlParse:FindSubTb  has something wrong")
						end
						if "path" ~= k and "name" ~= k 
							and "@prop" ~= k and "id" ~= k then
							v_table[k] = v
						end
					end
				end
				
				local SubLua = self:FromSrcToTb(UseInfo,v_table["src"])
				if SubLua then
					if "table" == type(SubLua) then
						v_table["@next"] = {}
						v_table["@next"] = SubLua
						local b,e,Name = string.find(PackageInfo.name,"(%g+).xml")
						v_table["@next"]["Classname"] = Name
						self:FindSubTb(SubLua)
					
					end
				end
			else
				self:FindSubTb(v_table)
			end
		end	
	end	
end

function xmlParse:isButtonNode(Node)
	if "table" == type(Node) then
		if Node["@next"] and Node["@next"]["component"] 
			and "Button" == Node["@next"]["component"]["extention"] then
			
			local Name = Node["@next"]["Classname"]
			local tmpComponent = Node["@next"]["component"]
			local width = tmpComponent.width
			local height = tmpComponent.height
			local normalImg = nil
			local selectImg = nil
			for k,v in pairs(tmpComponent["Children"]) do
				if "table" == type(v) and v["gearDisplay"] then
					if string.find(v["gearDisplay"]["pages"],"1") then
						selectImg = v["path"]
					else
						normalImg = v["path"]
					end
				end
			end
			if not Node.width then
				Node.width = width
			end
			if not Node.height then
				Node.height = height
			end
			Node["Classname"] = Name
			Node["normalImg"] = normalImg
			Node["selectImg"] = selectImg
			Node["@prop"] = "Button"
			Node["@next"] = nil
			
			return true
		end	
	end
	return false
end

function xmlParse:SpecialButtonHandle(SemiFinishTb)
	
	for k,v_node in pairs(SemiFinishTb) do
		if "table" == type(v_node) then
			if not self:isButtonNode(v_node) then
				self:SpecialButtonHandle(v_node)
			end
		end	
	end
	
end

function xmlParse:isNextLayer(Node)
	if "table" == type(Node) then
		if Node["@next"] and Node["@next"]["component"] then
			local Name = Node["@next"]["Classname"]
			local tmpComponent = Node["@next"]["component"]
			tmpComponent["@prop"] = nil
			Node["Classname"] = Name
			
			for k,v in pairs(tmpComponent) do
				if k ~= "plus" then
					Node[k] = v
				end
			end
			Node["@next"] = nil;
		end	
	end
	
end

function xmlParse:CancelNextLayer(SemiFinishTb)
	for k,v_node in pairs(SemiFinishTb) do
		if "table" == type(v_node) then
			self:isNextLayer(v_node)
			self:CancelNextLayer(v_node)
		end	
	end
end

function xmlParse:AddFirstLayerClassName(SemiFinishTb, ClassName)
	for k,v_com in pairs(SemiFinishTb) do
		if v_com["Children"] then
			v_com["Classname"] = ClassName
			v_com["name"] = ClassName
		end
	end
end

function xmlParse:sortByPlus(SemiFinishTb)
	
	for k,v_node in pairs(SemiFinishTb) do
		if "table" == type(v_node) then
			if v_node["Children"] then
				local tmpChildren = {}
				for c_k,c_v in pairs(v_node["Children"]) do
					if "table" == type(c_v) then
						table.insert(tmpChildren, c_v)
					end
				end
				
				table.sort(tmpChildren, function(a, b)
					return tonumber(a["plus"]) < tonumber(b["plus"])
				end)
				
				v_node["Children"] = tmpChildren;

			end
			
			self:sortByPlus(v_node)
		end
	end
		
	
end

return xmlParse
