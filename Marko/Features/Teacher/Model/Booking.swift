//
//  Booking.swift
//  Marko
//
//  Created by You on 2025-08-23.
//

import Foundation
import FirebaseFirestore

struct TimeSlot {
    let id: String
    let teacherId: String?
    let startTime: Date
    let endTime: Date
    let isBooked: Bool
    let bookedBy: String?

    init(id: String, teacherId: String? = nil, startTime: Date, endTime: Date, isBooked: Bool = false, bookedBy: String? = nil) {
        self.id = id
        self.teacherId = teacherId
        self.startTime = startTime
        self.endTime = endTime
        self.isBooked = isBooked
        self.bookedBy = bookedBy
    }

    // Compatibility initializer used elsewhere: keep teacherId parameter and set property
    init(teacherId: String, startTime: Date, endTime: Date, isBooked: Bool = false, bookedBy: String? = nil) {
        self.id = UUID().uuidString
        self.teacherId = teacherId
        self.startTime = startTime
        self.endTime = endTime
        self.isBooked = isBooked
        self.bookedBy = bookedBy
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let startTs = data["startTime"] as? Timestamp,
              let endTs = data["endTime"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.teacherId = data["teacherId"] as? String
        self.startTime = startTs.dateValue()
        self.endTime = endTs.dateValue()
        self.isBooked = data["isBooked"] as? Bool ?? false
        // Accept both field names to be robust with older documents:
        self.bookedBy = data["bookedBy"] as? String ?? data["bookedByUserId"] as? String
    }

    func calculatePrice() -> Double {
        let durationMinutes = endTime.timeIntervalSince(startTime) / 60.0
        let pricePerMinute: Double = 1.0
        return max(0.0, durationMinutes * pricePerMinute)
    }

    func formattedTimeSlot() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) — \(formatter.string(from: endTime))"
    }

    // Dictionary representation suitable for setData / batch.setData
    var firestoreData: [String: Any] {
        var d: [String: Any] = [
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "isBooked": isBooked
        ]
        if let tid = teacherId { d["teacherId"] = tid }
        if let b = bookedBy { d["bookedBy"] = b }
        return d
    }
}

struct Booking {
    let id: String
    let userId: String
    let teacherId: String
    let timeSlotId: String
    let paymentAmount: Double
    let status: String
    let createdAt: Date
    let timeSlot: TimeSlot

    init?(document: DocumentSnapshot, timeSlot: TimeSlot?) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let teacherId = data["teacherId"] as? String,
              let timeSlotId = data["timeSlotId"] as? String,
              let created = data["createdAt"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.userId = userId
        self.teacherId = teacherId
        self.timeSlotId = timeSlotId
        self.paymentAmount = data["paymentAmount"] as? Double ?? 0.0
        self.status = data["status"] as? String ?? "confirmed"
        self.createdAt = created.dateValue()

        if let ts = timeSlot {
            self.timeSlot = ts
        } else {
            let fallback = TimeSlot(id: timeSlotId, startTime: created.dateValue(), endTime: created.dateValue())
            self.timeSlot = fallback
        }
    }
}
