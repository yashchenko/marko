//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class ProfileViewModel {
    var user: User
    
    init(user: User) {
        self.user = user
    }
    
    func upgradePrompt() -> String? {
        // For example, if the user is at B1, suggest an upgrade.
        if user.englishLevel == "B1" {
            return "Upgrade to B2 by purchasing 30 additional lessons!"
        }
        return nil
    }
}
