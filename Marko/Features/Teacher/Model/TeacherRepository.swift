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
    func fetchTeachers(completion: @escaping ([Teacher]) -> Void) {
        print("Repo: Fetching teachers from Firestore collection '\(teachersCollection)'...")
        print("4. REPOSITORY: ViewModel запросил у меня учителей. Сейчас я запрошу их у Firebase.")
        
        // Use [weak self] because the completion handler of getDocuments could potentially
        // create a retain cycle if it strongly captures self and self holds a reference back
        // (less likely here, but good practice for escaping network closures)
        db.collection(teachersCollection).getDocuments { [weak self] snapshot, error in
            guard let self = self else { // Safely unwrap weak self
                print("Repo Warning: self was deallocated before fetchTeachers completion.")
                completion([])
                return
            }
            
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
            let group = DispatchGroup()
            
            for document in documents {
                let documentId = document.documentID
                let data = document.data()
                // print("Repo: Processing document \(documentId)...") // Verbose log
                
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
                
                var teacher = Teacher(
                    id: documentId, name: name, subject: subject, description: description,
                    rank: rank, profileImageURL: profileImageURLString
                )
                
                group.enter()
                let cacheKey = profileImageURLString as NSString
                
                if let cachedImage = self.imageCache.object(forKey: cacheKey) {
                    // print("Repo: Image cache HIT for \(name)") // Verbose log
                    teacher.profileImage = cachedImage
                    teachers.append(teacher)
                    group.leave()
                } else {
                    // print("Repo: Image cache MISS for \(name). Downloading...") // Verbose log
                    // **FIX:** No need for [weak self] inside the downloadImage completion handler
                    // because `self` here refers to the `TeacherRepository` instance which is
                    // likely alive for the duration. The outer closure already handles the weak ref.
                    self.downloadImage(from: profileImageURLString) { downloadedImage in
                        if let img = downloadedImage {
                            teacher.profileImage = img
                            self.imageCache.setObject(img, forKey: cacheKey) // Use unwrapped self
                            // print("Repo: Image downloaded and cached for \(name).") // Verbose log
                        } else {
                            print("Repo Warning: Image download failed for \(name). Using placeholder.")
                        }
                        teachers.append(teacher)
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("Repo: Finished processing all teachers. Total: \(teachers.count)")
                completion(teachers)
                print("5. РЕПОЗИТОРИЙ: Firebase предоставил мне данные! Я возвращаю их в ViewModel.")
                
            }
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
