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
        let viewModel = TeacherListViewModel(teachers: TeacherListViewModel.sampleData())
        
        // 1) Hook up the didSelectTeacher closure:
        viewModel.didSelectTeacher = { [weak self] teacher in
            self?.showTeacherDetail(for: teacher)
        }
        
        let teacherListVC = TeacherListViewController(viewModel: viewModel)
        navigationController.pushViewController(teacherListVC, animated: false)
    }
    
    // 2) Implement the showTeacherDetail method:
    private func showTeacherDetail(for teacher: Teacher) {
        // Usually you'd have a TeacherDetailViewModel, e.g.:
        let detailViewModel = TeacherDetailViewModel(teacher: teacher)
        let detailVC = TeacherDetailViewController(viewModel: detailViewModel)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
