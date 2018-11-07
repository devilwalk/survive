local WeaponSystem = require("WeaponSystem")
local GUI = require("GUI")
--local DEBUG=true
-----------------------------------------------------------------------------------------Common Function--------------------------------------------------------------------------------
local function assert(boolean, message)
    if not boolean then
        echo(
            "devilwalk",
            "devilwalk----------------------------------------------------------------assert failed!!!!:message:" ..
                tostring(message)
        )
    end
end
local function getDebugStack()
    if DEBUG then
        return debug.stack(nil, true)
    end
end
local function clone(from)
    local ret
    if type(from) == "table" then
        ret = {}
        for key, value in pairs(from) do
            ret[key] = clone(value)
        end
    else
        ret = from
    end
    return ret
end
local function new(class, parameters)
    local new_table = {}
    setmetatable(new_table, {__index = class})
    for key, value in pairs(class) do
        new_table[key] = clone(value)
    end
    local list = {}
    local dst = new_table
    while dst do
        list[#list + 1] = dst
        dst = dst._super
    end
    for i = #list, 1, -1 do
        list[i].construction(new_table, parameters)
    end
    return new_table
end
local function delete(inst)
    if inst then
        local list = {}
        local dst = inst
        while dst do
            list[#list + 1] = dst
            dst = dst._super
        end
        for i = 1, #list do
            list[i].destruction(inst)
        end
    end
end
local function inherit(class)
    local new_table = {}
    setmetatable(new_table, {__index = class})
    for key, value in pairs(class) do
        new_table[key] = clone(value)
    end
    new_table._super = class
    return new_table
end
local function lineStrings(text)
    local ret = {}
    local line = ""
    for i = 1, string.len(text) do
        local char = string.sub(text, i, i)
        if char == "\n" then
            ret[#ret + 1] = line
            line = ""
        elseif char == "\r" then
        else
            line = line .. char
        end
    end
    if line ~= "\n" and line ~= "" then
        ret[#ret + 1] = line
    end
    return ret
end
local function vec2Equal(vec1, vec2)
    return vec1[1] == vec2[1] and vec1[2] == vec2[2]
end
local function vec3Equal(vec1, vec2)
    return vec1[1] == vec2[1] and vec1[2] == vec2[2] and vec1[3] == vec2[3]
end
local function array(t)
    local ret = {}
    for _, value in pairs(t) do
        ret[#ret + 1] = value
    end
    return ret
end
local gOriginBlockIDs = {}
local function setBlock(x, y, z, blockID, blockDir)
    local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    if not gOriginBlockIDs[key] then
        gOriginBlockIDs[key] = GetBlockId(x, y, z)
    end
    SetBlock(x, y, z, blockID, blockDir)
end
local function restoreBlock(x, y, z)
    local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
    if gOriginBlockIDs[key] then
        SetBlock(x, y, z, gOriginBlockIDs[key])
    end
end
local SavedData = {mMoney = 10000000000}
local function getSavedData()
    return GetSavedData() or SavedData
end
-----------------------------------------------------------------------------------------Library-----------------------------------------------------------------------------------
local Command = {}
local CommandQueue = {}
local Timer = {}
local Property = {}
local PropertyGroup = {}
local EntitySyncer = {}
local EntitySyncerManager = {}
local EntityCustom = {}
local EntityCustomManager = {}
local Host = {}
local Client = {}
local GlobalProperty = {}
local InputManager = {}
local PlayerManager = {}
-----------------------------------------------------------------------------------------Command-----------------------------------------------------------------------------------
Command.EState = {Unstart = 0, Executing = 1, Finish = 2}
function Command:construction(parameter)
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:construction:parameter:")
    -- echo("devilwalk", parameter)
    self.mDebug = parameter.mDebug
    self.mState = Command.EState.Unstart
    self.mTimeOutProcess = parameter.mTimeOutProcess
end

function Command:destruction()
end

function Command:execute()
    self.mState = Command.EState.Executing
    echo("devilwalk", "devilwalk--------------------------------------------debug:Command:execute:self.mDebug:")
    echo("devilwalk", self.mDebug)
end

function Command:frameMove()
    if self.mState == Command.EState.Unstart then
        self:execute()
    elseif self.mState == Command.EState.Executing then
        self:executing()
    elseif self.mState == Command.EState.Finish then
        self:finish()
        return true
    end
end

function Command:executing()
    self.mExecutingTime = self.mExecutingTime or 0
    if self.mExecutingTime > 1000 then
        if self.mTimeOutProcess then
            self:mTimeOutProcess(self)
        else
            echo(
                "devilwalk",
                "devilwalk--------------------------------------------debug:Command:executing time out:self.mDebug:"
            )
            echo("devilwalk", self.mDebug)
        end
    end
    self.mExecutingTime = self.mExecutingTime + 1
end

function Command:finish()
    echo("devilwalk", "devilwalk--------------------------------------------debug:Command:finish:self.mDebug:")
    echo("devilwalk", self.mDebug)
end

function Command:stop()
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:stop:self.mDebug:")
    -- echo("devilwalk",self.mDebug)
end

function Command:restore()
    -- echo("devilwalk", "devilwalk--------------------------------------------debug:Command:restore:self.mDebug:")
    -- echo("devilwalk",self.mDebug)
end
-----------------------------------------------------------------------------------------Command Callback-----------------------------------------------------------------------------------------
local Command_Callback = inherit(Command)
function Command_Callback:construction(parameter)
    -- echo(
    --     "devilwalk",
    --     "devilwalk--------------------------------------------debug:Command_Callback:construction:parameter:"
    -- )
    -- echo("devilwalk", parameter)
    self.mExecuteCallback = parameter.mExecuteCallback
    self.mExecutingCallback = parameter.mExecutingCallback
    self.mFinishCallback = parameter.mFinishCallback
end

function Command_Callback:execute()
    Command_Callback._super.execute(self)
    if self.mExecuteCallback then
        self.mExecuteCallback(self)
    end
end

function Command_Callback:executing()
    Command_Callback._super.executing(self)
    if self.mExecutingCallback then
        self.mExecutingCallback(self)
    end
end

function Command_Callback:finish()
    Command_Callback._super.finish(self)
    if self.mFinishCallback then
        self.mFinishCallback(self)
    end
end
-----------------------------------------------------------------------------------------CommandQueue-----------------------------------------------------------------------------------
function CommandQueue.default()
    if not CommandQueue.msDefault then
        CommandQueue.msDefault = new(CommandQueue)
    end
    return CommandQueue.msDefault
end

function CommandQueue:construction()
    self.mCommands = {}
end

function CommandQueue:destruction()
    if self.mCommands and #self.mCommands > 0 then
        for _, command in pairs(self.mCommands) do
            echo(
                "devilwalk",
                "devilwalk--------------------------------------------warning:CommandQueue:delete:command:" ..
                    tostring(command.mDebug)
            )
        end
    end
    self.mCommands = nil
end

function CommandQueue:update()
    if self.mCommands[1] then
        local ret = self.mCommands[1]:frameMove()
        if ret then
            table.remove(self.mCommands, 1)
        end
    end
end

function CommandQueue:post(cmd)
    echo("devilwalk", "CommandQueue:post:")
    echo("devilwalk", cmd.mDebug)
    self.mCommands[#self.mCommands + 1] = cmd
end

function CommandQueue:empty()
    return #self.mCommands == 0
end
-----------------------------------------------------------------------------------------Timer-----------------------------------------------------------------------------------------
function Timer.global()
    Timer.mGlobal = Timer.mGlobal or new(Timer)
    return Timer.mGlobal
end

function Timer:construction()
    self.mInitTime = GetTime() * 0.001
    self.mTime = self.mInitTime
end

function Timer:destruction()
end

function Timer:delta()
    local new_time = GetTime() * 0.001
    local ret = new_time - self.mTime
    self.mTime = new_time
    return ret
end

function Timer:total()
    local new_time = GetTime() * 0.001
    local ret = new_time - self.mInitTime
    return ret
end
-----------------------------------------------------------------------------------------Property-----------------------------------------------------------------------------------------
function Property:construction()
    self.mCommandQueue = new(CommandQueue)
    self.mCache = {}
    self.mCommandRead = {}
    self.mCommandWrite = {}
end

function Property:destruction()
    delete(self.mCommandQueue)
    if self.mPropertyListeners then
        for property, listeners in pairs(self.mPropertyListeners) do
            GlobalProperty.removeListener(self:_getLockKey(property), self)
        end
    end
end

function Property:update()
    self.mCommandQueue:update()
end

function Property:lockRead(property, callback)
    GlobalProperty.lockRead(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:unlockRead(property)
    GlobalProperty.unlockRead(self:_getLockKey(property))
end

function Property:lockWrite(property, callback)
    GlobalProperty.lockWrite(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:unlockWrite(property)
    GlobalProperty.unlockWrite(self:_getLockKey(property))
end

function Property:write(property, value, callback)
    self.mCache[property] = value
    GlobalProperty.write(self:_getLockKey(property), value, callback)
end

function Property:safeWrite(property, value, callback)
    self.mCache[property] = value
    GlobalProperty.lockAndWrite(self:_getLockKey(property), value, callback)
end

function Property:safeRead(property, callback)
    self:lockRead(
        property,
        function(value)
            self:unlockRead(property)
            if callback then
                callback(value)
            end
        end
    )
end

function Property:read(property, callback)
    GlobalProperty.read(
        self:_getLockKey(property),
        function(value)
            self.mCache[property] = value
            callback(value)
        end
    )
end

function Property:readUntil(property, callback)
    self:read(
        property,
        function(value)
            if value then
                callback(value)
            else
                self:readUntil(property, callback)
            end
        end
    )
end

function Property:commandRead(property)
    -- self.mCommandQueue:post(
    --     new(
    --         Command_Callback,
    --         {
    --             mDebug = "Property:commandRead:" .. property,
    --             mExecuteCallback = function(command)
    --                 self:safeRead(
    --                     property,
    --                     function()
    --                         command.mState = Command.EState.Finish
    --                     end
    --                 )
    --             end
    --         }
    --     )
    -- )
    self.mCommandRead[property] = self.mCommandRead[property] or 0
    self.mCommandRead[property] = self.mCommandRead[property] + 1
    self:safeRead(
        property,
        function()
            self.mCommandRead[property] = self.mCommandRead[property] - 1
            if self.mCommandRead[property] == 0 then
                self.mCommandRead[property] = nil
            end
        end
    )
end

function Property:commandWrite(property, value)
    -- self.mCommandQueue:post(
    --     new(
    --         Command_Callback,
    --         {
    --             mDebug = "Property:commandWrite:" .. property,
    --             mExecuteCallback = function(command)
    --                 self:safeWrite(
    --                     property,
    --                     value,
    --                     function()
    --                         command.mState = Command.EState.Finish
    --                     end
    --                 )
    --             end
    --         }
    --     )
    -- )
    self.mCommandWrite[property] = self.mCommandWrite[property] or 0
    self.mCommandWrite[property] = self.mCommandWrite[property] + 1
    self:safeWrite(
        property,
        value,
        function()
            self.mCommandWrite[property] = self.mCommandWrite[property] - 1
            if self.mCommandWrite[property] then
                self.mCommandWrite[property] = nil
            end
        end
    )
end

function Property:commandFinish(callback, timeOutCallback)
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "Property:commandFinish",
                mTimeOutProcess = function()
                    echo(
                        "devilwalk",
                        "Property:commandFinish:time out--------------------------------------------------------------"
                    )
                    echo("devilwalk", "self.mCommandRead")
                    echo("devilwalk", self.mCommandRead)
                    echo("devilwalk", "self.mCommandWrite")
                    echo("devilwalk", self.mCommandWrite)
                    if timeOutCallback then
                        timeOutCallback()
                    end
                end,
                mExecutingCallback = function(command)
                    if not next(self.mCommandRead) and not next(self.mCommandWrite) then
                        callback()
                        command.mState = Command.EState.Finish
                    end
                end
            }
        )
    )
end

function Property:cache()
    return self.mCache
end

function Property:addPropertyListener(property, callbackKey, callback, parameter)
    callbackKey = tostring(callbackKey)
    self.mPropertyListeners = self.mPropertyListeners or {}
    if not self.mPropertyListeners[property] then
        GlobalProperty.addListener(
            self:_getLockKey(property),
            self,
            function(_, value, preValue)
                self.mCache[property] = value
                self:notifyProperty(property, value, preValue)
            end
        )
    else
        callback(parameter, self.mCache[property], self.mCache[property])
    end
    self.mPropertyListeners[property] = self.mPropertyListeners[property] or {}
    self.mPropertyListeners[property][callbackKey] = {mCallback = callback, mParameter = parameter}
end

function Property:removePropertyListener(property, callbackKey)
    callbackKey = tostring(callbackKey)
    if self.mPropertyListeners and self.mPropertyListeners[property] then
        self.mPropertyListeners[property][callbackKey] = nil
    end
end

function Property:notifyProperty(property, value, preValue)
    -- echo("devilwalk", "Property:notifyProperty:property:" .. property)
    -- echo("devilwalk", value)
    if self.mPropertyListeners and self.mPropertyListeners[property] then
        for _, listener in pairs(self.mPropertyListeners[property]) do
            listener.mCallback(listener.mParameter, value, preValue)
        end
    end
end
-----------------------------------------------------------------------------------------Property Group-----------------------------------------------------------------------------------
function PropertyGroup:construction()
    self.mProperties = {}
end

function PropertyGroup:destruction()
end

function PropertyGroup:commandRead(propertyInstance, propertyName)
    propertyInstance:commandRead(propertyName)
    self.mProperties[tostring(propertyInstance)] = true
end

function PropertyGroup:commandWrite(propertyInstance, propertyName, propertyValue)
    propertyInstance:commandWrite(propertyName, propertyValue)
    self.mProperties[tostring(propertyInstance)] = true
end

function PropertyGroup:commandFinish(callback)
    local function _finish(propertyInstance)
        self.mProperties[tostring(propertyInstance)] = nil
        if not next(self.mProperties) then
            callback()
        end
    end
    for property_instance, _ in pairs(self.mProperties) do
        property_instance:commandFinish(
            function()
                _finish(property_instance)
            end
        )
    end
end
-----------------------------------------------------------------------------------------Entity Syncer----------------------------------------------------------------------------------------
function EntitySyncer:construction(parameter)
    self.mCommandQueue = new(CommandQueue)
    if parameter.mEntityID then
        self.mEntityID = parameter.mEntityID
    elseif parameter.mEntity then
        self.mEntityID = parameter.mEntity.entityId
    end
end

function EntitySyncer:destruction()
end

function EntitySyncer:getEntity()
    return GetEntityById(self.mEntityID)
end

function EntitySyncer:update()
    self.mCommandQueue:update()
end

function EntitySyncer:setDisplayName(name, colour)
    self:broadcast("DisplayName", {mName = name, mColour = colour})
end

function EntitySyncer:setLocalDisplayNameColour(colour)
    self.mLocalDisplayNameColour = colour
    if self:getEntity() then
        self:getEntity():UpdateDisplayName(nil, self.mLocalDisplayNameColour)
    end
end

function EntitySyncer:broadcast(key, value)
    Host.broadcast(
        {mKey = "EntitySyncer", mEntityID = self:getEntity().entityId, mParameter = {mKey = key, mValue = value}}
    )
end

function EntitySyncer:receive(parameter)
    if not self:getEntity() then
        local parameter_clone = clone(parameter)
        self.mCommandQueue:post(
            new(
                Command_Callback,
                {
                    mDebug = "EntitySyncer:receive:mEntityID:" .. tostring(self.mEntityID),
                    mExecutingCallback = function(command)
                        if self:getEntity() then
                            self:receive(parameter_clone)
                            command.mState = Command.EState.Finish
                        end
                    end
                }
            )
        )
    else
        if parameter.mKey == "DisplayName" then
            -- echo("devilwalk","EntitySyncer:receive:DisplayName:"..parameter.mValue)
            self:getEntity():UpdateDisplayName(
                parameter.mValue.mName,
                self.mLocalDisplayNameColour or parameter.mValue.mColour
            )
        end
    end
end
-----------------------------------------------------------------------------------------Entity Syncer Manager----------------------------------------------------------------------------------------
function EntitySyncerManager.singleton()
    if not EntitySyncerManager.mInstance then
        EntitySyncerManager.mInstance = new(EntitySyncerManager)
    end
    return EntitySyncerManager.mInstance
end
function EntitySyncerManager:construction()
    self.mEntities = {}
    Client.addListener("EntitySyncer", self)
end

function EntitySyncerManager:destruction()
    Client.removeListener("EntitySyncer", self)
end

function EntitySyncerManager:update()
    for _, entity in pairs(self.mEntities) do
        entity:update()
    end
end

function EntitySyncerManager:receive(parameter)
    local entity = self.mEntities[parameter.mEntityID]
    if not entity then
        entity = new(EntitySyncer, {mEntityID = parameter.mEntityID})
        self.mEntities[parameter.mEntityID] = entity
    end
    entity:receive(parameter.mParameter)
end

function EntitySyncerManager:attach(entity)
    if not self.mEntities[entity.entityId] then
        self.mEntities[entity.entityId] = new(EntitySyncer, {mEntity = entity})
    end
end

function EntitySyncerManager:get(entity)
    self:attach(entity)
    return self.mEntities[entity.entityId]
end

function EntitySyncerManager:getByEntityID(entityID)
    return self.mEntities[entityID]
end
-----------------------------------------------------------------------------------------EntityCustom-----------------------------------------------------------------------------------------
function EntityCustom:construction(parameter)
    self.mEntity = CreateEntity(parameter.mX,parameter.mY,parameter.mZ,parameter.mModel)

    Client.addListener("EntityCustom",self)
end

function EntityCustom:destruction()
    self.mEntity:SetDead(true)

    Client.removeListener("EntityCustom",self)
end

function EntityCustom:broadcast(message,parameter,exceptSelf)
    Host.broadcast({mKey = "EntityCustom", mMessage = message, mParameter = parameter},exceptSelf)
end

function EntityCustom:receive(parameter)
    if parameter.mMessage == "SetPositionReal" then
        self:_setPositionReal(parameter.mParameter.mX,parameter.mParameter.mY,parameter.mParameter.mZ)
    end
end

function EntityCustom:setPositionReal(x,y,z)
    self:broadcast("SetPositionReal",{mX = x,mY = y,mZ = z})
end

function EntityCustom:_setPositionReal(x,y,z)
    self.mEntity:SetPosition(x,y,z)
end
-----------------------------------------------------------------------------------------EntityCustomManager-----------------------------------------------------------------------------------------
function EntityCustomManager.singleton()
    if not EntityCustomManager.msInstance then
        EntityCustomManager.msInstance = new(EntityCustomManager)
    end
    return EntityCustomManager.msInstance
end

function EntityCustomManager:construction()
    self.mEntities = {}
    self.mNextEntityKey = 1

    Client.addListener("EntityCustomManager",self)
end

function EntityCustomManager:destruction()
    for _,entity in pairs(self.mEntities) do
        delete(entity)
    end

    Client.removeListener("EntityCustomManager",self)
end

function EntityCustomManager:receive(parameter)
    if parameter.mMessage == "CreateEntity" then
        self:_createEntity(parameter.mParameter.mX,parameter.mParameter.mY,parameter.mParameter.mZ,parameter.mParameter.mModel,parameter.mParameter.mHostKey)
    elseif parameter.mMessage == "DestroyEntity" then
        self:_destroyEntity(parameter.mParameter.mHostKey)
    end
end

function EntityCustomManager:broadcast(message,parameter,exceptSelf)
    Host.broadcast({mKey = "EntityCustomManager", mMessage = message, mParameter = parameter},exceptSelf)
end

function EntityCustomManager:createEntity(x,y,z,path)
    local host_key = self:_generateNextEntityKey()
    self:broadcast("CreateEntity",{mX=x,mY=y,mZ=z,mModel=path,mHostKey = host_key})
    return host_key
end

function EntityCustomManager:getEntity(hostKey)
    return self.mEntities[hostKey]
end

function EntityCustomManager:destroyEntity(hostKey)
    self:broadcast("DestroyEntity",{mHostKey = hostKey})
end

function EntityCustomManager:_createEntity(x,y,z,path,hostKey)
    local ret = new(EntityCustom,{mX = x,mY = y,mZ = z,mModel = path})
    self.mEntities[hostKey] = ret
    return ret
end

function EntityCustomManager:_destroyEntity(hostKey)
    delete(self.mEntities[hostKey])
    self.mEntities[hostKey] = nil
end

function EntityCustomManager:_generateNextEntityKey()
    local ret = self.mNextEntityKey
    self.mNextEntityKey = self.mNextEntityKey + 1
    return ret
end
-----------------------------------------------------------------------------------------Host-----------------------------------------------------------------------------------------
function Host.addListener(key, listener)
    local listenerKey = tostring(listener)
    Host.mListeners = Host.mListeners or {}
    Host.mListeners[key] = Host.mListeners[key] or {}
    Host.mListeners[key][listenerKey] = listener
end

function Host.removeListener(key, listener)
    local listenerKey = tostring(listener)
    Host.mListeners[key][listenerKey] = nil
end

function Host.receive(parameter)
    if Host.mListeners then
        local listeners = Host.mListeners[parameter.mKey]
        if listeners then
            for _, listener in pairs(listeners) do
                listener:receive(parameter)
            end
        end
    end
end

function Host.sendTo(clientPlayerID, parameter)
    local new_parameter = clone(parameter)
    if not new_parameter.mFrom then
        new_parameter.mFrom = GetPlayerId()
    end
    SendTo(clientPlayerID, new_parameter)
end

function Host.broadcast(parameter, exceptSelf)
    local new_parameter = clone(parameter)
    new_parameter.mFrom = GetPlayerId()
    SendTo(nil, new_parameter)
    if not exceptSelf then
        receiveMsg(parameter)
    end
end

-----------------------------------------------------------------------------------------Client-----------------------------------------------------------------------------------------
function Client.addListener(key, listener)
    local listenerKey = tostring(listener)
    Client.mListeners = Client.mListeners or {}
    Client.mListeners[key] = Client.mListeners[key] or {}
    Client.mListeners[key][listenerKey] = listener
end

function Client.removeListener(key, listener)
    local listenerKey = tostring(listener)
    Client.mListeners[key][listenerKey] = nil
end

function Client.receive(parameter)
    if Client.mListeners then
        if parameter.mKey then
            local listeners = Client.mListeners[parameter.mKey]
            if listeners then
                for _, listener in pairs(listeners) do
                    listener:receive(parameter)
                end
            end
        elseif parameter.mMessage == "clear" then
            clear()
        end
    end
end

function Client.sendToHost(key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = "Host"
    if not new_parameter.mFrom then
        new_parameter.mFrom = GetPlayerId()
    end
    SendTo("host", new_parameter)
end

function Client.sendToClient(playerID, key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = playerID
    if not new_parameter.mFrom then
        new_parameter.mFrom = GetPlayerId()
    end
    if playerID == GetPlayerId() then
        Client.receive(new_parameter)
    else
        SendTo("host", new_parameter)
    end
end

function Client.broadcast(key, parameter)
    local new_parameter = clone(parameter)
    new_parameter.mKey = key
    new_parameter.mTo = "All"
    if not new_parameter.mFrom then
        new_parameter.mFrom = GetPlayerId()
    end
    SendTo("host", new_parameter)
end
-----------------------------------------------------------------------------------------GlobalProperty-----------------------------------------------------------------------------------------
function GlobalProperty.initialize()
    GlobalProperty.mCommandList = {}
    Host.addListener("GlobalProperty", GlobalProperty)
    Client.addListener("GlobalProperty", GlobalProperty)
end

function GlobalProperty.update()
    for index, command in pairs(GlobalProperty.mCommandList) do
        local ret = command:frameMove()
        if ret then
            table.remove(GlobalProperty.mCommandList, index)
            break
        end
    end
end

function GlobalProperty.clear()
end

function GlobalProperty.lockWrite(key, callback)
    callback = callback or function()
        end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    assert(GlobalProperty.mResponseCallback["LockWrite"][key] == nil, "GlobalProperty.lockWrite:key:" .. key)
    GlobalProperty.mResponseCallback["LockWrite"][key] = {callback}
    Client.sendToHost("GlobalProperty", {mMessage = "LockWrite", mParameter = {mKey = key, mDebug = getDebugStack()}})
end
--must be locked
function GlobalProperty.write(key, value, callback)
    callback = callback or function()
        end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    assert(GlobalProperty.mResponseCallback["Write"][key] == nil, "GlobalProperty.Write:key:" .. key)
    GlobalProperty.mResponseCallback["Write"][key] = {callback}
    Client.sendToHost(
        "GlobalProperty",
        {mMessage = "Write", mParameter = {mKey = key, mValue = value, mDebug = getDebugStack()}}
    )
end

function GlobalProperty.unlockWrite(key)
    Client.sendToHost("GlobalProperty", {mMessage = "UnlockWrite", mParameter = {mKey = key, mDebug = getDebugStack()}})
end

function GlobalProperty.lockRead(key, callback)
    callback = callback or function()
        end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    GlobalProperty.mResponseCallback["LockRead"][key] = GlobalProperty.mResponseCallback["LockRead"][key] or {}
    GlobalProperty.mResponseCallback["LockRead"][key][#GlobalProperty.mResponseCallback["LockRead"][key] + 1] = callback
    Client.sendToHost("GlobalProperty", {mMessage = "LockRead", mParameter = {mKey = key, mDebug = getDebugStack()}})
end

function GlobalProperty.unlockRead(key)
    Client.sendToHost("GlobalProperty", {mMessage = "UnlockRead", mParameter = {mKey = key, mDebug = getDebugStack()}})
end

function GlobalProperty.read(key, callback)
    callback = callback or function()
        end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    GlobalProperty.mResponseCallback["Read"][key] = GlobalProperty.mResponseCallback["Read"][key] or {}
    local callbacks = GlobalProperty.mResponseCallback["Read"][key]
    callbacks[#callbacks + 1] = callback
    Client.sendToHost("GlobalProperty", {mMessage = "Read", mParameter = {mKey = key, mDebug = getDebugStack()}})
end

function GlobalProperty.lockAndWrite(key, value, callback)
    callback = callback or function()
        end
    GlobalProperty.mResponseCallback =
        GlobalProperty.mResponseCallback or {LockWrite = {}, LockRead = {}, Write = {}, Read = {}, LockAndWrite = {}}
    GlobalProperty.mResponseCallback["LockAndWrite"][key] = GlobalProperty.mResponseCallback["LockAndWrite"][key] or {}
    local callbacks = GlobalProperty.mResponseCallback["LockAndWrite"][key]
    callbacks[#callbacks + 1] = callback
    Client.sendToHost(
        "GlobalProperty",
        {mMessage = "LockAndWrite", mParameter = {mKey = key, mValue = value, mDebug = getDebugStack()}}
    )
end

function GlobalProperty.addListener(key, listenerKey, callback, parameter)
    listenerKey = tostring(listenerKey)
    GlobalProperty.mListeners = GlobalProperty.mListeners or {}
    GlobalProperty.mListeners[key] = GlobalProperty.mListeners[key] or {}
    GlobalProperty.mListeners[key][listenerKey] = {mCallback = callback, mParameter = parameter}

    GlobalProperty.read(
        key,
        function(value)
            if value then
                callback(parameter, value, value)
            end
        end
    )
end

function GlobalProperty.removeListener(key, listenerKey)
    listenerKey = tostring(listenerKey)
    if GlobalProperty.mListeners and GlobalProperty.mListeners[key] then
        GlobalProperty.mListeners[key][listenerKey] = nil
    end
end

function GlobalProperty.notify(key, value, preValue)
    if GlobalProperty.mListeners and GlobalProperty.mListeners[key] then
        for listener_key, callback in pairs(GlobalProperty.mListeners[key]) do
            callback.mCallback(callback.mParameter, value, preValue)
        end
    end
end

function GlobalProperty:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
        local message = string.sub(parameter.mMessage, 1, is_responese - 1)
        if
            GlobalProperty.mResponseCallback and GlobalProperty.mResponseCallback[message] and
                GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey]
         then
            local callbacks = GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey]
            local callback = callbacks[1]
            if not callback then
                echo("devilwalk", "---------------------------------------------------------------------------------")
                echo("devilwalk", parameter)
            end
            table.remove(callbacks, 1)
            if not next(callbacks) then
                GlobalProperty.mResponseCallback[message][parameter.mParameter.mKey] = nil
            end
            callback(parameter.mParameter.mValue)
        end
    else
        GlobalProperty.mProperties = GlobalProperty.mProperties or {}
        GlobalProperty.mProperties[parameter.mParameter.mKey] =
            GlobalProperty.mProperties[parameter.mParameter.mKey] or {}
        if parameter.mMessage == "LockWrite" then -- host
            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from, parameter.mParameter.mDebug)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockWrite_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = GetEntityById(parameter._from).nickname .. ":LockWrite:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                                GlobalProperty._lockWrite(
                                    parameter.mParameter.mKey,
                                    parameter._from,
                                    parameter.mParameter.mDebug
                                )
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockWrite_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty write lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if GlobalProperty.mProperties[parameter.mParameter.mKey] then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(
                                            GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID
                                        ).nickname .. " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _, info in pairs(
                                        GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked
                                    ) do
                                        echo("devilwalk", GetEntityById(info.mPlayerID).nickname .. " read locked")
                                    end
                                end
                                echo("devilwalk", GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "UnlockWrite" then -- host
            GlobalProperty._unlockWrite(parameter.mParameter.mKey, parameter._from)
        elseif parameter.mMessage == "Write" then -- host
            GlobalProperty._write(parameter.mParameter.mKey, parameter.mParameter.mValue, parameter._from)
            Host.sendTo(
                parameter._from,
                {
                    mMessage = "Write_Response",
                    mKey = "GlobalProperty",
                    mParameter = {
                        mKey = parameter.mParameter.mKey,
                        mValue = parameter.mParameter.mValue
                    }
                }
            )
        elseif parameter.mMessage == "LockRead" then -- host
            if GlobalProperty._canRead(parameter.mParameter.mKey) then
                GlobalProperty._lockRead(parameter.mParameter.mKey, parameter._from, parameter.mParameter.mDebug)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockRead_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = tostring(parameter._from) .. ":LockRead:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canRead(parameter.mParameter.mKey) then
                                GlobalProperty._lockRead(
                                    parameter.mParameter.mKey,
                                    parameter._from,
                                    parameter.mParameter.mDebug
                                )
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockRead_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty read lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if GlobalProperty.mProperties[parameter.mParameter.mKey] then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(
                                            GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID
                                        ).nickname .. " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _, info in pairs(
                                        GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked
                                    ) do
                                        echo("devilwalk", GetEntityById(info.mPlayerID).nickname .. " read locked")
                                    end
                                end
                                echo("devilwalk", GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "UnlockRead" then -- host
            GlobalProperty._unlockRead(parameter.mParameter.mKey, parameter._from)
        elseif parameter.mMessage == "Read" then -- host
            Host.sendTo(
                parameter._from,
                {
                    mMessage = "Read_Response",
                    mKey = "GlobalProperty",
                    mParameter = {
                        mKey = parameter.mParameter.mKey,
                        mValue = GlobalProperty.mProperties[parameter.mParameter.mKey].mValue
                    }
                }
            )
        elseif parameter.mMessage == "LockAndWrite" then -- host
            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                GlobalProperty._lockWrite(parameter.mParameter.mKey, parameter._from, parameter.mParameter.mDebug)
                GlobalProperty._write(parameter.mParameter.mKey, parameter.mParameter.mValue, parameter._from)
                Host.sendTo(
                    parameter._from,
                    {
                        mMessage = "LockAndWrite_Response",
                        mKey = "GlobalProperty",
                        mParameter = {
                            mKey = parameter.mParameter.mKey,
                            mValue = parameter.mParameter.mValue
                        }
                    }
                )
            else
                GlobalProperty.mCommandList[#GlobalProperty.mCommandList + 1] =
                    new(
                    Command_Callback,
                    {
                        mDebug = GetEntityById(parameter._from).nickname ..
                            ":LockAndWrite:" .. parameter.mParameter.mKey,
                        mExecutingCallback = function(command)
                            if GlobalProperty._canWrite(parameter.mParameter.mKey) then
                                GlobalProperty._lockWrite(
                                    parameter.mParameter.mKey,
                                    parameter._from,
                                    parameter.mParameter.mDebug
                                )
                                GlobalProperty._write(
                                    parameter.mParameter.mKey,
                                    parameter.mParameter.mValue,
                                    parameter._from
                                )
                                Host.sendTo(
                                    parameter._from,
                                    {
                                        mMessage = "LockAndWrite_Response",
                                        mKey = "GlobalProperty",
                                        mParameter = {
                                            mKey = parameter.mParameter.mKey,
                                            mValue = parameter.mParameter.mValue
                                        }
                                    }
                                )
                                command.mState = Command.EState.Finish
                            end
                        end,
                        mTimeOutProcess = function(command)
                            echo("devilwalk", "GlobalProperty write lock time out:" .. command.mDebug)
                            echo("devilwalk", parameter.mParameter.mDebug)
                            if GlobalProperty.mProperties[parameter.mParameter.mKey] then
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked then
                                    echo(
                                        "devilwalk",
                                        GetEntityById(
                                            GlobalProperty.mProperties[parameter.mParameter.mKey].mWriteLocked.mPlayerID
                                        ).nickname .. " write locked"
                                    )
                                end
                                if GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked then
                                    for _, info in pairs(
                                        GlobalProperty.mProperties[parameter.mParameter.mKey].mReadLocked
                                    ) do
                                        echo("devilwalk", GetEntityById(info.mPlayerID).nickname .. " read locked")
                                    end
                                end
                                echo("devilwalk", GlobalProperty.mProperties[parameter.mParameter.mKey])
                            end
                        end
                    }
                )
            end
        elseif parameter.mMessage == "PropertyChange" then -- client
            GlobalProperty.notify(
                parameter.mParameter.mKey,
                parameter.mParameter.mValue,
                parameter.mParameter.mPreValue
            )
        end
    end
end

function GlobalProperty._lockWrite(key, playerID, debugInfo)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked == nil,
        "GlobalProperty._lockWrite:GlobalProperty.mProperties[key].mWriteLocked ~= nil"
    )
    assert(
        GlobalProperty.mProperties[key].mReadLocked == nil or #GlobalProperty.mProperties[key].mReadLocked == 0,
        "GlobalProperty._lockWrite:GlobalProperty.mProperties[key].mReadLocked ~= 0 and GlobalProperty.mProperties[key].mReadLocked ~= nil"
    )
    -- echo("devilwalk", "GlobalProperty._lockWrite:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mWriteLocked = {mPlayerID = playerID, mDebug = debugInfo}
    -- GlobalProperty._lockRead(key, playerID)
end

function GlobalProperty._unlockWrite(key, playerID)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked and
            GlobalProperty.mProperties[key].mWriteLocked.mPlayerID == playerID,
        "GlobalProperty._unlockWrite:GlobalProperty.mProperties[key].mWriteLocked ~= playerID"
    )
    -- echo("devilwalk", "GlobalProperty._unlockWrite:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mWriteLocked = nil
    -- GlobalProperty._unlockRead(key, playerID)
end

function GlobalProperty._write(key, value, playerID)
    assert(
        GlobalProperty.mProperties[key].mWriteLocked and
            GlobalProperty.mProperties[key].mWriteLocked.mPlayerID == playerID,
        "GlobalProperty._write:GlobalProperty.mProperties[key].mWriteLocked ~= playerID"
    )
    -- echo("devilwalk", "GlobalProperty._write:key,playerID,value:" .. tostring(key) .. "," .. tostring(playerID))
    -- echo("devilwalk", value)
    local pre_value = GlobalProperty.mProperties[key].mValue
    GlobalProperty.mProperties[key].mValue = value
    GlobalProperty._unlockWrite(key, playerID)
    Host.broadcast(
        {
            mMessage = "PropertyChange",
            mKey = "GlobalProperty",
            mParameter = {mKey = key, mValue = value, mPreValue = pre_value, mPlayerID = playerID}
        }
    )
end

function GlobalProperty._lockRead(key, playerID, debugInfo)
    --echo("devilwalk", "GlobalProperty._lockRead:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    GlobalProperty.mProperties[key].mReadLocked = GlobalProperty.mProperties[key].mReadLocked or {}
    GlobalProperty.mProperties[key].mReadLocked[#GlobalProperty.mProperties[key].mReadLocked + 1] = {
        mPlayerID = playerID,
        mDebug = debugInfo
    }
end

function GlobalProperty._unlockRead(key, playerID)
    --echo("devilwalk", "GlobalProperty._unlockRead:key,playerID:" .. tostring(key) .. "," .. tostring(playerID))
    local unlocked
    for i = #GlobalProperty.mProperties[key].mReadLocked, 1, -1 do
        if GlobalProperty.mProperties[key].mReadLocked[i].mPlayerID == playerID then
            table.remove(GlobalProperty.mProperties[key].mReadLocked, i)
            unlocked = true
            break
        end
    end
    assert(unlocked, "GlobalProperty._unlockRead:key:" .. key .. ",playerID:" .. tostring(playerID))
end

function GlobalProperty._canWrite(key)
    -- echo("devilwalk", "GlobalProperty._canWrite:key:" .. tostring(key))
    -- echo("devilwalk", GlobalProperty.mProperties)
    return not GlobalProperty.mProperties[key].mWriteLocked and
        (not GlobalProperty.mProperties[key].mReadLocked or #GlobalProperty.mProperties[key].mReadLocked == 0)
end

function GlobalProperty._canRead(key)
    -- return GlobalProperty._canWrite(key)
    return not GlobalProperty.mProperties[key].mWriteLocked
end
-----------------------------------------------------------------------------------------InputManager-----------------------------------------------------------------------------------------
function InputManager.addListener(key, callback, parameter)
    InputManager.mListeners = InputManager.mListeners or {}
    InputManager.mListeners[key] = {mCallback = callback, mParameter = parameter}
end

function InputManager.removeListener(key)
    InputManager.mListeners[key] = nil
end

function InputManager.notify(event)
    if InputManager.mListeners then
        for _, listener in pairs(InputManager.mListeners) do
            listener.mCallback(listener.mParameter, event)
        end
    end
end
-----------------------------------------------------------------------------------------PlayerManager-----------------------------------------------------------------------------------------
function PlayerManager.initialize()
    PlayerManager.onPlayerIn(EntityWatcher.get(GetPlayerId()))
    EntityWatcher.on(
        "create",
        function(inst)
            PlayerManager.onPlayerIn(inst)
            if PlayerManager.mHideAll then
                PlayerManager.hideAll()
            end
        end
    )
end

function PlayerManager.onPlayerIn(entityWatcher)
    PlayerManager.mPlayers = PlayerManager.mPlayers or {}
    PlayerManager.mPlayers[entityWatcher.id] = entityWatcher
    PlayerManager.notify("PlayerIn", {mPlayerID = entityWatcher.id})
end

function PlayerManager.getPlayerByID(id)
    id = id or GetPlayerId()
    return PlayerManager.mPlayers[id]
end

function PlayerManager.update()
    for id, player in pairs(PlayerManager.mPlayers) do
        if not GetEntityById(id) then
            PlayerManager.notify("PlayerRemoved", {mPlayerID = id})
            PlayerManager.mPlayers[id] = nil
        end
    end
end

function PlayerManager.showAll()
    PlayerManager.mHideAll = nil
    for _, player in pairs(PlayerManager.mPlayers) do
        player.mEntity:SetVisible(true)
        player.mEntity:ShowHeadOnDisplay(true)
    end
end

function PlayerManager.hideAll()
    PlayerManager.mHideAll = true
    for _, player in pairs(PlayerManager.mPlayers) do
        player.mEntity:ShowHeadOnDisplay(false)
        player.mEntity:SetVisible(false)
    end
end

function PlayerManager.clear()
end

function PlayerManager.addEventListener(eventType, key, callback, parameter)
    PlayerManager.mEventListeners = PlayerManager.mEventListeners or {}
    PlayerManager.mEventListeners[eventType] = PlayerManager.mEventListeners[eventType] or {}
    PlayerManager.mEventListeners[eventType][key] = {mCallback = callback, mParameter = parameter}
end

function PlayerManager.removeEventListener(eventType, key)
    PlayerManager.mEventListeners = PlayerManager.mEventListeners or {}
    PlayerManager.mEventListeners[eventType] = PlayerManager.mEventListeners[eventType] or {}
    PlayerManager.mEventListeners[eventType][key] = nil
end

function PlayerManager.notify(eventType, parameter)
    if PlayerManager.mEventListeners and PlayerManager.mEventListeners[eventType] then
        local listeners = PlayerManager.mEventListeners[eventType]
        for key, listener in pairs(listeners) do
            listener.mCallback(listener.mParameter, parameter)
        end
    end
end
-----------------------------------------------------------------------------------------Table Define-----------------------------------------------------------------------------------
local GameConfig = {}
local GameCompute = {}
local GamePlayerProperty = inherit(Property)
local GameMonsterProperty = inherit(Property)
local Host_Game = {}
local Host_GamePlayerManager = {}
local Host_GameMonsterManager = {}
local Host_GameTerrain = {}
local Host_GameMonsterGenerator = {}
local Host_GamePlayer = {}
local Host_GameMonster = {}
local Client_Game = {}
local Client_GamePlayerManager = {}
local Client_GameMonsterManager = {}
local Client_GamePlayer = {}
local Client_GameMonster = {}
-----------------------------------------------------------------------------------------GameConfig-----------------------------------------------------------------------------------
GameConfig.mMonsterPointBlockID = 2101
GameConfig.mHomePointBlockID = 2102
GameConfig.mMonsterLibrary = {
    {
        mModelResource = {hash = "Fta_KeWpZ2Uut43HCCwZuhIENsUk", pid = "6723", ext = "FBX"},
        mModelScaling = 2,
        mHP = 49,
        mDefence = {{mType = "穿刺", mValue = 0}},
        mAttack = {mType = "物理", mValue = 10},
        mAttackTime = 1,
        mStopTime = 1,
        mAttackRange = 1,
        mSpeed = 1,
        mName = "雄性菜头宝宝"
    },
    {
        mModelResource = {hash="FoHBdQE6rUCrF2BeYRxNbHRxCPPv",pid="12199",ext="FBX",},
        mModelScaling = 2,
        mHP = 49,
        mDefence = {{mType = "穿刺", mValue = 0}},
        mAttack = {mType = "物理", mValue = 10},
        mAttackTime = 1,
        mStopTime = 1,
        mAttackRange = 1,
        mSpeed = 1,
        mName = "蘑菇宝宝"
    },
    {
        mModelResource = {hash = "FklKvN9casvBiqCrvzMjFISaTt_1", pid = "6721", ext = "FBX"},
        mModelScaling = 2,
        mHP = 49,
        mDefence = {{mType = "穿刺", mValue = 0}},
        mAttack = {mType = "物理", mValue = 10},
        mAttackTime = 1,
        mStopTime = 1,
        mAttackRange = 1,
        mSpeed = 1,
        mName = "皇冠蛇宝宝"
    }
}
GameConfig.mTerrainLibrary = {
    {mTemplateResource = {hash = "FkokLxC_zI7okepx2bquNb-d85h7", pid = "5452", ext = "bmax"}},
    {mTemplateResource = {hash = "Fo_ZXJzECmw0-fPgj1ZSoLkjgnYA", pid = "5423", ext = "bmax"}},
    {mTemplateResource = {hash = "Fr1x_xY8fzz4YdLAxCYxfrJuXxUR", pid = "5424", ext = "bmax"}}
}
GameConfig.mSafeHouse = {mTemplateResource = {hash = "FpHOk_oMV1lBqaTtMLjqAtqyzJp4", pid = "5453", ext = "bmax"}}
GameConfig.mMatch = {
    mMonsterGenerateSpeed = 0.2,
    mMonsterCount = 20
}
GameConfig.mPlayers = {
    {mType = "战士", mHP = 70, mAttack = {mType = "穿刺", mValue = 10}, mDefence = {{mType = "物理", mValue = 0}}},
    mSpeed = 1,
    mAttackTime = 1,
    mStopTime = 0
}
GameConfig.mPrepareTime = 15
-----------------------------------------------------------------------------------------GameCompute-----------------------------------------------------------------------------------
function GameCompute.computePlayerHP(level)
    return 7 / GameCompute.computeMonsterAttackTime() * GameCompute.computeMonsterAttackValue(level)
end

function GameCompute.computePlayerAttackValue(level)
    return level + 19
end

function GameCompute.computePlayerAttackTime(level)
    local H1 = 0.00005
    local A8 = level
    local H2 = -(0.55+(100^2-1)*H1)/99
    local H3 = -H1+(0.55+(100^2-1)*H1)/99+0.6
    local J1 = -H2/(2*H1)
    local J2 = (4*H1*H3-H2^2)/(4*H1)
    return H1*(A8-J1)^2+J2
end

function GameCompute.computeMonsterHP(level)
    local C8 = GameCompute.computePlayerAttackValue(level)
    local B3 = 3
    local D8 = GameCompute.computePlayerAttackTime(level)
    return C8*B3/D8
end

function GameCompute.computeMonsterAttackValue(level)
    return 9 + level
end

function GameCompute.computeMonsterAttackTime(level)
    return 1
end

function GameCompute.computeMonsterLevel(players)
    local level = 0
    for _, player in pairs(players) do
        level = level + player:getProperty():cache().mHPLevel
        level = level + player:getProperty():cache().mAttackValueLevel
        level = level + player:getProperty():cache().mAttackTimeLevel
    end
    level = math.ceil(level / ((#players) * 3))
    return level
end

function GameCompute.computeMonsterGenerateCountScale(players)
    return #players
end

local function getNextLvTime(lv)
    if lv < 11 then
        return 0.02 * lv ^ 2 + 0.3 * lv + 1.08
    elseif lv >= 11 and lv < 31 then
        return 0.02 * lv ^ 2 + 0.3 * lv + 1.08
    elseif lv >= 31 and lv < 61 then
        return 0.06 * lv ^ 2 + 0.1 * lv - 27.5
    elseif lv >= 61 then
        return 0.25 * lv ^ 2 + 0.3 * lv - 710
    end
end

local function getNextLvGold(lv)
    local C3 = 3
    local nextLvTime = getNextLvTime(lv)
    local killEfficiency = C3 / 60
    local goldEfficiency = lv * 20 + 40
    local nextLvGold = goldEfficiency * nextLvTime
    return nextLvGold
end

function monLootGold(lv)
    local C3 = 3
    local nextLvTime = getNextLvTime(lv)
    local killEfficiency = C3 / 60
    local goldEfficiency = lv * 20 + 40
    local nextLvGold = goldEfficiency * nextLvTime
    local nextLvMonNum = nextLvTime / killEfficiency
    local monLootGold = nextLvGold / nextLvMonNum
    return monLootGold
end
------------------------------------------------------------------------------------------UI----------------------------------------------------------------------------
local GUI = require("GUI")
-- local Player = GetPlayer()
-- isServer = (Player.name == "__MP__admin")
-- if isServer then
--     local server = require("server")
-- end
-- local saveData = GetSavedData()
local saveData = getSavedData()
local gameUi = {
    {
        ui_name = "upgrade_background",
        type = "Picture",
        background_color = "0 148 236 255",
        align = "_ct",
        y = 0,
        x = 0,
        height = 500,
        width = 800,
        visible = true
    },
    {
        ui_name = "upgrade_title",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "能力提升"

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 50,
        x = function()
            return getUiValue("upgrade_background", "x") - 0
        end,
        y = function()
            return getUiValue("upgrade_background", "y") - 220
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "close_button",
        type = "Button",
        align = "_ct",
        background_color = "220 20 60 255",
        text = function()
            local text = "X"

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 30,
        x = function()
            return getUiValue("upgrade_background", "x") + 350
        end,
        y = function()
            return getUiValue("upgrade_background", "y") - 210
        end,
        onclick = function()
            closeSafeHouseUI()
        end,
        font_bold = true,
        height = 60,
        width = 60,
        text_format = 5,
        --text_border = true,
        shadow = true,
        font_color = "220 20 60",
        visible = true
    },
    {
        ui_name = "upgrade_fightingLevel",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "战斗力等级:" .. tostring(saveData.mHPLevel + saveData.mAttackValueLevel + saveData.mAttackTimeLevel)

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 35,
        x = function()
            return getUiValue("upgrade_background", "x") - 0
        end,
        y = function()
            return getUiValue("upgrade_background", "y") - 150
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_HP",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "生命等级:" .. tostring(saveData.mHPLevel)

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 35,
        x = function()
            return getUiValue("upgrade_fightingLevel", "x") - 200
        end,
        y = function()
            return getUiValue("upgrade_fightingLevel", "y") + 100
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_HP_button",
        type = "Button",
        align = "_ct",
        background_color = "0 0 0 255",
        text = function()
            local text = "升级"

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 30,
        x = function()
            return getUiValue("upgrade_HP", "x") + 200
        end,
        y = function()
            return getUiValue("upgrade_HP", "y") - 10
        end,
        onclick = function()
            local money = getNextLvGold(getSavedData().mHPLevel)
            if getSavedData().mMoney >= money then
                getSavedData().mMoney = getSavedData().mMoney - money
                getSavedData().mHPLevel = getSavedData().mHPLevel + 1
                local x,y,z = GetPlayer():GetBlockPos()
                local host_key = EntityCustomManager.singleton():createEntity(x,y,z,"character/v5/09effect/Upgrade/Upgrade_CirqueGlowRed.x")
                CommandQueue.default():post(new(Command_Callback,{mDebug = "Command_Callback/UpdateHP",mExecutingCallback = function(command)
                    command.mTimer = command.mTimer or new(Timer)
                    local x,y,z = GetPlayer():GetPosition()
                    EntityCustomManager.singleton():getEntity(host_key):setPositionReal(x,y,z)
                    if command.mTimer:total() > 0.8 then
                        delete(command.mTimer)
                        EntityCustomManager.singleton():destroyEntity(host_key)
                        command.mState = Command.EState.Finish
                    end
                end}))
            end
        end,
        font_bold = true,
        height = 50,
        width = 100,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_HP_gold",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "需要金钱：" .. tostring(getNextLvGold(getSavedData().mHPLevel))

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 20,
        x = function()
            return getUiValue("upgrade_HP_button", "x") + 150
        end,
        y = function()
            return getUiValue("upgrade_HP_button", "y") + 10
        end,
        font_bold = true,
        height = 50,
        width = 200,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attack",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "攻击等级:" .. tostring(saveData.mAttackValueLevel)

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 35,
        x = function()
            return getUiValue("upgrade_HP", "x") - 0
        end,
        y = function()
            return getUiValue("upgrade_HP", "y") + 100
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attack_button",
        type = "Button",
        align = "_ct",
        background_color = "0 0 0 255",
        text = function()
            local text = "升级"

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 30,
        x = function()
            return getUiValue("upgrade_attack", "x") + 200
        end,
        y = function()
            return getUiValue("upgrade_attack", "y") - 10
        end,
        onclick = function()
            local money = getNextLvGold(getSavedData().mAttackValueLevel)
            if getSavedData().mMoney >= money then
                getSavedData().mMoney = getSavedData().mMoney - money
                getSavedData().mAttackValueLevel = getSavedData().mAttackValueLevel + 1
                local x,y,z = GetPlayer():GetBlockPos()
                local host_key = EntityCustomManager.singleton():createEntity(x,y,z,"character/v5/09effect/Upgrade/Upgrade_CirqueGlowRed.x")
                CommandQueue.default():post(new(Command_Callback,{mDebug = "Command_Callback/UpdateAttackValue",mExecutingCallback = function(command)
                    command.mTimer = command.mTimer or new(Timer)
                    local x,y,z = GetPlayer():GetPosition()
                    EntityCustomManager.singleton():getEntity(host_key):setPositionReal(x,y,z)
                    if command.mTimer:total() > 0.8 then
                        delete(command.mTimer)
                        EntityCustomManager.singleton():destroyEntity(host_key)
                        command.mState = Command.EState.Finish
                    end
                end}))
            end
        end,
        font_bold = true,
        height = 50,
        width = 100,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attack_gold",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "需要金钱：" .. tostring(getNextLvGold(getSavedData().mAttackValueLevel))

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 20,
        x = function()
            return getUiValue("upgrade_attack_button", "x") + 150
        end,
        y = function()
            return getUiValue("upgrade_attack_button", "y") + 10
        end,
        font_bold = true,
        height = 50,
        width = 200,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attSpeed",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "攻速等级:" .. tostring(saveData.mAttackTimeLevel)

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 35,
        x = function()
            return getUiValue("upgrade_attack", "x") - 0
        end,
        y = function()
            return getUiValue("upgrade_attack", "y") + 100
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attSpeed_button",
        type = "Button",
        align = "_ct",
        background_color = "0 0 0 255",
        text = function()
            local text = "升级"

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 30,
        x = function()
            return getUiValue("upgrade_attSpeed", "x") + 200
        end,
        y = function()
            return getUiValue("upgrade_attSpeed", "y") - 10
        end,
        onclick = function()
            local money = getNextLvGold(getSavedData().mAttackTimeLevel)
            if getSavedData().mMoney >= money then
                getSavedData().mMoney = getSavedData().mMoney - money
                getSavedData().mAttackTimeLevel = getSavedData().mAttackTimeLevel + 1
                local x,y,z = GetPlayer():GetBlockPos()
                local host_key = EntityCustomManager.singleton():createEntity(x,y,z,"character/v5/09effect/Upgrade/Upgrade_CirqueGlowRed.x")
                CommandQueue.default():post(new(Command_Callback,{mDebug = "Command_Callback/UpdateAttackTime",mExecutingCallback = function(command)
                    command.mTimer = command.mTimer or new(Timer)
                    local x,y,z = GetPlayer():GetPosition()
                    EntityCustomManager.singleton():getEntity(host_key):setPositionReal(x,y,z)
                    if command.mTimer:total() > 0.8 then
                        delete(command.mTimer)
                        EntityCustomManager.singleton():destroyEntity(host_key)
                        command.mState = Command.EState.Finish
                    end
                end}))
            end
        end,
        font_bold = true,
        height = 50,
        width = 100,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "upgrade_attSpeed_gold",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "需要金钱：" .. tostring(getNextLvGold(getSavedData().mAttackTimeLevel))

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 20,
        x = function()
            return getUiValue("upgrade_attSpeed_button", "x") + 150
        end,
        y = function()
            return getUiValue("upgrade_attSpeed_button", "y") + 10
        end,
        font_bold = true,
        height = 50,
        width = 200,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 255 255",
        visible = true
    },
    {
        ui_name = "current_gold",
        type = "Text",
        align = "_ct",
        text = function()
            local text = "金钱：" .. tostring(saveData.mMoney)

            return text
        end,
        -- font_type = "Source Han Sans SC Bold",
        font_size = 40,
        x = function()
            return getUiValue("upgrade_background", "x") - 250
        end,
        y = function()
            return getUiValue("upgrade_background", "y") + 220
        end,
        font_bold = true,
        height = 70,
        width = 300,
        text_format = 1,
        --text_border = true,
        shadow = true,
        font_color = "255 215 0",
        visible = true
    }
}
function initUi()
    for i = 1, #gameUi do
        GUI.UI(gameUi[i])
    end
end

function openSafeHouseUI()
    for i = 1, #gameUi do
        gameUi[i].visible = true
    end
end

function closeSafeHouseUI()
    for i = 1, #gameUi do
        gameUi[i].visible = false
    end
end

function getUi(name)
    for i = 1, #gameUi do
        if gameUi[i].ui_name == name then
            return gameUi[i]
        end
    end
    return {}
end

function getUiValue(ui_name, key)
    local ui = getUi(ui_name)
    if type(ui[key]) == "function" then
        return ui[key]()
    end
    return ui[key]
end

function setUiValue(ui_name, key, value)
    local ui = getUi(ui_name)
    if ui then
        ui[key] = value
    end
end

function showUi(name)
    local ui = getUi(name)
    if ui then
        ui.visible = true
    end
end

function hideUi(name)
    local ui = getUi(name)
    if ui then
        ui.visible = false
    end
end
-----------------------------------------------------------------------------------------GamePlayerProperty-----------------------------------------------------------------------------------
function GamePlayerProperty:construction(parameter)
    self.mPlayerID = parameter.mPlayerID
end

function GamePlayerProperty:destruction()
    self:safeWrite("mHP")
    self:safeWrite("mHPLevel")
    self:safeWrite("mAttackValueLevel")
    self:safeWrite("mAttackTimeLevel")
    self:safeWrite("mConfigIndex")
end

function GamePlayerProperty:_getLockKey(propertyName)
    return "GamePlayerProperty/" .. tostring(self.mPlayerID) .. "/" .. propertyName
end
-----------------------------------------------------------------------------------------GameMonsterProperty-----------------------------------------------------------------------------------
function GameMonsterProperty:construction(parameter)
    self.mEntityID = parameter.mEntityID
end

function GameMonsterProperty:destruction()
    self:safeWrite("mHP")
    self:safeWrite("mLevel")
    self:safeWrite("mConfigIndex")
end

function GameMonsterProperty:_getLockKey(propertyName)
    return "GameMonsterProperty/" .. tostring(self.mEntityID) .. "/" .. propertyName
end
-----------------------------------------------------------------------------------------Host_Game-----------------------------------------------------------------------------------
function Host_Game.singleton()
    return Host_Game.msInstance
end

function Host_Game:construction()
    Host_Game.msInstance = self
    self.mCommandQueue = new(CommandQueue)

    self.mSafeHouse = {}
    local x, y, z = GetHomePosition()
    x, y, z = ConvertToBlockIndex(x, y + 0.5, z)
    y = y - 1
    self.mSafeHouse.mTerrain =
        new(
        Host_GameTerrain,
        {mTemplateResource = GameConfig.mSafeHouse.mTemplateResource, mHomePosition = {x, y + 100, z}}
    )
    self.mSafeHouse.mTerrain:applyTemplate(
        function()
            self.mPlayerManager = new(Host_GamePlayerManager)
            self.mMonsterManager = new(Host_GameMonsterManager)
            self:start()
        end
    )
end

function Host_Game:destruction()
    delete(self.mPlayerManager)
    delete(self.mMonsterManager)
    if self.mSafeHouse then
        delete(self.mSafeHouse.mTerrain)
    end
    if self.mScene then
        delete(self.mScene.mTerrain)
    end
    Host_Game.msInstance = nil
end

function Host_Game:update(deltaTime)
    self.mCommandQueue:update()
    if self.mPlayerManager then
        self.mPlayerManager:update(deltaTime)
    end
    if self.mMonsterManager then
        self.mMonsterManager:update(deltaTime)
    end
    if self.mSafeHouse then
        self.mSafeHouse.mTerrain:update()
    end
    if self.mScene then
        self.mScene.mTerrain:update()
    end
end

function Host_Game:getPlayerManager()
    return self.mPlayerManager
end

function Host_Game:getMonsterManager()
    return self.mMonsterManager
end

function Host_Game:setScene(scene, callback)
    if self.mScene then
        delete(self.mScene.mTerrain)
    end
    self.mScene = scene
    if self.mScene then
        self.mPlayerManager:leaveSafeHouse()
        self.mScene.mTerrain:applyTemplate(
            function()
                self.mPlayerManager:setScene(self.mScene)
                self.mMonsterManager:setScene(self.mScene)
                callback()
            end
        )
    else
        self.mPlayerManager:setScene(self.mSafeHouse)
        self.mPlayerManager:enterSafeHouse()
        callback()
    end
end

function Host_Game:start()
    self.mLevel = 1
    self.mPlayerManager:initializePlayerProperties()
    self:setScene(
        nil,
        function()
            self:_nextMatch()
        end
    )
end

function Host_Game:_nextMatch()
    self.mPlayerManager:initializePlayerProperties("mHP")
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "Host_Game:_nextMatch/Prepare",
                mExecutingCallback = function(command)
                    command.mTimer = command.mTimer or new(Timer)
                    if command.mTimer:total() > GameConfig.mPrepareTime then
                        command.mState = Command.EState.Finish
                    end
                end
            }
        )
    )
    self.mCommandQueue:post(
        new(
            Command_Callback,
            {
                mDebug = "Host_Game:_nextMatch/Start",
                mExecuteCallback = function(command)
                    command.mState = Command.EState.Finish
                    self:_startMatch(
                        function()
                            self.mCommandQueue:post(
                                new(
                                    Command_Callback,
                                    {
                                        mDebug = "Host_Game:_nextMatch/Check",
                                        mTimeOutProcess = function()
                                        end,
                                        mExecutingCallback = function(command)
                                            if self.mPlayerManager:isAllDead() then
                                                self.mCommandQueue:post(
                                                    new(
                                                        Command_Callback,
                                                        {
                                                            mDebug = "Host_Game:_nextMatch/Restart",
                                                            mTimeOutProcess = function()
                                                            end,
                                                            mExecutingCallback = function(command)
                                                                command.mTimer = command.mTimer or new(Timer)
                                                                if command.mTimer:total() >= 5 then
                                                                    command.mState = Command.EState.Finish
                                                                    self:start()
                                                                end
                                                            end
                                                        }
                                                    )
                                                )
                                                command.mState = Command.EState.Finish
                                            elseif self.mMonsterManager:isAllDead() then
                                                self.mCommandQueue:post(
                                                    new(
                                                        Command_Callback,
                                                        {
                                                            mDebug = "Host_Game:_nextMatch/NextMatch",
                                                            mTimeOutProcess = function()
                                                            end,
                                                            mExecutingCallback = function(command)
                                                                command.mTimer = command.mTimer or new(Timer)
                                                                if command.mTimer:total() >= 5 then
                                                                    command.mState = Command.EState.Finish
                                                                    self:setScene(nil,
                                                                        function()
                                                                            self.mLevel = self.mLevel + 1
                                                                            self:_nextMatch()
                                                                        end
                                                                    )
                                                                end
                                                            end
                                                        }
                                                    )
                                                )
                                                command.mState = Command.EState.Finish
                                            end
                                        end
                                    }
                                )
                            )
                        end
                    )
                end
            }
        )
    )
end

function Host_Game:_startMatch(callback)
    local scene = {mLevel = self.mLevel}
    local terrains = {}
    for _, terrain in pairs(GameConfig.mTerrainLibrary) do
        if not terrain.mLevel or terrain.mLevel == self.mLevel then
            terrains[#terrains + 1] = terrain
        end
    end
    if #terrains > 0 then
        local terrain_config = terrains[math.random(1, #terrains)]
        scene.mTerrain = new(Host_GameTerrain, {mTemplateResource = terrain_config.mTemplateResource})
        self:setScene(scene, callback)
    else
        self:setScene(nil,callback)
    end
end
-----------------------------------------------------------------------------------------Host_GamePlayerManager-----------------------------------------------------------------------------------
function Host_GamePlayerManager:construction()
    self.mPlayers = {}

    for id,player in pairs(PlayerManager.mPlayers) do
        self:_createPlayer(EntityWatcher.get(id))
    end
    PlayerManager.addEventListener(
        "PlayerIn",
        "Host_GamePlayerManager",
        function(inst, parameter)
            self:_createPlayer(EntityWatcher.get(parameter.mPlayerID))
        end,
        self
    )
    PlayerManager.addEventListener(
        "PlayerRemoved",
        "Host_GamePlayerManager",
        function(inst, parameter)
            self:_destroyPlayer(parameter.mPlayerID)
        end,
        self
    )
    Host.addListener("GamePlayerManager", self)
end

function Host_GamePlayerManager:destruction()
    self:reset()
    PlayerManager.removeEventListener("PlayerIn", "Host_GamePlayerManager")
    PlayerManager.removeEventListener("PlayerRemoved", "Host_GamePlayerManager")
    Host.removeListener("GamePlayerManager", self)
end

function Host_GamePlayerManager:update()
end

function Host_GamePlayerManager:broadcast(message, parameter)
    Host.broadcast({mKey = "GamePlayerManager", mMessage = message, mParameter = parameter})
end

function Host_GamePlayerManager:receive(parameter)
end

function Host_GamePlayerManager:reset()
    self:broadcast("Reset")
    for _, player in pairs(self.mPlayers) do
        delete(player)
    end
    self.mPlayers = {}
end

function Host_GamePlayerManager:getPlayerByID(playerID)
    playerID = playerID or GetPlayerId()
    for _, player in pairs(self.mPlayers) do
        if player:getID() == playerID then
            return player
        end
    end
end

function Host_GamePlayerManager:initializePlayerProperties(propertyName)
    self:eachPlayer("initializeProperty", propertyName)
end

function Host_GamePlayerManager:enterSafeHouse()
    self:eachPlayer("enterSafeHouse")
end

function Host_GamePlayerManager:leaveSafeHouse()
    self:eachPlayer("leaveSafeHouse")
end

function Host_GamePlayerManager:setScene(scene)
    self.mScene = scene
    if self.mScene then
        self:eachPlayer("setPosition", self.mScene.mTerrain:getHomePoint())
    end
end

function Host_GamePlayerManager:_createPlayer(entityWatcher)
    local ret = new(Host_GamePlayer, {mEntityWatcher = entityWatcher, mConfigIndex = 1})
    self.mPlayers[#self.mPlayers + 1] = ret
    if Host_Game.singleton().mScene then
        local pos = Host_Game.singleton().mScene.mTerrain:getHomePoint()
        SetEntityBlockPos(ret:getID(), pos[1], pos[2], pos[3])
    elseif Host_Game.singleton().mSafeHouse then
        local pos = Host_Game.singleton().mSafeHouse.mTerrain:getHomePoint()
        SetEntityBlockPos(ret:getID(), pos[1], pos[2], pos[3])
    end
    self:broadcast("CreatePlayer", {mPlayerID = ret:getID()})
    return ret
end

function Host_GamePlayerManager:_destroyPlayer(id)
    echo("devilwalk", "Host_GamePlayerManager:_destroyPlayer:id:" .. tostring(id))
    self:broadcast("DestroyPlayer", {mPlayerID = id})
    for i, player in pairs(self.mPlayers) do
        if player:getID() == id then
            delete(player)
            table.remove(self.mPlayers, i)
            break
        end
    end
end

function Host_GamePlayerManager:eachPlayer(functionName, ...)
    for _, player in pairs(self.mPlayers) do
        player[functionName](player, ...)
    end
end

function Host_GamePlayerManager:isAllDead()
    for _, player in pairs(self.mPlayers) do
        if not player:getProperty():cache().mHP or player:getProperty():cache().mHP > 0 then
            return false
        end
    end
    return true
end
-----------------------------------------------------------------------------------------Host_GameMonsterManager-----------------------------------------------------------------------------------
function Host_GameMonsterManager:construction()
    self.mMonsters = {}

    Host.addListener("GameMonsterManager", self)
end

function Host_GameMonsterManager:destruction()
    self:reset()

    Host.removeListener("GameMonsterManager", self)
end

function Host_GameMonsterManager:reset()
    self:broadcast("Reset")
    for _, monster in pairs(self.mMonsters) do
        delete(monster)
    end
    self.mMonsters = {}
    delete(self.mMonsterGenerator)
end

function Host_GameMonsterManager:setScene(scene)
    self:reset()

    if scene and scene.mTerrain and #scene.mTerrain:getMonsterPoints() > 0 then
        self.mMonsterGenerator =
            new(
            Host_GameMonsterGenerator,
            {
                mPositions = scene.mTerrain:getMonsterPoints(),
                mGenerateSpeed = GameConfig.mMatch.mMonsterGenerateSpeed,
                mGenerateCount = GameConfig.mMatch.mMonsterCount *
                    GameCompute.computeMonsterGenerateCountScale(Host_Game.singleton():getPlayerManager().mPlayers)
            }
        )
    else
        delete(self.mMonsterGenerator)
        self.mMonsterGenerator = nil
    end
end

function Host_GameMonsterManager:update(deltaTime)
    --更新现有怪物逻辑
    self:_updateMonsters(deltaTime)
    --产生新怪物
    self:_generateMonsters(deltaTime)
end

function Host_GameMonsterManager:broadcast(message, parameter)
    Host.broadcast({mKey = "GameMonsterManager", mMessage = message, mParameter = parameter})
end

function Host_GameMonsterManager:receive(parameter)
end

function Host_GameMonsterManager:isAllDead()
    if self.mMonsterGenerator and self.mMonsterGenerator.mGenerateCount > 0 then
        return false
    end
    for _, monster in pairs(self.mMonsters) do
        if monster:getProperty():cache().mHP > 0 then
            return false
        end
    end
    return true
end

function Host_GameMonsterManager:_createMonster(parameter)
    local ret =
        new(
        Host_GameMonster,
        {
            mConfigIndex = parameter.mConfigIndex,
            mPosition = parameter.mPosition,
            mLevel = Host_Game.singleton().mLevel
        }
    )
    self.mMonsters[#self.mMonsters + 1] = ret
    self:broadcast("CreateMonster", {mEntityID = ret:getID()})
    return ret
end

function Host_GameMonsterManager:_updateMonsters(deltaTime)
    for _, monster in pairs(self.mMonsters) do
        monster:update(deltaTime)
    end
end

function Host_GameMonsterManager:_generateMonsters(deltaTime)
    if self.mMonsterGenerator then
        local monsters = self.mMonsterGenerator:generate(deltaTime)
        for _, monster in pairs(monsters) do
            self:_createMonster(monster)
        end
    end
end
-----------------------------------------------------------------------------------------Host_GameTerrain-----------------------------------------------------------------------------------
function Host_GameTerrain:construction(parameter)
    local x, y, z = GetHomePosition()
    x, y, z = ConvertToBlockIndex(x, y + 0.5, z)
    y = y - 1
    self.mHomePosition = parameter.mHomePosition or {x, y, z}
    self.mTemplate = parameter.mTemplate
    self.mTemplateResource = parameter.mTemplateResource
    self.mMonsterPoints = {}
    self.mCommandQueue = new(CommandQueue)
end

function Host_GameTerrain:destruction()
    delete(self.mCommandQueue)
    self:restoreTemplate()
end

function Host_GameTerrain:update()
    self.mCommandQueue:update()
end

function Host_GameTerrain:applyTemplate(callback)
    if self.mTemplate then
        if self.mTemplate.mBlocks then
            local offset = {self.mHomePosition[1] + 1, self.mHomePosition[2] + 1, self.mHomePosition[3] + 1}
            for _, block in pairs(self.mTemplate.mBlocks) do
                if block[4] == GameConfig.mMonsterPointBlockID then
                    self.mMonsterPoints[#self.mMonsterPoints + 1] = {
                        block[1] + offset[1],
                        block[2] + offset[2],
                        block[3] + offset[3]
                    }
                    setBlock(block[1] + offset[1], block[2] + offset[2], block[3] + offset[3], 0)
                elseif block[4] == GameConfig.mHomePointBlockID then
                    self.mHomePoint = {block[1] + offset[1], block[2] + offset[2], block[3] + offset[3]}
                    setBlock(block[1] + offset[1], block[2] + offset[2], block[3] + offset[3], 0)
                else
                    setBlock(block[1] + offset[1], block[2] + offset[2], block[3] + offset[3], block[4], block[5])
                end
            end
        end
        if callback then
            self.mCommandQueue:post(new(Command_Callback,{mDebug = "Host_GameTerrain:applyTemplate",mExecutingCallback = function(command)
                command.mTimer = command.mTimer or new(Timer)
                if command.mTimer:total()>1 then
                    delete(command.mTimer)
                    command.mState = Command.EState.Finish
                    callback()
                end
            end}))
        end
    elseif self.mTemplateResource then
        GetResourceModel(
            self.mTemplateResource,
            function(path)
                self.mTemplate = LoadTemplate(path)
                self:applyTemplate(callback)
            end
        )
    end
end

function Host_GameTerrain:restoreTemplate()
    if self.mTemplate then
        if self.mTemplate.mBlocks then
            local offset = {self.mHomePosition[1] + 1, self.mHomePosition[2] + 1, self.mHomePosition[3] + 1}
            for _, block in pairs(self.mTemplate.mBlocks) do
                restoreBlock(block[1] + offset[1], block[2] + offset[2], block[3] + offset[3])
            end
        end
    end
end

function Host_GameTerrain:getMonsterPoints()
    return self.mMonsterPoints
end

function Host_GameTerrain:getHomePoint()
    return self.mHomePoint
end
-----------------------------------------------------------------------------------------Host_GameMonsterGenerator-----------------------------------------------------------------------------------
function Host_GameMonsterGenerator:construction(parameter)
    self.mPositions = parameter.mPositions
    self.mGenerateSpeed = parameter.mGenerateSpeed
    self.mGenerateCount = parameter.mGenerateCount
    self.mGenerateTime = 0
end

function Host_GameMonsterGenerator:destruction()
end

function Host_GameMonsterGenerator:generate(deltaTime)
    self.mGenerateTime = self.mGenerateTime + deltaTime
    local generate_time = math.floor(self.mGenerateTime)
    local need_generate_count = math.min(self.mGenerateCount, math.floor(generate_time * self.mGenerateSpeed))
    if need_generate_count > 0 then
        self.mGenerateTime = self.mGenerateTime - generate_time
    end
    self.mGenerateCount = self.mGenerateCount - need_generate_count
    local ret = {}
    for i = 1, need_generate_count do
        local config_index = math.random(1, #GameConfig.mMonsterLibrary)
        ret[#ret + 1] = {mConfigIndex = config_index, mPosition = self.mPositions[math.random(1, #self.mPositions)]}
    end
    return ret
end
-----------------------------------------------------------------------------------------Host_GamePlayer-----------------------------------------------------------------------------------
function Host_GamePlayer:construction(parameter)
    echo("devilwalk", "Host_GamePlayer:construction")
    self.mPlayerID = parameter.mEntityWatcher.id
    self.mProperty = new(GamePlayerProperty, {mPlayerID = self.mPlayerID})
    self.mConfigIndex = parameter.mConfigIndex

    self.mProperty:safeWrite("mConfigIndex", self.mConfigIndex)
    self.mProperty:addPropertyListener(
        "mHPLevel",
        self,
        function(_, value)
            if value then
                self.mProperty:safeWrite("mHP", GameCompute.computePlayerHP(value))
            end
        end
    )
    self.mProperty:addPropertyListener(
        "mAttackValueLevel",
        self,
        function(_, value)
        end
    )
    self.mProperty:addPropertyListener(
        "mAttackTimeLevel",
        self,
        function(_, value)
        end
    )

    Host.addListener(self:_getSendKey(), self)
end

function Host_GamePlayer:destruction()
    echo("devilwalk", "Host_GamePlayer:destruction")
    self.mProperty:removePropertyListener("mHPLevel", self)
    self.mProperty:removePropertyListener("mAttackValueLevel", self)
    self.mProperty:removePropertyListener("mAttackTimeLevel", self)
    delete(self.mProperty)
    Host.removeListener(self:_getSendKey(), self)
end

function Host_GamePlayer:sendToClient(message, parameter)
    Host.sendTo(self.mPlayerID, {mKey = self:_getSendKey(), mMessage = message, mParameter = parameter})
end

function Host_GamePlayer:receive(parameter)
end

function Host_GamePlayer:onHit(monster)
    self.mProperty:safeWrite(
        "mHP",
        math.max(
            self.mProperty:cache().mHP - GameCompute.computeMonsterAttackValue(monster:getProperty():cache().mLevel),
            0
        )
    )

    self:_checkDead()
end

function Host_GamePlayer:getID()
    return self.mPlayerID
end

function Host_GamePlayer:getProperty()
    return self.mProperty
end

function Host_GamePlayer:getConfig()
    return GameConfig.mPlayers[self.mConfigIndex]
end

function Host_GamePlayer:initializeProperty(propertyName)
    if propertyName then
        if propertyName == "mHP" then
            self.mProperty:safeRead(
                "mHPLevel",
                function(value)
                    if value then
                        self.mProperty:safeWrite("mHP", GameCompute.computePlayerHP(value))
                        self:_checkDead()
                    end
                end
            )
        end
    else
        self.mProperty:safeRead(
            "mHPLevel",
            function(value)
                if value then
                    self.mProperty:safeWrite("mHP", GameCompute.computePlayerHP(value))
                    self:_checkDead()
                end
            end
        )
    end
end

function Host_GamePlayer:setPosition(position)
    SetEntityBlockPos(self.mPlayerID, position[1], position[2], position[3])
end

function Host_GamePlayer:enterSafeHouse()
    self:sendToClient("EnterSafeHouse")
end

function Host_GamePlayer:leaveSafeHouse()
    self:sendToClient("LeaveSafeHouse")
end

function Host_GamePlayer:addMoney(money)
    self:sendToClient("AddMoney", {mMoney = money})
end

function Host_GamePlayer:_getSendKey()
    return "GamePlayer/" .. tostring(self.mPlayerID)
end

function Host_GamePlayer:_checkDead()
    if not self.mDead and self.mProperty:cache().mHP <= 0 then
        self.mDead = true
        self:sendToClient("Dead")
    elseif self.mDead and self.mProperty:cache().mHP > 0 then
        self.mDead = nil
        self:sendToClient("Revive")
    end
end
-----------------------------------------------------------------------------------------Host_GameMonster-----------------------------------------------------------------------------------
Host_GameMonster.mNameIndex = 1
function Host_GameMonster:construction(parameter)
    self.mConfigIndex = parameter.mConfigIndex
    self.mEntity =
        CreateNPC(
        {
            name = "GameMonster/" .. tostring(Host_GameMonster.mNameIndex),
            bx = parameter.mPosition[1],
            by = parameter.mPosition[2],
            bz = parameter.mPosition[3],
            facing = 0,
            can_random_move = false,
            item_id = 10062,
            --is_dummy = false,
            is_persistent = false,
            scaling = self:getConfig().mModelScaling
        }
    )
    self.mEntityID = self.mEntity.entityId
    Host_GameMonster.mNameIndex = Host_GameMonster.mNameIndex + 1
    self.mEntity:setModelFromResource(self:getConfig().mModelResource)
    self.mProperty = new(GameMonsterProperty, {mEntityID = self.mEntityID})

    self.mProperty:safeWrite("mConfigIndex", parameter.mConfigIndex)
    self.mProperty:safeWrite("mLevel", parameter.mLevel)
    self.mProperty:safeWrite("mInitHP", GameCompute.computeMonsterHP(self.mProperty:cache().mLevel))
    self.mProperty:safeWrite("mHP", GameCompute.computeMonsterHP(self.mProperty:cache().mLevel))

    Host.addListener(self:_getSendKey(), self)
end

function Host_GameMonster:destruction()
    delete(self.mProperty)
    if self.mEntity then
        self.mEntity:SetDead(true)
    end
    Host.removeListener(self:_getSendKey(), self)
end

function Host_GameMonster:update()
    if not self.mEntity then
        return
    end
    if
        self.mAttackTimer and
            self.mAttackTimer:total() >= GameCompute.computeMonsterAttackTime(self.mProperty:cache().mLevel)
     then
        delete(self.mAttackTimer)
        self.mAttackTimer = nil
    end
    if self.mStopTimer and self.mStopTimer:total() >= self:getConfig().mStopTime then
        delete(self.mStopTimer)
        self.mStopTimer = nil
    end
    if not self.mAttackTimer then
        local attacked
        for _, player in pairs(Host_Game.singleton():getPlayerManager().mPlayers) do
            if player:getProperty():cache().mHP and player:getProperty():cache().mHP > 0 then
                local dst_x, dst_y, dst_z = GetEntityById(player:getID()):GetBlockPos()
                local x, y, z = self.mEntity:GetBlockPos()
                local dst = math.pow((dst_x - x), 2) + math.pow((dst_y - y), 2) + math.pow((dst_z - z), 2)
                if dst <= self:getConfig().mAttackRange then
                    player:onHit(self)
                    attacked = true
                end
            end
        end
        if attacked then
            self.mAttackTimer = new(Timer)
            self.mStopTimer = new(Timer)
        end
    end
    if not self.mStopTimer then
        self:_updateMoveTarget()
    end
end

function Host_GameMonster:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
    else
        if parameter.mMessage == "PropertyChange" then
            self:_propertyChange(parameter._from, parameter.mParameter)
        end
    end
end

function Host_GameMonster:getID()
    return self.mEntityID
end

function Host_GameMonster:getEntity()
    return self.mEntity
end

function Host_GameMonster:getProperty()
    return self.mProperty
end

function Host_GameMonster:getConfig()
    return GameConfig.mMonsterLibrary[self.mConfigIndex]
end

function Host_GameMonster:_getSendKey()
    return "GameMonster/" .. tostring(self.mEntityID)
end

function Host_GameMonster:_propertyChange(playerID, change)
    if change.mHPSubtract then
        sub_stract = math.min(change.mHPSubtract, self.mProperty:cache().mHP)
        self.mDamaged = self.mDamaged or {}
        self.mDamaged[playerID] = self.mDamaged[playerID] or 0
        self.mDamaged[playerID] = self.mDamaged[playerID] + sub_stract
        self.mProperty:safeWrite("mHP", self.mProperty:cache().mHP - sub_stract)
    end

    self:_checkDead()
end

function Host_GameMonster:_checkDead()
    if self.mProperty:cache().mHP <= 0 then
        if self.mEntity then
            self.mEntity:SetDead(true)
            self.mEntity = nil
        end
        if self.mDamaged then
            local total_money = monLootGold(self.mProperty:cache().mLevel)
            for player_id, damage in pairs(self.mDamaged) do
                local player = Host_Game.singleton():getPlayerManager():getPlayerByID(player_id)
                if player then
                    local money = total_money * damage / self.mProperty:cache().mInitHP
                    player:addMoney(money)
                end
            end
            self.mDamaged = nil
        end
    end
end

function Host_GameMonster:_updateMoveTarget()
    if self.mHasTarget then
        self.mHasTarget = self.mEntity:HasTarget()
        return
    end
    local my_x, my_y, my_z = self.mEntity:GetBlockPos()
    for _, monster in pairs(Host_Game.singleton():getMonsterManager().mMonsters) do
        if monster ~= self and monster:getEntity() then
            local test_x, test_y, test_z = monster:getEntity():GetBlockPos()
            if test_x == my_x and test_y == my_y and test_z == my_z then
                local offset_x = math.random(-1, 1)
                local offset_z = math.random(-1, 1)
                self.mEntity:MoveTo(my_x + offset_x, my_y + 1, my_z + offset_z)
                self.mHasTarget = true
                return
            end
        end
    end
    local select
    for _, player in pairs(Host_Game.singleton():getPlayerManager().mPlayers) do
        if player:getProperty():cache().mHP and player:getProperty():cache().mHP > 0 then
            local dst_x, dst_y, dst_z = GetEntityById(player:getID()):GetBlockPos()
            local dst = math.pow((dst_x - my_x), 2) + math.pow((dst_y - my_y), 2) + math.pow((dst_z - my_z), 2)
            if not select then
                select = {x = dst_x, y = my_y, z = dst_z, len = dst}
            else
                if select.len > dst then
                    select = {x = dst_x, y = my_y, z = dst_z, len = dst}
                end
            end
        end
    end
    if select then
        self.mEntity:MoveTo(select.x, select.y + 1, select.z)
    else
        local offset_x = math.random(-1, 1)
        local offset_z = math.random(-1, 1)
        self.mEntity:MoveTo(my_x + offset_x, my_y + 1, my_z + offset_z)
        self.mHasTarget = true
    end
end
-----------------------------------------------------------------------------------------Client_Game-----------------------------------------------------------------------------------
function Client_Game.singleton()
    if not Client_Game.msInstance then
        Client_Game.msInstance = new(Client_Game)
    end
    return Client_Game.msInstance
end

function Client_Game:construction()
    self.mPlayerManager = new(Client_GamePlayerManager)
    self.mMonsterManager = new(Client_GameMonsterManager)
end

function Client_Game:destruction()
    delete(self.mMonsterManager)
    delete(self.mPlayerManager)
    Client_Game.msInstance = nil
end

function Client_Game:update(deltaTime)
    self.mPlayerManager:update(deltaTime)
    self.mMonsterManager:update(deltaTime)
end

function Client_Game:onHit(weapon, result)
    self.mPlayerManager:onHit(weapon, result)
    self.mMonsterManager:onHit(weapon, result)
end

function Client_Game:getPlayerManager()
    return self.mPlayerManager
end

function Client_Game:getMonsterManager()
    return self.mMonsterManager
end
-----------------------------------------------------------------------------------------Client_GamePlayerManager-----------------------------------------------------------------------------------
function Client_GamePlayerManager:construction()
    self.mPlayers = {}

    Client.addListener("GamePlayerManager", self)
end

function Client_GamePlayerManager:destruction()
    self:reset()
    Client.removeListener("GamePlayerManager", self)
end

function Client_GamePlayerManager:reset()
    for _, player in pairs(self.mPlayers) do
        delete(player)
    end
    self.mPlayers = {}
end

function Client_GamePlayerManager:update()
    for _, player in pairs(self.mPlayers) do
        player:update()
    end
end

function Client_GamePlayerManager:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
    else
        if parameter.mMessage == "CreatePlayer" then
            self:_createPlayer(parameter.mParameter.mPlayerID)
        elseif parameter.mMessage == "DestroyPlayer" then
            self:_destroyPlayer(parameter.mParameter.mPlayerID)
        elseif parameter.mMessage == "Reset" then
            self:reset()
        end
    end
end

function Client_GamePlayerManager:sendToHost(message, parameter)
    Client.sendToHost("GamePlayerManager", {mMessage = message, mParameter = parameter})
end

function Client_GamePlayerManager:getPlayerByID(playerID)
    playerID = playerID or GetPlayerId()
    for _, player in pairs(self.mPlayers) do
        if player:getID() == playerID then
            return player
        end
    end
end

function Client_GamePlayerManager:onHit(weapon, result)
    for _, player in pairs(self.mPlayers) do
        player:onHit(weapon, result)
    end
end

function Client_GamePlayerManager:_createPlayer(playerID)
    local ret = new(Client_GamePlayer, {mPlayerID = playerID})
    self.mPlayers[#self.mPlayers + 1] = ret
    return ret
end

function Client_GamePlayerManager:_destroyPlayer(playerID)
    for i, player in pairs(self.mPlayers) do
        if player:getID() == playerID then
            delete(player)
            table.remove(self.mPlayers, i)
            return
        end
    end
end
-----------------------------------------------------------------------------------------Client_GameMonsterManager-----------------------------------------------------------------------------------
function Client_GameMonsterManager:construction()
    self.mMonsters = {}

    Client.addListener("GameMonsterManager", self)
end

function Client_GameMonsterManager:destruction()
    self:reset()
    Client.removeListener("GameMonsterManager", self)
end

function Client_GameMonsterManager:update(deltaTime)
    for _, monster in pairs(self.mMonsters) do
        monster:update()
    end
end

function Client_GameMonsterManager:reset()
    for _, monster in pairs(self.mMonsters) do
        delete(monster)
    end
    self.mMonsters = {}
end

function Client_GameMonsterManager:sendToHost(message, parameter)
    Client.sendToHost("GameMonsterManager", {mMessage = message, mParameter = parameter})
end

function Client_GameMonsterManager:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
    else
        if parameter.mMessage == "CreateMonster" then
            self:_createMonster(parameter.mParameter.mEntityID)
        elseif parameter.mMessage == "Reset" then
            self:reset()
        end
    end
end

function Client_GameMonsterManager:onHit(weapon, result)
    if result.entity then
        for _, monster in pairs(self.mMonsters) do
            if result.entity.entityId == monster:getID() then
                monster:onHit(weapon)
                break
            end
        end
    end
end

function Client_GameMonsterManager:_createMonster(entityID)
    local ret = new(Client_GameMonster, {mEntityID = entityID})
    self.mMonsters[#self.mMonsters + 1] = ret
    return ret
end

function Client_GameMonsterManager:_destroyMonster(entityID)
    for i, monster in pairs(self.mMonsters) do
        if monster:getID() == entityID then
            delete(monster)
            table.remove(self.mMonsters, i)
            break
        end
    end
end
-----------------------------------------------------------------------------------------Client_GamePlayer-----------------------------------------------------------------------------------
function Client_GamePlayer:construction(parameter)
    self.mPlayerID = parameter.mPlayerID
    self.mProperty = new(GamePlayerProperty, {mPlayerID = self.mPlayerID})
    if self.mPlayerID == GetPlayerId() then
        local saved_data = getSavedData()
        saved_data.mHPLevel = saved_data.mHPLevel or 1
        saved_data.mAttackValueLevel = saved_data.mAttackValueLevel or 1
        saved_data.mAttackTimeLevel = saved_data.mAttackTimeLevel or 1
        saved_data.mMoney = saved_data.mMoney or 0
        self.mProperty:safeWrite("mHPLevel", saved_data.mHPLevel)
        self.mProperty:safeWrite("mAttackValueLevel", saved_data.mAttackValueLevel)
        self.mProperty:safeWrite("mAttackTimeLevel", saved_data.mAttackTimeLevel)

        self:_equpGun()
        -- 显示枪里子弹数量
        GUI.UI(
            {
                type = "Text",
                align = "_ctb",
                y = -100,
                text = function()
                    if WeaponSystem.get(1) then
                        return WeaponSystem.get(1):getAmmoCount()
                    else
                        return ""
                    end
                end,
                font_size = 50,
                font_color = "255 255 255"
            }
        )
        -- 显示提示
        Tip("按R键重装子弹")
        initUi()
    end
    self.mProperty:safeRead("mConfigIndex")
    self.mProperty:addPropertyListener(
        "mHPLevel",
        self,
        function()
        end
    )
    self.mProperty:addPropertyListener(
        "mAttackValueLevel",
        self,
        function()
        end
    )
    self.mProperty:addPropertyListener(
        "mAttackTimeLevel",
        self,
        function()
            if WeaponSystem.get(1) then
                WeaponSystem.get(1):setProperty(
                    "atk_speed",
                    GameCompute.computePlayerAttackTime(self.mProperty:cache().mAttackTimeLevel) * 1000
                )
            end
        end
    )
        self.mProperty:addPropertyListener(
            "mHP",
            self,
            function(_, value)
                if value then
                    self:_updateBloodUI()
                end
            end
        )

    Client.addListener(self:_getSendKey(), self)
end

function Client_GamePlayer:destruction()
    self.mProperty:removePropertyListener("mHPLevel", self)
    self.mProperty:removePropertyListener("mAttackValueLevel", self)
    self.mProperty:removePropertyListener("mAttackTimeLevel", self)
    self.mProperty:removePropertyListener("mHP", self)
    delete(self.mProperty)
    if self.mBloodUI then
        self.mBloodUI:destroy()
    end
    Client.removeListener(self:_getSendKey(), self)
end

function Client_GamePlayer:update()
    if self.mPlayerID == GetPlayerId() then
        local saved_data = getSavedData()
        if self.mProperty:cache().mHPLevel then
            if saved_data.mHPLevel ~= self.mProperty:cache().mHPLevel then
                self.mProperty:safeWrite("mHPLevel", saved_data.mHPLevel)
                self:_updateBloodUI()
            end
        end
        if self.mProperty:cache().mAttackValueLevel then
            if saved_data.mAttackValueLevel ~= self.mProperty:cache().mAttackValueLevel then
                self.mProperty:safeWrite("mAttackValueLevel", saved_data.mAttackValueLevel)
            end
        end
        if self.mProperty:cache().mAttackTimeLevel then
            if saved_data.mAttackTimeLevel ~= self.mProperty:cache().mAttackTimeLevel then
                self.mProperty:safeWrite("mAttackTimeLevel", saved_data.mAttackTimeLevel)
            end
        end
        if WeaponSystem.get(1) and WeaponSystem.get(1):getAmmoCount() == 0 then
            Tip("按R键重装子弹")
        end
    end
end

function Client_GamePlayer:receive(parameter)
    local is_responese, _ = string.find(parameter.mMessage, "_Response")
    if is_responese then
    else
        if parameter.mMessage == "Dead" then
            Die()
            SetItemStackToInventory(1, {})
            SetItemStackToInventory(2, {})
        elseif parameter.mMessage == "Revive" then
            Revive()
            self:_equpGun()
        elseif parameter.mMessage == "AddMoney" then
            local saved_data = getSavedData()
            saved_data.mMoney = saved_data.mMoney + parameter.mParameter.mMoney
        elseif parameter.mMessage == "EnterSafeHouse" then
            SetCameraMode(2)
            openSafeHouseUI()
        elseif parameter.mMessage == "LeaveSafeHouse" then
            SetCameraMode(3)
            closeSafeHouseUI()
        end
    end
end

function Client_GamePlayer:sendToHost(message, parameter)
    Client.sendToHost(self:_getSendKey(), {mMessage = message, mParameter = parameter})
end

function Client_GamePlayer:onHit(weapon, result)
    if self.mPlayerID==GetPlayerId() then
        local x,y,z = GetPlayer():GetBlockPos()
        GetResourceModel({hash="FrwJ2e5GdVX8aMghRov5waetE7WV",pid="278",ext="bmax",},function(path,err)
            local host_key = EntityCustomManager.singleton():createEntity(x,y + 1,z,path)
            local entity = EntityCustomManager.singleton():getEntity(host_key)
            CommandQueue.default():post(new(Command_Callback,{mDebug = "Client_GamePlayer:onHit",mExecutingCallback = function(command)
                if result.entity then
                    local dir = (result.entity:getPosition() - entity.mEntity:getPosition()):normalize()
                    local pos = entity.mEntity:getPosition() + dir
                    entity:setPositionReal(pos[1],pos[2],pos[3])
                elseif result.blockX and result.blockY and result.blockZ then
                    local x,y,z = entity.mEntity:GetBlockPos()
                    local dir = vector3d:new(result.blockX - x,result.blockY - y + 1,result.blockZ - z):normalize()
                    local pos = entity.mEntity:getPosition() + dir
                    entity:setPositionReal(pos[1],pos[2],pos[3])
                end
                command.mTimer = command.mTimer or new(Timer)
                if command.mTimer:total() > 1 then
                    delete(command.mTimer)
                    EntityCustomManager.singleton():destroyEntity(host_key)
                    command.mState = Command.EState.Finish
                end
            end}))
        end)
    end
end

function Client_GamePlayer:getID()
    return self.mPlayerID
end

function Client_GamePlayer:getProperty()
    return self.mProperty
end

function Client_GamePlayer:getEntity()
    return GetEntityById(self.mPlayerID)
end

function Client_GamePlayer:_getSendKey()
    return "GamePlayer/" .. tostring(self.mPlayerID)
end

function Client_GamePlayer:_updateBloodUI()
    if not self.mBloodUI and GetEntityHeadOnObject(self.mPlayerID, "Blood/" .. tostring(self.mPlayerID)) then
        self.mBloodUI =
            GetEntityHeadOnObject(self.mPlayerID, "Blood/" .. tostring(self.mPlayerID)):createChild(
            {
                ui_name = "background",
                type = "container",
                color = "255 0 0",
                align = "_ct",
                y = -150,
                x = -150,
                height = 20,
                width = 200,
                visible = true
            }
        )
    end
    if self.mProperty:cache().mHP and self.mProperty:cache().mHPLevel then
        self.mBloodUI.width =
            200 * self.mProperty:cache().mHP / GameCompute.computePlayerHP(self.mProperty:cache().mHPLevel)
    end
end

function Client_GamePlayer:_equpGun()
            -- 创建子弹
            local bullets = CreateItemStack(50101, 999)
            -- 创建枪
            local gun = CreateItemStack(40300, 1)
            -- 把枪和子弹放在人身上
            SetItemStackToInventory(1, gun)
            SetItemStackToInventory(2, bullets)

            -- 设置枪里起始的子弹
            WeaponSystem.get(1):setAmmoCount(30)
            WeaponSystem.get(1):setProperty(
                "atk_speed",
                GameCompute.computePlayerAttackTime(self.mProperty:cache().mAttackTimeLevel) * 1000
            )
end
-----------------------------------------------------------------------------------------Client_GameMonster-----------------------------------------------------------------------------------
function Client_GameMonster:construction(parameter)
    self.mCommandQueue = new(CommandQueue)
    self.mEntityID = parameter.mEntityID
    self.mProperty = new(GameMonsterProperty, {mEntityID = self.mEntityID})

    self.mProperty:addPropertyListener(
        "mLevel",
        self,
        function()
        end
    )
    self.mProperty:addPropertyListener(
        "mHP",
        self,
        function(_, value)
            self:_updateBloodUI()
        end
    )
    self.mProperty:addPropertyListener(
        "mConfigIndex",
        self,
        function(_,value)
            self:_updateBloodUI()
        end
    )
    Client.addListener(self:_getSendKey(), self)
end

function Client_GameMonster:destruction()
    self.mProperty:removePropertyListener("mLevel", self)
    self.mProperty:removePropertyListener("mHP", self)
    self.mProperty:removePropertyListener("mConfigIndex", self)
    if self.mBloodUI then
        self.mBloodUI:destroy()
    end
    delete(self.mProperty)
    Client.removeListener(self:_getSendKey(), self)
end

function Client_GameMonster:update()
    self.mCommandQueue:update()
end

function Client_GameMonster:sendToHost(message, parameter)
    Client.sendToHost(self:_getSendKey(), {mMessage = message, mParameter = parameter})
end

function Client_GameMonster:receive(parameter)
end

function Client_GameMonster:getID()
    return self.mEntityID
end

function Client_GameMonster:getConfig()
    if self.mProperty:cache().mConfigIndex then
        return GameConfig.mMonsterLibrary[self.mProperty:cache().mConfigIndex]
    end
end

function Client_GameMonster:onHit(weapon)
    local property_change = {}
    property_change.mHPSubtract =
        GameCompute.computePlayerAttackValue(
        Client_Game.singleton():getPlayerManager():getPlayerByID(GetPlayerId()):getProperty():cache().mAttackValueLevel
    )
    self:sendToHost("PropertyChange", property_change)
end

function Client_GameMonster:_getSendKey()
    return "GameMonster/" .. tostring(self.mEntityID)
end

function Client_GameMonster:_updateBloodUI()
    if GetEntityById(self.mEntityID) and GetEntityById(self.mEntityID):GetInnerObject() and 
            GetEntityHeadOnObject(self.mEntityID, "Blood/" .. tostring(self.mEntityID))
     then
        if not self.mBloodUI then
            self.mBloodUI =
                GetEntityHeadOnObject(self.mEntityID, "Blood/" .. tostring(self.mEntityID)):createChild(
                {
                    ui_name = "background",
                    type = "container",
                    color = "255 0 0",
                    align = "_ct",
                    y = -100,
                    x = -130,
                    height = 20,
                    width = 200,
                    visible = true
                }
            )
        end
        if not self.mNameUI then
            self.mNameUI =
                GetEntityHeadOnObject(self.mEntityID, "Name/" .. tostring(self.mEntityID)):createChild(
                {
                    ui_name = "background",
                    type = "text",
                    font_type = "微软雅黑",
                    font_color = "0 255 0",
                    font_size = 25,
                    align = "_ct",
                    y = -150,
                    x = -130,
                    height = 50,
                    width = 200,
                    visible = true
                }
            )
        end
    end
    if self.mBloodUI and self.mNameUI  then
        if self.mProperty:cache().mHP and self.mProperty:cache().mLevel then
            self.mBloodUI.width =
                200 * self.mProperty:cache().mHP / GameCompute.computeMonsterHP(self.mProperty:cache().mLevel)
        end
        if self:getConfig() and self.mProperty:cache().mLevel then
            self.mNameUI.text = "Lv"..tostring(self.mProperty:cache().mLevel).." "..self:getConfig().mName
        end
    else
        self.mCommandQueue:post(
            new(
                Command_Callback,
                {
                    mDebug = "Client_GameMonster:_updateBloodUI",
                    mExecuteCallback = function(command)
                        self:_updateBloodUI()
                        command.mState = Command.EState.Finish
                    end
                }
            )
        )
    end
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 入口
function main()
    Revive()
    GlobalProperty.initialize()
    PlayerManager.initialize()
    EntityCustomManager.singleton()
    SendTo("host", {mMessage = "CheckHost"})
end

function clear()
    Revive()
    SetCameraMode(2)
    SetItemStackToInventory(1, {})
    SetItemStackToInventory(2, {})

    if Client_Game.msInstance then
        delete(Client_Game.singleton())
    end
    if Host_Game.singleton() then
        delete(Host_Game.singleton())
        Host.broadcast({mMessage = "Clear"})
    end
    PlayerManager.clear()
    delete(CommandQueue.default())
end

-- 获取输入
function handleInput(event)
    InputManager.notify(event)
    return WeaponSystem.input(event)
end

WeaponSystem.onHit(
    function(weapon, result)
        Client_Game.singleton():onHit(weapon, result)
        -- 创建子弹击中方块效果
        if result.block_id then
            CreateBlockPieces(result.block_id, result.blockX, result.blockY, result.blockZ)
        elseif result.entity then
            CreateBlockPieces(2051, result.blockX, result.blockY, result.blockZ)
        end
    end
)

function receiveMsg(parameter)
    Client_Game.singleton()
    if parameter.mMessage == "CheckHost" then
        if not Host_Game.singleton() then
            new(Host_Game)
        end
    elseif parameter.mMessage == "Clear" then
        clear()
    end
    if parameter.mKey ~= "GlobalProperty" then
        echo("devilwalk", "receiveMsg:parameter:")
        echo("devilwalk", parameter)
    end
    if parameter.mTo then
        if parameter.mTo == "Host" then
            Host.receive(parameter)
        elseif parameter.mTo == "All" then
            parameter.mTo = nil
            parameter.mFrom = parameter._from
            Host.broadcast(parameter)
        else
            local to = parameter.mTo
            parameter.mTo = nil
            parameter.mFrom = parameter._from
            Host.sendTo(to, parameter)
        end
    else
        Client.receive(parameter)
    end
end

function update()
    GlobalProperty.update()
    CommandQueue.default():update()
    local delta_time = Timer.global():delta()
    PlayerManager.update()
    if Host_Game.singleton() then
        Host_Game.singleton():update(delta_time)
    end
    Client_Game.singleton():update(delta_time)
end
