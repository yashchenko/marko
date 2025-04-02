//  Booking.swift
//  Marko
//
//  Created by Ivan on 27.03.2025.
//

import UIKit
import FirebaseFirestore // For Timestamp

// Represents a confirmed booking record
struct Booking: Identifiable {
    let id: String // Firestore document ID for the booking itself
    let teacherId: String
    let timeSlotId: String // ID of the related TimeSlot document
    let userId: String
    let paymentAmount: Double
    let paymentDate: Date // Timestamp of when the booking/payment was confirmed
    // Embed the TimeSlot details as they were *at the time of booking*
    // This avoids issues if teacher rates or slot times change later.
    let timeSlot: TimeSlot
    var status: String // e.g., "confirmed", "cancelled", "completed"

    // Dictionary representation for writing Booking data TO Firestore
    var firestoreData: [String: Any] {
        return [
            // We don't store 'id' field inside the document, as the document ID is the id.
            "teacherId": teacherId,
            "timeSlotId": timeSlotId, // Store the link to the TimeSlot document
            "userId": userId,
            "paymentAmount": paymentAmount,
            "paymentDate": Timestamp(date: paymentDate), // Use Firestore Timestamp
            // Embed the dictionary representation of the TimeSlot
            "timeSlot": timeSlot.firestoreData,
            "status": status
        ]
    }

    // Note: An initializer from Firestore data (e.g., init?(document:))
    // is handled within the BookingRepository's fetch methods currently.
}
