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
            self?.showTeacherDetail(for: teacher)
        }
        
        let teacherListVC = TeacherListViewController(viewModel: viewModel)
        navigationController.pushViewController(teacherListVC, animated: false)
    }
    
    private func showTeacherDetail(for teacher: Teacher) {
        let detailViewModel = TeacherDetailViewModel(teacher: teacher)
        let detailVC = TeacherDetailViewController(viewModel: detailViewModel)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
