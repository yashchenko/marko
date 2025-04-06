//
//  ProfileCoordinator.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import Firebase if using Auth here

class ProfileCoordinator: Coordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        // Ideally, fetch the real user data based on logged-in user
        // For now, using placeholder
        let user = User(
            name: Auth.auth().currentUser?.displayName ?? "User", // Example: Use Firebase display name
            photo: UIImage(named: "profile") ?? UIImage(systemName: "person.circle.fill")!, // Use system default
            englishLevel: "B1", // Replace with actual level later
            nextTeacherSession: nil // This will be loaded dynamically by the ViewModel
        )

        let viewModel = ProfileViewModel(user: user)
        let profileVC = ProfileViewController(viewModel: viewModel)
        // Set this as the root view controller for this tab's navigation stack
        navigationController.setViewControllers([profileVC], animated: false)
    }
}
