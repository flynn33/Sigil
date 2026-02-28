import Foundation
import RFCoreModels
import SwiftUI

struct DynamicFieldDraft: Identifiable, Hashable {
    var id: UUID
    var key: String
    var label: String
    var section: String
    var type: DynamicFieldType
    var isRequired: Bool
    var optionsRaw: String
    var value: String

    init(
        id: UUID = UUID(),
        key: String = "",
        label: String = "",
        section: String = "Custom",
        type: DynamicFieldType = .text,
        isRequired: Bool = false,
        optionsRaw: String = "",
        value: String = ""
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.section = section
        self.type = type
        self.isRequired = isRequired
        self.optionsRaw = optionsRaw
        self.value = value
    }

    init(definition: DynamicFieldDefinition, value: String) {
        self.id = definition.id
        self.key = definition.key
        self.label = definition.label
        self.section = definition.section
        self.type = definition.type
        self.isRequired = definition.isRequired
        self.optionsRaw = definition.options.joined(separator: ", ")
        self.value = value
    }

    var parsedOptions: [String] {
        optionsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var normalizedKey: String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mapped = trimmed.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            if character == " " || character == "-" {
                return "_"
            }
            return "_"
        }
        return String(mapped).replacingOccurrences(of: "__", with: "_")
    }

    var normalizedLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? normalizedKey.replacingOccurrences(of: "_", with: " ").capitalized : trimmed
    }

    var normalizedSection: String {
        let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Custom" : trimmed
    }
}

struct ProfessionDraft: Identifiable, Hashable {
    var id: UUID
    var profession: String
    var titleOrPosition: String
    var yearsInProfession: String
    var customItemLabel: String
    var customItemValue: String

    init(
        id: UUID = UUID(),
        profession: String = "",
        titleOrPosition: String = "",
        yearsInProfession: String = "",
        customItemLabel: String = "",
        customItemValue: String = ""
    ) {
        self.id = id
        self.profession = profession
        self.titleOrPosition = titleOrPosition
        self.yearsInProfession = yearsInProfession
        self.customItemLabel = customItemLabel
        self.customItemValue = customItemValue
    }

    init(entry: ProfessionEntry) {
        id = entry.id
        profession = entry.profession
        titleOrPosition = entry.titleOrPosition
        yearsInProfession = String(entry.yearsInProfession)
        customItemLabel = entry.customItemLabel
        customItemValue = entry.customItemValue
    }
}

@MainActor
final class ProfileFormModel: ObservableObject {
    @Published var givenName: String = ""
    @Published var familyName: String = ""
    @Published var birthDate: Date = .now
    @Published var isBirthTimeUnknown: Bool = false
    @Published var birthOrder: String = "1"
    @Published var birthOrderTotal: String = ""
    @Published var birthplaceName: String = ""
    @Published var latitude: String = ""
    @Published var longitude: String = ""

    @Published var motherBirthOrder: String = "1"
    @Published var motherBirthOrderTotal: String = ""
    @Published var motherHairColor: String = ""
    @Published var motherEyeColor: String = ""

    @Published var fatherBirthOrder: String = "1"
    @Published var fatherBirthOrderTotal: String = ""
    @Published var fatherHairColor: String = ""
    @Published var fatherEyeColor: String = ""

    @Published var familyNamesRaw: String = ""
    @Published var heritageRaw: String = ""
    @Published var petNamesRaw: String = ""
    @Published var hobbiesInterestsRaw: String = ""
    @Published var professions: [ProfessionDraft] = []
    @Published var additionalTraitsRaw: String = ""
    @Published var dynamicFields: [DynamicFieldDraft] = []

    private var editingID: UUID?
    private var createdAt: Date = .now

    init(profile: PersonProfile? = nil) {
        guard let profile else { return }

        editingID = profile.id
        createdAt = profile.createdAt

        givenName = profile.givenName
        familyName = profile.familyName
        birthDate = profile.birthDetails.date
        isBirthTimeUnknown = profile.birthDetails.isTimeUnknown
        birthOrder = String(profile.birthOrder)
        birthOrderTotal = profile.birthOrderTotal.map(String.init) ?? ""
        birthplaceName = profile.birthplaceName
        latitude = String(profile.birthplace.latitude)
        longitude = String(profile.birthplace.longitude)

        motherBirthOrder = String(profile.mother.birthOrder)
        motherBirthOrderTotal = profile.mother.birthOrderTotal.map(String.init) ?? ""
        motherHairColor = profile.mother.hairColor
        motherEyeColor = profile.mother.eyeColor

        fatherBirthOrder = String(profile.father.birthOrder)
        fatherBirthOrderTotal = profile.father.birthOrderTotal.map(String.init) ?? ""
        fatherHairColor = profile.father.hairColor
        fatherEyeColor = profile.father.eyeColor

        familyNamesRaw = profile.traits.familyNames.joined(separator: ", ")
        heritageRaw = profile.traits.heritage.joined(separator: ", ")
        petNamesRaw = profile.traits.petNames.joined(separator: ", ")
        hobbiesInterestsRaw = profile.traits.hobbiesInterests.joined(separator: ", ")
        professions = profile.traits.professions.map(ProfessionDraft.init(entry:))
        additionalTraitsRaw = profile.traits.additionalTraits
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\n")

        dynamicFields = profile.traits.dynamicFields.map { definition in
            DynamicFieldDraft(
                definition: definition,
                value: profile.traits.dynamicFieldValues[definition.key] ?? ""
            )
        }
    }

