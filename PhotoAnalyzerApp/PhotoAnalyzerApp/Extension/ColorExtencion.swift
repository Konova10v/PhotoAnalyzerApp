//
//  ColorExtencion.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 24.06.2025.
//

import Foundation
import SwiftUI

extension Color {
	init(hex: UInt, alpha: Double = 1) {
		self.init(
			.sRGB,
			red: Double((hex >> 16) & 0xff) / 255,
			green: Double((hex >> 08) & 0xff) / 255,
			blue: Double((hex >> 00) & 0xff) / 255,
			opacity: alpha
		)
	}
}
