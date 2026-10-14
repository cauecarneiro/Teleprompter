import Photos

enum PhotoSaverError: LocalizedError {
    case denied
    var errorDescription: String? {
        "Sem permissão para salvar na galeria. Ative em Ajustes > Teleprompter > Fotos."
    }
}

/// Salva cada take na galeria (e no álbum "Teleprompter", quando há permissão de leitura).
enum PhotoSaver {
    private final class Box: @unchecked Sendable { var value: String? }

    /// Pede a permissão antes da primeira gravação, para o aviso do iOS não aparecer no fim do take.
    static func prepare(album: Bool) async {
        if album {
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .notDetermined {
                _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            }
        } else if PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
    }

    /// Move o arquivo para a galeria. Devolve o identificador do vídeo criado.
    static func save(videoAt url: URL, albumName: String?) async throws -> String? {
        let full = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if let albumName, full == .authorized {
            let album = try await findOrCreateAlbum(named: albumName)
            return try await create(from: url, in: album)
        }

        var addOnly = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if addOnly == .notDetermined {
            addOnly = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard addOnly == .authorized || addOnly == .limited || full == .limited else {
            throw PhotoSaverError.denied
        }
        return try await create(from: url, in: nil)
    }

    private static func create(from url: URL, in album: PHAssetCollection?) async throws -> String? {
        let box = Box()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            request.addResource(with: .video, fileURL: url, options: options)
            if let placeholder = request.placeholderForCreatedAsset {
                box.value = placeholder.localIdentifier
                if let album, let change = PHAssetCollectionChangeRequest(for: album) {
                    change.addAssets([placeholder] as NSArray)
                }
            }
        }
        return box.value
    }

    private static func findOrCreateAlbum(named name: String) async throws -> PHAssetCollection {
        if let existing = album(named: name) { return existing }
        let box = Box()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            box.value = request.placeholderForCreatedAssetCollection.localIdentifier
        }
        if let id = box.value,
           let created = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject {
            return created
        }
        guard let found = album(named: name) else { throw PhotoSaverError.denied }
        return found
    }

    private static func album(named name: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", name)
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options).firstObject
    }
}