    func addDynamicField() {
        dynamicFields.append(DynamicFieldDraft())
    }

    func addProfession() {
        professions.append(ProfessionDraft())
    }

    func removeProfession(id: UUID) {
        professions.removeAll(where: { $0.id == id })
    }

    func removeDynamicField(id: UUID) {
        dynamicFields.removeAll(where: { $0.id == id })
    }

    func professionBinding(id: UUID) -> Binding<ProfessionDraft>? {
        guard professions.contains(where: { $0.id == id }) else {
            return nil
        }

        return Binding(
            get: { [weak self] in
                guard let self else {
                    return ProfessionDraft(id: id)
                }
                return self.professions.first(where: { $0.id == id }) ?? ProfessionDraft(id: id)
            },
            set: { [weak self] updatedValue in
                guard let self else {
                    return
                }
                guard let index = self.professions.firstIndex(where: { $0.id == id }) else {
                    return
                }
                self.professions[index] = updatedValue
            }
        )
    }

    func dynamicFieldBinding(id: UUID) -> Binding<DynamicFieldDraft>? {
        guard dynamicFields.contains(where: { $0.id == id }) else {
            return nil
        }

        return Binding(
            get: { [weak self] in
                guard let self else {
                    return DynamicFieldDraft(id: id)
                }
                return self.dynamicFields.first(where: { $0.id == id }) ?? DynamicFieldDraft(id: id)
            },
            set: { [weak self] updatedValue in
                guard let self else {
                    return
                }
                guard let index = self.dynamicFields.firstIndex(where: { $0.id == id }) else {
                    return
                }
                self.dynamicFields[index] = updatedValue
            }
        )
    }

    func buildProfile() throws -> PersonProfile {
        guard let birthOrder = Int(birthOrder),
              let motherBirthOrder = Int(motherBirthOrder),
              let fatherBirthOrder = Int(fatherBirthOrder),
              let latitude = Double(latitude),
              let longitude = Double(longitude)
        else {
            throw ProfileFormError.invalidNumberInput
        }
        let birthOrderTotal = try parseOptionalPositiveInt(birthOrderTotal)
        let motherBirthOrderTotal = try parseOptionalPositiveInt(motherBirthOrderTotal)
        let fatherBirthOrderTotal = try parseOptionalPositiveInt(fatherBirthOrderTotal)

        try validateBirthOrder(position: birthOrder, total: birthOrderTotal, label: "Your birth order")
        try validateBirthOrder(position: motherBirthOrder, total: motherBirthOrderTotal, label: "Mother birth order")
        try validateBirthOrder(position: fatherBirthOrder, total: fatherBirthOrderTotal, label: "Father birth order")

        guard !givenName.trimmingCharacters(in: .whitespaces).isEmpty,
              !familyName.trimmingCharacters(in: .whitespaces).isEmpty,
              !birthplaceName.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            throw ProfileFormError.missingRequiredFields
        }

        var normalizedBirthDate = birthDate
        if isBirthTimeUnknown {
            normalizedBirthDate = ProfileFormModel.withNoonTime(birthDate)
        }

        let professionEntries = try parseProfessionEntries()
        let additionalTraits = parseAdditionalTraits(additionalTraitsRaw)
        let dynamicResult = try parseDynamicFields()

        let traits = TraitBundle(
            familyNames: parseCSV(familyNamesRaw),
            heritage: parseCSV(heritageRaw),
            petNames: parseCSV(petNamesRaw),
            professions: professionEntries,
            hobbiesInterests: parseCSV(hobbiesInterestsRaw),
            additionalTraits: additionalTraits,
            dynamicFields: dynamicResult.definitions,
            dynamicFieldValues: dynamicResult.values
        )

