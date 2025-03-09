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
        let tabBarController = UITabBarController()
        
        // Set up teacher tab with its own navigation controller & coordinator
        
        let teacherNav = UINavigationController()
        teacherCoordinator = TeacherCoordinator(navigationController: teacherNav)
        teacherCoordinator?.start()
        teacherNav.tabBarItem = UITabBarItem(title: "Teachers", image: UIImage(systemName: "person.crop.square"), tag: 0)
        
        let wordsMemoNav = UINavigationController()
        wordsMemoCoordinator = WordsMemoCoordinator(navigationController: wordsMemoNav)
        wordsMemoCoordinator?.start()
        wordsMemoNav.tabBarItem = UITabBarItem(title: "Words", image: UIImage(systemName: "wonsign.square"), tag: 1)
        
        let profileNav = UINavigationController()
        profileCoordinator = ProfileCoordinator(navigationController: profileNav)
        profileCoordinator?.start()
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "bag"), tag: 2)
        
        tabBarController.viewControllers = [teacherNav, wordsMemoNav, profileNav]
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
