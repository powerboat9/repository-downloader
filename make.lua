local fName = ...

fName = type(fName) == "string" and fs.exists(fName) and not fs.isDir(fName) and fName or error("Invalid file " .. tostring(fName))

local data
do
    local file = fs.open(fName, "r")
    data = file.read all()
    file.close()
end

local includes = {}

local line1 = data:gsub("^([^\n]*).*", "%1")
data = data:gsub("^[^\n]*\n(.*)", "%1")

if line1 == "
