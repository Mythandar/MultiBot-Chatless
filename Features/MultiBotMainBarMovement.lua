if not MultiBot then return end

-- WoW 3.3.5a compatibility: right-button drag events are unreliable when the
-- same button is also registered for RightButtonDown clicks. Move the main bar
-- directly from mouse down/up instead of depending on OnDragStart/OnDragStop.
local function installMainBarMovement()
    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local mainButton = multiBar and multiBar.buttons and multiBar.buttons["Main"]
    if not multiBar or not mainButton then
        return
    end

    mainButton:SetScript("OnDragStart", nil)
    mainButton:SetScript("OnDragStop", nil)

    mainButton:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton ~= "RightButton" then
            return
        end

        if self.__mbMoveLocked and not IsControlKeyDown() then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(MultiBot.L("mainbar.swap.locked"), 1, 0.25, 0.25, 1)
            end
            return
        end

        if MultiBot.MainBarAutoHide_NotifyInteraction then
            MultiBot.MainBarAutoHide_NotifyInteraction()
        end

        self.__mbMovingMainBar = true
        multiBar:StartMoving()
    end)

    mainButton:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton ~= "RightButton" or not self.__mbMovingMainBar then
            return
        end

        self.__mbMovingMainBar = nil
        multiBar:StopMovingOrSizing()

        if MultiBot.toPoint then
            local offsetX, offsetY = MultiBot.toPoint(multiBar)
            multiBar.x = offsetX
            multiBar.y = offsetY

            if MultiBot.SetSavedLayoutValue then
                MultiBot.SetSavedLayoutValue("MultiBarPoint", offsetX .. ", " .. offsetY)
            end
        end

        if MultiBot.RefreshMainBarAutoHideState then
            MultiBot.RefreshMainBarAutoHideState()
        end
        if MultiBot.MainBarAutoHide_NotifyInteraction then
            MultiBot.MainBarAutoHide_NotifyInteraction()
        end
    end)
end

installMainBarMovement()
