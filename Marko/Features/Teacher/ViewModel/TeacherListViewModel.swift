//  TeacherListViewModel.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

class TeacherListViewModel {
    private let repository = TeacherRepository()
    private(set) var teachers: [Teacher] = []

    // Closure to navigate when a teacher is selected
    var didSelectTeacher: ((Teacher) -> Void)?
    // Closure to notify ViewController when teacher data is loaded/updated
    var onTeachersLoaded: (() -> Void)?

    init() {
        print("TeacherListViewModel initialized")
        loadTeachers() // Load teachers on initialization
    }

    func loadTeachers() {
        print("TeacherListViewModel: Loading teachers...")
        repository.fetchTeachers { [weak self] fetchedTeachers in
            guard let self = self else { return }
            print("TeacherListViewModel: Received \(fetchedTeachers.count) teachers from repository.")
            // Sort teachers, e.g., alphabetically by name
            self.teachers = fetchedTeachers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            print("TeacherListViewModel: Processed and stored \(self.teachers.count) sorted teachers.")
            // Notify the ViewController on the main thread
            DispatchQueue.main.async {
                 self.onTeachersLoaded?()
            }
        }
    }
}
