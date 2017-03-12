//
//  SettingsManager.swift
//  SpeechPlayground
//
//  Created by Martin Mitrevski on 11/03/17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import UIKit

class SettingsManager: NSObject {
    
    static let volumeKey = "volume"
    static let pitchKey = "pitch"
    static let delayKey = "delay"
    static let rateKey = "rate"
    static let languageKey = "language"
    
    class func currentVolume() -> Float {
        return self.valueFor(key: volumeKey, defaultValue: Float(0.9)) as! Float
    }
    
    class func setVolume(value: Float) {
        self.set(value: value, key: volumeKey)
    }
    
    class func currentPitch() -> Float {
        return self.valueFor(key: pitchKey, defaultValue: Float(1)) as! Float
    }
    
    class func setPitch(value: Float) {
        self.set(value: value, key: pitchKey)
    }
    
    class func currentDelay() -> Double {
        return self.valueFor(key: delayKey, defaultValue: 0.0) as! Double
    }
    
    class func setDelay(value: Double) {
        self.set(value: value, key: delayKey)
    }
    
    class func currentRate() -> Float {
        return self.valueFor(key: rateKey, defaultValue: Float(0.5)) as! Float
    }
    
    class func setRate(value: Float) {
        self.set(value: value, key: rateKey)
    }
    
    class func languageCode() -> String {
        return self.valueFor(key: languageKey, defaultValue: "en-US") as! String
    }
    
    class func setLanguageCode(value: String) {
        self.set(value: value, key: languageKey)
    }
    
    class private func valueFor(key: String, defaultValue: Any) -> Any {
        if let value = UserDefaults.standard.value(forKey: key) {
            return value
        }
        return defaultValue
    }
    
    class private func set(value: Any, key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
}
