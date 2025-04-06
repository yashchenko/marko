//
//  TeacherCoordinator.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

class TeacherCoordinator: Coordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        print("TeacherCoordinator started")
        let viewModel = TeacherListViewModel()

        // Hook up the didSelectTeacher closure:
        viewModel.didSelectTeacher = { [weak self] teacher in
            print("Teacher selected: \(teacher.name)")
            // Use weak self to avoid retain cycles
            self?.showTeacherDetail(for: teacher)
        }

        let teacherListVC = TeacherListViewController(viewModel: viewModel)
        // Set this as the root view controller for this tab's navigation stack
        navigationController.setViewControllers([teacherListVC], animated: false)
    }

    private func showTeacherDetail(for teacher: Teacher) {
        let detailViewModel = TeacherDetailViewModel(teacher: teacher)
        let detailVC = TeacherDetailViewController(viewModel: detailViewModel)
        // Push the detail view controller onto the existing navigation stack
        navigationController.pushViewController(detailVC, animated: true)
    }
}
