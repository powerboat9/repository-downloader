local tArgs = {...}
local user = tArgs[1]
local repository = tArgs[2]
local gitPath = tArgs[3] or "/"--"/folder/folder/file" or "/" for root
local branch = tArgs[5] or nil
local URL = "https://api.github.com/repos/" .. user .. "/" .. repository .. "/contents" .. gitPath .. (branch and "?ref=" or "") .. (branch or "")
local removeLuaExtention = tArgs[4] or true

function getFilesInDir(json)
    json = json:gsub("%s*\n%s*", "") --removes '\n' and the whitespace around it
    json = json:gsub("\"([^\"]*)\"%s*:%s*", "%1 = ") --turns '"hi": ' into 'hi = '
    json = json:sub(2, -2) --removes brackets around the almostJSON
    json = "{" .. json .. "}" --adds curly brackets
    local data = assert(textutils.unserialize(json), "Failed to unserialize:\n" .. json)
    local returnData = {}
    for k, v in ipairs(data) do
        local getPath = function(s)
            local path = {}
            for name in s:gfind("([^/]*)/") do
                path[#path + 1] = name
            end
            return path
        end
        if v.type == "file" then
            
            --returnData.files[#returnData.files + 1] = {url = v.download_url, path = v.path, name = v.name}
        elseif v.type == "dir" then
            returnData.dir[#returnData.dir + 1] = {url = v.url, path = v.path, name = v.name}
            elseif v.type == "s
end

downloading = {}
function download(url)
    http.request(url)
    downloading[#downloading + 1] = url
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

while true do
