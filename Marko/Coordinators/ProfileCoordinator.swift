//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class ProfileCoordinator: Coordinator {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let user = User(
            name: "Alice",
            photo: UIImage(named: "profile") ?? UIImage(),
            englishLevel: "B1",
            nextTeacherSession: "Next session on 02/01/2025"
        )
        let viewModel = ProfileViewModel(user: user)
        let profileVC = ProfileViewController(viewModel: viewModel)
        navigationController.pushViewController(profileVC, animated: false)
    }
}
