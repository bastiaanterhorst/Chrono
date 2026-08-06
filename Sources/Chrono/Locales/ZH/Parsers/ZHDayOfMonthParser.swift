// ZHDayOfMonthParser.swift - Parser for a bare day of the month: 15号, 十五号
import Foundation

/// Parser for a day of the month written without its month: `15号`, `十五号`, `５号`, `31號`.
///
/// This is the form Chinese uses for everything that recurs monthly — `15号交房租` (rent on the
/// 15th), `10号发工资` (payday on the 10th), `25号还信用卡` (credit card on the 25th). It has no real
/// English counterpart: where English picks between "July 15", "the 15th" and "7/15", Chinese drops
/// the month and says `15号`, so leaving it unparsed costs a Chinese user far more than leaving
/// "the 15th" unparsed costs an English one.
///
/// ## Why only 号, and never 日
///
/// `日` is also the *day unit* (`3日后` = "three days later"), and the two readings collide head-on
/// in the shapes that matter: `15日前` is "before the 15th" but `3日前` is "three days ago", and
/// nothing in the text tells them apart. `号` carries no such second meaning, and it is the everyday
/// form in any case — the formal `日` almost always appears with its month (`3月15日`), which
/// `ZHStandardParser` already reads. So the bare form is deliberately 号/號 only.
///
/// ## Why this needs three guards rather than one
///
/// 号 is how Chinese labels almost everything numbered: 3号线 (metro line 3), 5号楼 (building 5),
/// 5号电池 (an AA battery), 会议室2号, 42号鞋, 大号/中号/小号. Getting a *wrong date* out of "buy AA
/// batteries" would be far worse than getting no date, so three independent layers have to agree:
///
/// 1. **`NOT_AFTER_IDENTIFIER_CONTAINER`** — a container noun before the number makes it a label
///    (会议室2号, 工位3号, 大号).
/// 2. **`NOT_AN_IDENTIFIER_NOUN`** — a classifier after 号 does the same from the right (3号线,
///    5号楼, 5号电池).
/// 3. **the 1…31 range** — which on its own removes most room and phone numbers.
///
/// A month or year immediately before the number is excluded too, so `3月15号` and `下个月15号` stay
/// whole expressions owned by `ZHStandardParser` and `ZHRelativeUnitKeywordParser`.
public struct ZHDayOfMonthParser: Parser {
    public init() {}

    public func pattern(context: ParsingContext) -> String {
        // `(?<![月年])` keeps this from firing inside a full date; the digit lookbehind keeps the
        // day from starting inside a longer number (2015号 is not "the 15th").
        return ZHConstants.NOT_AFTER_IDENTIFIER_CONTAINER
            + "(?<![月年0-9０-９])"
            + "(\(ZHConstants.NUMBER))\\s*(?:号|號)"
            + ZHConstants.NOT_AN_IDENTIFIER_NOUN
    }

    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        guard let dayText = match.string(at: 1),
              let day = ZHConstants.parseNumber(dayText),
              (1...31).contains(day),
              let (year, month) = resolveMonth(containing: day, context: context) else {
            return nil
        }

        let components = context.createParsingComponents()
        // The day is what the text actually stated; the month and year were inferred around it.
        components.assign(.day, value: day)
        components.imply(.month, value: month)
        components.imply(.year, value: year)
        components.addTag("ZHDayOfMonthParser")
        return components
    }

    /// Picks the month this day belongs to: the reference month, rolled forward when the day has
    /// already passed and the caller asked for forward dates.
    ///
    /// The roll also skips months that do not contain the day at all, so `31号` in February lands on
    /// the 31st of a month that has one instead of silently overflowing into the 1st of the next.
    private func resolveMonth(containing day: Int, context: ParsingContext) -> (year: Int, month: Int)? {
        let calendar = Calendar.current
        let reference = calendar.dateComponents([.year, .month, .day], from: context.refDate)
        guard let referenceYear = reference.year,
              let referenceMonth = reference.month,
              let referenceDay = reference.day,
              var candidate = calendar.date(from: DateComponents(year: referenceYear, month: referenceMonth, day: 1))
        else {
            return nil
        }

        if context.options.forwardDate, day < referenceDay {
            guard let next = calendar.date(byAdding: .month, value: 1, to: candidate) else { return nil }
            candidate = next
        }

        // Twelve tries is more than enough: every day 1…31 occurs within any seven consecutive months.
        for _ in 0..<12 {
            if let range = calendar.range(of: .day, in: .month, for: candidate), range.contains(day) {
                let values = calendar.dateComponents([.year, .month], from: candidate)
                guard let year = values.year, let month = values.month else { return nil }
                return (year, month)
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: candidate) else { return nil }
            candidate = next
        }
        return nil
    }
}
