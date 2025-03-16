//
//  TeacherListViewModel.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

class TeacherListViewModel {
    private let repository = TeacherRepository()
    private(set) var teachers: [Teacher] = []
    
    // Closure to signal selection
    var didSelectTeacher: ((Teacher) -> Void)?
    var onTeachersLoaded: (() -> Void)?
    
    init() {
        print("TeacherListViewModel initialized")
        loadTeachers()
    }
    
    func loadTeachers() {
        print("Loading teachers...")
        repository.fetchTeachers { [weak self] teachers in
            print("Teachers loaded: \(teachers.count)")
            self?.teachers = teachers
            self?.onTeachersLoaded?()
        }
    }
}
