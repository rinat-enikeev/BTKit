//
//  RuuviDaemoniOS13.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/18/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation
import BackgroundTasks
import BTKit

class RuuviTaskDaemoniOS13: RuuviTaskDaemon {
    
    static let shared = RuuviTaskDaemoniOS13()
    
    private let id = "io.btkit.BTKitTester.RuuviTaskDaemoniOS13"
    private let queue = DispatchQueue(label: "RuuviTaskDaemoniOS13", qos: .background)
    private let scanner = BTKit.backgroundScanner(for: RuuviNUSService())
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: queue) { task in
            self.listenToAdvertisements(in: task as! BGAppRefreshTask)
        }
    }
    
    func schedule() {
        queue.async {
            let request = BGAppRefreshTaskRequest(identifier: self.id)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func listenToAdvertisements(in task: BGAppRefreshTask) {
        schedule()
        
        LocalNotification.shared.show(title: "Background", body: "Called")
        
        let heartbeatPersistence = HeartbeatPersistenceUserDefaults.shared
        var tokens = [ObservationToken]()
        heartbeatPersistence.all()?.forEach({ (uuid) in
            tokens.append(scanner.connect(self, uuid: uuid, connected: { (observer, error) in
                LocalNotification.shared.show(title: "Connected", body: "Daemon")
                task.setTaskCompleted(success: true)
            }, heartbeat: { (observer, data, error) in
                LocalNotification.shared.show(title: "Heartbeat", body: "Daemon")
                task.setTaskCompleted(success: true)
            }, disconnected: { (observer, error) in
                LocalNotification.shared.show(title: "Disconnected", body: "Daemon")
                task.setTaskCompleted(success: true)
            }))
        })
        
        task.expirationHandler = {
            tokens.forEach({ $0.invalidate() })
        }
    }
}
