import Foundation
import UIKit
import Photos

/// Lưu trữ ảnh chụp và video vào ứng dụng Ảnh (Photos / Camera Roll) của iOS
final class PhotoLibraryExporter {

    /// Lưu ảnh tĩnh vào Thư viện ảnh
    static func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, NSError(domain: "CATV", code: 403, userInfo: [NSLocalizedDescriptionKey: "Chưa được cấp quyền lưu vào Thư viện Ảnh"]))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }

    /// Lưu file video vào Thư viện ảnh
    static func saveVideoToPhotoLibrary(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, NSError(domain: "CATV", code: 403, userInfo: [NSLocalizedDescriptionKey: "Chưa được cấp quyền lưu vào Thư viện Ảnh"]))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }) { success, error in
                // Xoá file tạm sau khi đã ghi thành công vào Photos
                try? FileManager.default.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}
