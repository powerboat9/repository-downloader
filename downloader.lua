local tArgs = {...}
local user = tArgs[1]
local repository = tArgs[2]
local gitPath = tArgs[3] --"/folder/folder/file"
local URL = "http://api.github.com/repos/" .. user .. "/" .. repository .. "/contents" .. gitPath .. "/"

function getFileDownloadURLs(url, gatheredFiles, gatheredDirectories)
    assert(url, "url invalid")
    local json = http.get(url)
    assert(json, "http.get failed")
    json = json:gsub("%s*\n%s*", "") --removes white space around '\n' and '\n'
    json = json:gsub("\"(.-)\"%s*:%s*", "%1 : ") --turns '"hi": ' into 'hi = '
    json = json:sub(2, almostJSON - 1) --removes brackets around the almostJSON
    local jsonTable = textutils.unserialize(json)
    local files = gatheredUrls or {}
    local directories = gatheredDirectories or {}
    for v in ipairs(jsonTable) do
        if v.type == "file" then
            files
