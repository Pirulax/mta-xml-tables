
--> xml functions
function writeXmlFromTable(path, rootNode, table, rootNodeIndex)--> the caller funcion
    local xmlFile = getXmlFileFromPath(path)
    if (xmlFile) then
        rootNodeIndex = rootNodeIndex or 0
        --> because the node already exists it will add the childrens to this node again with the same name, and we will have a corrupted table later, so
        --> We destroy it, and then recreate it.
        xmlDestroyNode(xmlFindChild(xmlFile, rootNode, rootNodeIndex))       
        local result = writeXMLFromTableRecursive(xmlCreateChild(xmlFile, rootNode), table)
        xmlSaveFile(xmlFile)
        xmlUnloadFile(xmlFile)
        return result
    else
        return result, "Failed to read/create "..path
    end
end

function writeXMLFromTableRecursive(parentNode, table)
    local numberedIndexStr = ""
    for i, v in pairs(table) do
        --> loop thru the table
        --> create a new attribute at the index if its not a table
        if not (type(v)=="table") then
            --> if the index is a number, then we will save the key-value pair to the numberedIndexStr string.
            if (type(i)=="number") then
                numberedIndexStr = numberedIndexStr..string.format("%i:%s;", i, v)
            else
                xmlNodeSetAttribute(parentNode, i, tostring(v))
            end
        else--> if its a table then we use recursivity and call this funcion again, and create a new node for the table index.   
            writeXMLFromTableRecursive(xmlCreateChild(parentNode,  i), v)
        end
    end
    if (#numberedIndexStr>0) then--> Only then create the node if the numberedIndexStrs lenght is more than 0.
        xmlNodeSetAttribute(parentNode,  "numberedIndex", string.sub(numberedIndexStr, 0, #numberedIndexStr-1))--> Because we'll have an unused ';' at the end of the string, which is 2char wide.
    end
    return true
end

function getTableFromXml(path, rootNode, rootNodeIndex) 
    rootNodeIndex = rootNodeIndex or 0
    local xmlFile = getXmlFileFromPath(path)
    if (xmlFile) then    
        local node = xmlFindChild(xmlFile, rootNode, rootNodeIndex)
        if (node) then
            local tbl = loadTableFromXmlRecursive(node)
            xmlSaveFile(xmlFile)
            xmlUnloadFile(xmlFile)
            if (tbl) then         
                return tbl, "Success"
            else
                return false, "Something went wrong"
            end    
        else
            return false, "Failed to find child at the given index."
        end
    else
        return false, "Failed to read/create "..path
    end
end

function loadTableFromXmlRecursive(parentNode)
    --> we create an empty table
    local tbl = {}
    --> get the atts of it, and loop thru them.
    for attName, attValue in pairs(xmlNodeGetAttributes(parentNode)) do
        --> If its not the numberedIndex att. then we just add the key-value pair to the table.
        if not (attName=="numberedIndex") then
            if (attValue:find("(true)")) or (attValue:find("(false)")) then
                tbl[attName] = attValue=="true"
            elseif (tonumber(attValue)) then
                tbl[attName] = tonumber(attValue)
            else
                tbl[attName] = attValue
            end
        else--> If its the numberedIndex att then we add the indexes to the table.
            for _, keyValuePair in pairs(split(attValue, ";")) do
                --> the first gettok is the key, the second is the value.
                tbl[gettok(keyValuePair, 1, ":")] = gettok(keyValuePair, 2, ":")
            end
        end
    end
    --> and the childrens, and loop thru them,
    for _, node in pairs(xmlNodeGetChildren(parentNode)) do
        tbl[xmlNodeGetName(node)] = loadTableFromXmlRecursive(node)
    end
    return tbl
end


function getXmlFileFromPath(path)
    return (fileExists(path) and xmlLoadFile(path, "root")) or (xmlCreateFile(path,  "root"))
end
