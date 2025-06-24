//
//  ContentView.swift
//  PhotoAnalyzerApp
//
//  Created by Кирилл Коновалов on 23.06.2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
	@Environment(\.modelContext) private var modelContext
	@StateObject private var viewModel = PhotoViewModel()
	@State private var selectedItem: PhotosPickerItem?
	@State private var showPicker = false
	@State var search: String = ""

	var body: some View {
		ZStack {
			Color.black
				.ignoresSafeArea()

			VStack {
				HStack {
					Button {
						showPicker = true
					} label: {
						Image(.icon)
					}

					Spacer()

					Text("Projects")
						.foregroundStyle(.white)
						.font(.system(size: 17))
						.bold()
						.padding(.trailing, 16)

					Spacer()
				}
				.padding(.horizontal)

				TextField("", text: $search)
					.placeholder(when: search.isEmpty) {
						Text("Search")
							.foregroundColor(.gray)
							.padding(.horizontal, 5)
					}
					.padding(10)
					.frame(width: UIScreen.main.bounds.width - 32)
					.background(
						RoundedRectangle(cornerRadius: 30)
							.fill(Color(hex: 0x353535))
					)
					.foregroundColor(.white)
					.accentColor(.white)
					.padding(.top)

				if viewModel.processedImages.isEmpty {
					Spacer()
					VStack(spacing: 10) {
						Image(._54Px)
							.font(.system(size: 54))
							.foregroundColor(.gray)

						Text("No projects yet")
							.foregroundStyle(.white)
							.font(.system(size: 19))
							.bold()

						Text("Start editing your photos now")
							.foregroundStyle(Color(hex: 0xAAAAAA))
							.font(.system(size: 13))
						
						Button {
							showPicker = true
						} label: {
							Text("Start editing")
								.foregroundStyle(.black)
								.font(.system(size: 13))
								.padding(.vertical)
								.frame(width: UIScreen.main.bounds.width / 2)
								.background(Color(hex: 0x00DECB))
								.cornerRadius(20)
						}
						.padding(.top)
					}
					Spacer()
				} else {
					ScrollView {
						LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
							ForEach(viewModel.processedImages) { img in
								VStack {
									Image(uiImage: img.image)
										.resizable()
										.aspectRatio(contentMode: .fill)
										.frame(height: heightFor(img.orientation))
										.clipShape(RoundedRectangle(cornerRadius: 12))
									HStack {
										Text(img.name)
											.font(.caption)
											.foregroundColor(.white)
										Spacer()
										Image(img.containsFace ? .layer16 : .gallery)
									}
								}
								.onTapGesture {
									viewModel.selectedImage = img.image
									viewModel.tempName = img.name
									viewModel.tempFaceDetected = img.containsFace
									viewModel.showingDetail = true
								}
							}
						}
						.padding()

						if !viewModel.showingDetail {
							Button {
								showPicker = true
							} label: {
								Text("Start editing")
									.foregroundStyle(.black)
									.font(.system(size: 13))
									.padding(.vertical)
									.frame(width: UIScreen.main.bounds.width / 2)
									.background(Color(hex: 0x00DECB))
									.cornerRadius(20)
							}
							.padding(.top)
						}
					}
				}
			}

			if viewModel.showingDetail, let image = viewModel.selectedImage {
				ZStack {
					Color.black.opacity(0.8)
						.ignoresSafeArea()
						.onTapGesture {
							viewModel.showingDetail = false
						}
					VStack(spacing: 16) {
						if viewModel.isProcessing {
							Rectangle()
								.fill(.gray.opacity(0.3))
								.frame(width: 240, height: 300)
								.overlay(ProgressView())
							Text(viewModel.tempName)
								.foregroundColor(.white)
						} else {
							Spacer()

							Image(uiImage: image)
								.resizable()
								.scaledToFit()

							HStack {
								Text(viewModel.tempName)
									.foregroundColor(.white)
								Image(viewModel.tempFaceDetected ? .layer16 : .gallery)
									.foregroundColor(.cyan)
							}
							.frame(width: 240)

							Spacer()

							Button {
								if let found = viewModel.processedImages.first(where: { $0.name == viewModel.tempName }) {
									viewModel.saveToPhotoLibrary(image: found.image)
								}
							} label: {
								Text("Export")
									.foregroundStyle(.black)
									.font(.system(size: 13))
									.padding(.vertical)
									.frame(width: UIScreen.main.bounds.width / 2)
									.background(Color(hex: 0x00DECB))
									.cornerRadius(20)
							}
							.padding(.top)
						}
					}
					.padding()
				}
				.transition(.opacity)
			}
		}
		.onAppear {
			viewModel.loadFromStorage(context: modelContext)
		}
		.photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
		.onChange(of: selectedItem) { newItem in
			Task {
				if let data = try? await newItem?.loadTransferable(type: Data.self),
				   let uiImage = UIImage(data: data) {
					viewModel.processImage(uiImage, context: modelContext)
				}
				selectedItem = nil
			}
		}
		.onChange(of: search) { newValue in
			if newValue.isEmpty {
				viewModel.processedImages = viewModel.allImages
			} else {
				viewModel.processedImages = viewModel.allImages.filter {
					$0.name.lowercased().contains(newValue.lowercased())
				}
			}
		}
		.alert("Уведомление", isPresented: $viewModel.showAlert) {
			Button("Ок", role: .cancel) { }
		} message: {
			Text(viewModel.alertMessage)
		}
	}

	func heightFor(_ orientation: ProcessedImage.Orientation) -> CGFloat {
		switch orientation {
		case .portrait: return 220
		case .square: return 160
		case .landscape: return 120
		}
	}
}

#Preview {
    ContentView()
}
