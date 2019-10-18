//
//  NotificationsService.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/18/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation
import UserNotifications

class LocalNotification {
    static let shared = LocalNotification()
    
    func show(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
