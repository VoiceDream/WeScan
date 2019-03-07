//
//  CaptureSession.swift
//  WeScan
//
//  Created by Julian Schiavo on 23/9/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMotion

/// A class containing global variables and settings for this capture session
public final class CaptureSession {
    
    /// The possible states that the current device's flashlight can be in
    public enum FlashState {
        case on
        case off
        case unavailable
        case unknown
    }
    
    public static let current = CaptureSession()
    
    /// The AVCaptureDevice used for the flash and focus setting
    public var device: CaptureDevice?
    
    /// Whether the user is past the scanning screen or not (needed to disable auto scan on other screens)
    public var isEditing: Bool
    
    /// The status of auto scan. Auto scan tries to automatically scan a detected rectangle if it has a high enough accuracy.
    public var isAutoScanEnabled: Bool
    
    /// The orientation of the captured image
    public var editImageOrientation: CGImagePropertyOrientation
    
    private init(isAutoScanEnabled: Bool = true, editImageOrientation: CGImagePropertyOrientation = .up) {
        self.device = AVCaptureDevice.default(for: .video)
        
        self.isEditing = false
        self.isAutoScanEnabled = isAutoScanEnabled
        self.editImageOrientation = editImageOrientation
    }
    
    /// Toggles the current device's flashlight on or off.
    public func toggleFlash() -> FlashState {
        guard let device = device, device.isTorchAvailable else { return .unavailable }
        
        do {
            try device.lockForConfiguration()
        } catch {
            return .unknown
        }
        
        defer {
            device.unlockForConfiguration()
        }
        
        if device.torchMode == .on {
            device.torchMode = .off
            return .off
        } else if device.torchMode == .off {
            device.torchMode = .on
            return .on
        }
        
        return .unknown
    }
    
    /// Sets the camera's exposure and focus point to the given point
    public func setFocusPointToTapPoint(_ tapPoint: CGPoint) throws {
        guard let device = device else {
            let error = ImageScannerControllerError.inputDevice
            throw error
        }
        
        try device.lockForConfiguration()
        
        defer {
            device.unlockForConfiguration()
        }
        
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = tapPoint
            device.focusMode = .autoFocus
        }
        
        if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposurePointOfInterest = tapPoint
            device.exposureMode = .continuousAutoExposure
        }
    }
    
    /// Resets the camera's exposure and focus point to automatic
    public func resetFocusToAuto() throws {
        guard let device = device else {
            let error = ImageScannerControllerError.inputDevice
            throw error
        }
        
        try device.lockForConfiguration()
        
        defer {
            device.unlockForConfiguration()
        }
        
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
    }
    
    /// Removes an existing focus rectangle if one exists, optionally animating the exit
    public func removeFocusRectangleIfNeeded(_ focusRectangle: FocusRectangleView?, animated: Bool) {
        guard let focusRectangle = focusRectangle else { return }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                focusRectangle.alpha = 0.0
            }, completion: { (_) in
                focusRectangle.removeFromSuperview()
            })
        } else {
            focusRectangle.removeFromSuperview()
        }
    }
    
    public func setImageOrientation() {
        let motion = CMMotionManager()
        
        /// This value should be 0.2, but since we only need one cycle (and stop updates immediately),
        /// we set it low to get the orientation immediately
        motion.accelerometerUpdateInterval = 0.01
        
        guard motion.isAccelerometerAvailable else { return }
        
        motion.startAccelerometerUpdates(to: OperationQueue()) { data, error in
            guard let data = data, error == nil else { return }
            
            /// The minimum amount of sensitivity for the landscape orientations
            /// This is to prevent the landscape orientation being incorrectly used
            /// Higher = easier for landscape to be detected, lower = easier for portrait to be detected
            let motionThreshold = 0.35
            
            if data.acceleration.x >= motionThreshold {
                self.editImageOrientation = .left
            } else if data.acceleration.x <= -motionThreshold {
                self.editImageOrientation = .right
            } else {
                /// This means the device is either in the 'up' or 'down' orientation, BUT,
                /// it's very rare for someone to be using their phone upside down, so we use 'up' all the time
                /// Which prevents accidentally making the document be scanned upside down
                self.editImageOrientation = .up
            }
            
            motion.stopAccelerometerUpdates()
            
            // If the device is reporting a specific landscape orientation, we'll use it over the accelerometer's update.
            // We don't use this to check for "portrait" because only the accelerometer works when portrait lock is enabled.
            // For some reason, the left/right orientations are incorrect (flipped) :/
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                self.editImageOrientation = .right
            case .landscapeRight:
                self.editImageOrientation = .left
            default:
                break
            }
        }
    }
}
