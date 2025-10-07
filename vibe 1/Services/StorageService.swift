import Foundation
import FirebaseStorage
import UIKit

struct StorageService {
    private let storage = Storage.storage()

    func uploadAvatar(image: UIImage, for uid: String) async throws -> String {
        let ref = storage.reference().child("avatars/\(uid).jpg")
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "JPEG conversion failed"])
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload then fetch download URL (with retries for propagation)
        return try await withCheckedThrowingContinuation { cont in
            ref.putData(data, metadata: metadata) { _, error in
                if let error = error { cont.resume(throwing: error); return }

                var attempts = 0
                func fetchURL() {
                    ref.downloadURL { url, err in
                        if let url = url {
                            cont.resume(returning: url.absoluteString)
                            return
                        }
                        attempts += 1
                        if attempts <= 5 {
                            // Retry with backoff (0.2s, 0.4s, 0.6s, 0.8s, 1.0s)
                            let delay = 0.2 * Double(attempts)
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                fetchURL()
                            }
                        } else {
                            cont.resume(throwing: err ?? NSError(domain: "storage", code: 404, userInfo: [NSLocalizedDescriptionKey: "downloadURL unavailable"]))
                        }
                    }
                }
                fetchURL()
            }
        }
    }
}


