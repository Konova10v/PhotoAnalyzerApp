//
//  ProcessedImage.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 24.06.2025.
//

import Foundation
import UIKit
import SwiftData

// MARK: - SwiftData Model
@Model
class StoredImage {
	var id: UUID = UUID()
	var name: String
	var containsFace: Bool
	var orientation: String
	var imageData: Data

	init(name: String, containsFace: Bool, orientation: String, imageData: Data) {
		self.name = name
		self.containsFace = containsFace
		self.orientation = orientation
		self.imageData = imageData
	}
}

// MARK: - Модель представления
struct ProcessedImage: Identifiable, Hashable {
	let id = UUID()
	let image: UIImage
	let name: String
	let containsFace: Bool
	let orientation: Orientation

	enum Orientation {
		case portrait, landscape, square
	}
}
