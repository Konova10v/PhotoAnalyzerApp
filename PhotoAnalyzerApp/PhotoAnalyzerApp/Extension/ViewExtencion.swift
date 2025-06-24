//
//  ViewExtencion.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 24.06.2025.
//

import Foundation
import SwiftUI

extension View {
	func placeholder<Content: View>(
		when shouldShow: Bool,
		alignment: Alignment = .leading,
		@ViewBuilder placeholder: () -> Content
	) -> some View {
		ZStack(alignment: alignment) {
			placeholder().opacity(shouldShow ? 1 : 0)
			self
		}
	}
}
