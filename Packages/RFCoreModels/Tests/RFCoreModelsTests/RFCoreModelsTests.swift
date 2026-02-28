import Foundation
import Testing
@testable import RFCoreModels

@Test
func canonicalVectorSerializationUsesStableFormat() {
    let vector = CanonicalVector(H_entropy: 0.5, K_complexity: 0.25, D_fractal_dim: 2.0, S_symmetry: 0.75, L_generator_length: 321)
    #expect(vector.canonicalSerialized() == "H:0.500000;K:0.250000;D:2.000000;S:0.750000;L:321;")
}

@Test
func weekdayIsDerivedFromDate() {
    var components = DateComponents()
    components.year = 1990
    components.month = 7
    components.day = 15
    components.hour = 12
    components.minute = 0

    let calendar = Calendar(identifier: .gregorian)
    let date = calendar.date(from: components)!
    let profile = PersonProfile(
        givenName: "John",
        familyName: "Doe",
        birthDetails: BirthDetails(date: date, isTimeUnknown: false),
        birthOrder: 2,
        birthplaceName: "NYC",
        birthplace: GeoPoint(latitude: 40.7128, longitude: -74.0060),
        mother: ParentTraits(birthOrder: 1, hairColor: "Black", eyeColor: "Brown"),
        father: ParentTraits(birthOrder: 2, hairColor: "Brown", eyeColor: "Blue"),
        traits: TraitBundle()
    )

    #expect(profile.derivedBirthWeekday(calendar: calendar) == "Sunday")
}

@Test
func traitBundleDecodesLegacyPayloadWithoutDynamicFields() throws {
    let json = """
    {
      "familyNames": ["Doe"],
      "heritage": ["Irish"],
      "petNames": ["Luna"],
      "additionalTraits": {"lucky_number":"7"}
    }
    """

    let bundle = try JSONDecoder().decode(TraitBundle.self, from: Data(json.utf8))
    #expect(bundle.dynamicFields.isEmpty)
    #expect(bundle.dynamicFieldValues.isEmpty)
    #expect(bundle.professions.isEmpty)
    #expect(bundle.hobbiesInterests.isEmpty)
    #expect(bundle.additionalTraits["lucky_number"] == "7")
}

@Test
func traitBundleDecodesLegacyHobbiesAlias() throws {
    let json = """
    {
      "familyNames": [],
      "heritage": [],
      "petNames": [],
      "hobbies": ["Archery", "Astrophotography"],
      "additionalTraits": {}
    }
    """

    let bundle = try JSONDecoder().decode(TraitBundle.self, from: Data(json.utf8))
    #expect(bundle.hobbiesInterests == ["Archery", "Astrophotography"])
}

@Test
func imageExportSettingsDecodeLegacyPayloadWithDefaults() throws {
    let json = """
    {
      "width": 1024,
      "height": 1024,
      "jpegQuality": 0.8
    }
    """

    let settings = try JSONDecoder().decode(ImageExportSettings.self, from: Data(json.utf8))
    #expect(settings.width == 1024)
    #expect(settings.height == 1024)
    #expect(settings.jpegQuality == 0.8)
    #expect(settings.preset == .standard)
    #expect(settings.metadataMode == .none)
}

@Test
func exportPresetDefaultsAreAvailable() {
    let settings = ImageExportSettings.settings(for: .social)
    #expect(settings.width == 1080)
    #expect(settings.height == 1080)
    #expect(settings.preset == .social)
}

@Test
func studioPresetDecodesLegacyPayloadWithoutFavoriteFlag() throws {
    let profileID = UUID()
    let json = """
    {
      "id": "\(UUID().uuidString)",
      "profileID": "\(profileID.uuidString)",
      "name": "Legacy Preset",
      "layers": [],
      "createdAt": "2026-02-11T00:00:00Z",
      "updatedAt": "2026-02-11T00:00:00Z"
    }
    """

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let preset = try decoder.decode(StudioLayerPreset.self, from: Data(json.utf8))
    #expect(preset.name == "Legacy Preset")
    #expect(preset.isFavorite == false)
}

