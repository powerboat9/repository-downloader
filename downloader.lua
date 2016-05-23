local user, repo, savePath, gitPath, branch = ...

local baseURL = ("https://api.github.com/repos/%s/%s/contents/"):format(user, repo) .. "%s" .. (branch and ("?ref=" .. branch)) or ""
local function getURL(path)
    return baseURL:format(path)
end

local downloads = {}
local function download(path)
    local gPath = fs.combine(gitPath, path)
    local sPath = fs.combine(savePath, path)
    local downURL = getURL(gPath)
    downloads[downURL] = sPath
    http.request(downURL)
end

local save = coroutine.create("
