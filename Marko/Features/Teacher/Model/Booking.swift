//
//  Booking.swift
//  Marko
//
//  Created by Ivan on 27.03.2025.
//
import UIKit

struct Booking {
    let id: String
    let teacherId: String
    let timeSlotId: String
    let userId: String
    let paymentAmount: Double
    let paymentDate: Date
    let timeSlot: TimeSlot
    let status: String // "confirmed", "cancelled", etc.
    
    var toDictionary: [String: Any] {
        return [
            "id": id,
            "teacherId": teacherId,
            "timeSlotId": timeSlotId,
            "userId": userId,
            "paymentAmount": paymentAmount,
            "paymentDate": paymentDate,
            "timeSlot": timeSlot.toDictionary,
            "status": status
        ]
    }
}
