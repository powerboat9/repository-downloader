local user, repo, savePath, gitPath, branch = ...

local function getBaseURL(path)
    path = fs.combine(gitPath, path)
    return baseURL = ("https://api.github.com/repos/%s/%s/contents/%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

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
        if downloads[url] then
            if downloads
