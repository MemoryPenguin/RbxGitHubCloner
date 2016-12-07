local BaseApiUrl = "https://api.github.com/"
local BaseRawUrl = "https://raw.githubusercontent.com/"
local DefaultTag = "master"

local HttpService = game:GetService("HttpService")

local HttpBroker = require(script.Parent.HttpBroker)

local broker = HttpBroker.new(200)

local GitHubCloner = {}

function GitHubCloner.Clone(user, repository, tag, apiKey)
	tag = tag or DefaultTag
	local files = {}
	
	-- Can't set User-Agent so going to use From
	local headers = {
		["From"] = "ROBLOX GitHub Cloner: MemoryPenguin/RbxGitHubCloner";
	}
	
	if apiKey ~= nil and apiKey ~= "" then
		headers["Authorization"] = "token "..apiKey
	end

	local success, treeListingJson = broker:Get(("%srepos/%s/%s/git/trees/%s?recursive=1"):format(BaseApiUrl, user, repository, tag), false, headers)
	if not success then
		error("[GitHubCloner]: Could not retrieve file tree for user "..user.."'s repository "..repository.."@"..tag..": "..treeListingJson, 0)
	end

	local treeListing = HttpService:JSONDecode(treeListingJson)
	if treeListing.truncated then
		warn("[GitHubCloner]: Truncated tree received for user "..user.."'s repository "..repository.."@"..tag.."; not all files can be retrieved.")
	end

	for _, entry in ipairs(treeListing.tree) do
		if entry.type == "blob" then
			local url = ("%s%s/%s/%s/%s"):format(BaseRawUrl, user, repository, tag, entry.path)
			local success, contents = broker:Get(url, false, headers)
			
			if not success then
				error("[GitHubCloner]: Could not get file at "..url..": "..contents, 0)
			end
			
			table.insert(files, {
				Path = entry.path;
				Content = contents;
				Sha = entry.sha;
			})
		end
	end

	return files
end

function GitHubCloner.GetRateLimit()
	local success, limitsJson = broker:Get(("%srate_limit"):format(BaseApiUrl), false, {
		["From"] = "ROBLOX GitHub Cloner: MemoryPenguin/RbxGitHubCloner";
	})

	if success then
		local rawLimits = HttpService:JSONDecode(limitsJson)
		return {
			Limit = rawLimits.resources.core.limit;
			Remaining = rawLimits.resources.core.remaining;
			ResetsAt = rawLimits.resources.core.reset;
		}
	else
		error(limitsJson)
	end
end

return GitHubCloner