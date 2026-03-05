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

    var body: some View {
        NavigationStack {
            Form {
                // Photo - same style as person picker but square, no cropping
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
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
                .listRowBackground(Color.clear)

                Section {
                    TextField("Gift idea name", text: $title)
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
            .navigationTitle("Gift Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImage = uiImage
                    }
                }
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
