//  TimeSlotRepository.swift
//  Marko
//
//  Created by Ivan on 15.03.2025.
//

import UIKit
import FirebaseFirestore
// Removed FirebaseFirestoreSwift import as we are using manual dictionary conversion

class TimeSlotRepository {
    private let db = Firestore.firestore()
    private let timeSlotsCollection = "timeSlots"

    // Fetch ALL time slots for a specific teacher (usually filtered later)
    func fetchTimeSlots(for teacherId: String, completion: @escaping ([TimeSlot]) -> Void) {
        print("Repo: Fetching all time slots for teacher: \(teacherId)")
        db.collection(timeSlotsCollection)
            .whereField("teacherId", isEqualTo: teacherId)
            // Optional: Add .order(by: "startTime") if needed, might affect indexing requirements
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching time slots for teacher \(teacherId): \(error.localizedDescription)")
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("Repo: No time slot documents found for teacher \(teacherId)")
                    completion([])
                    return
                }
                print("Repo: Found \(documents.count) raw documents for teacher \(teacherId)")
                // Use compactMap with the initializer that reads document.documentID
                let timeSlots = documents.compactMap { TimeSlot(document: $0) }
                print("Repo: Parsed \(timeSlots.count) TimeSlot objects for teacher \(teacherId)")
                completion(timeSlots)
            }
    }

    // Fetch available time slots for a specific date and teacher using Firestore query
    func fetchTimeSlots(for teacherId: String, on date: Date, completion: @escaping ([TimeSlot]) -> Void) {
         let calendar = Calendar.current
         let startOfDay = calendar.startOfDay(for: date)
         // Calculate the start of the *next* day for the upper bound (<)
         guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
             print("Error calculating end of day for date: \(date)")
             completion([])
             return
         }
         let startTimestamp = Timestamp(date: startOfDay)
         let endTimestamp = Timestamp(date: endOfDay) // Query range is [startOfDay, endOfDay)

         print("Repo: Fetching slots for teacher \(teacherId) between \(startTimestamp.dateValue()) and \(endTimestamp.dateValue())")

         db.collection(timeSlotsCollection)
             .whereField("teacherId", isEqualTo: teacherId)
             .whereField("startTime", isGreaterThanOrEqualTo: startTimestamp) // startTime >= startOfDay
             .whereField("startTime", isLessThan: endTimestamp)            // startTime < startOfNextDay
             // Optional: Order results by start time directly in the query
             .order(by: "startTime", descending: false)
             .getDocuments { snapshot, error in
                 if let error = error {
                     // Check for index suggestion error
                     if let firestoreError = error as NSError?, firestoreError.code == FirestoreErrorCode.failedPrecondition.rawValue {
                         print("Firestore Error: \(error.localizedDescription). You might need to create a composite index in Firestore for this query (teacherId ASC, startTime ASC).")
                     } else {
                         print("Error fetching time slots for teacher \(teacherId) on \(date): \(error.localizedDescription)")
                     }
                     completion([])
                     return
                 }
                 guard let documents = snapshot?.documents else {
                     print("Repo: No time slot documents found for teacher \(teacherId) on \(date)")
                     completion([])
                     return
                 }
                 print("Repo: Found \(documents.count) raw documents for teacher \(teacherId) on \(date)")
                 let timeSlots = documents.compactMap { TimeSlot(document: $0) }
                 print("Repo: Parsed \(timeSlots.count) TimeSlot objects for teacher \(teacherId) on \(date)")
                 completion(timeSlots)
             }
    }

    // Add sample time slots for a teacher (for testing) - Use TimeSlot.id as Document ID
    // Uses batch write for efficiency.
    func addSampleTimeSlots(for teacherId: String, completion: @escaping () -> Void) {
        let calendar = Calendar.current
        // Start samples from today's date
        let today = calendar.startOfDay(for: Date())
        let batch = db.batch() // Create a Firestore batch

        print("Repo: Preparing batch to add sample time slots for teacher \(teacherId)")

        // Create time slots for the next 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            // Define sample hours (e.g., 9:00, 11:00, 14:00, 16:00) - 1 hour duration
            let hourSlots = [9, 11, 14, 16]

            for hour in hourSlots {
                // Calculate start and end times for the slot
                var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
                startComponents.hour = hour
                startComponents.minute = 0
                var endComponents = startComponents
                endComponents.hour = hour + 1 // 1-hour lesson

                guard let startTime = calendar.date(from: startComponents),
                      let endTime = calendar.date(from: endComponents) else {
                    print("Error creating date components for sample slot.")
                    continue
                }

                // Create TimeSlot instance (generates its own UUID `id`)
                let timeSlot = TimeSlot(
                    teacherId: teacherId,
                    startTime: startTime,
                    endTime: endTime
                    // isBooked defaults to false, bookedByUserId defaults to nil
                )

                // ** CRITICAL: Get a document reference using the timeSlot's generated ID **
                let docRef = db.collection(timeSlotsCollection).document(timeSlot.id)

                // Add the setData operation to the batch, using the dictionary representation
                batch.setData(timeSlot.firestoreData, forDocument: docRef)
                // print("Repo: Batching add slot: \(timeSlot.id) for \(timeSlot.formattedTimeSlot())") // Verbose log
            }
        }

        // Commit the entire batch at once
        print("Repo: Committing sample time slots batch...")
        batch.commit { error in
            if let error = error {
                print("Error adding sample time slots batch: \(error.localizedDescription)")
            } else {
                print("Repo: Sample time slots batch committed successfully for teacher \(teacherId).")
            }
            // Call completion handler whether it succeeded or failed
            completion()
        }
    }

    // Helper to quickly check if *any* slots exist for a teacher (to avoid adding samples repeatedly)
     func checkIfSampleSlotsExist(for teacherId: String, completion: @escaping (Bool) -> Void) {
         db.collection(timeSlotsCollection)
             .whereField("teacherId", isEqualTo: teacherId)
             .limit(to: 1) // We only need to know if at least one exists
             .getDocuments { snapshot, error in
                 if let error = error {
                     print("Error checking for existing slots for teacher \(teacherId): \(error.localizedDescription)")
                     completion(false) // Assume they don't exist on error
                     return
                 }
                 // If snapshot is not nil and not empty, then slots exist
                 let exists = snapshot?.isEmpty == false
                 print("Repo: Check if slots exist for teacher \(teacherId): \(exists)")
                 completion(exists)
             }
     }

    // Get user's booked sessions - relies on TimeSlot having bookedByUserId field populated
    func fetchUserBookings(for userId: String, completion: @escaping ([TimeSlot]) -> Void) {
         print("Repo: Fetching booked time slots for user: \(userId)")
         db.collection(timeSlotsCollection)
             .whereField("bookedByUserId", isEqualTo: userId)
             .whereField("isBooked", isEqualTo: true) // Explicitly check if marked as booked
             // Optional: Order by time
             .order(by: "startTime", descending: false)
             .getDocuments { snapshot, error in
                 if let error = error {
                     print("Error fetching user bookings for \(userId): \(error.localizedDescription)")
                     completion([])
                     return
                 }
                 guard let documents = snapshot?.documents else {
                     print("Repo: No booking documents found matching user \(userId)")
                     completion([])
                     return
                 }
                 print("Repo: Found \(documents.count) raw booking documents for user \(userId)")
                 let bookings = documents.compactMap { TimeSlot(document: $0) }
                 print("Repo: Parsed \(bookings.count) booked TimeSlots for user \(userId)")
                 completion(bookings)
             }
     }
}
