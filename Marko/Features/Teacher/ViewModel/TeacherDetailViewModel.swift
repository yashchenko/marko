//  TeacherDetailViewModel.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

//
//  TeacherDetailViewModel.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import Firestore

class TeacherDetailViewModel {
    let teacher: Teacher
    private let timeSlotRepository = TimeSlotRepository()
    private let bookingRepository = BookingRepository()

    private(set) var availableTimeSlots: [TimeSlot] = []

    var onTimeSlotsLoaded: (([TimeSlot]) -> Void)?
    var onBookingCompleted: ((_ success: Bool, _ message: String?, _ timeSlot: TimeSlot?) -> Void)?

    init(teacher: Teacher) {
        self.teacher = teacher
    }

    // Load time slots for a specific date, filtering for future, available slots
    // This function remains the core way to load slots for a given date.
    func loadTimeSlots(for date: Date) {
        let requestedDate = Calendar.current.startOfDay(for: date)
         print("ViewModel: Loading time slots for teacher \(teacher.id) on date \(requestedDate)")
        timeSlotRepository.fetchTimeSlots(for: teacher.id, on: requestedDate) { [weak self] timeSlots in
            guard let self = self else { return }
            print("ViewModel: Received \(timeSlots.count) slots from repository for \(requestedDate).")

            let now = Date()
            let relevantTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime >= now }
            self.availableTimeSlots = relevantTimeSlots.sorted { $0.startTime < $1.startTime }
            print("ViewModel: Filtered to \(self.availableTimeSlots.count) available future slots.")

            DispatchQueue.main.async {
                self.onTimeSlotsLoaded?(self.availableTimeSlots)
            }
        }
    }

    // Initiate booking a time slot
    func bookTimeSlot(_ timeSlot: TimeSlot, userId: String) {
        print("ViewModel: Requesting booking for slot \(timeSlot.id) by user \(userId)")
        bookingRepository.createBooking(
            teacherId: teacher.id,
            timeSlot: timeSlot,
            userId: userId
        ) { [weak self] success, bookingId, errorMessage in
            guard let self = self else { return }
            print("ViewModel: Booking repository result - Success: \(success), BookingID: \(bookingId ?? "N/A"), ErrorMsg: \(errorMessage ?? "None")")
            let message: String?
            if success {
                let bookingIdString = bookingId != nil ? " (ID: \(bookingId!))" : ""
                message = "Session confirmed with \(self.teacher.name) for \(timeSlot.formattedTimeSlot())!\(bookingIdString)"
            } else {
                message = errorMessage ?? "Failed to book the session. Please try again."
            }
             DispatchQueue.main.async {
                self.onBookingCompleted?(success, message, success ? timeSlot : nil)
             }
             if success {
                self.sendTeacherNotification(bookingId: bookingId, timeSlot: timeSlot, userId: userId)
             }
        }
    }

    // **MODIFIED:** Function to handle sample data logic (DEBUG only)
    // It now calls a completion handler when done, without loading slots itself.
    func ensureSampleDataExists(completion: @escaping () -> Void) {
        #if DEBUG
        // Only check/add sample data in Debug builds
        print("DEBUG: Ensuring sample data exists for teacher \(teacher.id)...")
        timeSlotRepository.checkIfSampleSlotsExist(for: teacher.id) { [weak self] exist in
            guard let self = self else { completion(); return } // Call completion even if self is gone
            if !exist {
                print("DEBUG: Sample data not found. Adding sample time slots for teacher \(self.teacher.id)...")
                self.timeSlotRepository.addSampleTimeSlots(for: self.teacher.id) {
                    print("DEBUG: Sample time slots addition process completed.")
                    completion() // Signal completion after attempting to add
                }
            } else {
                 print("DEBUG: Sample slots already exist.")
                 completion() // Signal completion immediately if samples exist
            }
        }
        #else
        // In Release builds, do nothing regarding sample data, just complete.
        print("RELEASE: Skipping sample data check.")
        completion()
        #endif
    }


    // --- Teacher Notification (Simulated) ---
    private func sendTeacherNotification(bookingId: String?, timeSlot: TimeSlot, userId: String) {
        guard let bookingId = bookingId else { return }
        let db = Firestore.firestore()
        let notificationRef = db.collection("teacherNotifications").document()
        let notificationData: [String: Any] = [
            "teacherId": teacher.id,
            "bookingId": bookingId,
            "timeSlotId": timeSlot.id,
            "userId": userId,
            "message": "New booking from user \(userId) for \(timeSlot.formattedTimeSlot())",
            "createdAt": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        notificationRef.setData(notificationData) { error in
            if let error = error {
                print("Error creating teacher notification document: \(error.localizedDescription)")
            } else {
                print("Teacher notification document created successfully (Notification ID: \(notificationRef.documentID)).")
            }
        }
    }
}
