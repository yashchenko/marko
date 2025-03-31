//
//  BookingRepository.swift
//  Marko
//
//  Created by Ivan on 27.03.2025.
//

import UIKit
import Firebase

class BookingRepository {
    private let db = Firestore.firestore()
    
    func createBooking(teacherId: String,
                     timeSlot: TimeSlot,
                     userId: String,
                     completion: @escaping (Bool, String?) -> Void) {
        
        let bookingRef = db.collection("bookings").document()
        
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
        
        bookingRef.setData(booking.toDictionary) { error in
            if let error = error {
                print("Error saving booking: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            // Also update the time slot as booked
            self.updateTimeSlotAvailability(timeSlot.id, isAvailable: false) { success in
                completion(success, booking.id)
            }
        }
    }
    
    private func updateTimeSlotAvailability(_ timeSlotId: String, isAvailable: Bool, completion: @escaping (Bool) -> Void) {
        let timeSlotRef = db.collection("timeSlots").document(timeSlotId)
        
        timeSlotRef.updateData(["isAvailable": isAvailable]) { error in
            if let error = error {
                print("Error updating time slot availability: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
        }
    }
}
