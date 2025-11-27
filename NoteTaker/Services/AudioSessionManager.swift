//
//  AudioSessionManager.swift
//  NoteTaker
//
//  Created by onkar.rajput on 21/11/25.
//

import AVFoundation
import Foundation

protocol AudioSessionManaging: AnyObject {
    func configureSession() throws
    func deactivateSession()
    var interruptionHandler: ((AVAudioSession.InterruptionType) -> Void)? { get set }
    var routeChangeHandler: ((AVAudioSession.RouteChangeReason) -> Void)? { get set }
}

final class AudioSessionManager: AudioSessionManaging {
    private let session: AVAudioSession
    var interruptionHandler: ((AVAudioSession.InterruptionType) -> Void)?
    var routeChangeHandler: ((AVAudioSession.RouteChangeReason) -> Void)?

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configureSession() throws {
        try session.setCategory(.record)
        try session.setMode(.measurement)
        try session.setActive(true)
    }

    func deactivateSession() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: session)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let rawValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawValue)
        else { return }
        interruptionHandler?(type)
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let rawValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue)
        else { return }
        
        switch reason {
        case .oldDeviceUnavailable:
            routeChangeHandler?(reason)
        case .newDeviceAvailable, .categoryChange, .override, .wakeFromSleep, .noSuitableRouteForCategory, .routeConfigurationChange:
            break
        default:
            routeChangeHandler?(reason)
        }
    }
    
    private func describeRouteChange(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .unknown: return "unknown"
        case .newDeviceAvailable: return "new device available"
        case .oldDeviceUnavailable: return "old device unavailable"
        case .categoryChange: return "category change"
        case .override: return "override"
        case .wakeFromSleep: return "wake from sleep"
        case .noSuitableRouteForCategory: return "no suitable route"
        case .routeConfigurationChange: return "route configuration change"
        @unknown default: return "unknown(\(reason.rawValue))"
        }
    }
}

