//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase

class TeacherDetailViewModel {
    let teacher: Teacher
    private let timeSlotRepository = TimeSlotRepository()
    private(set) var availableTimeSlots: [TimeSlot] = []
    private let bookingRepository = BookingRepository()
    
    
    // Callback for when time slots are loaded
    var onTimeSlotsLoaded: (([TimeSlot]) -> Void)?
    
    // Callback for when booking is completed
    var onBookingCompleted: ((Bool, TimeSlot) -> Void)?
    
    init(teacher: Teacher) {
        self.teacher = teacher
    }
    
    // Load all available time slots for this teacher
    func loadAvailableTimeSlots() {
        timeSlotRepository.fetchTimeSlots(for: teacher.id) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Filter to only include non-booked slots in the future
            let now = Date()
            self.availableTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime > now }
            
            // Sort by start time
            self.availableTimeSlots.sort { $0.startTime < $1.startTime }
            
            // Notify listeners
            self.onTimeSlotsLoaded?(self.availableTimeSlots)
        }
    }
    
    // Load time slots for a specific date
    func loadTimeSlots(for date: Date) {
        timeSlotRepository.fetchTimeSlots(for: teacher.id, on: date) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Filter to only include non-booked slots in the future
            let now = Date()
            self.availableTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime > now }
            
            // Sort by start time
            self.availableTimeSlots.sort { $0.startTime < $1.startTime }
            
            // Notify listeners
            self.onTimeSlotsLoaded?(self.availableTimeSlots)
        }
    }
    
    // Book a time slot
    func bookTimeSlot(_ timeSlot: TimeSlot, userId: String) {
        bookingRepository.createBooking(
            teacherId: teacher.id,
            timeSlot: timeSlot,
            userId: userId
        ) { [weak self] success, bookingId in
            self?.onBookingCompleted?(success, timeSlot)
            
            if success {
                // Also trigger a notification for the teacher (via Firebase Cloud Messaging)
                self?.sendTeacherNotification(bookingId: bookingId, timeSlot: timeSlot)
            }
        }
    }
    
    
    // Add sample time slots (for testing)
    func addSampleTimeSlots(completion: @escaping () -> Void) {
        timeSlotRepository.addSampleTimeSlots(for: teacher.id, completion: completion)
    }
    
    private func sendTeacherNotification(bookingId: String?, timeSlot: TimeSlot) {
        guard let bookingId = bookingId else { return }
        
        // This would typically be a server-side operation using Cloud Functions
        // But for now, we can simulate by adding a notification record in Firestore
        
        let db = Firestore.firestore()
        let notificationRef = db.collection("teacherNotifications").document()
        
        let notificationData: [String: Any] = [
            "teacherId": teacher.id,
            "bookingId": bookingId,
            "message": "New booking received for \(timeSlot.formattedTimeSlot())",
            "createdAt": FieldValue.serverTimestamp(),
            "read": false
        ]
        
        notificationRef.setData(notificationData) { error in
            if let error = error {
                print("Error sending teacher notification: \(error.localizedDescription)")
            } else {
                print("Teacher notification sent successfully")
            }
        }
    }
}
