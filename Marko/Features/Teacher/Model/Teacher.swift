//
//  Teacher.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

// later it ought to conform Codable

import UIKit

struct Teacher {
    let id: String
    let name: String
    let subject: String
    let description: String
    let rank: String
    let profileImageURL: String
    var profileImage: UIImage
    
    init(id: String, name: String, subject: String, description: String, rank: String, profileImageURL: String, profileImage: UIImage = UIImage()) {
        self.id = id
        self.name = name
        self.subject = subject
        self.description = description
        self.rank = rank
        self.profileImageURL = profileImageURL
        self.profileImage = profileImage
    }
}

//
//extension Teacher {
//    func getAvailableDates() -> [Date] {
//        // Get unique dates from availability (just the day, not time)
//        let calendar = Calendar.current
//        let uniqueDays = Set(availability.map {
//            calendar.startOfDay(for: $0.startTime)
//        })
//        return Array(uniqueDays)
//    }
//
//    func getTimeSlots(for date: Date) -> [TimeSlot] {
//        let calendar = Calendar.current
//        return availability.filter {
//            calendar.isDate($0.startTime, inSameDayAs: date) && !$0.isBooked
//        }
//    }
//}
