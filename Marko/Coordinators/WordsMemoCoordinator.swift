//
//  WordsMemoCoordinator.swift
//  Marko
//
//  Created by Ivan on 25.02.2025.
//

import UIKit

class WordsMemoCoordinator: Coordinator {
    var navigationController: UINavigationController

    // Correctly assign the navigation controller passed from MainCoordinator
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        print("WordsMemoCoordinator start() needs proper implementation.")
        // TODO: Replace this with your actual starting ViewController for this tab
        let placeholderVC = UIViewController()
        placeholderVC.title = "Words" // Set title
        placeholderVC.view.backgroundColor = .systemOrange
        let label = UILabel()
        label.text = "Words Memo Tab"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        placeholderVC.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: placeholderVC.view.centerYAnchor)
        ])
        // Set placeholder as the root view controller for this tab's navigation stack
        navigationController.setViewControllers([placeholderVC], animated: false)
    }
}
