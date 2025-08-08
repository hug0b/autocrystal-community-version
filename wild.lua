Mem = require("/data/Memory")
memory.usememorydomain("System Bus")

local desired_species = -1
local atkdef
local spespc
local species
local item = 0
local shinyvalue = 0
local printedMessage = false
local enemy_addr
local daytime
local LoadBattleMenuAddr
local EnemyWildmonInitialized
initialX, initialY = memory.readbyte(0xdcb8), memory.readbyte(0xdcb7)
mapgroup, mapnumber = memory.readbyte(0xdcb5), memory.readbyte(0xdcb6)
local version = memory.readbyte(0x141)
local region = memory.readbyte(0x142)
local encounterCount
local framesInDirection = 0
local maxFramesInDirection = 1
local highestSpeSpc = 0
local highestAtkDef = 0
input = {}
actions = {"B", "Right", "Right", "Down", "A","A"}
currentActionIndex = 1
framesInAction = 0
framesPerAction = 1
input2 = {}
actions2 = {"Right", "Up", "Left", "Down"}
currentActionIndex2 = 1
framesInAction2 = 0
framesPerAction2 = 1

if version == 0x54 then
     console.log("Crystal detected")
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        enemy_addr = 0xd20c
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4EF2)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x7648)
        Mem.SetRomBankAddress("Crystal")
    elseif region == 0x45 then
        enemy_addr = 0xd20c
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4EF2)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x7648)
        Mem.SetRomBankAddress("Crystal")
    elseif region == 0x4A then
        enemy_addr = 0xd23d
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4EF2)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x7648)
        Mem.SetRomBankAddress("Crystal")
    end
elseif version == 0x55 or version == 0x58 then
    if region == 0x44 or region == 0x46 or region == 0x49 or region == 0x53 then
        print("EUR Gold/Silver detected")
        enemy_addr = 0xda22
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4E62)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x73c5)
        Mem.SetRomBankAddress("Gold")
    elseif region == 0x45 then
        print("USA Gold/Silver detected")
        enemy_addr = 0xda22
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4E62)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x73C5)
        Mem.SetRomBankAddress("Gold")
    elseif region == 0x4A then
        print("JPN Gold/Silver detected")
        enemy_addr = 0xd9e8
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4E62)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x73C5)
        Mem.SetRomBankAddress("Gold")
    elseif region == 0x4B then
        print("KOR Gold/Silver detected")
        enemy_addr = 0xdb1f
        LoadBattleMenuAddr = Mem.BankAddressToLinear(0x9, 0x4E62)
        EnemyWildmonInitialized = Mem.BankAddressToLinear(0xF, 0x73C5)
        Mem.SetRomBankAddress("Gold")
    end
else
    print("No valid ROM detected")
    return
end

local dv_flag_addr = enemy_addr + 0x21
local species_addr = enemy_addr + 0x22
local item_addr = enemy_addr - 0x05
local daytime_addr = 0xd269


function shiny(atkdef, spespc)
    if spespc == 0xAA then
        if atkdef == 0x2A or atkdef == 0x3A or atkdef == 0x6A or atkdef == 0x7A or atkdef == 0xAA or atkdef == 0xBA or atkdef == 0xEA or atkdef == 0xFA then
            shinyvalue = 1
            return true
        end
    end
    return false
end


function press_button(btn)
    input = {[btn]=true}
    for i=1,4 do -- Hold button for 4 frames (make sure the game registers it)
        joypad.set(input)
        emu.frameadvance()
    end
    emu.frameadvance() -- Add one frame buffer so consecutive button presses don't blend together
end

local have_battle_controls = false
Mem.RegisterROMHook(LoadBattleMenuAddr, function()
    console.log("Battle menu loaded")
    have_battle_controls = true
end, "Detect Battle Menu")

