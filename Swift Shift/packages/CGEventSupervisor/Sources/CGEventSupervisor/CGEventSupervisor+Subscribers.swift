//
//  CGEventSupervisor+Subscribers.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation;

// MARK: - Subscribe/Unsubscribe

public extension CGEventSupervisor {
    
    /// Register a subscription to global `NSEvent` events of
    /// the given type.
    /// - Parameters:
    ///   - subscriber: The unique name of the subscriber.
    ///   - events: The event types to which the subscriber will subscribe.
    ///   - callback: The callback which will handle the subscribed event types.
    func subscribe(
        as subscriber: String,
        to events: EventDescriptor<NSEvent.EventType>,
        using callback: @escaping NSEventCallback
    ) {
        if events.rawValue.isEmpty { return }
        
        let needsSetup = !events.rawValue.allSatisfy({
            self.subscribedEvents.contains($0)
        });
        
        self.__nsEventSubscribers.updateValue(
            (callback, events.rawValue), forKey: subscriber);
        
        if needsSetup { self.setup() }
    }
    
    /// Register a subscription to global `CGEvent` events of
    /// the given type.
    /// - Parameters:
    ///   - subscriber: The unique name of the subscriber.
    ///   - events: The event types to which the subscriber will subscribe.
    ///   - callback: The callback which will handle the subscribed event types.
    func subscribe(
        as subscriber: String,
        to events: EventDescriptor<CGEventType>,
        using callback: @escaping CGEventCallback
    ) {
        if events.rawValue.isEmpty { return }
        
        let needsSetup = !events.rawValue.allSatisfy({
            self.subscribedEvents.contains($0)
        });
        
        self.__cgEventSubscribers.updateValue(
            (callback, events.rawValue), forKey: subscriber);
        
        if needsSetup { self.setup() }
    }
    
    /// Cancel the named subscriber's event subscription.
    ///
    func cancel(subscriber: String) {
        let preSubscribedEvents = self.subscribedEvents;
        
        self.__nsEventSubscribers.removeValue(forKey: subscriber);
        self.__cgEventSubscribers.removeValue(forKey: subscriber);
        
        let postSubscribedEvents = self.subscribedEvents;
        let needsSetup = !preSubscribedEvents.allSatisfy({
            postSubscribedEvents.contains($0)
        });
        
        /// Remove events from the mask which no longer
        /// have any subscribers, or disable the tap if
        /// no subscribers remain.
        ///
        if needsSetup { self.setup() }
    }
    
    /// Cancel all event subscriptions and dispose of the `CGEventTap`.
    ///
    func cancelAll() {
        self.__cgEventSubscribers.removeAll();
        self.__nsEventSubscribers.removeAll();
        
        self.teardown();
    }
    
}

// MARK: - Computed

public extension CGEventSupervisor {
    
    /// All event types having at least one subscriber.
    ///
    var subscribedEvents: [CGEventType] {
        var allEvents = self.nsEventSubscribers.values.flatMap({ $0.events });
        allEvents.append(contentsOf: self.cgEventSubscribers.values.flatMap({ $0.events }));
        
        var uniqueEvents = [CGEventType]();
        for event in allEvents {
            if uniqueEvents.contains(event) { continue }
            uniqueEvents.append(event);
        }
        
        return uniqueEvents;
    }
    
    /// The total number of event subscribers.
    ///
    var totalSubscribers: Int {
        self.nsEventSubscribers.count + self.cgEventSubscribers.count
    }
    
}

