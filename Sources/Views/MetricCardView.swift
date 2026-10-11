import SwiftUI

public struct MetricCardView: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    public let systemImage: String
    public let accentColor: Color
    public var progress: Double? = nil

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        accentColor: Color,
        progress: Double? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.15))
                    )

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 5)

                        Capsule()
                            .fill(accentColor)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
