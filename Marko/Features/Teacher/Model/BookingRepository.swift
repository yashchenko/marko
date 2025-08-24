//
//  BookingRepository.swift
//  Marko
//
//  Created by You on 2025-08-23.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BookingRepository {
    private let db = Firestore.firestore()

    init() {}

    func fetchUserBookings(for userId: String, completion: @escaping ([Booking]) -> Void) {
        let bookingsRef = db.collection("users").document(userId).collection("bookings")
        let q = bookingsRef.order(by: "createdAt", descending: false)

        q.getDocuments { (snapshot, error) in
            if let error = error {
                print("BookingRepository: Error fetching bookings: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let docs = snapshot?.documents else {
                completion([])
                return
            }

            var bookings: [Booking] = []
            let group = DispatchGroup()

            for doc in docs {
                guard let teacherId = doc.data()["teacherId"] as? String,
                      let timeSlotId = doc.data()["timeSlotId"] as? String
                else {
                    continue
                }

                group.enter()
                let teacherSlotRef = self.db.collection("teachers").document(teacherId).collection("timeSlots").document(timeSlotId)
                teacherSlotRef.getDocument { (tsSnap, tsError) in
                    var tsModel: TimeSlot? = nil
                    if let tsSnap = tsSnap, tsSnap.exists {
                        tsModel = TimeSlot(document: tsSnap)
                    } else {
                        let fallbackRef = self.db.collection("timeSlots").document(timeSlotId)
                        fallbackRef.getDocument { (fallbackSnap, fallbackError) in
                            if let fallbackSnap = fallbackSnap, fallbackSnap.exists {
                                tsModel = TimeSlot(document: fallbackSnap)
                            }
                            if let booking = Booking(document: doc, timeSlot: tsModel) {
                                bookings.append(booking)
                            } else {
                                print("BookingRepository: Could not map booking doc \(doc.documentID)")
                            }
                            group.leave()
                        }
                        return
                    }

                    if let booking = Booking(document: doc, timeSlot: tsModel) {
                        bookings.append(booking)
                    } else {
                        print("BookingRepository: Could not map booking doc \(doc.documentID)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let sorted = bookings.sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
                completion(sorted)
            }
        }
    }

    func createBooking(teacherId: String,
                       timeSlot: TimeSlot,
                       userId: String,
                       paymentAmount: Double? = nil,
                       completion: @escaping (_ success: Bool, _ bookingId: String?, _ errorMessage: String?) -> Void) {

        let newBookingRef = db.collection("users").document(userId).collection("bookings").document()
        let bookingId = newBookingRef.documentID
        let timeSlotRef = db.collection("timeSlots").document(timeSlot.id)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let timeSlotSnapshot: DocumentSnapshot
            do {
                try timeSlotSnapshot = transaction.getDocument(timeSlotRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard timeSlotSnapshot.exists, let slotData = timeSlotSnapshot.data() else {
                let err = NSError(domain: "BookingRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Time slot not found"])
                errorPointer?.pointee = err
                return nil
            }

            let existingBookedBy = slotData["bookedBy"] as? String
            let isBooked = slotData["isBooked"] as? Bool ?? false

            if existingBookedBy != nil || isBooked {
                let err = NSError(domain: "BookingRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Time slot already booked"])
                errorPointer?.pointee = err
                return nil
            }

            let computedPayment: Double
            if let p = paymentAmount {
                computedPayment = p
            } else {
                computedPayment = timeSlot.calculatePrice()
            }

            let timeSlotUpdate: [String: Any] = [
                "bookedBy": userId,
                "isBooked": true,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            transaction.updateData(timeSlotUpdate, forDocument: timeSlotRef)

            let bookingData: [String: Any] = [
                "userId": userId,
                "teacherId": teacherId,
                "timeSlotId": timeSlot.id,
                "paymentAmount": computedPayment,
                "status": "confirmed",
                "createdAt": FieldValue.serverTimestamp()
            ]
            transaction.setData(bookingData, forDocument: newBookingRef)

            return nil
        }, completion: { (result, error) in
            if let error = error {
                completion(false, nil, error.localizedDescription)
            } else {
                completion(true, bookingId, nil)
            }
        })
    }
}
