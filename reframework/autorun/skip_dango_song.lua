local modName = "Skip Dango Song"
local folderName = modName
local version = "Version: 1.2.0"
local author = "Made by Raff"
local credits = "Credits to DSC-173(DSC173 on Nexus) for the code for telling which skills have activated!"

local modUtils = require(folderName .. "/mod_utils")

modUtils.info(modName .. " " .. version .. " loaded!")

local settings = modUtils.getConfigHandler({
    skipDangoSong = true,
    skipEating = true,
    skipMotley = true
}, folderName)

local getCookDemoHandler = modUtils.getType(
                               "snow.gui.fsm.kitchen.GuiKitchenFsmManager"):get_method(
                               "get_KitchenCookDemoHandler");
local getEatDemoHandler = modUtils.getType(
                              "snow.gui.fsm.kitchen.GuiKitchenFsmManager"):get_method(
                              "get_KitchenEatDemoHandler");
local setCookDemoSkip = modUtils.getType(
                            "snow.gui.fsm.kitchen.GuiKitchenFsmManager"):get_method(
                            "set_IsCookDemoSkip");
local getBBQDemoHandler = modUtils.getType("snow.gui.GuiKitchen_BBQ"):get_field(
                              "_DemoHandler");
local reqFinish = modUtils.getType("snow.eventcut.EventcutHandler"):get_method(
                      "reqFinish");
local getPlaying = modUtils.getType("snow.eventcut.EventcutHandler"):get_method(
                       "get_Playing");
local getLoadState =
    modUtils.getType("snow.eventcut.EventcutHandler"):get_method("get_LoadState");

local function assertSafety(obj, objName)
    if obj:get_reference_count() == 1 then
        modUtils.info(objName .. " was disposed by the game, breaking")
        error("")
    end
end

local lastCookHandlerStopped;
local lastEatHandlerStopped;
local lastMotleyHandlerStopped;
local skippedCutsceneThisFrame;

local hpStaminaMessage = "<COL>Status Increased!</COL>" ..
                            "\n<COL RED>  Health                         50</COL>" ..
                            "\n<COL RED>  Stamina                      50</COL>"

local function printSkills()
    local chatManager = sdk.get_managed_singleton("snow.gui.ChatManager")
    local player = sdk.get_managed_singleton("snow.player.PlayerManager"):call("findMasterPlayer")
    local dataShortcut =
        sdk.create_instance("snow.data.DataShortcut", true):add_ref()

    local message = "<COL>Dango Skills activated!</COL>"
    local playerSkillData = player:get_field("_refPlayerSkillList")
    playerSkillData = playerSkillData:call("get_KitchenSkillData")
    for i, v in pairs(playerSkillData:get_elements()) do
        if v:get_field("_SkillId") ~= 0 then
            message = message .. "\n<COL RED>  " ..
                          dataShortcut:call(
                              "getName(snow.data.DataDef.PlKitchenSkillId)",
                              v:get_field("_SkillId")) .. "</COL>"
        end
    end

    chatManager:call("reqAddChatInfomation", hpStaminaMessage, 0)
    chatManager:call("reqAddChatInfomation", message, 2289944406)
end

re.on_frame(function()
    if not settings.data.skipDangoSong and not settings.data.skipEating then
        return
    end

    local kitchen = sdk.get_managed_singleton(
                        "snow.gui.fsm.kitchen.GuiKitchenFsmManager")

    if kitchen ~= nil then
        assertSafety(kitchen, "kitchen")
        local cookHandler = getCookDemoHandler:call(kitchen)
        assertSafety(kitchen, "kitchen")
        local eatHandler = getEatDemoHandler:call(kitchen)
        skippedCutsceneThisFrame = false

        if cookHandler ~= nil and settings.data.skipDangoSong then
            assertSafety(cookHandler, "cookHandler")
            local loadState = getLoadState:call(cookHandler)
            assertSafety(cookHandler, "cookHandler")
            local isPlaying = getPlaying:call(cookHandler)

            if loadState == 5 and isPlaying and cookHandler ~=
                lastCookHandlerStopped then
                modUtils.info("Requesting finish for cookHandler!")
                assertSafety(cookHandler, "cookHandler")
                lastCookHandlerStopped = cookHandler
                skippedCutsceneThisFrame = true
                reqFinish:call(cookHandler, 0)
            end
        end
        if eatHandler ~= nil and settings.data.skipEating then
            if skippedCutsceneThisFrame then
                modUtils.info(
                    "(eatHandler) Already skipped a cutscene on this frame. Waiting for the next one.")
                return
            end

            assertSafety(eatHandler, "eatHandler")
            local loadState = getLoadState:call(eatHandler)
            assertSafety(eatHandler, "eatHandler")
            local isPlaying = getPlaying:call(eatHandler)

            if loadState == 5 and isPlaying and eatHandler ~=
                lastEatHandlerStopped then
                modUtils.info("Requesting finish for eatHandler!")
                assertSafety(eatHandler, "eatHandler")
                lastEatHandlerStopped = eatHandler
                reqFinish:call(eatHandler, 0)
                printSkills()
            end
        end

        local guiManager = sdk.get_managed_singleton("snow.gui.GuiManager")
        local bbq = guiManager:call("get_refGuiKichen_BBQ");

        assertSafety(bbq, "bbq")
        local motleyHandler = getBBQDemoHandler:get_data(bbq)

        if motleyHandler ~= nil and settings.data.skipMotley then
            assertSafety(motleyHandler, "motleyHandler")
            local loadState = getLoadState:call(motleyHandler)
            assertSafety(motleyHandler, "motleyHandler")
            local isPlaying = getPlaying:call(motleyHandler)

            if loadState == 5 and isPlaying and motleyHandler ~=
                lastMotleyHandlerStopped then
                modUtils.info("Requesting finish for motleyHandler!")
                assertSafety(motleyHandler, "motleyHandler")
                lastMotleyHandlerStopped = motleyHandler;
                reqFinish:call(motleyHandler, 0)
            end
        end
    end
end)

re.on_draw_ui(function()
    if imgui.tree_node(modName) then
        local changedEnabled, userenabled =
            imgui.checkbox("Skip the song", settings.data.skipDangoSong)
        settings.handleChange(changedEnabled, userenabled, "skipDangoSong")

        local changedEating, userEating =
            imgui.checkbox("Skip eating", settings.data.skipEating)
        settings.handleChange(changedEating, userEating, "skipEating")

        local changedMotley, userMotley =
            imgui.checkbox("Skip Motley Mix", settings.data.skipMotley)
        settings.handleChange(changedMotley, userMotley, "skipMotley")

        if not settings.isSavingAvailable then
            imgui.text(
                "WARNING: JSON utils not available (your REFramework version may be outdated). Configuration will not be saved between restarts.")
        end

        imgui.text(version)
        imgui.text(author)
        imgui.text(credits)
        imgui.tree_pop()
    end
end)
