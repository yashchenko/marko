//
//  Coordinator.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

protocol Coordinator {
    var navigationController: UINavigationController { get set }
    func start()
}
