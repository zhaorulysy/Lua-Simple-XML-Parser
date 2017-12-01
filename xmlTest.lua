
--  xml:ParseXmlText(xmlString) or xml:loadFile(xmlFilename, base)
local zrPrint = require("ZrPrint")
local xmlParse = require("xmlParse")
local config = require("config")

if not config then
	error("First xml filename config is not finish ")
end

xmlParse.isParsePackage = true
xmlParse:changePackage()

pgLua = xmlParse:XmlPathToLuaTb(xmlParse.PATH .. "/package.xml")
UseInfo = {}
for k,v_node in pairs(pgLua) do
	if "table" == type(v_node) and v_node["resources"] then
		UseInfo = v_node["resources"]
	end
end

xmlParse.isParsePackage = false
xmlParse:changePackage()

local HeadXml = xmlParse.PATH .. "/" .. config
local PlayViewLua = xmlParse:XmlPathToLuaTb(HeadXml)

xmlParse:FindSubTb(PlayViewLua)
xmlParse:SpecialButtonHandle(PlayViewLua)
xmlParse:CancelNextLayer(PlayViewLua)
xmlParse:sortByPlus(PlayViewLua)
local b,e,fileName = string.find(config,"/(%g+).xml")
if b then
	xmlParse:AddFirstLayerClassName(PlayViewLua, fileName)
	zrPrint.GetLuaFile(PlayViewLua, fileName)
else
	error("config file name has something wrong")
end	

-- zrPrint.p(UseInfo)


