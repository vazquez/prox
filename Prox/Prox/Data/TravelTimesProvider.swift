/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FirebaseRemoteConfig
import Foundation
import MapKit

struct TravelTimesProvider {

    static var MIN_WALKING_TIME: Int = {
        // Note that this is semantically maximum walking time, 
        // rather than minimum walking time (as used throughout the codebase).
        return RemoteConfigKeys.maxWalkingTimeInMins.value
    }()

    static var YOU_ARE_HERE_WALKING_TIME: Int = {
        return RemoteConfigKeys.youAreHereWalkingTimeMins.value
    }()

    private static func directions(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D, byTransitType transitType: MKDirectionsTransportType) -> MKDirections {

        let directionsRequest = MKDirectionsRequest()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: fromLocation, addressDictionary: nil))
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: toLocation, addressDictionary: nil))
        directionsRequest.departureDate = Date()
        directionsRequest.transportType = transitType

        return MKDirections(request: directionsRequest)
    }

    static func travelTime(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D, byTransitType transitType: MKDirectionsTransportType = .any, withCompletion completion: @escaping ((TravelTimes?) -> ())) {
        let directions = self.directions(fromLocation: fromLocation, toLocation: toLocation, byTransitType: transitType)
        directions.calculateETA { (response, error) in
            if let error = error {
                dump(error)
                completion(nil)
                return
            }
            guard let response = response else {
                return completion(nil)
            }
            let travelTime: TravelTimes?
            switch response.transportType {
            case MKDirectionsTransportType.automobile:
                travelTime = TravelTimes(walkingTime: nil, drivingTime: response.expectedTravelTime, publicTransportTime: nil)
            case MKDirectionsTransportType.transit:
                travelTime = TravelTimes(walkingTime: nil, drivingTime: nil, publicTransportTime: response.expectedTravelTime)
            case MKDirectionsTransportType.walking:
                travelTime = TravelTimes(walkingTime: response.expectedTravelTime, drivingTime: nil, publicTransportTime: nil)
            default:
                travelTime = nil
            }
            completion(travelTime)
        }
    }

    static func travelTime(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D, byTransitTypes transitTypes: [MKDirectionsTransportType], withCompletion completion: @escaping ((TravelTimes?) -> ())) {
        var allTimes = [TravelTimes?]()
        for transitType in transitTypes {
            self.travelTime(fromLocation: fromLocation, toLocation: toLocation, byTransitType: transitType) { (travelTime) in
                allTimes.append(travelTime)
                if allTimes.count == transitTypes.count {
                    var walking: TimeInterval?
                    var driving: TimeInterval?
                    var transit: TimeInterval?
                    for time in allTimes {
                        if let walkingTime = time?.walkingTime { walking = walkingTime }
                        else if let drivingTime = time?.drivingTime { driving = drivingTime }
                        else if let transitTime = time?.publicTransportTime { transit = transitTime }
                    }
                    if walking == nil && driving == nil && transit == nil {
                        return completion(nil)
                    }
                    return completion(TravelTimes(walkingTime: walking, drivingTime: driving, publicTransportTime: transit))
                }
            }
        }
    }

    static func canTravelFrom(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D, before: Date, withCompletion completion: @escaping (Bool) -> ()) {
        let timeInterval = before.timeIntervalSince(Date())
        TravelTimesProvider.travelTime(fromLocation: fromLocation, toLocation: toLocation, byTransitType: [.automobile], withCompletion: { (times) in
            guard let travelTimes = times,
                let drivingTime = travelTimes.drivingTime else {
                    return completion(false)
            }
            let travelTimePadding = RemoteConfigKeys.travelTimePaddingMins.value * 60
            completion((drivingTime + travelTimePadding)  <= timeInterval)
        })
    }
}

struct TravelTimes {
    let walkingTime: TimeInterval?
    let drivingTime: TimeInterval?
    let publicTransportTime: TimeInterval?
}
