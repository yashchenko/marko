//
//  BookingRepository.swift
//  Marko
//
//  Created by Ivan on 27.03.2025.
//

import UIKit
import FirebaseFirestore

class BookingRepository {
    private let db = Firestore.firestore()
    private let bookingsCollection = "bookings"
    private let timeSlotsCollection = "timeSlots"

    // Create booking using a transaction for atomicity
    func createBooking(teacherId: String,
                       timeSlot: TimeSlot, // The specific slot user wants to book
                       userId: String,
                       // Completion handler includes success status, optional booking ID, and optional error message
                       completion: @escaping (_ success: Bool, _ bookingId: String?, _ errorMessage: String?) -> Void) {

        let newBookingRef = db.collection(bookingsCollection).document()
        let timeSlotRef = db.collection(timeSlotsCollection).document(timeSlot.id)
        print("Repo: Starting booking transaction for TimeSlot ID: \(timeSlot.id)")

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let timeSlotSnapshot: DocumentSnapshot
            do {
                print("Transaction [Read]: Getting TimeSlot document \(timeSlot.id)...")
                try timeSlotSnapshot = transaction.getDocument(timeSlotRef)
            } catch let fetchError as NSError {
                print("Transaction Error [Read]: Failed to get TimeSlot document: \(fetchError)")
                errorPointer?.pointee = fetchError
                return nil // Abort
            }

            // **FIX:** Use the TimeSlot initializer that accepts DocumentSnapshot
            guard timeSlotSnapshot.exists,
                  let currentDbTimeSlot = TimeSlot(snapshot: timeSlotSnapshot) // Use init(snapshot:)
            else {
                let error = NSError(domain: "BookingErrorDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Selected time slot could not be found."])
                print("Transaction Error [Validate]: TimeSlot document \(timeSlot.id) not found or failed to parse.")
                errorPointer?.pointee = error
                return nil // Abort
            }

            if currentDbTimeSlot.isBooked {
                let error = NSError(domain: "BookingErrorDomain", code: 409, userInfo: [NSLocalizedDescriptionKey: "Sorry, this time slot was booked by someone else just now."])
                print("Transaction Error [Check]: TimeSlot \(timeSlot.id) is already booked.")
                errorPointer?.pointee = error
                return nil // Abort
            }

            let newBooking = Booking(
                id: newBookingRef.documentID,
                teacherId: teacherId,
                timeSlotId: timeSlot.id,
                userId: userId,
                paymentAmount: timeSlot.calculatePrice(),
                paymentDate: Date(),
                timeSlot: timeSlot,
                status: "confirmed"
            )

            print("Transaction [Write]: Updating TimeSlot \(timeSlot.id) to booked by \(userId)...")
            transaction.updateData([
                "isBooked": true,
                "bookedByUserId": userId
            ], forDocument: timeSlotRef)

            print("Transaction [Write]: Creating Booking document \(newBookingRef.documentID)...")
            transaction.setData(newBooking.firestoreData, forDocument: newBookingRef)

