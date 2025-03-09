//
//  TeacherListViewModel.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

class TeacherListViewModel {
    // This might be loaded from Firebase.
    
    let teachers: [Teacher]
    
    // closure to signal detextion
    
    var didSelectTeacher: ( (Teacher) -> Void )?
    
    
    init(teachers: [Teacher]) {
        self.teachers = teachers
    }
    
    
    static func sampleData() -> [Teacher] {
        return [
            Teacher(
                name: "John Smith",
                subject: "Business English",
                description: "Specializes in corporate communication and business vocabulary for professionals.",
                rank: "Senior",
                id: "t01",
                profileImage: UIImage(named: "Teacher01") ?? UIImage()
            ),
            Teacher(
                name: "Jane Doe",
                subject: "General Conversation",
                description: "Focuses on everyday conversation skills and natural fluency.",
                rank: "Advanced",
                id: "t02",
                profileImage: UIImage(named: "Teacher02") ?? UIImage()
            ),
            Teacher(
                name: "Mary Johnson",
                subject: "Test Prep",
                description: "Expert in TOEFL, IELTS, and other standardized English proficiency tests.",
                rank: "Senior",
                id: "t03",
                profileImage: UIImage(named: "Teacher03") ?? UIImage()
            ),
            Teacher(
                name: "Robert Chen",
                subject: "Academic Writing",
                description: "Helps students master essay writing and academic paper structure.",
                rank: "Expert",
                id: "t04",
                profileImage: UIImage(named: "Teacher04") ?? UIImage()
            ),
            Teacher(
                name: "Sarah Williams",
                subject: "Pronunciation",
                description: "Specializes in accent reduction and natural-sounding speech patterns.",
                rank: "Advanced",
                id: "t05",
                profileImage: UIImage(named: "Teacher05") ?? UIImage()
            ),
            Teacher(
                name: "David Kim",
                subject: "Technical English",
                description: "Focuses on vocabulary and communication for engineering and IT professionals.",
                rank: "Senior",
                id: "t06",
                profileImage: UIImage(named: "Teacher06") ?? UIImage()
            ),
            Teacher(
                name: "Emma Garcia",
                subject: "Literature & Culture",
                description: "Explores English through classic literature and cultural context.",
                rank: "Expert",
                id: "t07",
                profileImage: UIImage(named: "Teacher07") ?? UIImage()
            )
        ]
    }
}

//
//class TeacherListViewModel {
//    // In a real app, this might be loaded from Firebase.
//    let teachers: [Teacher]
//
//    // Closure to signal selection
//    var didSelectTeacher: ((Teacher) -> Void)?
//
//    init(teachers: [Teacher]) {
//        self.teachers = teachers
//    }
//
//    static func sampleData() -> [Teacher] {
//        return [
//            Teacher(name: "John Smith", subject: "Business English", profileImage: UIImage(named: "Teacher01") ?? UIImage()),
//            Teacher(name: "Jane Doe", subject: "General Conversation", profileImage: UIImage(named: "Teacher02") ?? UIImage()),
//            Teacher(name: "Mary Johnson", subject: "Test Prep", profileImage: UIImage(named: "Teacher03") ?? UIImage())
//        ]
//    }
//}
