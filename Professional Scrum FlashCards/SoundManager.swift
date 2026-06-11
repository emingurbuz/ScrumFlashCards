//
//  SoundManager.swift
//  Scrum FlashCards
//

import Foundation
import AudioToolbox

class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    func playCorrect() {
        // System sound IDs:
        // 1025: Tinker (soft)
        // 1057: Buffering (default success)
        // 1325: Mail sent
        // 1407: Fanfare (Encouraging)
        // 1109: Photo Shutter (Click)
        // 1013: New Mail
        AudioServicesPlaySystemSound(1407)
    }
    
    func playIncorrect() {
        // System sound IDs:
        // 1053: Pulse (Default failure)
        // 1051: Bloom (Soft)
        // 1073: Alert (Sharp)
        AudioServicesPlaySystemSound(1053)
    }
}