            return newBooking.id // Return booking ID on success inside transaction
        }) { (result, error) in
            // --- Transaction Completion ---
            if let error = error as NSError? {
                print("Booking Transaction failed: \(error.localizedDescription) (Code: \(error.code))")
                let errorMessage = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "An unknown error occurred during booking."
                completion(false, nil, errorMessage)
            } else if let bookingId = result as? String {
                print("Booking Transaction successful! Booking ID: \(bookingId)")
                completion(true, bookingId, nil) // Success
            } else {
                 print("Booking Transaction Error: Succeeded but result was not a String ID.")
                 completion(false, nil, "Booking completed but failed to get confirmation ID.")
            }
        }
    }

    // Get user's bookings (Reads from 'bookings' collection)
     func fetchUserBookings(for userId: String, completion: @escaping ([Booking]) -> Void) {
         print("Repo: Fetching bookings for user: \(userId)")
         db.collection(bookingsCollection)
             .whereField("userId", isEqualTo: userId)
             .order(by: "paymentDate", descending: true)
             .getDocuments { snapshot, error in
                 if let error = error {
                     print("Error fetching user bookings for \(userId): \(error.localizedDescription)")
                     completion([])
                     return
                 }
                 guard let documents = snapshot?.documents else {
                     print("Repo: No booking documents found for user \(userId)")
                     completion([])
                     return
                 }
                 print("Repo: Found \(documents.count) raw booking documents for user \(userId)")

                 let bookings = documents.compactMap { document -> Booking? in
                     let data = document.data()
                     let bookingId = document.documentID
                     // print("Repo: Parsing booking document \(bookingId)...") // Verbose log

                     guard let teacherId = data["teacherId"] as? String,
                           let timeSlotId = data["timeSlotId"] as? String,
                           let fetchedUserId = data["userId"] as? String,
                           let paymentAmount = data["paymentAmount"] as? Double,
                           let paymentTimestamp = data["paymentDate"] as? Timestamp,
                           let status = data["status"] as? String,
                           let timeSlotData = data["timeSlot"] as? [String: Any]
                     else {
                         print("Repo Error: Missing or invalid top-level fields in booking \(bookingId).")
                         return nil
                     }

                     guard let tsId = timeSlotData["id"] as? String,
                           let tsTeacherId = timeSlotData["teacherId"] as? String,
                           let tsStartTimeStamp = timeSlotData["startTime"] as? Timestamp,
                           let tsEndTimeStamp = timeSlotData["endTime"] as? Timestamp,
                           let tsIsBooked = timeSlotData["isBooked"] as? Bool
                           // **FIX:** Removed unused 'tsPrice' causing warning
                           // let tsPrice = timeSlotData["price"] as? Double
                     else {
                          print("Repo Error: Missing or invalid fields in embedded timeSlot for booking \(bookingId).")
                          return nil
                     }
                       if tsId != timeSlotId { print("Warning: Mismatch between embedded timeSlot ID (\(tsId)) and booking's timeSlotId (\(timeSlotId)) for booking \(bookingId)") }

                     let embeddedTimeSlot = TimeSlot(
                         id: tsId,
                         teacherId: tsTeacherId,
                         startTime: tsStartTimeStamp.dateValue(),
                         endTime: tsEndTimeStamp.dateValue(),
                         isBooked: tsIsBooked,
                         bookedByUserId: timeSlotData["bookedByUserId"] as? String ?? fetchedUserId
                     )

                     return Booking(
                         id: bookingId,
                         teacherId: teacherId,
                         timeSlotId: timeSlotId,
                         userId: fetchedUserId,
                         paymentAmount: paymentAmount,
                         paymentDate: paymentTimestamp.dateValue(),
                         timeSlot: embeddedTimeSlot,
                         status: status
                     )
                 }
                 print("Repo: Parsed \(bookings.count) valid Booking objects for user \(userId)")
                 completion(bookings)
             }
     }

    // Cancel a booking (Requires updating Booking status and TimeSlot availability atomically)
    func cancelBooking(bookingId: String, completion: @escaping (Bool, String?) -> Void) {
        let bookingRef = db.collection(bookingsCollection).document(bookingId)
        print("Repo: Attempting to cancel booking: \(bookingId)")

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let bookingSnapshot: DocumentSnapshot
            do {
                 // print("Transaction [Read]: Getting Booking document \(bookingId)...") // Verbose log
                try bookingSnapshot = transaction.getDocument(bookingRef)
            } catch let fetchError as NSError {
                 print("Transaction Error [Read]: Failed to get Booking document: \(fetchError)")
                errorPointer?.pointee = fetchError
                return nil // Abort
            }

            guard bookingSnapshot.exists,
                  let bookingData = bookingSnapshot.data(),
                  let timeSlotId = bookingData["timeSlotId"] as? String,
                  let currentStatus = bookingData["status"] as? String else {
                let error = NSError(domain: "BookingErrorDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Booking not found or data is incomplete."])
                 print("Transaction Error [Validate]: Booking \(bookingId) not found or invalid.")
                errorPointer?.pointee = error
                return nil // Abort
            }

            if currentStatus == "cancelled" {
                 let error = NSError(domain: "BookingErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "This booking has already been cancelled."])
                 print("Transaction Error [Check]: Booking \(bookingId) already cancelled.")
                 errorPointer?.pointee = error
                 return nil // Abort
            }
             if currentStatus == "completed" {
                  let error = NSError(domain: "BookingErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot cancel a completed session."])
                  print("Transaction Error [Check]: Booking \(bookingId) already completed.")
                  errorPointer?.pointee = error
                  return nil // Abort
             }

            let timeSlotRef = self.db.collection(self.timeSlotsCollection).document(timeSlotId)

            print("Transaction [Write]: Updating Booking \(bookingId) status to 'cancelled'...")
            transaction.updateData(["status": "cancelled"], forDocument: bookingRef)

            print("Transaction [Write]: Updating TimeSlot \(timeSlotId) to available...")
            transaction.updateData([
                "isBooked": false,
                "bookedByUserId": FieldValue.delete()
            ], forDocument: timeSlotRef)

            return true // Indicate success within transaction block
        }) { (result, error) in
            // --- Transaction Completion ---
            if let error = error as NSError? {
                print("Cancel Booking Transaction failed: \(error.localizedDescription)")
                 let errorMessage = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Could not cancel the booking due to an error."
                 completion(false, errorMessage)
            } else {
                print("Cancel Booking Transaction successful for booking: \(bookingId)")
                completion(true, nil) // Success
            }
        }
    }
}
