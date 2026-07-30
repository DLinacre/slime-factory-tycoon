--!strict
--[[
	AudioEngine — StarterPlayerScripts/AudioEngine

	Procedural audio. Every sound is synthesised from Roblox's built-in
	pitch-shiftable assets rather than uploaded audio files, which means:
	  * zero upload cost and zero moderation delay
	  * no audio streaming hitch on mobile
	  * infinite variation from a handful of assets

	Sounds are pooled and reused. Creating a new Sound instance per tap would
	produce hundreds of instances per minute and stutter on low-end phones.
]]

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local AudioEngine = {}

-- Roblox-provided SFX. These are stock assets available to every creator.
local LIBRARY = {
	tap = "rbxasset://sounds/electronicpingshort.wav",
	purchase = "rbxasset://sounds/bass.wav",
	reward = "rbxasset://sounds/victory.wav",
	error = "rbxasset://sounds/switch3.wav",
}

local pool: { [string]: { Sound } } = {}
local POOL_SIZE = 6

local settings = { sfxVolume = 0.7, musicVolume = 0.5, reducedMotion = false }

local group: SoundGroup

function AudioEngine.init()
	group = Instance.new("SoundGroup")
	group.Name = "GameSFX"
	group.Volume = settings.sfxVolume
	group.Parent = SoundService

	for name, asset in LIBRARY do
		pool[name] = {}
		for _ = 1, POOL_SIZE do
			local s = Instance.new("Sound")
			s.SoundId = asset
			s.SoundGroup = group
			s.Parent = SoundService
			table.insert(pool[name], s)
		end
	end
end

function AudioEngine.applySettings(s: { [string]: any })
	settings.sfxVolume = (s.sfxVolume or 70) / 100
	settings.musicVolume = (s.musicVolume or 50) / 100
	settings.reducedMotion = s.reducedMotion == true
	if group then
		group.Volume = settings.sfxVolume
	end
end

--- Plays a pooled sound. `pitch` lets one asset cover a whole musical range —
--- rising pitch on consecutive taps is what makes clicking feel good.
function AudioEngine.play(name: string, pitch: number?, volume: number?)
	if settings.sfxVolume <= 0 then
		return
	end
	local bank = pool[name]
	if not bank then
		return
	end

	-- find a free voice; if all are busy, steal the oldest
	local chosen: Sound? = nil
	for _, s in bank do
		if not s.IsPlaying then
			chosen = s
			break
		end
	end
	chosen = chosen or bank[1]
	if not chosen then
		return
	end

	chosen.PlaybackSpeed = pitch or 1
	chosen.Volume = volume or 1
	chosen:Play()
end

-- Combo pitch: consecutive taps climb a pentatonic scale, then reset when the
-- player pauses. Costs nothing and makes rapid tapping genuinely satisfying.
local PENTATONIC = { 1.0, 1.122, 1.26, 1.498, 1.682, 2.0 }
local comboIndex = 1
local lastTap = 0

function AudioEngine.playTap()
	local now = os.clock()
	if now - lastTap > 0.6 then
		comboIndex = 1
	else
		comboIndex = math.min(comboIndex + 1, #PENTATONIC)
	end
	lastTap = now
	AudioEngine.play("tap", PENTATONIC[comboIndex], 0.35)
end

function AudioEngine.playPurchase()
	AudioEngine.play("purchase", 1.0, 0.5)
end

function AudioEngine.playReward()
	AudioEngine.play("reward", 1.0, 0.6)
end

function AudioEngine.playError()
	AudioEngine.play("error", 0.8, 0.4)
end

--- Rarity-scaled fanfare: rarer hatches get a higher, brighter sting.
function AudioEngine.playHatch(rarity: string)
	local pitchByRarity = {
		Common = 0.9,
		Uncommon = 1.0,
		Rare = 1.15,
		Epic = 1.3,
		Legendary = 1.5,
		Mythic = 1.7,
	}
	AudioEngine.play("reward", pitchByRarity[rarity] or 1, 0.6)
end

return AudioEngine
