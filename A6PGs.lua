local shared = odh_shared_plugins

if shared and shared.game_name == "Murder Mystery 2" then
    if shared.Notify then
        shared.Notify("Final Update - Removed All Features", 3)
    end

    if shared.AddSection then
        local creditsSection = shared.AddSection("Credits")
        if creditsSection and creditsSection.AddParagraph then
            creditsSection:AddParagraph("@lzzzx", "Made this plugin, if you have requests feel free to ask.")
        end
    end
end
