//
//  AuthManager.swift
//  vibe 1
//awdawdawdawdawdawdawdawd
//  Created by Jamie Cheatham on 10/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // Method to force sign out (useful for development/testing)
    func forceSignOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "UserUsername")
        } catch {
            print("Error force signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create user with email and password
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            
            // Create user profile in Firestore
            try await createUserProfile(uid: user.uid, email: email, username: username)
            
            // Update local username
            UserDefaults.standard.set(username, forKey: "UserUsername")
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Load user profile and username
            try await loadUserProfile(uid: authResult.user.uid)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "UserUsername")
    }
    
    // MARK: - User Profile Management
    
    private func createUserProfile(uid: String, email: String, username: String) async throws {
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "username": username.lowercased(),
            "displayName": username,
            "avatarURL": "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Save to users collection
        try await db.collection("users").document(uid).setData(userData)
        
        // Save to usernames collection for search
        try await db.collection("usernames").document(username.lowercased()).setData([
            "uid": uid
        ])
    }
    
    private func loadUserProfile(uid: String) async throws {
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard let data = document.data(),
              let username = data["username"] as? String else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        // Update local username
        UserDefaults.standard.set(username, forKey: "UserUsername")
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
}
