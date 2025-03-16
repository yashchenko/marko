
//  TimeSlot.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.


import UIKit
import FirebaseFirestore

struct TimeSlot: Codable {
    let startTime: Date
    let endTime: Date
    let isBooked: Bool
    
    // Custom coding keys for Firestore compatibility
    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
        case isBooked
    }
    
    // Firestore timestamp representation
    private struct FirestoreTimestamp: Decodable {
        let seconds: Int64
        let nanoseconds: Int32
        
        var date: Date {
            return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanoseconds) / 1_000_000_000)
        }
    }
    
    // Custom decoder to handle Firestore Timestamps
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode as FirestoreTimestamp first
        if let startTimestamp = try? container.decode(FirestoreTimestamp.self, forKey: .startTime) {
            startTime = startTimestamp.date
        } else {
            startTime = try container.decode(Date.self, forKey: .startTime)
        }
        
        if let endTimestamp = try? container.decode(FirestoreTimestamp.self, forKey: .endTime) {
            endTime = endTimestamp.date
        } else {
            endTime = try container.decode(Date.self, forKey: .endTime)
        }
        
        isBooked = try container.decode(Bool.self, forKey: .isBooked)
    }
    
    // Default initializer
    init(startTime: Date, endTime: Date, isBooked: Bool = false) {
        self.startTime = startTime
        self.endTime = endTime
        self.isBooked = isBooked
    }
    
    // To save a TimeSlot to Firebase
    func saveTimeSlot(_ timeSlot: TimeSlot, for teacherId: String) {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "startTime": Timestamp(date: timeSlot.startTime),
            "endTime": Timestamp(date: timeSlot.endTime),
            "isBooked": timeSlot.isBooked
        ]
        
        db.collection("teachers").document(teacherId).collection("timeSlots").addDocument(data: data)
    }
    
    // To fetch TimeSlots from Firebase
    func fetchTimeSlots(for teacherId: String, completion: @escaping ([TimeSlot]) -> Void) {
        let db = Firestore.firestore()
        db.collection("teachers").document(teacherId).collection("timeSlots").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                completion([])
                return
            }
            
            let timeSlots = documents.compactMap { document -> TimeSlot? in
                guard
                    let startTimestamp = document.get("startTime") as? Timestamp,
                    let endTimestamp = document.get("endTime") as? Timestamp,
                    let isBooked = document.get("isBooked") as? Bool
                else {
                    return nil
                }
                
                return TimeSlot(
                    startTime: startTimestamp.dateValue(),
                    endTime: endTimestamp.dateValue(),
                    isBooked: isBooked
                )
            }
            
            completion(timeSlots)
        }
    }
}