@Test
func sigilResultDecodesLegacyPayloadWithoutVersionFields() throws {
    let json = """
    {
      "profileID": "\(UUID().uuidString)",
      "vector": {
        "H_entropy": 0.42,
        "K_complexity": 0.58,
        "D_fractal_dim": 2.13,
        "S_symmetry": 0.67,
        "L_generator_length": 288
      },
      "bits9": {
        "bits": "011101110",
        "parity": "even"
      },
      "celestialName": "Thal Rion Kael Void",
      "lsystem": {
        "axiom": "F",
        "rules": {"F": "F[+F][-F]"},
        "angle": 27.5,
        "iterations": 4
      },
      "geometry": {
        "lines": [
          {"startX": 0.0, "startY": 0.0, "endX": 1.0, "endY": 1.0}
        ]
      }
    }
    """

    let decoded = try JSONDecoder().decode(SigilResult.self, from: Data(json.utf8))
    #expect(decoded.pipelineVersion == RFConstants.pipelineVersion)
    #expect(decoded.engineDataVersion == RFConstants.engineDataVersion)
    #expect(decoded.geometryHash == "")
}

@Test
func sigilResultPreservesExplicitLegacyVersionFields() throws {
    let json = """
    {
      "profileID": "\(UUID().uuidString)",
      "vector": {
        "H_entropy": 0.25,
        "K_complexity": 0.45,
        "D_fractal_dim": 2.40,
        "S_symmetry": 0.60,
        "L_generator_length": 144
      },
      "bits9": {
        "bits": "010101010",
        "parity": "odd"
      },
      "celestialName": "Aeth Caus Shad Cel",
      "lsystem": {
        "axiom": "X",
        "rules": {"X": "F[+X]-X"},
        "angle": 30,
        "iterations": 5
      },
      "geometry": {
        "lines": [
          {"startX": 0.0, "startY": 0.0, "endX": 0.0, "endY": 1.0}
        ]
      },
      "geometryHash": "legacy-hash",
      "pipelineVersion": "rf.pipeline.v1",
      "engineDataVersion": "yggdrasil.snapshot.2025-12-01"
    }
    """

    let decoded = try JSONDecoder().decode(SigilResult.self, from: Data(json.utf8))
    #expect(decoded.pipelineVersion == "rf.pipeline.v1")
    #expect(decoded.engineDataVersion == "yggdrasil.snapshot.2025-12-01")
    #expect(decoded.geometryHash == "legacy-hash")
}

@Test
func personProfileDecodesLegacyPayloadWithoutBirthOrderTotals() throws {
    let json = """
    {
      "id": "\(UUID().uuidString)",
      "givenName": "Alicia",
      "familyName": "Wolfsbane",
      "birthDetails": {
        "date": "2026-02-10T12:00:00Z",
        "isTimeUnknown": false
      },
      "birthOrder": 2,
      "birthplaceName": "Seattle",
      "birthplace": {
        "latitude": 47.6062,
        "longitude": -122.3321
      },
      "mother": {
        "birthOrder": 1,
        "hairColor": "Brown",
        "eyeColor": "Hazel"
      },
      "father": {
        "birthOrder": 3,
        "hairColor": "Black",
        "eyeColor": "Blue"
      },
      "traits": {
        "familyNames": [],
        "heritage": [],
        "petNames": [],
        "additionalTraits": {},
        "dynamicFields": [],
        "dynamicFieldValues": {}
      },
      "createdAt": "2026-02-10T12:00:00Z",
      "updatedAt": "2026-02-10T12:00:00Z"
    }
    """

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(PersonProfile.self, from: Data(json.utf8))
    #expect(decoded.birthOrderTotal == nil)
    #expect(decoded.mother.birthOrderTotal == nil)
    #expect(decoded.father.birthOrderTotal == nil)
}
