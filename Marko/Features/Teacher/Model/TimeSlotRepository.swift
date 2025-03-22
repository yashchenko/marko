//
//  TeacherRepository.swift
//  Marko
//
//  Created by Ivan on 15.03.2025.
//

import UIKit
import FirebaseFirestore

class TimeSlotRepository {
    private let db = Firestore.firestore()
    private let timeSlotsCollection = "timeSlots"
    
    // Fetch available time slots for a specific teacher
    func fetchTimeSlots(for teacherId: String, completion: @escaping ([TimeSlot]) -> Void) {
        // Query for time slots that belong to this teacher and aren't booked yet
        db.collection(timeSlotsCollection)
            .whereField("teacherId", isEqualTo: teacherId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching time slots: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No time slots found")
                    completion([])
                    return
                }
                
                let timeSlots = documents.compactMap { TimeSlot(document: $0) }
                completion(timeSlots)
            }
    }
    
    // Fetch available time slots for a specific date and teacher
    func fetchTimeSlots(for teacherId: String, on date: Date, completion: @escaping ([TimeSlot]) -> Void) {
        fetchTimeSlots(for: teacherId) { allSlots in
            let calendar = Calendar.current
            let filteredSlots = allSlots.filter { slot in
                calendar.isDate(slot.startTime, inSameDayAs: date)
            }
            completion(filteredSlots)
        }
    }
    
    // Book a time slot
    func bookTimeSlot(_ timeSlot: TimeSlot, userId: String, completion: @escaping (Bool) -> Void) {
        guard let documentRef = timeSlot.documentRef else {
            print("Error: Time slot has no document reference")
            completion(false)
            return
        }
        
        // Update the document in Firestore
        documentRef.updateData([
            "isBooked": true,
            "bookedByUserId": userId
        ]) { error in
            if let error = error {
                print("Error booking time slot: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    // Add sample time slots for a teacher (for testing)
    func addSampleTimeSlots(for teacherId: String, completion: @escaping () -> Void) {
        let calendar = Calendar.current
        let today = Date()
        
        // Create time slots for the next 7 days
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: day, to: today) else { continue }
            
            // Create 3 time slots per day (10:00, 14:00, 18:00)
            let hourOffsets = [10, 14, 18]
            
            for hourOffset in hourOffsets {
                // Create start time components
                var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
                startComponents.hour = hourOffset
                startComponents.minute = 0
                
                // Create end time components (1 hour later)
                var endComponents = startComponents
                endComponents.hour = hourOffset + 1
                
                guard
                    let startTime = calendar.date(from: startComponents),
                    let endTime = calendar.date(from: endComponents)
                else { continue }
                
                let timeSlot = TimeSlot(
                    teacherId: teacherId,
                    startTime: startTime,
                    endTime: endTime
                )
                
                // Add to Firestore
                db.collection(timeSlotsCollection).addDocument(data: timeSlot.asDictionary) { error in
                    if let error = error {
                        print("Error adding time slot: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        completion()
    }
    
    // Get user's booked sessions
    func fetchUserBookings(for userId: String, completion: @escaping ([TimeSlot]) -> Void) {
        db.collection(timeSlotsCollection)
            .whereField("bookedByUserId", isEqualTo: userId)
            .whereField("isBooked", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user bookings: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No bookings found")
                    completion([])
                    return
                }
                
                let bookings = documents.compactMap { TimeSlot(document: $0) }
                completion(bookings)
            }
    }
}
