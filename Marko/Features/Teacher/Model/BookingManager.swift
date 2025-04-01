//
//  BookingManager.swift
//  Marko
//
//  Created by Ivan on 31.03.2025.
//

import UIKit
import FirebaseFirestore

class BookingManager {
    private let bookingRepository = BookingRepository()
    private let timeSlotRepository = TimeSlotRepository()
    
    // Callback for when booking status changes
    var onBookingStatusChanged: ((Bool, String, TimeSlot?) -> Void)?
    
    // Process a booking with validation
    func processBooking(teacher: Teacher, timeSlot: TimeSlot, userId: String) {
        // First check if the time slot is still available
        timeSlotRepository.fetchTimeSlots(for: teacher.id) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Find the time slot in the latest data
            if let updatedTimeSlot = timeSlots.first(where: { $0.id == timeSlot.id }) {
                // Verify it's not booked
                if updatedTimeSlot.isBooked {
                    self.onBookingStatusChanged?(false, "This time slot has already been booked.", nil)
                    return
                }
                
                // Process the booking
                self.bookingRepository.createBooking(
                    teacherId: teacher.id,
                    timeSlot: updatedTimeSlot,
                    userId: userId
                ) { success, bookingId in
                    if success {
                        self.onBookingStatusChanged?(true, "Booking confirmed! Your reference number is \(bookingId ?? "").", updatedTimeSlot)
                    } else {
                        self.onBookingStatusChanged?(false, "There was an error processing your booking. Please try again.", nil)
                    }
                }
            } else {
                self.onBookingStatusChanged?(false, "The selected time slot is no longer available.", nil)
            }
        }
    }
    
    // Get user's upcoming bookings
    func fetchUpcomingBookings(for userId: String, completion: @escaping ([Booking]) -> Void) {
        bookingRepository.fetchUserBookings(for: userId) { bookings in
            // Filter to only include future and confirmed bookings
            let now = Date()
            let upcomingBookings = bookings.filter { booking in
                return booking.timeSlot.startTime > now && booking.status == "confirmed"
            }
            
            // Sort by start time
            let sortedBookings = upcomingBookings.sorted { $0.timeSlot.startTime < $1.timeSlot.startTime }
            
            completion(sortedBookings)
        }
    }
    
    // Cancel a booking
    func cancelBooking(bookingId: String, completion: @escaping (Bool, String) -> Void) {
        bookingRepository.cancelBooking(bookingId: bookingId) { success in
            if success {
                completion(true, "Your booking has been cancelled successfully.")
            } else {
                completion(false, "There was an error cancelling your booking. Please try again.")
            }
        }
    }
}
