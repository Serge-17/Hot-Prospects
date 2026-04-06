//
//  Prospect.swift
//  Hot Prospects
//
//  Created by Serge Eliseev on 04.02.2026.
//

import SwiftUI
import SwiftData

@Model
class Prospect {
    var name: String
    var emailAddress: String
    var isContacted: Bool
    var lastContacted: Date?
    
    init(name: String, emailAddress: String, isContacted: Bool, lastContacted: Date? = nil) {
        self.name = name
        self.emailAddress = emailAddress
        self.isContacted = isContacted
        self.lastContacted = lastContacted
    }
}
