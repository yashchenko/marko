
//  TimeSlot.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.


import UIKit
import FirebaseFirestore

struct TimeSlot: Identifiable {
       var id: String = UUID().uuidString
       let teacherId: String
       let startTime: Date
       let endTime: Date
       var isBooked: Bool
       var bookedByUserId: String?
       
       // Firestore document reference (non-Codable)
       var documentRef: DocumentReference? = nil
    
    // Default initializer
    init(id: String = UUID().uuidString,
         teacherId: String,
         startTime: Date,
         endTime: Date,
         isBooked: Bool = false,
         bookedByUserId: String? = nil) {
        self.id = id
        self.teacherId = teacherId
        self.startTime = startTime
        self.endTime = endTime
        self.isBooked = isBooked
        self.bookedByUserId = bookedByUserId
    }
    
    // Firestore dictionary representation
    var asDictionary: [String: Any] {
        return [
            "id": id,
            "teacherId": teacherId,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "isBooked": isBooked,
            "bookedByUserId": bookedByUserId ?? NSNull()
        ]
    }
    
    // Create from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard
            let id = data["id"] as? String,
            let teacherId = data["teacherId"] as? String,
            let startTimestamp = data["startTime"] as? Timestamp,
            let endTimestamp = data["endTime"] as? Timestamp,
            let isBooked = data["isBooked"] as? Bool
        else {
            return nil
        }
        
        self.id = id
        self.teacherId = teacherId
        self.startTime = startTimestamp.dateValue()
        self.endTime = endTimestamp.dateValue()
        self.isBooked = isBooked
        self.bookedByUserId = data["bookedByUserId"] as? String
        self.documentRef = document.reference
    }
    
    // Format time slot for display
    func formattedTimeSlot() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let dayString = dateFormatter.string(from: startTime)
        
        dateFormatter.dateFormat = "h:mm a"
        let startTimeString = dateFormatter.string(from: startTime)
        let endTimeString = dateFormatter.string(from: endTime)
        
        return "\(dayString), \(startTimeString) - \(endTimeString)"
    }
    
    // Calculate price based on duration (in UAH)
    func calculatePrice(hourlyRate: Double = 300.0) -> Double {
        let duration = endTime.timeIntervalSince(startTime) / 3600 // in hours
        return duration * hourlyRate
    }
}

extension TimeSlot: Codable {
    enum CodingKeys: String, CodingKey {
        case id, teacherId, startTime, endTime, isBooked, bookedByUserId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        teacherId = try container.decode(String.self, forKey: .teacherId)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        isBooked = try container.decode(Bool.self, forKey: .isBooked)
        bookedByUserId = try container.decodeIfPresent(String.self, forKey: .bookedByUserId)
        documentRef = nil // This field isn't decoded
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(teacherId, forKey: .teacherId)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isBooked, forKey: .isBooked)
        try container.encodeIfPresent(bookedByUserId, forKey: .bookedByUserId)
        // documentRef is not encoded
    }
}

//
//
//import UIKit
//import FirebaseFirestore
//
//struct TimeSlot: Codable {
//    let startTime: Date
//    let endTime: Date
//    let isBooked: Bool
//
//    // Custom coding keys for Firestore compatibility
//    enum CodingKeys: String, CodingKey {
//        case startTime
//        case endTime
//        case isBooked
//    }
//
//    // Firestore timestamp representation
//    private struct FirestoreTimestamp: Decodable {
//        let seconds: Int64
//        let nanoseconds: Int32
//
//        var date: Date {
//            return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanoseconds) / 1_000_000_000)
//        }
//    }
//
//    // Custom decoder to handle Firestore Timestamps
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        // Try to decode as FirestoreTimestamp first
//        if let startTimestamp = try? container.decode(FirestoreTimestamp.self, forKey: .startTime) {
//            startTime = startTimestamp.date
//        } else {
//            startTime = try container.decode(Date.self, forKey: .startTime)
//        }
//
//        if let endTimestamp = try? container.decode(FirestoreTimestamp.self, forKey: .endTime) {
//            endTime = endTimestamp.date
//        } else {
//            endTime = try container.decode(Date.self, forKey: .endTime)
//        }
//
//        isBooked = try container.decode(Bool.self, forKey: .isBooked)
//    }
//
//    // Default initializer
//    init(startTime: Date, endTime: Date, isBooked: Bool = false) {
//        self.startTime = startTime
//        self.endTime = endTime
//        self.isBooked = isBooked
//    }
//
//    // To save a TimeSlot to Firebase
//    func saveTimeSlot(_ timeSlot: TimeSlot, for teacherId: String) {
//        let db = Firestore.firestore()
//        let data: [String: Any] = [
//            "startTime": Timestamp(date: timeSlot.startTime),
//            "endTime": Timestamp(date: timeSlot.endTime),
//            "isBooked": timeSlot.isBooked
//        ]
//
//        db.collection("teachers").document(teacherId).collection("timeSlots").addDocument(data: data)
//    }
//
//    // To fetch TimeSlots from Firebase
//    func fetchTimeSlots(for teacherId: String, completion: @escaping ([TimeSlot]) -> Void) {
//        let db = Firestore.firestore()
//        db.collection("teachers").document(teacherId).collection("timeSlots").getDocuments { snapshot, error in
//            guard let documents = snapshot?.documents, error == nil else {
//                completion([])
//                return
//            }
//
//            let timeSlots = documents.compactMap { document -> TimeSlot? in
//                guard
//                    let startTimestamp = document.get("startTime") as? Timestamp,
//                    let endTimestamp = document.get("endTime") as? Timestamp,
//                    let isBooked = document.get("isBooked") as? Bool
//                else {
//                    return nil
//                }
//
//                return TimeSlot(
//                    startTime: startTimestamp.dateValue(),
//                    endTime: endTimestamp.dateValue(),
//                    isBooked: isBooked
//                )
//            }
//
//            completion(timeSlots)
//        }
//    }
//}
