local tArgs = {...}
local user = tArgs[1]
local repository = tArgs[2]
local gitPath = tArgs[3] or "/"--"/folder/folder/file/" or "/" for root
local branch = tArgs[5] or nil
local URL = "http://api.github.com/repos/" .. user .. "/" .. repository .. "/contents" .. gitPath .. (branch and "?ref=" or "") .. (branch or "")
local removeLuaExtention = tArgs[4] or true

function getFileDownloadURLs(url, gatheredFiles, gatheredDirectories)
    assert(url, "url invalid")
    print("Downloading " .. url)
    local handle = assert(http.get(url), "Getting " .. url .. " failed")
    assert(handle.readAll(), "Reading failed for url " .. url)
    local json = handle.readAll()
    assert(json, "http.get failed to get " .. url)
    json = json:gsub("%s*\n%s*", "") --removes white space around '\n' and '\n'
    json = json:gsub("\"(.-)\"%s*:%s*", "%1 : ") --turns '"hi": ' into 'hi = '
    json = json:sub(2, almostJSON - 1) --removes brackets around the almostJSON
    local jsonTable = textutils.unserialize(json)
    local files = gatheredUrls or {}
    local directories = gatheredDirectories or {}
    for v in ipairs(jsonTable) do
        if v.type == "file" then
            files[#files + 1] = {url = v.download_url, path = v.path}
        elseif v.type == "dir" then
            directories[#directories + 1] = v.url
        end
    end
    local recursiveURL = directories[1]
    directories = table.remove(directories, 1)
    if #directories > 0 then
        return getFileDownloadURLs(recursiveURL, files, directories)
    end
    return files
end

for v in ipairs(getFileDownloadURLs(URL)) do
    if (v.path:sub(#v.path - 3) == ".lua") and removeLuaExtention then
        v.path = v.path:sub(1, #v.path - 4)
    end
    print("Saving " .. v.url .. " as " .. repository .. "/" .. v.path)
    local writeFile = fs.open(repository .. "/" .. v.path)
    local webHandle = assert(http.get(v.url), "Getting " .. v.url .. " failed")
    local webContents = assert(webHandle.readAll(), "Reading " .. v.url .. " failed")
    writeFile.write(http.get(v.url))
    writeFile.close()
end
