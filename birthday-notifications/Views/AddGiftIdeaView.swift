import PhotosUI
import SwiftData
import SwiftUI

struct AddGiftIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: Person

    @State private var title = ""
    @State private var notes = ""
    @State private var priceText = ""
    @State private var url = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showPhotoSourceDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false

    var body: some View {
        NavigationStack {
            Form {
                // Photo - same style as person picker but square, no cropping
                Section {
                    Button {
                        showPhotoSourceDialog = true
                    } label: {
                        Group {
                            if let pickedImage {
                                Image(uiImage: pickedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.gray.opacity(0.2), lineWidth: 3)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.gray.opacity(0.12))
                                    .frame(width: 160, height: 160)
                                    .overlay(
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.gray.opacity(0.4))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.gray.opacity(0.15), lineWidth: 3)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField("What is it?", text: $title)
                }

                Section {
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Optional", text: $priceText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        if !priceText.isEmpty {
                            Text("kr")
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Link")
                        Spacer()
                        TextField("Optional", text: $url)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section("Notes") {
                    TextField("Where to buy, size, color...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New gift idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                SaveCancelToolbar(
                    saveDisabled: title.trimmingCharacters(in: .whitespaces).isEmpty,
                    onSave: save
                )
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showLibrary, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImage = uiImage
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    pickedImage = image
                }
                .ignoresSafeArea()
            }
        }
    }

    private func save() {
        let price = Double(priceText)
        let gift = GiftIdea(
            title: title,
            notes: notes,
            estimatedPrice: price,
            url: url.isEmpty ? nil : url,
            photoData: pickedImage?.jpegData(compressionQuality: 0.85),
            person: person
        )
        person.giftIdeas.append(gift)
        dismiss()
    }
}
