//
//  CGEventSupervisor+Types.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation;

// MARK: - Subscribers

public extension CGEventSupervisor {
    
    typealias NSEventCallback = (_ event: NSEvent) -> Void
    typealias CGEventCallback = (_ event: CGEvent) -> Void
    
    typealias NSEventSubscriber = (callback: NSEventCallback, events: [CGEventType]);
    typealias CGEventSubscriber = (callback: CGEventCallback, events: [CGEventType]);
    
    typealias NSEventSubscriberStore = [String: NSEventSubscriber];
    typealias CGEventSubscriberStore = [String: CGEventSubscriber];

}

// MARK: - Events

public extension CGEventSupervisor {
    
    /// A type which describes both the events to which a subscriber
    /// will subscribe as well as the format in which the event is
    /// expected — `NSEvent` or `CGEvent`.
    ///
    struct EventDescriptor<T>: RawRepresentable {
        public var rawValue: [CGEventType];
        
        public init(rawValue: [CGEventType]) {
            self.rawValue = rawValue;
        }
    }
    
}

//MARK: - CGEvent

public extension CGEventSupervisor.EventDescriptor where T == CGEventType {
    
    /// The subscriber receives events from the `CGEventTap` which are of the
    /// given event types.
    ///
    static func cgEvents(_ events: CGEventType...) -> Self {
        .init(rawValue: events)
    }
    
}

// MARK: - NSEvent

public extension CGEventSupervisor.EventDescriptor where T == NSEvent.EventType {
    
    /// The subscriber receives events from the `CGEventTap` which are of the
    /// given universal event types and which have been cast to `NSEvent`.
    ///
    static func nsEvents(_ events: UniversalEventType...) -> Self {
        .init(rawValue: events.compactMap({ CGEventType(rawValue: $0.rawValue)} ))
    }
    
    /// Events available in both the `CGEventType` and `NSEvent.EventType`
    /// enumerations.
    ///
    enum UniversalEventType: UInt32 {
        /* Mouse events. */
        case     leftMouseDown = 1;
        case       leftMouseUp = 2;
        case    rightMouseDown = 3;
        case      rightMouseUp = 4;
        case        mouseMoved = 5;
        case  leftMouseDragged = 6;
        case rightMouseDragged = 7;
        
        /* Keyboard events. */
        case      keyDown = 10;
        case        keyUp = 11;
        case flagsChanged = 12;
        
        /* Specialized control devices. */
        case       scrollWheel = 22;
        case     tabletPointer = 23;
        case   tabletProximity = 24;
        case    otherMouseDown = 25;
        case      otherMouseUp = 26;
        case otherMouseDragged = 27;
    }
    
}

