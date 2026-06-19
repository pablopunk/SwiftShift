//
//  CGEventSupervisor.swift
//
//  Created by Stephan Casas on 4/24/23.
//

import Foundation;

public class CGEventSupervisor {
    
    public static let shared = CGEventSupervisor();
    
    // MARK: - Public
    
    var nsEventSubscribers: NSEventSubscriberStore { self.__nsEventSubscribers }
    var cgEventSubscribers: CGEventSubscriberStore { self.__cgEventSubscribers }
    
    // MARK: - Internal
    
    internal var     eventTapMachPort:            CFMachPort? = nil;
    internal var     eventTapRunLoopSource:        CFRunLoopSource? = nil;
    internal var __nsEventSubscribers: NSEventSubscriberStore = [:];
    internal var __cgEventSubscribers: CGEventSubscriberStore = [:];
    
}
