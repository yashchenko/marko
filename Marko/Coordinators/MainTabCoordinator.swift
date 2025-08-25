//
//  MainTabCoordinator.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

class MainCoordinator: Coordinator {
    var navigationController: UINavigationController
    var window: UIWindow?
    
    // child coordinators for each tabs
    
    var teacherCoordinator: TeacherCoordinator?
    var wordsMemoCoordinator: WordsMemoCoordinator?
    var profileCoordinator: ProfileCoordinator?
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    func start() {
        // AC #2 & #3: Create an instance of our new MainViewController
        let mainVC = MainViewController()

        // Instead of a UITabBarController, our window's root is now the MainViewController.
        // The navigationController of the coordinator will be used for pushing detail views later.
        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()
        
        // We will re-integrate the child coordinators later.
        // For now, this meets the acceptance criteria.
    }
}
