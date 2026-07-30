--!strict
--[[
	ServiceRegistry — ReplicatedStorage/Modules/ServiceRegistry

	A minimal service locator with an explicit lifecycle. Solves three problems
	the original Bootstrap had:

	  1. Manual dependency wiring (`PetService.setMonetization(...)`) — services
	     now resolve each other by name, so there's no wiring order to get wrong.
	  2. Circular requires — resolution happens at :start(), after every module
	     has loaded, so two services can reference each other freely.
	  3. Editing Bootstrap for every new system — drop a ModuleScript into the
	     Services folder and it's picked up automatically.

	Lifecycle, in order:
	    :init()   -- set up internal state. Do NOT touch other services here.
	    :start()  -- other services are guaranteed to exist. Wire and run loops.
	    :onPlayerAdded(player)   / :onPlayerRemoving(player)
	All are optional.
]]

local ServiceRegistry = {}

local services: { [string]: any } = {}
local order: { string } = {}
local started = false

function ServiceRegistry.register(name: string, service: any)
	assert(not started, ("ServiceRegistry: cannot register '%s' after start"):format(name))
	assert(not services[name], ("ServiceRegistry: duplicate service '%s'"):format(name))
	services[name] = service
	table.insert(order, name)
	service.Name = name
	return service
end

--- Requires every ModuleScript in a container and registers it under its name.
function ServiceRegistry.registerFolder(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, mod = pcall(require, child)
			if ok and typeof(mod) == "table" then
				ServiceRegistry.register(child.Name, mod)
			elseif not ok then
				warn(("[ServiceRegistry] failed to require %s: %s"):format(child.Name, tostring(mod)))
			end
		end
	end
end

--- Fetches a service. Errors loudly if missing — a typo becomes a boot failure
--- with a clear message instead of a nil-index deep in gameplay code.
function ServiceRegistry.get(name: string): any
	local svc = services[name]
	if not svc then
		error(("ServiceRegistry: unknown service '%s'"):format(name), 2)
	end
	return svc
end

function ServiceRegistry.tryGet(name: string): any?
	return services[name]
end

function ServiceRegistry.all(): { [string]: any }
	return services
end

local function callPhase(phase: string)
	for _, name in order do
		local svc = services[name]
		local fn = svc[phase]
		if typeof(fn) == "function" then
			local t0 = os.clock()
			local ok, err = pcall(fn, svc)
			if not ok then
				warn(("[ServiceRegistry] %s:%s() failed: %s"):format(name, phase, tostring(err)))
			elseif phase == "start" then
				local ms = (os.clock() - t0) * 1000
				if ms > 50 then
					warn(("[ServiceRegistry] %s:start() took %.0fms -- consider deferring work"):format(name, ms))
				end
			end
		end
	end
end

function ServiceRegistry.start()
	assert(not started, "ServiceRegistry: already started")
	callPhase("init")
	started = true
	callPhase("start")
end

--- Fans a player lifecycle event out to every service that implements it.
function ServiceRegistry.dispatch(phase: "onPlayerAdded" | "onPlayerRemoving", player: Player)
	for _, name in order do
		local svc = services[name]
		local fn = svc[phase]
		if typeof(fn) == "function" then
			local ok, err = pcall(fn, svc, player)
			if not ok then
				warn(("[ServiceRegistry] %s:%s(%s) failed: %s"):format(name, phase, player.Name, tostring(err)))
			end
		end
	end
end

return ServiceRegistry
