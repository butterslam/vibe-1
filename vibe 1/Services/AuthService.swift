import Foundation
import FirebaseAuth
import FirebaseFirestore

struct AuthService {
    private let db = Firestore.firestore()

    func signUp(email: String, password: String, username: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        try await db.collection("users").document(uid).setData([
            "uid": uid,
            "email": email.lowercased(),
            "username": username.lowercased(),
            "avatarURL": "",
            "createdAt": FieldValue.serverTimestamp()
        ])
        try await db.collection("usernames").document(username.lowercased()).setData(["uid": uid], merge: true)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
}