Mem.RegisterROMHook(EnemyWildmonInitialized, function()
    console.log("combat started")
    item = memory.readbyte(item_addr)
        atkdef = memory.readbyte(enemy_addr)
        spespc = memory.readbyte(enemy_addr + 1)
        highestAtkDef = math.max(highestAtkDef, atkdef)
        highestSpeSpc = math.max(highestSpeSpc, spespc)
        species = memory.readbyte(species_addr)

    console.log(string.format("Atk: %d Def: %d Spe: %d Spc: %d", math.floor(atkdef/16), atkdef%16, math.floor(spespc/16), spespc%16))
    
end, "Tell Display Battle Started / sending data")

while true do
    emu.frameadvance()

    if memory.readbyte(species_addr) == 0 then
        have_battle_controls = false

        for i=1,8,1 do
            emu.frameadvance()
            joypad.set({B=true})
        end


        local currentX, currentY = memory.readbyte(0xdcb8), memory.readbyte(0xdcb7)

        if currentX ~= initialX or currentY ~= initialY and memory.readbyte(species_addr) == 0 then
            -- Navigate back to initial position
            local deltaX = initialX - currentX
            local deltaY = initialY - currentY

            for _ = 1, math.abs(deltaX) do
                emu.frameadvance()
                joypad.set({Up = false, Right = (deltaX > 0), Down = false, Left = (deltaX < 0)})
                emu.frameadvance()
                if memory.readbyte(species_addr) ~= 0 then
                    emu.frameadvance()
                    break
                end
            end

            for _ = 1, math.abs(deltaY) do
                emu.frameadvance()
                joypad.set({Up = (deltaY < 0), Right = false, Down = (deltaY > 0), Left = false})
                emu.frameadvance()
                if memory.readbyte(species_addr) ~= 0 then
                    emu.frameadvance()
                    break
                end
            end
        else
            joypad.set({Right=true})
            emu.frameadvance()
            joypad.set({Right=false})
            joypad.set({Left=true})
            emu.frameadvance()
            joypad.set({Left=false})
            joypad.set({Down=true})
            emu.frameadvance()
            joypad.set({Down=false})
            joypad.set({Up=true})
            emu.frameadvance()
            joypad.set({Up=false})

        end

    else
        -- Fallback: wait until the enemy DV bytes appear to be initialized
        -- (works regardless of exact ROM routine addresses)
        local dv_ready = 0
        local dv_timeout = 0
        repeat
            press_button("B")               -- clear any intro text
            emu.frameadvance()
            atkdef  = memory.readbyte(enemy_addr)
            spespc  = memory.readbyte(enemy_addr + 1)
            if (atkdef ~= 0 or spespc ~= 0) then
                dv_ready = dv_ready + 1     -- see nonzero values two frames in a row
            else
                dv_ready = 0
            end
            dv_timeout = dv_timeout + 1
        until dv_ready >= 2 or dv_timeout > 180

        -- If our ROM hook fired, great; if not, proceed after the settle
        have_battle_controls = have_battle_controls or true



        item = memory.readbyte(item_addr)
        atkdef = memory.readbyte(enemy_addr)
        spespc = memory.readbyte(enemy_addr + 1)
        highestAtkDef = math.max(highestAtkDef, atkdef)
        highestSpeSpc = math.max(highestSpeSpc, spespc)
        species = memory.readbyte(species_addr)

        
        if shiny(atkdef, spespc) then
            shinyvalue = 1
            console.log("Shiny found!!")
            break
        end

     
    end


    if memory.readbyte(species_addr) ~= 0 then
        -- If the ROM hook didn't fire, fall back after ~2 seconds
        if not have_battle_controls then
            press_button("B")
            emu.frameadvance()
            menu_wait = (menu_wait or 0) + 1
            if menu_wait >= 120 then
                have_battle_controls = true
                console.log("Fallback: proceeding without battle-menu hook")
            end
        end

        if have_battle_controls then
            -- reset the fallback counter for the next battle
            menu_wait = 0

        local currentAction = actions[currentActionIndex]
        press_button(currentAction)

        framesInAction = framesInAction + 1
            if framesInAction >= framesPerAction then
                framesInAction = 0
                currentActionIndex = (currentActionIndex % #actions) + 1
                emu.frameadvance()
            end
        end
    end
end
