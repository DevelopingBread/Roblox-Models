local Debris = game:GetService('Debris')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Events = ReplicatedStorage:WaitForChild('Events')

local tagging = {}

-- How 2 use lol
-- Use server script to .Link a player by doing game.Players.PlayerAdded:Connect(function() module.Link() end) this can check if player died and stuff
-- use :Add to add a tag when someone get's hit or dammaged (player, attacker, damage (adds onto the prev one), killMsg, delay (how long the tag lasts for))

function GetHumanoidFromPlayer(player: Player)
	local character = player.Character
	local humanoid = character:WaitForChild('Humanoid')
	
	return humanoid
end

function tagging:GetTagsFolder(player: Player)
	local tagsFolder = GetHumanoidFromPlayer(player):FindFirstChild('Tags')
	return tagsFolder and tagsFolder or nil
end

function tagging:FindTag(player: Player, attacker: Player)
	local tagsFolder = tagging:GetTagsFolder(player)
	
	if not tagsFolder then return nil end
	
	for _, item in pairs(tagsFolder:GetChildren()) do
		if not item:IsA('ObjectValue') then continue end
		if item.Value == attacker then return item end
	end
	
	return nil
end

function tagging:GetTags(player: Player)
	local tagsFolder = tagging:GetTagsFolder(player)
	
	if not tagsFolder then return nil end
	
	local killMsg, attacker = (function() 
		local highestDmg, killMsg, player = 0, '', nil
		
		for _, tag in pairs(tagsFolder:GetChildren()) do
			local tag_damage = tag:GetAttribute('Damage')
			
			if not (tag_damage > highestDmg) then continue end
			
			highestDmg = tag_damage
			player = tag
			killMsg = tag:GetAttribute('KillMessage')
		end
		
		return player and killMsg, player or nil
	end)()
	local assists = (function() 
		if not attacker then return nil end
		
		local assists = tagsFolder:GetChildren()
		table.remove(assists, table.find(assists, attacker))
		
		return assists
	end)()
	
	return attacker ~= nil and {attacker, assists, killMsg} or nil
end

function tagging:Add(player: Player, attacker: Player, damage: number, attackMsg: string, delay: number)
	local humanoid = GetHumanoidFromPlayer(player)
	local tag = tagging:FindTag(player, attacker)
	local tagFolder = tagging:GetTagsFolder(player)
	
	if not tagFolder then tagFolder = Instance.new('Folder', GetHumanoidFromPlayer(player)) tagFolder.Name = 'Tags' end
	
	local new_tag = Instance.new('ObjectValue', tagFolder)
	
	new_tag.Name = attacker.UserId
	new_tag.Value = attacker
	new_tag:SetAttribute('Damage', (tag and tag:GetAttribute('Damage') or 0) + damage)
	new_tag:SetAttribute('KillMessage', attackMsg or 'killed')
	
	if tag then tag:Destroy() end
	
	Debris:AddItem(new_tag, delay or 5)
end

function tagging.Link(player: Player)
	if not player.Character then player.CharacterAdded:Wait() end
	
	local function CharacterAdded(char)
		local humanoid = char:WaitForChild('Humanoid')
		
		humanoid.Died:Wait()
		
		local tagFolder = tagging:GetTagsFolder(player)
		local tags = tagging:GetTags(player)
		
		if not tagFolder then warn('No tags, but player died.') return end
		if not tags then warn('Tag folder exists, but GetTags returned nil. Player died by void?') return end
		
		Events.ServerKillFeedEvent:Fire(table.unpack(tags))
		Events.KillFeedEvent:FireAllClients(table.unpack(tags))
	end
	
	player.CharacterAdded:Connect(CharacterAdded)
	CharacterAdded(player.Character)
end

return tagging
