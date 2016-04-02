local tArgs = {...}

function printUsage()
    print("Usage: [options] user repository\n\n    -b: specifies a branch other than the default\n\n    -p: the path the files are downloaded to, defaults to the name of the repository\n\n    -g: the path files are downloaded from in the repository\n\n    -v: makes the program verbose\n\n    -q: make the program silent, can't be present with option -v\n\n    -l: removes the .lua extension from files")
end

function equals(v, ...)
    local args = {...}
    for _, compare in ipairs(args) do
        if v == compare then
            return true
        end
    end
    return false
end

local wrongParam = function(p, tier)
    tier = (tier and (tier > 0) and tier) or 1
    error("Invalid Options, Did Not Use \"" .. p .. "\" Correctly", tier + 1)
end

local user = ""
local repository = ""
local gitPath = ""
local branch = ""
local myPath = "" --The path files are moved to
local removeLuaExtention = false

local mode = 0 --0 is normal, 1 is verbose, 2 is silent

local done = {}

local nextParam = ""
for k, v in ipairs(tArgs) do
    if equals(v, "-b", "-p", "-g") then --"-v", "-q", "-l"
        if nextParam ~= "" then
            wrongParam(nextParam, 2)
        end
        nextParam = v
        done[v:sub(2, -1)] = true
    elseif v == "-v" then
        if done.vOrQ then wrongParam(v, 2) end
        done.vOrQ = true
        mode = 1
    elseif v == "-q" then
        if done.vOrQ then wrongParam(v, 2) end
        done.vOrQ = true
        mode = 2
    elseif v == "-l" then
        if done.l then wrongParam(v, 2) end
        done.l = true
        removeLuaExtension = true
    elseif nextParam ~= "" then
        if nextParam == "-b" then
            branch = v
        elseif nextParam == "-p" then
            myPath = v
        elseif nextParam == "-g" then
            gitPath = v
        end
        nextParam = ""
    else
        user = v
        repository = tArgs[k + 1]
        break
    end
end

if not (user and repository) then
    error("Invalid User or Repository", 2)
end

myPath = myPath or ("/" .. repository)
local URL = "https://api.github.com/repos/" .. user .. "/" .. repository .. "/contents" .. gitPath .. (branch and "?ref=" or "") .. (branch or "")

function getPath(s)
    local returnPath = {}
    for name in s:gfind("([^/]*)/") do
        returnPath[#path + 1] = name
    end
    return returnPath
end

function getFilesInDir(json)
    if type(json) == "string" then
        json = json:gsub("%s*\n%s*", "") --removes '\n' and the whitespace around it
        json = json:gsub("\"([^\"]*)\"%s*:%s*", "%1 = ") --turns '"hi": ' into 'hi = '
        json = json:sub(2, -2) --removes brackets around the almostJSON
        json = "{" .. json .. "}" --adds curly brackets
        json = assert(textutils.unserialize(json), "Failed to unserialize:\n" .. json)
    else
        error("Invalid type for JSON input", 2)
    end
    local searchDirs, files, symlinks = {}, {}
    for k, v in ipairs(json) do
        local getName = function(p) --Gets the name from a path
            local namePos = {p:find("[^/]*$")}
            return p:sub(namePos[1], namePos[2])
        end
        if v.type == "file" then
            files[#files + 1] = {url = v.download_url, path = v.path, name = v.name}
        elseif v.type == "dir" then
            searchDirs[#searchDirs + 1] = {url = v.url, path = v.path, name = v.name}
        elseif v.type == "symlink" then
            symlinks[#searchDirs + 1] = {path = v.target, name = getName(v.target)}
        end
    end
end

downloading = {}
function download(url)
    http.request(url)
    downloading[#downloading + 1] = url
end

function downloadMulti(...)
    local data = {}
    local args = {...}
    for _, v in args do
        download(v)
        data[v] = false
    end
    while true do
        e, url, handle = os.pullEvent()
        if ((e == "http_success") or (e == "http_failure)) and (data[url] == false) then
            
end

function getFileDownloadURLs(url, gatheredFiles, gatheredDirectories)
    assert(url, "url invalid")
    print("Downloading " .. url)
    local handle = assert(http.get(url), "Getting " .. url .. " failed")
    local json = assert(handle.readAll(), "Reading failed for url " .. url)
    local jsonTable = getFilesInDir(json)
    local files = gatheredFiles or {}
    local directories = gatheredDirectories or {}
    for k, v in ipairs(jsonTable) do
        if v.type == "file" then
            files[#files + 1] = {url = v.download_url, path = v.path}
        elseif v.type == "dir" then
            directories[#directories + 1] = v.url
        end
    end
    local recursiveURL = directories[1]
    if not recursiveURL then
        return files
    end
    if recursiveURL then
        table.remove(directories, 1)
        return getFileDownloadURLs(recursiveURL, files, directories)
    end
end

while true do
    download()

for k, v in ipairs(getFileDownloadURLs(URL)) do
    if (v.path:sub(#v.path - 3) == ".lua") and removeLuaExtention then
        v.path = v.path:sub(1, #v.path - 4)
    end
    print("Saving " .. v.url .. " as " .. repository .. "/" .. v.path)
    local writeFile = fs.open(repository .. "/" .. v.path, "w")
    local webHandle = assert(http.get(v.url), "Getting " .. v.url .. " failed")
    local webContents = assert(webHandle.readAll(), "Reading " .. v.url .. " failed")
    writeFile.write(webContents)
    writeFile.close()
end
