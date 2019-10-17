//
//  HeartbeatServiceBTKit.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/17/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation
import BTKit
import UserNotifications

class HeartbeatServiceBTKit: HeartbeatService {
    
    static let shared = HeartbeatServiceBTKit()
    
    private let heartbeatPersistence: HeartbeatPersistence = HeartbeatPersistenceUserDefaults.shared
    
    private var tokens = [String: ObservationToken]()
    
    func subscribe(to uuid: String) {
        heartbeatPersistence.persist(uuid: uuid)
        startListening(to: uuid)
    }
    
    func unsubscribe(from uuid: String) {
        heartbeatPersistence.remove(uuid: uuid)
        stopListening(to: uuid)
    }
    
    func restore() {
        heartbeatPersistence.all()?.forEach({ (uuid) in
            startListening(to: uuid)
        })
    }
    
    func isSubscribed(uuid: String) -> Bool {
        return heartbeatPersistence.contains(uuid: uuid)
    }
    
    private func startListening(to uuid: String) {
        tokens[uuid] = BTKit.background.ruuvi.heartbeat(for: self, uuid: uuid) { (observer, result) in
            switch result {
            case .success(let ruuviTag):
                print(ruuviTag)
                
                let content = UNMutableNotificationContent()
                content.title = "Heartbeat"
                content.body = ruuviTag.uuid
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func stopListening(to uuid: String) {
        tokens[uuid]?.invalidate()
        tokens.removeValue(forKey: uuid)
    }
}
