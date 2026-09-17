--[[
	noeadir.lua - hide Synology "@eaDir" directories from VLC.

	Synology NAS units create an "@eaDir" directory inside every shared
	folder, holding thumbnails and indexing metadata. Inside it there are
	subdirectories named exactly like your videos, for example
	"@eaDir/movie.mp4/SYNOINDEX_MEDIA_INFO". When you open a NAS folder,
	VLC expands it recursively and the playlist fills up with unplayable
	duplicates. Filtering by extension does not help, because the bogus
	directory is itself named "movie.mp4".

	This script removes those entries from the playlist. It NEVER touches
	the disk: it only calls vlc.playlist.delete(), which drops an entry
	from the playlist. Files and folders on the NAS are left alone.

	See README.md for installation.
]]--

-- How often to re-check the playlist. The shorter it is, the less likely
-- VLC is to try opening an "@eaDir" entry before it gets removed.
local POLL_INTERVAL = 200000 -- microseconds

-- Lowercase path components to hide.
-- VLC percent-encodes "@" as %40 in URIs, so both spellings are needed.
local BLOCKED = {
	["@eadir"] = true,
	["%40eadir"] = true,
}

-- true if the URI goes through a directory we want to hide. Whole path
-- components are compared, not substrings, so a file that merely happens
-- to contain "@eaDir" in its name is kept.
local function is_blocked(path)
	if not path then
		return false
	end
	for component in string.gmatch(string.lower(path), "[^/]+") do
		if BLOCKED[component] then
			return true
		end
	end
	return false
end

-- Collect the ids of the nodes to hide. Subtrees of an already matched
-- node are not visited: removing the parent removes its children too.
local function collect(node, ids)
	if is_blocked(node.path) then
		table.insert(ids, node.id)
		return
	end
	for _, child in ipairs(node.children or {}) do
		collect(child, ids)
	end
end

local function clean()
	local ok, playlist = pcall(vlc.playlist.get, "playlist", true)
	if not ok or type(playlist) ~= "table" then
		return 0
	end

	local ids = {}
	collect(playlist, ids)
	for _, id in ipairs(ids) do
		-- removes the playlist entry, not the file on disk
		pcall(vlc.playlist.delete, id)
	end
	if #ids > 0 then
		vlc.msg.info("[noeadir] hid " .. #ids .. " @eaDir entries")
	end
	return #ids
end

local function run()
	while true do
		clean()
		vlc.misc.mwait(vlc.misc.mdate() + POLL_INTERVAL)
	end
end

vlc.msg.info("[noeadir] @eaDir filter active")
local ok, err = pcall(run)
-- mwait raises "Interrupted." when VLC shuts the interface down
if not ok and not string.find(tostring(err), "Interrupted") then
	vlc.msg.err("[noeadir] error: " .. tostring(err))
end
