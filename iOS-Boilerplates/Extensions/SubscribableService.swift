//
//  SubscribableService.swift
//  tawk.ios
//
//  Created by Nazmul Islam on 15/3/22.
//  Copyright © 2022 tawk. All rights reserved.
//

import Foundation

protocol SubscribableService: AnyObject {
    associatedtype Subscriber

    var weakSubscribers: [String: (DispatchQueue?, Weak<Subscriber>)] { get set }

    /// Subscriber uses this method to subscribe for events
    /// - Parameters:
    ///   - queue: the queue on which event will be delivered to the subscriber, if nil event will be delivered on the queue it happend
    ///   - subscriber: subscriber who wants to receive events
    /// - Returns: Subscription that can be canceled by the subscriber at any moment. Subscriber must keep a strong reference to this subscription inorder to get any event. Failing to do so will immediately cancel the subscription. Subscriber does not need to call cancell when it is deallocated. When subscriber is deallocated subscription will be cancelled automatically.
    func subscribe(
        on queue: DispatchQueue?,
        _ subscriber: Subscriber
    ) -> CancellableSubscription
}

extension SubscribableService {
    func subscribe(
        on queue: DispatchQueue?,
        _ subscriber: Subscriber
    ) -> CancellableSubscription {
        
        let token = UUID().uuidString
        let weakSubscriber = Weak(subscriber)
        weakSubscribers[token] = (queue, weakSubscriber)
        print("Added subscriber for token: \(token)")
        let subscription = CancellableSubscription { [weak self] in
            // be cautious about what you capture here
            // capturing self or subscriber strongly will cause a memory leak
            self?.weakSubscribers.removeValue(forKey: token)
            print("Removed subscriber for token: \(token)")
        }
        return subscription
    }
    
    func subscribe(_ subscriber: Subscriber) -> CancellableSubscription {
        subscribe(on: nil, subscriber)
    }
    
    /// Helper method for the service to publish event on the queue subscriber propvided for receiving event
    /// - Parameter notificationTask: task needed be executed to notify the subscriber
    func notifySubscribers(
        _ notificationTask: @escaping (Subscriber) -> Void
    ) {
        for (queue, weakSubscriber) in self.weakSubscribers.values {
            guard let subscriber = weakSubscriber.reference else {
                continue
            }
            
            if let queue = queue {
                queue.async { notificationTask(subscriber) }
            } else {
                notificationTask(subscriber)
            }
        }
    }
}
