/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Flurry_iOS_SDK

class Analytics {

    static func startAppSession() {
        guard let apiPlistPath = Bundle.main.path(forResource: AppConstants.APIKEYS_PATH, ofType: "plist") else {
            fatalError("Unable to load API keys plist. Did you include the API keys plist file?")
        }

        let keysDict = NSDictionary(contentsOfFile: apiPlistPath) as! [String: String]
        guard let flurryKey = keysDict["FLURRY"] else {
            print("No Flurry key! Not collecting analytics.")
            return
        }
        Flurry.startSession(flurryKey)
        Flurry.logEvent(AnalyticsEvent.APP_INIT)
    }

    static func logEvent(event: String, params: [String: Any]) {
        Flurry.logEvent(event, withParameters: params)
    }

    static func startSession(sessionName: String, params: [String: Any]) {
        Flurry.logEvent(sessionName, withParameters: params, timed: true)
    }

    static func endSession(sessionName: String, params: [String: Any]) {
        Flurry.endTimedEvent(sessionName, withParameters: params)
    }
}

public struct AnalyticsEvent {
    static let APP_INIT = "app_init";

    static let SESSION_SUFFIX = "_session_duration"
    static let DETAILS_CARD_SESSION_DURATION   = "details_card" + SESSION_SUFFIX


    // Place Details
    static let YELP               = "yelp_link"
    static let YELP_TOGGLE        = "yelp_review_toggle"
    static let TRIPADVISOR        = "tripadvisor_link"
    static let WIKIPEDIA          = "wikipedia_link"
    static let WIKIPEDIA_TOGGLE   = "wikipedia_toggle"
    static let DIRECTIONS         = "directions_link"
    static let WEBSITE            = "website_link"
    static let MAP_BUTTON         = "map_button" // For returning to the Carousel
    static let NUM_CARDS          = "num_cards"
    static let CARD_INDEX         = "card_index"

    // Event Actions
    static let EVENT_BANNER_LINK  = "event_banner_link"
    static let EVENT_NOTIFICATION = "event_notification"

    static let PARAM_ACTION = "action"
}
