// KORelativeUnitParser.swift - 2주 후 / 3일 전 / 다음 주 / 이번 달 / 내년 / 주말.
import Foundation

/// Korean relative expressions, in two families.
///
/// **Counted** — a number, a unit and a direction: 2주 후 (in two weeks), 3일 전 (three days ago),
/// 6개월 뒤. 후 and 뒤 both mean "later", 전 means "ago".
///
/// **Named** — a modifier and a unit: 다음 주, 이번 달, 지난주, and the standalone 내년 / 작년 / 올해.
/// A named week resolves to a whole week (so it can schedule as one) rather than to a single day;
/// 주말 resolves instead to a concrete Saturday, because a weekend is days, not a week.
public struct KORelativeUnitParser: Parser {
    public init() {}

    private static let countedUnits: [String: Calendar.Component] = [
        "일": .day, "주일": .weekOfYear, "주": .weekOfYear,
        "개월": .month, "달": .month, "년": .year, "해": .year,
    ]

    public func pattern(context: ParsingContext) -> String {
        let s = KOConstants.optionalSpace
        let units = Self.countedUnits.keys.sorted { $0.count > $1.count }.joined(separator: "|")
        let modifiers = KOConstants.relativeModifiers.keys.sorted { $0.count > $1.count }
            .joined(separator: "|")
        // 1: count, 2: unit, 3: direction
        let counted = "(\\d{1,3})" + s + "(" + units + ")" + s + "(후|뒤|전|이내|안)"
        // 4: modifier, 5: named unit (주말 first so it wins over 주)
        let named = "(" + modifiers + ")" + s + "(주말|주|달|월|해|년)(?!요일)"
        // 6: standalone year words
        let standalone = "(내년|작년|올해|금년)"
        return "(?:" + counted + "|" + named + "|" + standalone + ")"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        let calendar = Calendar.current

        if let countStr = match.string(at: 1), let count = Int(countStr),
           let unitToken = match.string(at: 2), let unit = Self.countedUnits[unitToken],
           let direction = match.string(at: 3) {
            let signed = (direction == "전") ? -count : count
            guard let target = calendar.date(byAdding: unit, value: signed, to: context.refDate) else {
                return nil
            }
            let components = context.createParsingComponents()
            components.assignRelativeDate(from: target, unitIsTime: false, calendar: calendar)
            components.addTag("KORelativeUnitParser")
            return components
        }

        if let modifier = match.string(at: 4), let offset = KOConstants.relativeModifiers[modifier],
           let unit = match.string(at: 5) {
            switch unit {
            case "주말":
                guard let components = WeekendResolver.weekendComponents(
                    context: context, weekOffset: offset, localeIdentifier: "ko") else { return nil }
                components.addTag("KORelativeUnitParser")
                return components
            case "주":
                return weekComponents(context: context, offset: offset)
            case "달", "월":
                return shifted(context: context, component: .month, offset: offset, snapToFirst: true)
            default:
                return shifted(context: context, component: .year, offset: offset, snapToFirst: false)
            }
        }

        if let word = match.string(at: 6) {
            let offset = (word == "내년") ? 1 : (word == "작년" ? -1 : 0)
            return shifted(context: context, component: .year, offset: offset, snapToFirst: false)
        }

        return nil
    }

    /// A named week is a *week*, carried as week components so it schedules as one.
    private func weekComponents(context: ParsingContext, offset: Int) -> ParsingComponents? {
        let calendar = context.weekCalendar
        guard let target = calendar.date(byAdding: .weekOfYear, value: offset, to: context.refDate) else {
            return nil
        }
        let components = context.createParsingComponents()
        components.assign(.isoWeek, value: calendar.component(.weekOfYear, from: target))
        components.assign(.isoWeekYear, value: calendar.component(.yearForWeekOfYear, from: target))
        components.assignNull(.hour)

        var dc = DateComponents()
        dc.weekOfYear = calendar.component(.weekOfYear, from: target)
        dc.yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: target)
        dc.weekday = calendar.firstWeekday
        dc.hour = 12
        if let start = calendar.date(from: dc) {
            let v = calendar.dateComponents([.year, .month, .day], from: start)
            if let y = v.year { components.assign(.year, value: y) }
            if let m = v.month { components.assign(.month, value: m) }
            if let d = v.day { components.assign(.day, value: d) }
        }
        components.addTag("KORelativeUnitParser")
        return components
    }

    /// 다음 달 means the first of next month, the way "next month" does elsewhere; a year keeps the
    /// reference day.
    private func shifted(context: ParsingContext, component: Calendar.Component, offset: Int,
                         snapToFirst: Bool) -> ParsingComponents? {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: component, value: offset, to: context.refDate) else {
            return nil
        }
        let v = calendar.dateComponents([.year, .month, .day], from: target)
        guard let year = v.year, let month = v.month, let day = v.day else { return nil }
        let components = context.createParsingComponents()
        components.assign(.year, value: year)
        components.assign(.month, value: month)
        components.assign(.day, value: snapToFirst ? 1 : day)
        components.addTag("KORelativeUnitParser")
        return components
    }
}
