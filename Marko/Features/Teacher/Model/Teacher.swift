//
//  Teacher.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit

struct Teacher {
    let id: String
    let name: String
    let subject: String
    let description: String
    let rank: String
    let profileImageURL: String

    // The initializer no longer deals with UIImages at all.
    // It just takes the data.
    init(id: String, name: String, subject: String, description: String, rank: String, profileImageURL: String) {
        self.id = id
        self.name = name
        self.subject = subject
        self.description = description
        self.rank = rank
        self.profileImageURL = profileImageURL
    }
}
