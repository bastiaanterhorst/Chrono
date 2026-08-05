// ZHRelativeUnitKeywordParser.swift - Parser for expressions like 下个月 and 明年
import Foundation

/// Parser for Chinese relative keyword unit expressions: months (`这个月`, `本月`, `下个月`, `上上月`)
/// and years (`今年`, `明年`, `后年`, `去年`, `前年`).
///
/// Linguistic notes:
///
/// - The month forms are generated from the shared offset-prefix lexicon plus the optional measure
///   word 个/個, so 这月 / 这个月 / 這個月 / 本月 / 下月 / 下个月 / 下個月 / 下下个月 / 上月 / 上个月 /
///   上上个月 are all one alternative, read back through `ZHConstants.offset(forPrefix:)`.
/// - A trailing `(?![亮球])` is mandatory. Chinese has no word boundaries — ICU classifies Han as
///   `\w`, so `\b` never fires between two Han characters — and 月亮 / 月球 (the moon) begin exactly
///   where a month word ends: `这个月亮很美` is "this moon is beautiful", not a date.
/// - The year words are a closed two-character list, none a prefix of another. Three carry an
///   explicit guard because they also occur inside ordinary vocabulary: 说明年度 (说明 + 年度),
///   以后年度 / 今后年度, and 上年纪 ("to grow old").
public struct ZHRelativeUnitKeywordParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // Group 2 captures the offset prefix, which is what distinguishes a month from a year below.
        let month = "(\(ZHConstants.OFFSET_PREFIX))(?:个|個)?月(?![亮球])"
        let year = "(?:今年|本年|(?<![说說])明年|来年|來年|(?<![以之今此])(?:后年|後年)|去年|上年(?![纪紀])|前年)"
        return "(\(month)|\(year))"
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let text = match.string(at: 1) else {
            return nil
        }

        let calendarUnit: Calendar.Component
        let offset: Int

        if let prefix = match.string(at: 2), !prefix.isEmpty {
            // A month: the offset is carried entirely by the prefix (这/這/本 = 0, 下 = +1,
            // 下下 = +2, 上 = -1, 上上 = -2).
            guard let prefixOffset = ZHConstants.offset(forPrefix: prefix) else { return nil }
            calendarUnit = .month
            offset = prefixOffset
        } else {
            calendarUnit = .year
            switch text {
            case "今年", "本年":
                offset = 0
            case "明年", "来年", "來年":
                offset = 1
            case "后年", "後年":
                offset = 2
            case "去年", "上年":
                offset = -1
            case "前年":
                offset = -2
            default:
                return nil
            }
        }

        guard let targetDate = Calendar.current.date(
            byAdding: calendarUnit,
            value: offset,
            to: context.reference.instant
        ) else {
            return nil
        }

        let values = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        let component = context.createParsingComponents()

        if let year = values.year {
            component.assign(.year, value: year)
        }
        if let month = values.month {
            component.assign(.month, value: month)
        }
        // A relative MONTH means the 1st of that month (start of the unit), not the reference
        // day-of-month — matching how a relative week anchors to its Monday.
        if calendarUnit == .month {
            component.assign(.day, value: 1)
        } else if let day = values.day {
            component.assign(.day, value: day)
        }

        component.addTag("ZHRelativeUnitKeywordParser")
        return component
    }
}
