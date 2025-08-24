//
//  ProfileViewModel.swift
//  Marko
//
//  Created by You on 2025-08-23.
//

import Foundation
import FirebaseAuth

class ProfileViewModel {
    // Backwards-compatible user property expected by your view / coordinator
    var user: User?

    // New simplified display property (kept for new code)
    var userDisplay: String

    private let bookingRepository: BookingRepository
    private let teacherRepository: TeacherRepository
    var bookedSessions: [Booking] = []
    var teachers: [String: Teacher] = [:]
    var onSessionsLoaded: (() -> Void)?

    // Backwards-compatible initializer used across your app
    init(user: User,
         bookingRepository: BookingRepository = BookingRepository(),
         teacherRepository: TeacherRepository = TeacherRepository()) {
        self.user = user
        self.userDisplay = user.name
        self.bookingRepository = bookingRepository
        self.teacherRepository = teacherRepository
    }

    // New convenience initializer (keeps previous behavior for any new code)
    init(userDisplay: String,
         bookingRepository: BookingRepository = BookingRepository(),
         teacherRepository: TeacherRepository = TeacherRepository()) {
        self.userDisplay = userDisplay
        self.bookingRepository = bookingRepository
        self.teacherRepository = teacherRepository
    }

    func loadBookedSessions() {
        guard let userId = AuthService.shared.currentUser?.uid else {
            clearUserSessionData()
            return
        }

        bookingRepository.fetchUserBookings(for: userId) { [weak self] bookings in
            guard let self = self else { return }
            self.bookedSessions = bookings.filter { $0.status == "confirmed" && $0.timeSlot.endTime > Date() }
            self.loadTeacherDetails(for: self.bookedSessions)
        }
    }

    private func loadTeacherDetails(for bookings: [Booking]) {
        let requiredTeacherIds = Set(bookings.map { $0.teacherId })
        guard !requiredTeacherIds.isEmpty else {
            DispatchQueue.main.async { self.onSessionsLoaded?() }
            return
        }

        teacherRepository.fetchTeachers { [weak self] allTeachers in
            guard let self = self else { return }
            for teacher in allTeachers {
                if requiredTeacherIds.contains(teacher.id) {
                    self.teachers[teacher.id] = teacher
                }
            }
            DispatchQueue.main.async { self.onSessionsLoaded?() }
        }
    }

    // Backwards-compatible method used by your UI code
    func upgradePrompt() -> String? {
        guard let user = self.user else { return nil }
        if user.englishLevel == "B1" {
            return "Upgrade to B2 by purchasing 30 additional lessons!"
        }
        return nil
    }

    func getNextSessionInfo() -> String? {
        guard let nextBooking = bookedSessions.sorted(by: { $0.timeSlot.startTime < $1.timeSlot.startTime }).first else { return nil }
        let teacherName = teachers[nextBooking.teacherId]?.name ?? "Teacher"
        return "Next session with \(teacherName) on \(nextBooking.timeSlot.formattedTimeSlot())"
    }

    func clearUserSessionData() {
        self.bookedSessions = []
        self.teachers = [:]
        DispatchQueue.main.async { self.onSessionsLoaded?() }
    }
}
