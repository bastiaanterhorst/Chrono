// ZHIntegrationRegressionTests.swift - End-to-end Chinese phrases through the full pipeline.
import Testing
import Foundation
@testable import Chrono

/// These exercise the whole configuration — parsers, the ZH refiners, and the shared common
/// refiners — on the kind of text a user actually types into a task field.
///
/// Reference: Tuesday 2026-02-17 12:00.
@Suite("ZH — integration")
struct ZHIntegrationTests {

    /// Chinese has no spaces, so a date and a time sit flush against each other. The merge refiner
    /// must treat a **zero-length gap** as the ordinary case, not the exception.
    @Test func dateAndTimeMergeWithNoSeparator() {
        zhExpectDay("明天下午3点", 2026, 2, 18)
        zhExpectTime("明天下午3点", hour: 15)
        #expect(zhParse("明天下午3点").count == 1, "明天下午3点 must merge into one result")

        zhExpectDay("下周三上午10点", 2026, 2, 25)
        zhExpectTime("下周三上午10点", hour: 10)

        zhExpectDay("2026年3月15日晚上8点", 2026, 3, 15)
        zhExpectTime("2026年3月15日晚上8点", hour: 20)
    }

    /// 的 is the usual connector when one is written at all.
    @Test func dateAndTimeMergeAcrossAConnector() {
        zhExpectDay("明天的下午3点", 2026, 2, 18)
        zhExpectTime("明天的下午3点", hour: 15)
    }

    @Test func dateAndColonTimeMerge() {
        zhExpectDay("3月15日 14:30", 2026, 3, 15)
        zhExpectTime("3月15日 14:30", hour: 14, minute: 30)
    }

    /// A date range yields one result carrying both endpoints.
    @Test func dateRangesMerge() {
        let results = zhParse("3月1日到3月5日")
        #expect(results.count == 1, "a range is one result, got \(results.map { $0.text })")
        guard let r = results.first else { return }
        let cal = Calendar.current
        let start = cal.dateComponents([.month, .day], from: r.start.date)
        #expect((start.month, start.day) == (3, 1), "range start")
        #expect(r.end != nil, "range must carry an end")
        if let end = r.end {
            let e = cal.dateComponents([.month, .day], from: end.date)
            #expect((e.month, e.day) == (3, 5), "range end")
        }
    }

    @Test func dateRangeConnectorVariants() {
        for text in ["3月1日到3月5日", "3月1日至3月5日", "3月1日-3月5日", "3月1日~3月5日"] {
            let results = zhParse(text)
            #expect(results.first?.end != nil, "「\(text)」should produce a range")
        }
    }

    /// 从 precedes the first date and is simply left unconsumed.
    @Test func rangeWithLeadingCong() {
        #expect(zhParse("从3月1日到3月5日").first?.end != nil, "从…到… is a range")
    }

    /// Real task-field text: the date is found inside a sentence with no delimiters at all.
    @Test func datesInsideRunningText() {
        zhExpectDay("明天和张三开会", 2026, 2, 18)
        zhExpectDay("下周三提交报告", 2026, 2, 25)
        zhExpectDay("3月15日之前完成设计稿", 2026, 3, 15)
        zhExpectDay("买牛奶今天", 2026, 2, 17)
    }

    /// The matched span must cover only the date expression, so a consumer can strip it out and
    /// keep the rest of the task name.
    @Test func matchedSpanIsTheDateOnly() {
        #expect(zhParse("明天开会").first?.text == "明天")
        #expect(zhParse("开会明天").first?.text == "明天")
        #expect(zhParse("下周三提交报告").first?.text == "下周三")
    }

    /// Results stay ordered by their position in the text (the library sorts after refining).
    @Test func multipleDatesStayOrdered() {
        let results = zhParse("今天写代码，明天开会")
        #expect(results.count >= 2, "both dates should be found")
        if results.count >= 2 {
            #expect(results[0].index < results[1].index, "results must be index-ordered")
        }
    }

    /// The strict configuration drops the casual keywords but keeps the formal formats.
    @Test func strictConfigurationDropsCasualKeywords() {
        let strict = Chrono.zh.strict
        let opts = ParsingOptions(forwardDate: false)
        #expect(strict.parse(text: "今天", referenceDate: zhRef, options: opts).isEmpty,
                "strict drops casual keywords")
        #expect(!strict.parse(text: "2026年3月15日", referenceDate: zhRef, options: opts).isEmpty,
                "strict keeps formal dates")
    }

    /// Parsing the same text twice must give the same answer — the library re-sorts by index after
    /// refining precisely so that set-keyed refiners cannot make output order process-dependent.
    @Test func parsingIsDeterministic() {
        let first = zhParse("下周三上午10点和张三开会").map { "\($0.index):\($0.text)" }
        for _ in 0..<5 {
            let again = zhParse("下周三上午10点和张三开会").map { "\($0.index):\($0.text)" }
            #expect(again == first, "parse must be deterministic")
        }
    }

    /// Traditional-script input is accepted by the same locale.
    @Test func traditionalScriptEndToEnd() {
        zhExpectDay("下週三", 2026, 2, 25)
        zhExpectDay("三天後", 2026, 2, 20)
        zhExpectDay("兩個月後", 2026, 4, 17)
        zhExpectDay("二〇二六年三月十五日", 2026, 3, 15)
    }
}
