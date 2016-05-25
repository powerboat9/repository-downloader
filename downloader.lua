local user, repo, savePath, gitPath, branch = ...

local function getBaseURL(path)
    path = fs.combine(gitPath, path)
    return baseURL = ("https://api.github.com/repos/%s/%s/contents/%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

local function getTime()
    return os.time() + os.day() * 24000
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

local function save(url, h)
    if downloads[url] and (downloads[url].type == "file") then
        local file = fs.open(downloads[url].path, "w")
        file.write(h.readAll())
        file.close()
    end
    h.close()
end

local function fail()
    url = coroutine.yield()
    if downloads[url] then
        local old = term.getBackgroundColor()
        term.write("Downloading \"")
        local new
        if term.isColor() then new = colors.blue else new = colors.grey end
        term.setTextColor(new)
        term.write(url)
        term.setBackgroundColor(old)
        term.write("\" failed")
        return true
    end
    return false
end

local explore = coroutine.create(function()
    while true do
        local _, url
