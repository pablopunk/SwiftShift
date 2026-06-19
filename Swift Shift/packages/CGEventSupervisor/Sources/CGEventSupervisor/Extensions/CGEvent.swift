//
//  CGEvent.swift
//  
//
//  Created by Stephan Casas on 8/6/23.
//

import Cocoa;
import Foundation

fileprivate var kSupervisedCGEventShouldCancelKey: String = "__SupervisedCGEventShouldCancel";

public extension CGEvent {
    
    /// If the event is supervised by `CGEventSupervisor`, setting this
    /// to `true` will stop the event from propagating to the next-installed
    /// callback and will prevent the event from reaching its intended target.
    ///
    internal var supervisorShouldCancel: Bool {
        set { objc_setAssociatedObject(
            self,
            &kSupervisedCGEventShouldCancelKey,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
        get { objc_getAssociatedObject(
            self,
            &kSupervisedCGEventShouldCancelKey
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
