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
    
    // Create booking with transaction to ensure data consistency
    func createBooking(teacherId: String,
                     timeSlot: TimeSlot,
                     userId: String,
                     completion: @escaping (Bool, String?) -> Void) {
        
        // Reference to the booking document
        let bookingRef = db.collection("bookings").document()
        
        // Reference to the timeSlot document
        let timeSlotRef = db.collection("timeSlots").document(timeSlot.id)
        
        // Use a transaction to ensure atomicity
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            
            // First, check if the time slot is still available
            let timeSlotSnapshot: DocumentSnapshot
            do {
                try timeSlotSnapshot = transaction.getDocument(timeSlotRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Verify the slot exists and is available
            guard let timeSlotData = timeSlotSnapshot.data(),
                  let isBooked = timeSlotData["isBooked"] as? Bool else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Time slot not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // If already booked, return error
            if isBooked {
                let error = NSError(domain: "AppErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Time slot already booked"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Create the booking object
            let booking = Booking(
                id: bookingRef.documentID,
                teacherId: teacherId,
                timeSlotId: timeSlot.id,
                userId: userId,
                paymentAmount: timeSlot.calculatePrice(),
                paymentDate: Date(),
                timeSlot: timeSlot,
                status: "confirmed"
            )
            
            // Update the time slot as booked
            transaction.updateData([
                "isBooked": true,
                "bookedByUserId": userId
            ], forDocument: timeSlotRef)
            
            // Create the booking document
            transaction.setData(booking.toDictionary, forDocument: bookingRef)
            
            return booking.id
        }) { (result, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
                // Provide specific error handling based on error code
                if let nsError = error as NSError?, nsError.code == -2 {
                    // Handle already booked error specifically
                    print("Time slot was already booked by someone else")
                }
                completion(false, nil)
                return
            }
            
            guard let bookingId = result as? String else {
                completion(false, nil)
                return
            }
            
            completion(true, bookingId)
        }
    }
    
    // Get user's bookings
    func fetchUserBookings(for userId: String, completion: @escaping ([Booking]) -> Void) {
        db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
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
                
                let bookings = documents.compactMap { document -> Booking? in
                    let data = document.data()
                    
                    // Extract the embedded timeSlot data
                    guard let timeSlotData = data["timeSlot"] as? [String: Any],
                          let teacherId = data["teacherId"] as? String,
                          let timeSlotId = data["timeSlotId"] as? String,
                          let userId = data["userId"] as? String,
                          let paymentAmount = data["paymentAmount"] as? Double,
                          let paymentTimestamp = data["paymentDate"] as? Timestamp,
                          let status = data["status"] as? String,
                          
                          // TimeSlot data
                          let startTimestamp = timeSlotData["startTime"] as? Timestamp,
                          let endTimestamp = timeSlotData["endTime"] as? Timestamp,
                          let slotTeacherId = timeSlotData["teacherId"] as? String,
                          let id = timeSlotData["id"] as? String else {
                        print("Missing required fields in booking document")
                        return nil
                    }
                    
                    // Reconstruct the TimeSlot
                    let timeSlot = TimeSlot(
                        id: id,
                        teacherId: slotTeacherId,
                        startTime: startTimestamp.dateValue(),
                        endTime: endTimestamp.dateValue(),
                        isBooked: true,
                        bookedByUserId: userId
                    )
                    
                    return Booking(
                        id: document.documentID,
                        teacherId: teacherId,
                        timeSlotId: timeSlotId,
                        userId: userId,
                        paymentAmount: paymentAmount,
                        paymentDate: paymentTimestamp.dateValue(),
                        timeSlot: timeSlot,
                        status: status
                    )
                }
                
                completion(bookings)
            }
    }
    
    // Cancel a booking
    func cancelBooking(bookingId: String, completion: @escaping (Bool) -> Void) {
        let bookingRef = db.collection("bookings").document(bookingId)
        
        // First get the booking to find the time slot
        bookingRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching booking: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data(),
                  let timeSlotId = data["timeSlotId"] as? String else {
                print("Invalid booking data")
                completion(false)
                return
            }
            
            // Use a transaction to ensure consistency
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                // Update booking status
                transaction.updateData(["status": "cancelled"], forDocument: bookingRef)
                
                // Update time slot availability
                let timeSlotRef = self.db.collection("timeSlots").document(timeSlotId)
                transaction.updateData([
                    "isBooked": false,
                    "bookedByUserId": FieldValue.delete()
                ], forDocument: timeSlotRef)
                
                return true
            }) { (result, error) in
                if let error = error {
                    print("Error cancelling booking: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
}
