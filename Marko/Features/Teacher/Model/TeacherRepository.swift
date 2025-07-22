//
//  TeacherRepository.swift
//  Marko
//
//  Created by Ivan on 15.03.2025.
//

import UIKit
import FirebaseFirestore

class TeacherRepository {
    private let db = Firestore.firestore()
    private let teachersCollection = "teachers"
    private let imageCache = NSCache<NSString, UIImage>()
    
    // Fetch all teachers from Firestore
    // New fetchTeachers in TeacherRepository.swift
    func fetchTeachers(completion: @escaping ([Teacher]) -> Void) {
         print("Repo: Fetching teachers from Firestore collection '\(teachersCollection)'...")
        db.collection(teachersCollection).getDocuments { snapshot, error in
            if let error = error {
                print("Repo Error: Failed fetching teachers: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                print("Repo: No teacher documents found.")
                completion([])
                return
            }
            print("Repo: Found \(documents.count) teacher documents.")

            var teachers: [Teacher] = []

            for document in documents {
                let documentId = document.documentID
                let data = document.data()

                guard
                    let name = data["name"] as? String,
                    let subject = data["subject"] as? String,
                    let description = data["description"] as? String,
                    let rank = data["rank"] as? String,
                    let profileImageURLString = data["profileImageURL"] as? String
                else {
                    print("Repo Warning: Skipping document \(documentId) due to missing/invalid fields. Data: \(data)")
                    continue
                }

                // Create the new, simpler Teacher object
                let teacher = Teacher(
                    id: documentId, name: name, subject: subject, description: description,
                    rank: rank, profileImageURL: profileImageURLString
                )
                teachers.append(teacher)
            }

            // Call completion right after the loop. No more waiting.
            print("Repo: Finished processing all teachers. Total: \(teachers.count)")
            completion(teachers)
        }
    }
    
    
    
    // Download image from URL
    // No need for [weak self] in the dataTask closure itself unless the TeacherRepository
    // could be deallocated *while* a download is in progress AND the closure held a strong ref.
    // Here, the capture is generally short-lived relative to the repository's lifetime.
    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Repo Error: Invalid image URL string: \(urlString)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Repo Error: Image download failed for \(url): \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Repo Error: Invalid HTTP response status (\(statusCode)) for \(url)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                print("Repo Error: No data or invalid image data received for \(url)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Success
            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.resume()
    }
}
