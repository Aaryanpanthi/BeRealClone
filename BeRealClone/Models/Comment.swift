//
//  Comment.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/9/26.
//

import Foundation
import ParseSwift

struct Comment: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom properties
    var text: String?
    var user: User?
    var post: Pointer<Post>?
}
