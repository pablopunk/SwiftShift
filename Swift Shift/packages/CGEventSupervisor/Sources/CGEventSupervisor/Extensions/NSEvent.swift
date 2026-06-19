//
//  NSEvent.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation;

fileprivate var kSupervisedNSEventShouldCancelKey: String = "__SupervisedNSEventShouldCancel";

public extension NSEvent {
    
    /// If the event is supervised by `CGEventSupervisor`, setting this
    /// to `true` will stop the event from propagating to the next-installed
    /// callback and will prevent the event from reaching its intended target.
    ///
    internal var supervisorShouldCancel: Bool {
        set { objc_setAssociatedObject(
            self,
            &kSupervisedNSEventShouldCancelKey,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
        get { objc_getAssociatedObject(
            self,
            &kSupervisedNSEventShouldCancelKey
        ) as? Bool ?? false }
    }
    
    /// If the event is supervised by `CGEventSupervisor`, end
    /// propagation into the next subscriber and do not
    /// send the event to its user-intended target.
    ///
    func cancel() {
        self.supervisorShouldCancel = true;
    }
    
}
