//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class ProfileViewModel {
    var user: User
    private let timeSlotRepository = TimeSlotRepository()
    private(set) var bookedSessions: [TimeSlot] = []
    private(set) var teachers: [String: Teacher] = [:]
    
    // Callback when sessions are loaded
    var onSessionsLoaded: (() -> Void)?
    
    init(user: User) {
        self.user = user
        loadBookedSessions()
    }
    
    func upgradePrompt() -> String? {
        // For example, if the user is at B1, suggest an upgrade.
        if user.englishLevel == "B1" {
            return "Upgrade to B2 by purchasing 30 additional lessons!"
        }
        return nil
    }
    
    // Load all booked sessions for the current user
    func loadBookedSessions() {
        // In a real app, you would use the authenticated user's ID
        let userId = "current_user_id"
        
        timeSlotRepository.fetchUserBookings(for: userId) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Sort by start time
            self.bookedSessions = timeSlots.sorted { $0.startTime < $1.startTime }
            
            // Load teacher details for each session
            self.loadTeacherDetails(for: self.bookedSessions)
        }
    }
    
    // Load teacher details for the booked sessions
    private func loadTeacherDetails(for sessions: [TimeSlot]) {
        let teacherIds = Set(sessions.map { $0.teacherId })
        let teacherRepository = TeacherRepository()
        
        // Load all teachers
        teacherRepository.fetchTeachers { [weak self] allTeachers in
            guard let self = self else { return }
            
            // Filter and create a dictionary with teacher ID as key
            for teacher in allTeachers {
                if teacherIds.contains(teacher.id) {
                    self.teachers[teacher.id] = teacher
                }
            }
            
            // Notify that sessions are ready to display
            self.onSessionsLoaded?()
        }
    }
    
    // Get the next booked session info
    func getNextSessionInfo() -> String? {
        // Find the next upcoming session
        let now = Date()
        guard let nextSession = bookedSessions.first(where: { $0.startTime > now }),
              let teacher = teachers[nextSession.teacherId] else {
            return nil
        }
        
        return "Next session with \(teacher.name) on \(nextSession.formattedTimeSlot())"
    }
}
