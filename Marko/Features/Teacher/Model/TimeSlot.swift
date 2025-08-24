////
////  TimeSlot.swift
////  Marko
////
////  Created by Ivan on 24.02.2025.
////
//
//import UIKit
//import FirebaseFirestore
//
//struct TimeSlot: Identifiable, Equatable {
//    var id: String // Firestore Document ID
//    let teacherId: String
//    let startTime: Date
//    let endTime: Date
//    var isBooked: Bool
//    var bookedByUserId: String?
//    var documentRef: DocumentReference? = nil
//
//    // Default initializer
//    init(id: String = UUID().uuidString,
//         teacherId: String,
//         startTime: Date,
//         endTime: Date,
//         isBooked: Bool = false,
//         bookedByUserId: String? = nil,
//         documentRef: DocumentReference? = nil) {
//        self.id = id
//        self.teacherId = teacherId
//        self.startTime = startTime
//        self.endTime = endTime
//        self.isBooked = isBooked
//        self.bookedByUserId = bookedByUserId
//        self.documentRef = documentRef
//    }
//
//    // Initializer from Firestore QueryDocumentSnapshot (used in getDocuments)
//    init?(document: QueryDocumentSnapshot) {
//        self.init(id: document.documentID, data: document.data(), ref: document.reference)
//    }
//
//    // Initializer from Firestore DocumentSnapshot (used in getDocument)
//    init?(snapshot: DocumentSnapshot) {
//        guard let data = snapshot.data() else { return nil }
//        self.init(id: snapshot.documentID, data: data, ref: snapshot.reference)
//    }
//
//    // Private common initializer logic
//    private init?(id: String, data: [String: Any], ref: DocumentReference) {
//        guard
//            let teacherId = data["teacherId"] as? String,
//            let startTimestamp = data["startTime"] as? Timestamp,
//            let endTimestamp = data["endTime"] as? Timestamp,
//            let isBooked = data["isBooked"] as? Bool
//        else {
//             print("Failed to parse TimeSlot from document ID: \(id). Missing/invalid fields. Data: \(data)")
//             return nil
//        }
//        self.id = id
//        self.teacherId = teacherId
//        self.startTime = startTimestamp.dateValue()
//        self.endTime = endTimestamp.dateValue()
//        self.isBooked = isBooked
//        if let userId = data["bookedByUserId"] as? String, userId != "" {
//            self.bookedByUserId = userId
//        } else {
//            self.bookedByUserId = nil
//        }
//        self.documentRef = ref
//    }
//
//
//    // Dictionary for writing to Firestore
//    var firestoreData: [String: Any] {
//        return [
//            "id": id,
//            "teacherId": teacherId,
//            "startTime": Timestamp(date: startTime),
//            "endTime": Timestamp(date: endTime),
//            "isBooked": isBooked,
//            "bookedByUserId": bookedByUserId as Any? ?? NSNull(),
//            "price": calculatePrice()
//        ]
//    }
//
//    // Formatted string for UI display
//    func formattedTimeSlot() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "E, MMM d, h:mm a"
//        let startTimeString = dateFormatter.string(from: startTime)
//        dateFormatter.dateFormat = "h:mm a"
//        let endTimeString = dateFormatter.string(from: endTime)
//        return "\(startTimeString) - \(endTimeString)"
//    }
//
//    // Price calculation
//    func calculatePrice(hourlyRate: Double = 300.0) -> Double {
//        let durationInSeconds = endTime.timeIntervalSince(startTime)
//        guard durationInSeconds > 0 else { return 0.0 }
//        let durationInHours = durationInSeconds / 3600.0
//        return (durationInHours * hourlyRate * 100).rounded() / 100
//    }
//
//    // Equatable conformance
//    static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
