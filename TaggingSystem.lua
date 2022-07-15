local Debris = game:GetService('Debris')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Events = ReplicatedStorage:WaitForChild('Events')

local tagging = {}

function GetHumanoidFromPlayer(player: Player)
	local character = player.Character
	local humanoid = character:WaitForChild('Humanoid')
	
	return humanoid
end

function tagging:GetTagsFolder(player: Player)
	local tagsFolder = GetHumanoidFromPlayer(player):FindFirstChild('Tags')
	return tagsFolder and (#tagsFolder:GetChildren() > 0 and tagsFolder or nil) or nil
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
	new_tag:SetAttribute('AttackMessage', attackMsg or 'killed')
	
	if tag then tag:Destroy() end
	
	Debris:AddItem(new_tag, delay or 5)
end

function tagging.link(player: Player)
	if not player.Character then player.CharacterAdded:Wait() end
	
	local function CharacterAdded(char)
		local humanoid = char:WaitForChild('Humanoid')
		
		humanoid.Died:Wait()
		
		local tags = tagging:GetTags(player)
		
		if not tagging:GetTagsFolder(player) then warn('No tags, but player died.') return end
		if not tags then warn('Tag folder exists, but no tags exists. Player died by void.') return end
		
		Events.ServerKillFeedEvent:Fire(tags)
		Events.KillFeedEvent:FireAllClients(tags)
	end
	
	player.CharacterAdded:Connect(CharacterAdded)
	CharacterAdded(player.Character)
end

return tagging
