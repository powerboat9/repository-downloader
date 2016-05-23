local user, repo, savePath, gitPath, branch = ...

local downloads = {}
local function download(path)
    local path
