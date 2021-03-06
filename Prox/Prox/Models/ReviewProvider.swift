/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Firebase

class ReviewProvider {

    let url: String

    // Optional values.
    let rating: Float?
    let reviews: [String]?
    let totalReviewCount: Int?

    init(url: String, rating: Float? = nil, reviews: [String]? = nil, totalReviewCount: Int? = nil) {
        self.url = url
        self.rating = rating
        self.reviews = reviews
        self.totalReviewCount = totalReviewCount
    }

    convenience init?(fromFirebaseSnapshot data: FIRDataSnapshot) {
        guard data.exists(), data.hasChildren(),
                let value = data.value as? NSDictionary,
                let url = value["url"] as? String else {
            return nil
        }

        self.init(url: url, rating: value["rating"] as? Float, reviews: [], totalReviewCount: value["totalReviewCount"] as? Int)
    }
}
