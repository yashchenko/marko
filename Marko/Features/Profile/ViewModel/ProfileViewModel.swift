//
//  ProfileViewModel.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import if using Auth

class ProfileViewModel {
    var user: User // Represents the app's user model (name, photo, level)
    private let bookingRepository = BookingRepository()
    private let teacherRepository = TeacherRepository()

    // **FIX:** Removed private(set) to allow modification from outside if needed,
    // or specifically by the clearUserSessionData method now inside the class.
    var bookedSessions: [Booking] = []
    var teachers: [String: Teacher] = [:]

    var onSessionsLoaded: (() -> Void)?

    init(user: User) {
        self.user = user
        // Initial load depends on auth state, which is checked in ProfileVC's viewWillAppear/updateUI
        // So, maybe don't load here directly, let the VC trigger it when user is confirmed logged in.
        // loadBookedSessions() // Removed initial load from here
    }

    func upgradePrompt() -> String? {
        if user.englishLevel == "B1" { // Example logic
            return "Upgrade to B2 by purchasing 30 additional lessons!"
        }
        return nil
    }

    // Load upcoming confirmed sessions for the *currently logged-in* Firebase user
    func loadBookedSessions() {
        guard let userId = Auth.auth().currentUser?.uid else {
             print("ProfileViewModel Error: Cannot load sessions, user not logged in.")
             // Ensure data is cleared if user logs out and this is called somehow
             clearUserSessionData() // Call clear method to reset state
             return
         }

        print("ProfileViewModel: Loading booked sessions for user \(userId)")
        bookingRepository.fetchUserBookings(for: userId) { [weak self] bookings in
            guard let self = self else { return }
            print("ProfileViewModel: Received \(bookings.count) bookings from repository.")

            let now = Date()
            self.bookedSessions = bookings
                .filter { $0.status == "confirmed" && $0.timeSlot.startTime > now }
                .sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
            print("ProfileViewModel: Filtered to \(self.bookedSessions.count) upcoming confirmed sessions.")

            self.loadTeacherDetails(for: self.bookedSessions) // Load associated teacher info
        }
    }

    // Load teacher details needed for the currently loaded bookings
    private func loadTeacherDetails(for bookings: [Booking]) {
        let requiredTeacherIds = Set(bookings.map { $0.teacherId })
        print("ProfileViewModel: Requiring teacher details for IDs: \(requiredTeacherIds)")
        guard !requiredTeacherIds.isEmpty else {
            print("ProfileViewModel: No teacher details required.")
            // If no details needed, still notify that loading (of sessions) is complete
            DispatchQueue.main.async { self.onSessionsLoaded?() }
            return
        }

        // Simple approach: Fetch all teachers and filter/cache
        // Improvement: Fetch only required IDs if TeacherRepository supports it
        teacherRepository.fetchTeachers { [weak self] allTeachers in
            guard let self = self else { return }
            print("ProfileViewModel: Received \(allTeachers.count) teachers for detail lookup.")
            var updatedCache = false
            for teacher in allTeachers {
                if requiredTeacherIds.contains(teacher.id) {
                    // Add or update teacher in cache
                    if self.teachers[teacher.id]?.name != teacher.name { // Example check if update needed
                        self.teachers[teacher.id] = teacher
                        updatedCache = true
                    } else if self.teachers[teacher.id] == nil {
                         self.teachers[teacher.id] = teacher
                         updatedCache = true
                    }
                }
            }
             if updatedCache { print("ProfileViewModel: Teacher cache updated.") }

            // Notify UI that data loading process is complete
            DispatchQueue.main.async { self.onSessionsLoaded?() }
        }
    }

    // Get display string for the next session
    func getNextSessionInfo() -> String? {
        guard let nextBooking = bookedSessions.first else { return nil }
        let teacherName = teachers[nextBooking.teacherId]?.name ?? "Teacher"
        return "Next session with \(teacherName) on \(nextBooking.timeSlot.formattedTimeSlot())"
    }

    // **FIX:** Moved this method inside the class definition
    // Method to clear user-specific data (e.g., on sign out)
    func clearUserSessionData() {
         print("ProfileViewModel: Clearing user session data.")
         self.bookedSessions = []
         self.teachers = [:] // Clear teacher cache too
         // Notify UI immediately after clearing, if appropriate
         // The onSessionsLoaded callback is often used for this.
         DispatchQueue.main.async {
              self.onSessionsLoaded?()
         }
    }
}
