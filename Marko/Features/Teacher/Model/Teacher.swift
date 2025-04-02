//
//  Teacher.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

struct Teacher {
    let id: String // Firestore Document ID
    let name: String
    let subject: String
    let description: String
    let rank: String
    let profileImageURL: String
    var profileImage: UIImage // Keep the downloaded image

    // Initializer provides a default placeholder image
    // This default is used if the image download fails or before it completes.
    init(id: String, name: String, subject: String, description: String, rank: String, profileImageURL: String, profileImage: UIImage = UIImage(systemName: "person.crop.circle.fill")!) {
        self.id = id
        self.name = name
        self.subject = subject
        self.description = description
        self.rank = rank
        self.profileImageURL = profileImageURL
        self.profileImage = profileImage
    }
}
