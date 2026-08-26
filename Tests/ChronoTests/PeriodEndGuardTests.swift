import Testing
import Foundation
@testable import Chrono

/// End-of-period phrases are deliberately not read — but "not read" has to mean *unrecognised*,
/// not *reversed*. Before this guard, "end of next month" claimed the month on its own and resolved
/// to the **first**: 1 September for a phrase meaning the 30th, a month away from what was written,
/// with the "end of" left stranded in the task name. The same in Dutch, French, Japanese and Korean.
///
/// Reference: Wed 26 August 2026.
@Suite("End-of-period phrases are unread, not reversed")
struct PeriodEndGuardTests {
    private let ref = ParsingReference(instant: createDate(2026, 8, 26, 10))
    private let opts = ParsingOptions(forwardDate: true)

    private func dates(_ text: String, _ chrono: Chrono) -> [ParsedResult] {
        chrono.parse(text: text, referenceDate: ref, options: opts)
    }

    private func day(_ text: String, _ chrono: Chrono) -> (Int, Int)? {
        guard let r = dates(text, chrono).first else { return nil }
        let c = Calendar.current.dateComponents([.month, .day], from: r.start.date)
        return (c.month!, c.day!)
    }

    @Test func anEndOfPeriodPhraseYieldsNothing() {
        #expect(dates("report end of next month", EN.casual).isEmpty)
        #expect(dates("report end of next week", EN.casual).isEmpty)
        #expect(dates("rapport eind volgende maand", NL.casual).isEmpty)
        #expect(dates("rapport eind volgende week", NL.casual).isEmpty)
        #expect(dates("rapport fin du mois prochain", FR.casual).isEmpty)
        #expect(dates("来月末 レポート", JA.casual).isEmpty)
        #expect(dates("다음 달 말 보고서", KO.casual).isEmpty)
    }

    /// The *start* of a period already resolves correctly, so those phrases must keep working —
    /// the first of next month is exactly what "beginning of next month" means.
    @Test func startOfPeriodPhrasesStillResolve() {
        #expect(day("report beginning of next month", EN.casual)! == (9, 1))
        #expect(day("report start of next month", EN.casual)! == (9, 1))
        #expect(day("rapport begin volgende maand", NL.casual)! == (9, 1))
        #expect(day("rapport début du mois prochain", FR.casual)! == (9, 1))
    }

    /// A word the match *consumed* is not stranded, and must not trip the guard: Japanese 来週末 is
    /// "next weekend", one word carrying its own 末, and it is correct.
    @Test func aConsumedEndWordIsNotStranded() {
        #expect(day("来週末 レポート", JA.casual)! == (9, 5))
        #expect(day("今週末 レポート", JA.casual)! == (8, 29))
        #expect(day("다음 주말 보고서", KO.casual)! == (9, 5))
    }

    /// The bare relative phrases are untouched.
    @Test func plainRelativePhrasesAreUnaffected() {
        #expect(day("report next month", EN.casual)! == (9, 1))
        #expect(day("来月 レポート", JA.casual)! == (9, 1))
        #expect(day("다음 달 보고서", KO.casual)! == (9, 1))
        #expect(day("rapport volgende maand", NL.casual)! == (9, 1))
    }

    /// The guard reads only what sits *immediately* outside the match, so an end-word elsewhere in
    /// the sentence cannot suppress an unrelated date.
    @Test func anEndWordElsewhereDoesNotSuppress() {
        #expect(day("call mum tomorrow end of day", EN.casual)! == (8, 27))
        #expect(day("end of quarter review tomorrow", EN.casual)! == (8, 27))
    }

    /// Chinese reads these phrases properly — 月底 and 年底 are single words there, not preposition
    /// phrases — and keeps doing so.
    @Test func chineseStillReadsItsOwnPeriodWords() {
        #expect(day("下个月底 报告", ZH.casual)! == (9, 30))
        #expect(day("年底 报告", ZH.casual)! == (12, 31))
        #expect(day("月初 报告", ZH.casual)! == (9, 1))
    }
}
