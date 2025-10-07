import Foundation
import FirebaseFirestore

struct AlliesService {
    struct User: Identifiable {
        let id: String
        let username: String
        let avatarURL: String?
    }

    private let db = Firestore.firestore()

    func upsertUser(uid: String, username: String, avatarURL: String?) async throws {
        let userRef = db.collection("users").document(uid)
        let unameRef = db.collection("usernames").document(username.lowercased())

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let unameSnap = try transaction.getDocument(unameRef)
                    if let data = unameSnap.data(), let existing = data["uid"] as? String, existing != uid {
                        let err = NSError(domain: "username", code: 409, userInfo: [NSLocalizedDescriptionKey: "Username taken"])
                        errorPointer?.pointee = err
                        return nil
                    }

                    transaction.setData([
                        "uid": uid,
                        "username": username.lowercased(),
                        "avatarURL": avatarURL ?? "",
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: userRef, merge: true)

                    transaction.setData(["uid": uid], forDocument: unameRef, merge: true)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                return nil
            }, completion: { _, error in
                if let error = error { cont.resume(throwing: error) } else { cont.resume(returning: ()) }
            })
        }
    }

    func searchUsers(prefix: String, limit: Int = 20) async throws -> [User] {
        guard !prefix.isEmpty else { return [] }
        let q = db.collection("users")
            .order(by: "username")
            .start(at: [prefix.lowercased()])
            .end(at: [prefix.lowercased() + "\u{f8ff}"])
            .limit(to: limit)
        let snap = try await q.getDocuments()
        return snap.documents.map { doc in
            let data = doc.data()
            return User(
                id: data["uid"] as? String ?? doc.documentID,
                username: (data["username"] as? String ?? "").lowercased(),
                avatarURL: (data["avatarURL"] as? String)?.isEmpty == true ? nil : (data["avatarURL"] as? String)
            )
        }
    }

    func addAlly(userId: String, allyId: String) async throws {
        try await db.collection("allies").addDocument(data: [
            "userId": userId,
            "allyId": allyId,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func fetchAllies(for uid: String) async throws -> [String] {
        async let s1 = db.collection("allies").whereField("userId", isEqualTo: uid).getDocuments()
        async let s2 = db.collection("allies").whereField("allyId", isEqualTo: uid).getDocuments()
        let (r1, r2) = try await (s1, s2)
        let ids1 = r1.documents.compactMap { $0["allyId"] as? String }
        let ids2 = r2.documents.compactMap { $0["userId"] as? String }
        return Array(Set(ids1 + ids2))
    }
}


