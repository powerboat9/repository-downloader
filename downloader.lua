local user, repo, savePath, gitPath, branch = ...

local function getBaseURL(path)
    path = fs.combine(gitPath, path)
    return baseURL = ("https://api.github.com/repos/%s/%s/contents/%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

local function exit(crashed)
    local msg
    if crashed then
        printError(

local downloads = {}
local function download(path, type)
    local sPath = fs.combine(savePath, path)
    local downURL = getURL(gPath)
    downloads[downURL] = {type = type, path = sPath}
    http.request(downURL)
end

local save = coroutine.create(function()
    while true do
        local _, url, h = os.pullEvent("http_success")
        if downloads[url] and (downloads[url].type == "file") then
            local file = fs.open(downloads[url].path, "w")
            file.write(h.readAll())
            file.close()
        end
        h.close()
    end
end

local retry = {}
local fail = coroutine.create(function()
    while true do
        local _, url = os.pullEvent("http_failure")
        if downloads[url] then
            