        return PersonProfile(
            id: editingID ?? UUID(),
            givenName: givenName.trimmingCharacters(in: .whitespacesAndNewlines),
            familyName: familyName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDetails: BirthDetails(date: normalizedBirthDate, isTimeUnknown: isBirthTimeUnknown),
            birthOrder: birthOrder,
            birthOrderTotal: birthOrderTotal,
            birthplaceName: birthplaceName,
            birthplace: GeoPoint(latitude: latitude, longitude: longitude),
            mother: ParentTraits(
                birthOrder: motherBirthOrder,
                birthOrderTotal: motherBirthOrderTotal,
                hairColor: motherHairColor,
                eyeColor: motherEyeColor
            ),
            father: ParentTraits(
                birthOrder: fatherBirthOrder,
                birthOrderTotal: fatherBirthOrderTotal,
                hairColor: fatherHairColor,
                eyeColor: fatherEyeColor
            ),
            traits: traits,
            createdAt: createdAt,
            updatedAt: .now
        )
    }

    private func parseDynamicFields() throws -> (definitions: [DynamicFieldDefinition], values: [String: String]) {
        var definitions: [DynamicFieldDefinition] = []
        var values: [String: String] = [:]
        var seenKeys: Set<String> = []

        for draft in dynamicFields {
            let key = draft.normalizedKey
            let label = draft.normalizedLabel

            guard !key.isEmpty else {
                continue
            }

            if seenKeys.contains(key) {
                throw ProfileFormError.duplicateDynamicFieldKey(key)
            }
            seenKeys.insert(key)

            let definition = DynamicFieldDefinition(
                id: draft.id,
                key: key,
                label: label,
                section: draft.normalizedSection,
                type: draft.type,
                isRequired: draft.isRequired,
                options: draft.parsedOptions
            )
            definitions.append(definition)

            let value = draft.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if definition.isRequired && value.isEmpty {
                throw ProfileFormError.missingDynamicFieldValue(label)
            }
            if !value.isEmpty {
                values[key] = value
            }
        }

        return (definitions, values)
    }

    private func parseProfessionEntries() throws -> [ProfessionEntry] {
        var parsed: [ProfessionEntry] = []

        for draft in professions {
            let profession = draft.profession.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = draft.titleOrPosition.trimmingCharacters(in: .whitespacesAndNewlines)
            let yearsRaw = draft.yearsInProfession.trimmingCharacters(in: .whitespacesAndNewlines)
            let customLabel = draft.customItemLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let customValue = draft.customItemValue.trimmingCharacters(in: .whitespacesAndNewlines)

            let hasAnyValue = !profession.isEmpty
                || !title.isEmpty
                || !yearsRaw.isEmpty
                || !customLabel.isEmpty
                || !customValue.isEmpty

            if !hasAnyValue {
                continue
            }

            guard !profession.isEmpty else {
                throw ProfileFormError.missingProfessionName
            }

            guard let years = Int(yearsRaw), years > 0 else {
                throw ProfileFormError.invalidProfessionYears(profession)
            }

            if customLabel.isEmpty != customValue.isEmpty {
                throw ProfileFormError.incompleteProfessionCustomItem(profession)
            }

            parsed.append(
                ProfessionEntry(
                    id: draft.id,
                    profession: profession,
                    titleOrPosition: title,
                    yearsInProfession: years,
                    customItemLabel: customLabel,
                    customItemValue: customValue
                )
            )
        }

        return parsed
    }

    private static func withNoonTime(_ date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        return calendar.date(from: components) ?? date
    }

    private func parseCSV(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseAdditionalTraits(_ raw: String) -> [String: String] {
        var map: [String: String] = [:]
        for line in raw.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { continue }
            map[key] = value
        }
        return map
    }

    private func parseOptionalPositiveInt(_ raw: String) throws -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        guard let parsed = Int(trimmed), parsed > 0 else {
            throw ProfileFormError.invalidNumberInput
        }
        return parsed
    }

    private func validateBirthOrder(position: Int, total: Int?, label: String) throws {
        guard position > 0 else {
            throw ProfileFormError.invalidBirthOrderRange(label)
        }
        if let total, position > total {
            throw ProfileFormError.invalidBirthOrderRange(label)
        }
    }
}

enum ProfileFormError: LocalizedError {
    case invalidNumberInput
    case invalidBirthOrderRange(String)
    case missingProfessionName
    case invalidProfessionYears(String)
    case incompleteProfessionCustomItem(String)
    case missingRequiredFields
    case duplicateDynamicFieldKey(String)
    case missingDynamicFieldValue(String)

    var errorDescription: String? {
        switch self {
        case .invalidNumberInput:
            "Birth order values and coordinates must be valid numbers."
        case .invalidBirthOrderRange(let label):
            "\(label) must be a positive position that does not exceed total children."
        case .missingProfessionName:
            "Each profession entry must include a profession name."
        case .invalidProfessionYears(let profession):
            "Profession '\(profession)' requires a valid years value greater than zero."
        case .incompleteProfessionCustomItem(let profession):
            "Profession '\(profession)' has a partial custom item. Provide both label and value or leave both empty."
        case .missingRequiredFields:
            "Given name, family name, and birthplace are required."
        case .duplicateDynamicFieldKey(let key):
            "Dynamic field key '\(key)' is duplicated."
        case .missingDynamicFieldValue(let label):
            "Required dynamic field '\(label)' is missing a value."
        }
    }
}
