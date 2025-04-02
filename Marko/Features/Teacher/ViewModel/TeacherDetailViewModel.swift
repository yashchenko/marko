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
    private let bookingRepository = BookingRepository() // Use BookingRepository for booking logic

    // Store the fetched available time slots for the currently selected date
    private(set) var availableTimeSlots: [TimeSlot] = []

    // Callback to notify ViewController when time slots are loaded/updated
    var onTimeSlotsLoaded: (([TimeSlot]) -> Void)?

    // Callback to notify ViewController when a booking attempt is completed
    // Parameters: success(Bool), message(String?), bookedTimeSlot(TimeSlot?)
    var onBookingCompleted: ((_ success: Bool, _ message: String?, _ timeSlot: TimeSlot?) -> Void)?

    init(teacher: Teacher) {
        self.teacher = teacher
    }

    // Load time slots for a specific date, filtering for future, available slots
    func loadTimeSlots(for date: Date) {
        let requestedDate = Calendar.current.startOfDay(for: date) // Normalize date
         print("ViewModel: Loading time slots for teacher \(teacher.id) on date \(requestedDate)")
        timeSlotRepository.fetchTimeSlots(for: teacher.id, on: requestedDate) { [weak self] timeSlots in
            guard let self = self else { return }
            print("ViewModel: Received \(timeSlots.count) slots from repository for \(requestedDate).")

            // Filter for slots that are not booked and start now or in the future
            let now = Date()
            // Use >= now to include slots starting exactly now
            let relevantTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime >= now }

            // Sort the filtered slots by their start time
            self.availableTimeSlots = relevantTimeSlots.sorted { $0.startTime < $1.startTime }
             print("ViewModel: Filtered to \(self.availableTimeSlots.count) available future slots.")

            // Notify the ViewController on the main thread
            DispatchQueue.main.async {
                self.onTimeSlotsLoaded?(self.availableTimeSlots)
            }
        }
    }

    // Initiate booking a time slot using the BookingRepository
    func bookTimeSlot(_ timeSlot: TimeSlot, userId: String) {
        print("ViewModel: Requesting booking for slot \(timeSlot.id) by user \(userId)")
        bookingRepository.createBooking(
            teacherId: teacher.id,
            timeSlot: timeSlot,
            userId: userId
        ) { [weak self] success, bookingId, errorMessage in // Use the updated completion handler
            guard let self = self else { return }
            print("ViewModel: Booking repository result - Success: \(success), BookingID: \(bookingId ?? "N/A"), ErrorMsg: \(errorMessage ?? "None")")

            let message: String?
            if success {
                // Construct success message including the booking ID if available
                let bookingIdString = bookingId != nil ? " (ID: \(bookingId!))" : ""
                message = "Session confirmed with \(self.teacher.name) for \(timeSlot.formattedTimeSlot())!\(bookingIdString)"
            } else {
                // Use the error message from the repository, or a generic failure message
                message = errorMessage ?? "Failed to book the session. The slot might have been taken, or an error occurred."
            }

            // Notify the ViewController about the booking attempt result
            // Ensure callback is on the main thread as it might trigger UI updates indirectly
             DispatchQueue.main.async {
                 // Pass success status, message, and the slot (if successful) back
                self.onBookingCompleted?(success, message, success ? timeSlot : nil)
             }
             // If successful, also trigger teacher notification (can remain async)
             if success {
                self.sendTeacherNotification(bookingId: bookingId, timeSlot: timeSlot, userId: userId)
             }
        }
    }

    // Add sample time slots for testing, but only if they don't seem to exist already
    func addSampleTimeSlotsIfNeeded(completion: @escaping () -> Void) {
        timeSlotRepository.checkIfSampleSlotsExist(for: teacher.id) { [weak self] exist in
            guard let self = self else { completion(); return }
            if exist {
                print("Sample time slots likely already exist for teacher \(self.teacher.id). Skipping addition.")
                completion() // Proceed without adding samples
            } else {
                print("Adding sample time slots for teacher \(self.teacher.id)...")
                // Call the repository method to add sample data
                self.timeSlotRepository.addSampleTimeSlots(for: self.teacher.id) {
                    print("Sample time slots addition process completed.")
                    completion() // Signal completion after attempting to add
                }
            }
        }
    }

    // --- Teacher Notification (Simulated) ---
    // In a real app, this should trigger a Cloud Function to send FCM
    private func sendTeacherNotification(bookingId: String?, timeSlot: TimeSlot, userId: String) {
        guard let bookingId = bookingId else { return }

        let db = Firestore.firestore()
        // Create a document in a collection teachers can listen to
        let notificationRef = db.collection("teacherNotifications").document()

        let notificationData: [String: Any] = [
            "teacherId": teacher.id,
            "bookingId": bookingId,
            "timeSlotId": timeSlot.id,
            "userId": userId, // Include user who booked
            "message": "New booking from user \(userId) for \(timeSlot.formattedTimeSlot())",
            "createdAt": FieldValue.serverTimestamp(),
            "isRead": false // Flag for teacher's UI
        ]

        notificationRef.setData(notificationData) { error in
            if let error = error {
                print("Error creating teacher notification document: \(error.localizedDescription)")
            } else {
                print("Teacher notification document created successfully (Notification ID: \(notificationRef.documentID)).")
                // Note: This does NOT send a push notification via FCM.
            }
        }
    }
}
