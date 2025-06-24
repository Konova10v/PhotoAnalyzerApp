//
//  PhotoViewModel.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 24.06.2025.
//

import Foundation
import UIKit
import Vision
import Photos
import SwiftData

class PhotoViewModel: ObservableObject {
	@Published var processedImages: [ProcessedImage] = []
	@Published var allImages: [ProcessedImage] = []
	@Published var selectedImage: UIImage?
	@Published var isProcessing = false
	@Published var tempName = ""
	@Published var tempFaceDetected = false
	@Published var showingDetail = false
	
	@Published var showAlert = false
	@Published var alertMessage = ""

	private let namePool = [
		"Sunset", "Mountain", "Beach", "Forest", "Cityscape",
		"Portrait", "Pet", "Food", "Flower", "Building",
		"Lake", "Art", "Landscape", "Tree", "Cloud",
		"River", "Snow", "Sand", "Road", "Horizon"
	]
	private var nameCount: [String: Int] = [:]

	func loadFromStorage(context: ModelContext) {
		do {
			let items = try context.fetch(FetchDescriptor<StoredImage>())
			let mapped: [ProcessedImage] = items.compactMap { stored in
				guard let image = UIImage(data: stored.imageData) else { return nil }
				let orientation: ProcessedImage.Orientation
				switch stored.orientation {
				case "portrait": orientation = .portrait
				case "landscape": orientation = .landscape
				default: orientation = .square
				}
				return ProcessedImage(image: image, name: stored.name, containsFace: stored.containsFace, orientation: orientation)
			}

			self.allImages = mapped
			self.processedImages = mapped
		} catch {
			print("[SwiftData] Ошибка загрузки: \(error.localizedDescription)")
		}
	}

	func saveToStorage(processed: ProcessedImage, context: ModelContext) {
		guard let data = processed.image.jpegData(compressionQuality: 0.9) else { return }
		let orientationString: String
		switch processed.orientation {
		case .portrait: orientationString = "portrait"
		case .landscape: orientationString = "landscape"
		case .square: orientationString = "square"
		}
		let stored = StoredImage(name: processed.name, containsFace: processed.containsFace, orientation: orientationString, imageData: data)
		context.insert(stored)
		do {
			try context.save()
		} catch {
			print("[SwiftData] Ошибка сохранения: \(error.localizedDescription)")
		}
	}

	func processImage(_ image: UIImage, context: ModelContext) {
		isProcessing = true
		selectedImage = image

		DispatchQueue.global(qos: .userInitiated).async {
			let faceDetected = self.detectFace(in: image)
			let randomName = self.generateRandomName()
			let orientation = self.calculateOrientation(image: image)

			DispatchQueue.main.async {
				let processed = ProcessedImage(image: image, name: randomName, containsFace: faceDetected, orientation: orientation)
				self.processedImages.append(processed)
				self.tempName = randomName
				self.tempFaceDetected = faceDetected
				self.isProcessing = false
				self.showingDetail = true
				self.saveToStorage(processed: processed, context: context)
			}
		}
	}

	private func detectFace(in image: UIImage) -> Bool {
		guard let data = image.pngData(),
			  let uiImage = UIImage(data: data),
			  let cgImage = uiImage.cgImage else {
			return false
		}
		let request = VNDetectFaceRectanglesRequest()
		let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
		try? handler.perform([request])
		return !(request.results?.isEmpty ?? true)
	}

	private func generateRandomName() -> String {
		let word = namePool.randomElement() ?? "Image"
		nameCount[word, default: 0] += 1
		return "\(word.lowercased())-\(nameCount[word]!)"
	}

	private func calculateOrientation(image: UIImage) -> ProcessedImage.Orientation {
		let size = image.size
		if size.width > size.height {
			return .landscape
		} else if size.width < size.height {
			return .portrait
		} else {
			return .square
		}
	}

	func saveToPhotoLibrary(image: UIImage) {
		PHPhotoLibrary.requestAuthorization { status in
			Task { @MainActor in
				guard status == .authorized || status == .limited else {
					self.alertMessage = "Нет доступа к фотогалерее. Разрешите доступ в настройках."
					self.showAlert = true
					return
				}

				UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
				self.alertMessage = "Изображение успешно сохранено в галерею."
				self.showAlert = true
			}
		}
	}
}
