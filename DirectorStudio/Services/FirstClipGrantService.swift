import Foundation
import SwiftUI

// MARK: - First Clip Grant Service
@MainActor
public class FirstClipGrantService: ObservableObject {
    @Published var isClaiming = false
    @Published var claimError: String?
    @Published var hasClaimedFirstClip: Bool = false
    
    private let ledgerAPI = LedgerAPI.shared
    private let keychain = KeychainService.shared
    
    init() {
        loadClaimStatus()
    }
    
    // MARK: - Claim First Clip
    func claimIfEligible(siwaToken: String) async -> Bool {
        guard !hasClaimedFirstClip else {
            return false // Already claimed
        }
        
        isClaiming = true
        claimError = nil
        
        defer {
            isClaiming = false
        }
        
        do {
            let deviceId = getOrCreateDeviceId()
            let response = try await ledgerAPI.claimFirstClip(siwaToken: siwaToken, deviceId: deviceId)
            
            if response.granted {
                hasClaimedFirstClip = true
                saveClaimStatus(true)
                
                // Store the auth token for future use
                if let authToken = response.auth_token {
                    UserDefaults.standard.set(authToken, forKey: "auth_token")
                }
                
                return true
            } else {
                claimError = response.error ?? "Failed to claim first clip"
                return false
            }
        } catch {
            claimError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Device ID Management
    private func getOrCreateDeviceId() -> String {
        let key = "device_install_id"
        
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    // MARK: - Claim Status Persistence
    private func loadClaimStatus() {
        hasClaimedFirstClip = UserDefaults.standard.bool(forKey: "first_clip_claimed")
    }
    
    private func saveClaimStatus(_ claimed: Bool) {
        UserDefaults.standard.set(claimed, forKey: "first_clip_claimed")
    }
    
    // MARK: - Reset for Testing
    func resetClaimStatus() {
        hasClaimedFirstClip = false
        saveClaimStatus(false)
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "device_install_id")
    }
}
