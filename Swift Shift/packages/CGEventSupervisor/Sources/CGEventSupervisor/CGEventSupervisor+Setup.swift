//
//  CGEventSupervisor+Setup.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation;

extension CGEventSupervisor {

    /// Setup the event tap and receiving mach port for subscription
    /// to the currently-subscribed event types.
    ///
    internal func setup() {
        self.teardown();
        
        if self.totalSubscribers == 0 { return }
        
        guard let eventTapMachPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: self.eventMask,
            callback: CGEventSupervisorCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[CGEventSupervisor]: Could not allocate the required mach port for CGEventTap.")
            return;
        }
        
        let runLoop = CFRunLoopGetCurrent();
        let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTapMachPort, 0);
        
        CFRunLoopAddSource(runLoop, runLoopSrc, .commonModes);
        CGEvent.tapEnable(tap: eventTapMachPort, enable: true);
        
        self.eventTapMachPort = eventTapMachPort;
        self.eventTapRunLoopSource = runLoopSrc;
    }
    
    /// Disable the event tap, and dispose of the receiving mach port.
    ///
    internal func teardown() {
        if let src = self.eventTapRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
            self.eventTapRunLoopSource = nil
        }
        guard let eventTapMachPort = self.eventTapMachPort else { return }
        CGEvent.tapEnable(tap: eventTapMachPort, enable: false);
        CFMachPortInvalidate(eventTapMachPort)
        self.eventTapMachPort = nil;
    }

    /// The `CGEventTap` mask/filter.
    ///
    var eventMask: CGEventMask {
        CGEventMask(self.subscribedEvents.reduce(0, {
            $0 | (1 << $1.rawValue)
        }))
    }
    
}
