//
//  ProfileViewModel.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import if using Auth

class ProfileViewModel {
    var user: User
    // Use BookingRepository to get full booking details
    private let bookingRepository = BookingRepository()
    // Keep TeacherRepository to fetch teacher details if needed (could be optimized)
    private let teacherRepository = TeacherRepository()
    private(set) var bookedSessions: [Booking] = [] // Store full Booking objects
    private(set) var teachers: [String: Teacher] = [:] // Cache for teacher details

    // Callback when sessions and related data are loaded
    var onSessionsLoaded: (() -> Void)?

    init(user: User) {
        self.user = user
        // Load sessions when ViewModel is created
        loadBookedSessions()
    }

    func upgradePrompt() -> String? {
        if user.englishLevel == "B1" {
            return "Upgrade to B2 by purchasing 30 additional lessons!"
        }
        return nil
    }

    // Load all *upcoming* confirmed booked sessions for the current user
    func loadBookedSessions() {
        // Use Firebase Auth to get the real user ID
        guard let userId = Auth.auth().currentUser?.uid else {
             print("User not logged in, cannot load profile sessions.")
             self.bookedSessions = [] // Clear existing
             DispatchQueue.main.async { // Notify UI on main thread
                self.onSessionsLoaded?()
             }
             return
         }

        print("ProfileViewModel: Loading booked sessions for user \(userId)")
        bookingRepository.fetchUserBookings(for: userId) { [weak self] bookings in
            guard let self = self else { return }
            print("ProfileViewModel: Received \(bookings.count) bookings from repository.")

            // Filter for upcoming confirmed sessions and sort by start time
            let now = Date()
            self.bookedSessions = bookings
                .filter { $0.status == "confirmed" && $0.timeSlot.startTime > now }
                .sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
            print("ProfileViewModel: Filtered to \(self.bookedSessions.count) upcoming confirmed sessions.")

            // Load teacher details needed for these booked sessions
            self.loadTeacherDetails(for: self.bookedSessions)
        }
    }

    // Load teacher details for the booked sessions
    // Optimization: This currently fetches *all* teachers every time.
    // A better approach would be fetchTeachersByIds if the number of teachers is large.
    private func loadTeacherDetails(for bookings: [Booking]) {
        let requiredTeacherIds = Set(bookings.map { $0.teacherId })
        print("ProfileViewModel: Requiring teacher details for IDs: \(requiredTeacherIds)")

        guard !requiredTeacherIds.isEmpty else {
            print("ProfileViewModel: No teacher details required.")
            // No teachers needed, sessions are ready (though might lack teacher names)
            DispatchQueue.main.async { self.onSessionsLoaded?() }
            return
        }

        // Fetch all teachers (assuming repository handles caching or efficiency)
        teacherRepository.fetchTeachers { [weak self] allTeachers in
            guard let self = self else { return }
            print("ProfileViewModel: Received \(allTeachers.count) teachers from repository for detail lookup.")
            var updated = false
            for teacher in allTeachers {
                if requiredTeacherIds.contains(teacher.id) && self.teachers[teacher.id] == nil {
                    self.teachers[teacher.id] = teacher
                    updated = true
                    print("ProfileViewModel: Cached details for teacher \(teacher.name)")
                }
            }
             if updated { print("ProfileViewModel: Teacher cache updated.") }

            // Notify that sessions (and hopefully teacher details) are ready
            DispatchQueue.main.async { self.onSessionsLoaded?() }
        }
    }


    // Get the next booked session info
    func getNextSessionInfo() -> String? {
        // Use the already filtered and sorted bookedSessions
        guard let nextBooking = bookedSessions.first else {
            return nil // No upcoming sessions
        }

        // Try to get teacher name from cache
        let teacherName = teachers[nextBooking.teacherId]?.name ?? "Teacher" // Fallback name

        return "Next session with \(teacherName) on \(nextBooking.timeSlot.formattedTimeSlot())"
    }
}
