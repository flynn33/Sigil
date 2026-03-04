import RFCoreModels
import RFGeocoding
import SwiftUI
import UIKit

struct ProfileEditorView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.openURL) private var openURL
    @ObservedObject var model: ProfileFormModel
    @AppStorage("rf.theme.variant") private var themeVariantRaw = RFMysticTheme.defaultVariant.rawValue

    let onSave: (PersonProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var placeQuery: String = ""
    @State private var placeResults: [PlaceCandidate] = []
    @State private var activeHelp: ProfileHelpTopic?
    @State private var isSearchingPlaces = false
    @State private var isUsingCurrentLocation = false
    @State private var locationPermissionStatus: LocationPermissionStatus = .notDetermined

    var body: some View {
        let palette = RFMysticTheme.palette(for: RFMysticTheme.variant(from: themeVariantRaw))

        Form {
            Section("Identity") {
                textFieldRow(
                    title: "Given Name",
                    help: "Your first name used in celestial-name and sigil computations.",
                    placeholder: "Enter given name",
                    text: $model.givenName
                )
                textFieldRow(
                    title: "Family Name",
                    help: "Your primary family/surname used in deterministic name and vector derivation.",
                    placeholder: "Enter family name",
                    text: $model.familyName
                )
                numberFieldRow(
                    title: "Your Birth Position",
                    help: "Your numeric birth order position in your siblings (example: 2 means second born).",
                    placeholder: "e.g. 2",
                    text: $model.birthOrder
                )
                numberFieldRow(
                    title: "Total Children in Family (Optional)",
                    help: "Total children in your birth family (example: if you are 2nd of 4, enter 4).",
                    placeholder: "e.g. 4",
                    text: $model.birthOrderTotal
                )
            }

            Section("Birth") {
                datePickerRow(
                    title: "Birth Date and Time",
                    help: "Enter birth date/time. Weekday is derived from this and used in canonical interpretation.",
                    selection: $model.birthDate
                )
                toggleRow(
                    title: "Birth Time Unknown",
                    help: "When enabled, Sigil stores unknown birth time and uses deterministic 12:00 for calculations.",
                    label: "Use deterministic 12:00 fallback",
                    isOn: $model.isBirthTimeUnknown
                )
                VStack(alignment: .leading, spacing: 4) {
                    fieldHeader(
                        title: "Derived Weekday",
                        help: "Automatically computed from the birth date/time input. This value is not manually edited."
                    )
                    Text(derivedWeekday)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Physical Traits") {
                textFieldRow(
                    title: "Your Hair Color",
                    help: "Your hair-color descriptor used in canonical and extension trait mapping.",
                    placeholder: "e.g. Brown",
                    text: $model.userHairColor
                )
                textFieldRow(
                    title: "Your Eye Color",
                    help: "Your eye-color descriptor used in canonical and extension trait mapping.",
                    placeholder: "e.g. Hazel",
                    text: $model.userEyeColor
                )
                numberFieldRow(
                    title: "Your Height (cm, Optional)",
                    help: "Optional integer height in centimeters included in deterministic generation.",
                    placeholder: "e.g. 178",
                    text: $model.userHeightCentimeters
                )
            }

            Section("Birthplace") {
                textFieldRow(
                    title: "Birthplace Name",
                    help: "Human-readable birthplace label saved with the profile.",
                    placeholder: "City, Region, Country",
                    text: $model.birthplaceName
                )
                decimalFieldRow(
                    title: "Latitude",
                    help: "Decimal latitude coordinate used in deterministic pipeline calculations.",
                    placeholder: "e.g. 47.6062",
                    text: $model.latitude
                )
                decimalFieldRow(
                    title: "Longitude",
                    help: "Decimal longitude coordinate used in deterministic pipeline calculations.",
                    placeholder: "e.g. -122.3321",
                    text: $model.longitude
                )

                VStack(alignment: .leading, spacing: 6) {
                    fieldHeader(
                        title: "Search Apple Maps",
                        help: "Lookup a birthplace with Apple Maps and populate name/coordinates automatically."
                    )
                    HStack {
                        TextField("Search query", text: $placeQuery)
                        Button("Find") {
                            Task { await findPlaces() }
                        }
                        .disabled(isSearchingPlaces || placeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Button {
                        Task { await useCurrentLocation() }
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use My Current Location")
                            if isUsingCurrentLocation {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isUsingCurrentLocation)

                    Text(locationPermissionMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
                        Button("Open Location Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(url)
                        }
                        .font(.caption)
                    }
                }

                if !placeResults.isEmpty {
                    ForEach(placeResults.prefix(5)) { place in
                        Button {
                            apply(place: place)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(place.title)
                                Text(place.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Mother") {
                numberFieldRow(
                    title: "Mother Birth Position",
                    help: "Mother's birth position in her siblings (example: 3 means third born daughter/child).",
                    placeholder: "e.g. 3",
                    text: $model.motherBirthOrder
                )
                numberFieldRow(
                    title: "Mother Total Children (Optional)",
                    help: "Total children in mother's birth family (example: 3rd of 5 => enter 5).",
                    placeholder: "e.g. 5",
                    text: $model.motherBirthOrderTotal
                )
                textFieldRow(
                    title: "Mother Hair Color",
                    help: "Mother hair-color descriptor used by name and symbolic alignment rules.",
                    placeholder: "e.g. Brown",
                    text: $model.motherHairColor
                )
                textFieldRow(
                    title: "Mother Eye Color",
                    help: "Mother eye-color descriptor used by name and symbolic alignment rules.",
                    placeholder: "e.g. Hazel",
                    text: $model.motherEyeColor
                )
            }

            Section("Father") {
                numberFieldRow(
                    title: "Father Birth Position",
                    help: "Father's birth position in his siblings (example: 7 means seventh born son/child).",
                    placeholder: "e.g. 7",
                    text: $model.fatherBirthOrder
                )
                numberFieldRow(
                    title: "Father Total Children (Optional)",
                    help: "Total children in father's birth family (example: 7th of 9 => enter 9).",
                    placeholder: "e.g. 9",
                    text: $model.fatherBirthOrderTotal
                )
                textFieldRow(
                    title: "Father Hair Color",
                    help: "Father hair-color descriptor used by name and symbolic alignment rules.",
                    placeholder: "e.g. Black",
                    text: $model.fatherHairColor
                )
                textFieldRow(
                    title: "Father Eye Color",
                    help: "Father eye-color descriptor used by name and symbolic alignment rules.",
                    placeholder: "e.g. Blue",
                    text: $model.fatherEyeColor
                )
            }

            Section("Traits") {
                textFieldRow(
                    title: "Family Names",
                    help: "Comma-separated family surnames or lineage names.",
                    placeholder: "e.g. Wolfsbane, Dale",
                    text: $model.familyNamesRaw
                )
                textFieldRow(
                    title: "Heritage",
                    help: "Comma-separated heritage descriptors used in deterministic mapping.",
                    placeholder: "e.g. Norse, Celtic",
                    text: $model.heritageRaw
                )
                textFieldRow(
                    title: "Pet Names",
                    help: "Comma-separated names of meaningful pets; these can influence extension mapping.",
                    placeholder: "e.g. Fen, Ash",
                    text: $model.petNamesRaw
                )
                textFieldRow(
                    title: "Hobbies / Interests",
                    help: "Comma-separated hobbies or interests used in extension mapping and personal interpretation.",
                    placeholder: "e.g. Hiking, Archery, Astronomy",
                    text: $model.hobbiesInterestsRaw
                )
            }

            Section {
                Button {
                    model.addProfession()
                } label: {
                    Label("Add Profession", systemImage: "plus.circle")
                }

                if model.professions.isEmpty {
                    Text("No professions yet. Example: Police Officer, Detective Sergeant, 20 years, Badge Number = 4172.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(model.professions) { profession in
                    if let professionBinding = model.professionBinding(id: profession.id) {
                        professionEditorRow(
                            profession: professionBinding,
                            onDelete: {
                                model.removeProfession(id: profession.id)
                            }
                        )
                    }
                }
            } header: {
                sectionHeader(
                    title: "Professions",
                    help: "Add one or more profession records. Each record supports profession, title/position, years in role, and an optional custom item."
                )
            }

            Section {
                Button {
                    model.addDynamicField()
                } label: {
                    Label("Add Dynamic Field", systemImage: "plus.circle")
                }

                if model.dynamicFields.isEmpty {
                    Text("No dynamic fields yet. Add fields to capture custom profile traits.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(model.dynamicFields) { field in
                    if let fieldBinding = model.dynamicFieldBinding(id: field.id) {
                        DynamicFieldEditorRow(field: fieldBinding) {
                            model.removeDynamicField(id: field.id)
                        }
                    }
                }
            } header: {
                sectionHeader(
                    title: "Dynamic Form Builder",
                    help: "Use custom fields for traits not covered by standard profile inputs. Field keys and values are included in deterministic sigil mapping."
                )
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    fieldHeader(
                        title: "Additional Traits",
                        help: "Optional fallback traits in key=value lines. Example: totem=Raven."
                    )
                    TextField("key=value per line", text: $model.additionalTraitsRaw, axis: .vertical)
                        .lineLimit(4...8)
                }
            } header: {
                sectionHeader(
                    title: "Legacy Additional Traits",
                    help: "Optional fallback traits in key=value format. Example: totem=Raven. Leave empty if dynamic custom fields are enough."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            MysticNebulaBackground(palette: palette)
                .ignoresSafeArea()
        }
        .navigationTitle("Profile")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(palette.secondaryBackground.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    do {
                        onSave(try model.buildProfile())
                    } catch {
                        coordinator.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .alert(item: $activeHelp) { topic in
            Alert(
                title: Text(topic.title),
                message: Text(topic.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            locationPermissionStatus = coordinator.dependencies.geocoder.locationAuthorizationStatus()
        }
    }

    private var derivedWeekday: String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: model.birthDate)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.weekdaySymbols[weekday - 1]
    }

    private func textFieldRow(
        title: String,
        help: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title: title, help: help)
            TextField(placeholder, text: text)
        }
    }

    private func numberFieldRow(
        title: String,
        help: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title: title, help: help)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
        }
    }

    private func decimalFieldRow(
        title: String,
        help: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title: title, help: help)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
        }
    }

    private func datePickerRow(
        title: String,
        help: String,
        selection: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title: title, help: help)
            DatePicker("Select birth date/time", selection: selection)
        }
    }

    private func toggleRow(
        title: String,
        help: String,
        label: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldHeader(title: title, help: help)
            Toggle(label, isOn: isOn)
        }
    }

    private func fieldHeader(title: String, help: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Button {
                activeHelp = ProfileHelpTopic(title: title, message: help)
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Info about \(title)")
        }
    }

    private func sectionHeader(title: String, help: String) -> some View {
        fieldHeader(title: title, help: help)
    }

    private func professionEditorRow(
        profession: Binding<ProfessionDraft>,
        onDelete: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Profession Entry")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .labelStyle(.iconOnly)
            }

            textFieldRow(
                title: "Profession",
                help: "Primary profession category. Example: Police Officer, IT, Teacher.",
                placeholder: "e.g. Police Officer",
                text: profession.profession
            )

            textFieldRow(
                title: "Title / Position Held",
                help: "Specific role or title held in that profession.",
                placeholder: "e.g. Detective Sergeant",
                text: profession.titleOrPosition
            )

            numberFieldRow(
                title: "Years in Profession",
                help: "Total years in this profession. Must be a positive whole number.",
                placeholder: "e.g. 20",
                text: profession.yearsInProfession
            )

            textFieldRow(
                title: "Custom Item Label (Optional)",
                help: "Optional extra field label for profession-specific detail.",
                placeholder: "e.g. Badge Number",
                text: profession.customItemLabel
            )

            textFieldRow(
                title: "Custom Item Value (Optional)",
                help: "Value for the custom item label. Example: if label is Badge Number, value might be 4172.",
                placeholder: "e.g. 4172",
                text: profession.customItemValue
            )
        }
        .padding(.vertical, 6)
    }

    private var locationPermissionMessage: String {
        switch locationPermissionStatus {
        case .notDetermined:
            "Allow location access to auto-fill your current place and coordinates."
        case .restricted:
            "Location is restricted on this device. You can still search Apple Maps manually."
        case .denied:
            "Location access is off. Enable it in Settings to use current location."
        case .authorizedWhenInUse, .authorizedAlways:
            "Location access granted. You can use your current location or search Apple Maps."
        }
    }

    private func findPlaces() async {
        isSearchingPlaces = true
        defer { isSearchingPlaces = false }

        do {
            placeResults = try await coordinator.dependencies.geocoder.search(query: placeQuery)
        } catch {
            coordinator.errorMessage = "Apple Maps search failed: \(error.localizedDescription)"
            placeResults = []
        }
    }

    private func useCurrentLocation() async {
        isUsingCurrentLocation = true
        defer { isUsingCurrentLocation = false }

        let geocoder = coordinator.dependencies.geocoder
        let permission = await geocoder.requestLocationPermissionIfNeeded()
        locationPermissionStatus = permission

        guard permission.canUseLocation else {
            coordinator.errorMessage = "Location permission is required to use your current location."
            return
        }

        do {
            let place = try await geocoder.currentLocationCandidate()
            apply(place: place)
        } catch {
            coordinator.errorMessage = "Failed to read current location: \(error.localizedDescription)"
        }
    }

    private func apply(place: PlaceCandidate) {
        model.birthplaceName = place.title
        model.latitude = String(format: "%.6f", place.location.latitude)
        model.longitude = String(format: "%.6f", place.location.longitude)
        placeQuery = place.title
        placeResults = []
    }
}

private struct ProfileHelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
