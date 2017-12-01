--[[--
   
    Zr：添加打印功能
    
 ]]


local ZrPrint = {}


function ZrPrint.p(data)
	print("#############core.print data zrp###########");
	local cstring = ""
	ZrPrint.tableprint(data,cstring)
end

function ZrPrint.tableprint(data,cstring)
	
	local data_type = type(data)
	
	local cs = cstring .. "	"
	print(cstring .."{")
	
	if(data_type == "table") then
		for k, v in pairs(data) do
			if type(v) ~= "function" then
				print(cs..tostring(k).." = "..tostring(v))
				
			end
			if(type(v)=="table") 
				and k ~= "___children" 
				then
				ZrPrint.tableprint(v,cs) 
			end
		end
	else
		print(cs..tostring(data))
		
	end
	print(cstring .."}")
	
end

function ZrPrint.WriteFile(WriteInfo, file)
	
	local data_type = type(WriteInfo)
	if "table" == data_type then
		file:write(" {")
		for k,v in pairs(WriteInfo) do
			file:write(" [\"" .. k .. "\"]" .. " = ")
			if "table" == type(v) then
				ZrPrint.WriteFile(v, file)
			else
				file:write("\"" .. tostring(v) .. "\", ")
			end
		end
		file:write(" };")
	else
		file:write(tostring(WriteInfo))
	end
	
end

function ZrPrint.GetLuaFile(WriteInfo, fileName)
	local f=assert(io.open("output\\" .. fileName ..".lua",'w'))
	f:write("local UIInfo = ")
	ZrPrint.WriteFile(WriteInfo, f)
	f:write("\n return UIInfo")
	f:close()
end

return ZrPrint;
