//
//  Constants.swift
//  crushd
//
//  Created by Don Sirivat on 1/19/18.
//  Copyright © 2018 Don Sirivat. All rights reserved.
//

import Foundation
import Firebase

struct Constants {
    struct refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
