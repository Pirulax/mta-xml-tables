xmlFindChild = function(parentNode, childName)
    for _, childNode in pairs(xmlNodeGetChildren(parentNode)) do
        if (xmlNodeGetName(childNode)==childName) then
            return childNode
        end
    end
    return false
end


function writeTableToXml(path, rootNodeName, table)--> the caller funcion
    assert(type(path)=="string",     "Expected string at argument 1 @ writeTableToXml[Got "..type(path).."]"    )
    assert(type(table)=="table",     "Expected table at argument 2 @ writeTableToXml[Got "..type(table).."]"    )
    assert(type(rootNodeName)=="string", "Expected string at argument 3 @ writeTableToXml[Got "..type(rootNode).."]")
    local xmlFile = getXmlFileFromPath(path)
    if (xmlFile) then
        rootNodeIndex = rootNodeIndex or "0"
        --> because the node already exists it will add the childrens to this node again with the same name, and we will have a corrupted table later, so
        --> We destroy it, and then recreate it.
        local node = findNode(xmlFile, rootNodeName)
        if (node) then
            local pNode = xmlFile
            local pName = rootNodeName
            if (node) then
                pNode = xmlNodeGetParent(node)
                pName = xmlNodeGetName(node)
                xmlDestroyNode(node)   
            end
            local result = writeTableToXmlRecursive(xmlCreateChild(pNode, pName), table)
            xmlSaveFile(xmlFile)
            xmlUnloadFile(xmlFile)
            return result
        else
            print("Failed to find/recreate the node.")
            return false
        end
    end
    return false
end

function writeTableToXmlRecursive(parentNode, table)
    for i, v in pairs(table) do
        --> If the value isnt a table
        local node = xmlCreateChild(parentNode, (type(i)=="number" and "__numIndex__") or (i))
        if (type(i)=="number") then
            xmlNodeSetAttribute(node, "index", i)  
        end
        if not (type(v)=="table") then      
            xmlNodeSetValue(node, tostring(v))
            xmlNodeSetAttribute(node, "valueType", type(v))
        else
            writeTableToXmlRecursive(node, v)
        end
    end
    return true
end

function getTableFromXml(path, rootNodeName) 
    rootNodeIndex = rootNodeIndex or 0
    local xmlFile = getXmlFileFromPath(path)
    if (xmlFile) then    
        local node = findNode(xmlFile, rootNodeName)
        if (node) then
            local tbl = getTableFromXmlRecursive(node)
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

function getTableFromXmlRecursive(parentNode)
    local tbl = {}
    for _, node in pairs(xmlNodeGetChildren(parentNode)) do
        local nName = xmlNodeGetName(node)
        local nValue = xmlNodeGetValue(node)
        local nValueType = xmlNodeGetAttribute(node, "valueType") or "table"
        nValue = ((nValueType=="table" or nValueType=="") and getTableFromXmlRecursive(node)) or nValue
        if (nValueType=="number") then
            nValue = tonumber(nValue)
        elseif (nValueType=="boolean") then
            nValue = nValue=="true"
        end
        tbl[((nName=="__numIndex__") and tonumber(xmlNodeGetAttribute(node, "index"))) or nName] = nValue
    end
    return tbl
end

function getXmlFileFromPath(path)
    return (fileExists(path) and xmlLoadFile(path, "root")) or (xmlCreateFile(path,  "root"))
end
