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
    
    // Fetch all teachers
    func fetchTeachers(completion: @escaping ([Teacher]) -> Void) {
        db.collection("teachers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching teachers: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            print("Found \(documents.count) teachers")
            
            var teachers: [Teacher] = []
            let group = DispatchGroup()
            
            for document in documents {
                group.enter()
                let data = document.data()
                
                print("Processing document: \(document.documentID)")
                print("Document data: \(data)")
                
                guard
                    let name = data["name"] as? String,
                    let subject = data["subject"] as? String,
                    let description = data["description"] as? String,
                    let rank = data["rank"] as? String,
                    let profileImageURL = data["profileImageURL"] as? String
                else {
                    print("Missing required fields in document: \(document.documentID)")
                    group.leave()
                    continue
                }
                
                let teacher = Teacher(
                    id: document.documentID,
                    name: name,
                    subject: subject,
                    description: description,
                    rank: rank,
                    profileImageURL: profileImageURL
                )
                
                // Download image
                self.downloadImage(from: profileImageURL) { image in
                    var teacherWithImage = teacher
                    teacherWithImage.profileImage = image ?? UIImage(named: "placeholder_teacher") ?? UIImage()
                    teachers.append(teacherWithImage)
                    print("Added teacher: \(teacherWithImage.name) with image: \(image != nil ? "Yes" : "No")")
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("Finished loading \(teachers.count) teachers")
                completion(teachers)
            }
        }
    }
    
    // Download image from URL
    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        print("Downloading image from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("No data received for image")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            print("Image data received: \(data.count) bytes")
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                completion(image)
            }
        }.resume()
    }
}
