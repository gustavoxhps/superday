import Foundation

class IntroViewModel
{
    let isFirstUse : Bool
    
    init(settingsService : SettingsService)
    {
        self.isFirstUse = settingsService.installDate == nil
    }
}
