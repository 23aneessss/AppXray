import SwiftUI
import AppKit
import AppXrayKit

struct ReportView: View {
    let report: AppReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                summaryCard
                badgesGrid
                signatureSection

                if !report.warnings.isEmpty {
                    section("Warnings", systemImage: "exclamationmark.triangle") {
                        ForEach(Array(report.warnings.enumerated()), id: \.offset) { _, w in
                            FindingRow(risk: w.risk, title: w.title, detail: w.detail)
                        }
                    }
                }
                if !report.entitlements.isEmpty {
                    section("Entitlements (\(report.entitlements.count))", systemImage: "key") {
                        ForEach(Array(report.entitlements.enumerated()), id: \.offset) { _, e in
                            FindingRow(risk: e.risk, title: e.title,
                                       detail: e.explanation, trailing: e.valueDescription)
                        }
                    }
                }
                if !report.privacyUsage.isEmpty {
                    section("Privacy resources it can request", systemImage: "hand.raised") {
                        ForEach(Array(report.privacyUsage.enumerated()), id: \.offset) { _, p in
                            FindingRow(risk: .notable, title: p.resource,
                                       detail: p.statedReason.isEmpty ? "(no reason given)" : p.statedReason)
                        }
                    }
                }
                if !report.privateFrameworks.isEmpty {
                    section("Private / undocumented frameworks", systemImage: "lock.shield") {
                        ForEach(report.privateFrameworks, id: \.self) { p in
                            Text(p).font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
                if !report.nestedComponents.isEmpty {
                    section("Nested components (\(report.nestedComponents.count))", systemImage: "shippingbox") {
                        ForEach(Array(report.nestedComponents.enumerated()), id: \.offset) { _, c in
                            let sb = c.sandboxed.map { $0 ? "sandboxed" : "not sandboxed" } ?? "—"
                            FindingRow(risk: .info, title: "\(c.kind): \(c.path)",
                                       detail: "\(c.signingSummary) · \(sb)")
                        }
                    }
                }
                if !report.networkHints.isEmpty {
                    section("Network hints (heuristic)", systemImage: "network") {
                        Text("Extracted statically from strings — not proof of any connection.")
                            .font(.caption).foregroundStyle(.orange)
                        ForEach(report.networkHints, id: \.self) { h in
                            Text(h).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Export as Markdown…") { export(.markdown) }
                    Button("Export as JSON…") { export(.json) }
                } label: { Label("Export", systemImage: "square.and.arrow.up") }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: report.bundlePath))
                .resizable().frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.name).font(.largeTitle).bold()
                if let id = report.bundleID {
                    Text(id).font(.callout).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let v = report.version { Label(v, systemImage: "number") }
                    Label(report.architectures.joined(separator: ", "),
                          systemImage: "cpu")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var summaryCard: some View {
        Text(report.summary)
            .font(.callout)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }

    private var badgesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(Array(report.badges.enumerated()), id: \.offset) { _, badge in
                HStack(spacing: 8) {
                    Image(systemName: badge.isOn ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(badge.isOn ? (badge.risk == .info ? Color.green : badge.risk.color) : Color.secondary)
                    Text(badge.label)
                        .font(.callout)
                        .foregroundStyle(badge.isOn ? .primary : .secondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var signatureSection: some View {
        section("Code signature", systemImage: "checkmark.seal") {
            LabeledContent("Signing") {
                Text(report.signature.kind.label).foregroundStyle(report.signature.kind.color)
            }
            if let team = report.signature.teamID { LabeledContent("Team ID", value: team) }
            LabeledContent("Hardened Runtime", value: report.signature.hardenedRuntime ? "yes" : "no")
            LabeledContent("Sandboxed", value: report.isSandboxed ? "yes" : "no")
            LabeledContent("Notarized", value: report.isNotarized ? "yes" : "no")
            LabeledContent("Gatekeeper accepts", value: report.gatekeeperAccepted ? "yes" : "no")
            if let leaf = report.signature.authorities.first {
                LabeledContent("Authority", value: leaf)
            }
        }
    }

    // MARK: Section helper

    private func section<Content: View>(_ title: String, systemImage: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        let inner = content()
        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) { inner }
                .padding(.top, 6)
        } label: {
            Label(title, systemImage: systemImage).font(.headline)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Export

    private enum Format { case markdown, json }

    private func export(_ format: Format) {
        let panel = NSSavePanel()
        let base = report.name.replacingOccurrences(of: " ", with: "-")
        switch format {
        case .markdown:
            panel.nameFieldStringValue = "\(base)-audit.md"
            panel.allowedContentTypes = [.init(filenameExtension: "md") ?? .plainText]
        case .json:
            panel.nameFieldStringValue = "\(base)-audit.json"
            panel.allowedContentTypes = [.json]
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let data: Data?
        switch format {
        case .markdown: data = report.markdown().data(using: .utf8)
        case .json: data = try? report.jsonData()
        }
        try? data?.write(to: url)
    }
}

/// A single titled finding row with a risk dot and optional trailing value.
private struct FindingRow: View {
    let risk: RiskLevel
    let title: String
    var detail: String = ""
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: risk.symbolName)
                .foregroundStyle(risk.color)
                .font(.caption)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(.callout).bold()
                    if let trailing {
                        Text(trailing)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}
