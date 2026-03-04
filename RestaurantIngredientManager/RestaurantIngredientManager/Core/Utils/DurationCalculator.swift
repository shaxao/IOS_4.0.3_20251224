import Foundation

enum DurationCalculator {
    static func totalMinutes(for value: DurationValue) -> Int {
        let amount = max(value.amount, 0)
        switch value.unit {
        case .minute:
            return amount
        case .hour:
            return amount * 60
        case .day:
            return amount * 24 * 60
        case .month:
            return amount * 30 * 24 * 60
        case .year:
            return amount * 365 * 24 * 60
        case .custom:
            return max(value.customMinutes ?? amount, 0)
        }
    }

    static func add(_ duration: DurationValue, to date: Date, calendar: Calendar = .current) -> Date {
        let safeAmount = max(duration.amount, 0)
        switch duration.unit {
        case .minute:
            return calendar.date(byAdding: .minute, value: safeAmount, to: date) ?? date
        case .hour:
            return calendar.date(byAdding: .hour, value: safeAmount, to: date) ?? date
        case .day:
            return calendar.date(byAdding: .day, value: safeAmount, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: safeAmount, to: date) ?? date
        case .year:
            return calendar.date(byAdding: .year, value: safeAmount, to: date) ?? date
        case .custom:
            let minutes = max(duration.customMinutes ?? safeAmount, 0)
            return calendar.date(byAdding: .minute, value: minutes, to: date) ?? date
        }
    }

    static func formatAsChineseDuration(_ duration: DurationValue) -> String {
        let minutes = totalMinutes(for: duration)
        let years = minutes / (365 * 24 * 60)
        let remAfterYear = minutes % (365 * 24 * 60)
        let months = remAfterYear / (30 * 24 * 60)
        let remAfterMonth = remAfterYear % (30 * 24 * 60)
        let days = remAfterMonth / (24 * 60)
        let remAfterDay = remAfterMonth % (24 * 60)
        let hours = remAfterDay / 60
        let mins = remAfterDay % 60
        return "\(years)年\(months)月\(days)日\(hours)时\(mins)分"
    }
}
