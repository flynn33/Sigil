import RFCoreModels
import SwiftUI

struct DynamicFieldEditorRow: View {
    @Binding var field: DynamicFieldDraft
    let onDelete: () -> Void

    private static let isoFormatter = ISO8601DateFormatter()
    @State private var activeHelp: HelpTopic?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Custom Field")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .labelStyle(.iconOnly)
            }

            fieldEditor("Field Label", help: "Name shown to the user in this profile form.") {
                TextField("e.g. Spirit Animal", text: $field.label)
            }

            fieldEditor("Field Key", help: "Stable key used in deterministic sigil mapping. Use lowercase words with underscores.") {
                TextField("e.g. spirit_animal", text: $field.key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }

            fieldEditor("Section", help: "Groups this field with related fields in profile editing.") {
                TextField("e.g. Heritage", text: $field.section)
            }

            fieldEditor("Type", help: "Controls how value input works. Use choice types when options are predefined.") {
                Picker("Type", selection: $field.type) {
                    ForEach(DynamicFieldType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Toggle("Required", isOn: $field.isRequired)
                infoButton(
                    title: "Required",
                    message: "Required fields must have a value before the profile can be saved."
                )
            }

            if field.type.allowsOptions {
                fieldEditor("Options", help: "Comma-separated values available for single/multi-choice fields.") {
                    TextField("e.g. Raven, Wolf, Bear", text: $field.optionsRaw)
                        .textInputAutocapitalization(.never)
                }
            }

            fieldEditor("Value", help: "Current value saved to this profile for deterministic sigil generation.") {
                valueEditor
            }
        }
        .padding(.vertical, 6)
        .alert(item: $activeHelp) { topic in
            Alert(
                title: Text(topic.title),
                message: Text(topic.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func fieldEditor<Content: View>(
        _ title: String,
        help: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                infoButton(title: title, message: help)
            }
            content()
        }
    }

    private func infoButton(title: String, message: String) -> some View {
        Button {
            activeHelp = HelpTopic(title: title, message: message)
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Info about \(title)")
    }

    @ViewBuilder
    private var valueEditor: some View {
        switch field.type {
        case .boolean:
            Toggle("Value", isOn: Binding(
                get: { field.value.lowercased() == "true" || field.value == "1" },
                set: { field.value = $0 ? "true" : "false" }
            ))
            .labelsHidden()
        case .date:
            DatePicker("Value", selection: Binding(
                get: {
                    DynamicFieldEditorRow.isoFormatter.date(from: field.value) ?? .now
                },
                set: {
                    field.value = DynamicFieldEditorRow.isoFormatter.string(from: $0)
                }
            ))
            .labelsHidden()
        case .singleChoice:
            if field.parsedOptions.isEmpty {
                TextField("Value", text: $field.value)
            } else {
                Picker("Value", selection: Binding(
                    get: {
                        field.parsedOptions.contains(field.value) ? field.value : (field.parsedOptions.first ?? "")
                    },
                    set: { field.value = $0 }
                )) {
                    ForEach(field.parsedOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        case .multiChoice:
            TextField("Values (comma separated)", text: $field.value)
        case .number:
            TextField("Value", text: $field.value)
                .keyboardType(.decimalPad)
        case .text:
            TextField("Value", text: $field.value)
        }
    }
}

private struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
