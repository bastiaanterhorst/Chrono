// ZHNumeralTests.swift - Unit tests for Chinese numeral parsing.
import Testing
import Foundation
@testable import Chrono

/// `ZHConstants` accepts numbers in three scripts, because all three occur in ordinary Chinese
/// input: ASCII (`3`), full-width (`３`, what a Chinese IME emits in its default punctuation mode)
/// and Chinese numerals (`三`). The Japanese locale only ever handled the first two; ZH needs the
/// third because `三天后` is exactly as ordinary as `3天后`.
@Suite("ZH — numerals")
struct ZHNumeralTests {

    @Test func asciiAndFullWidthDigits() {
        #expect(ZHConstants.parseNumber("3") == 3)
        #expect(ZHConstants.parseNumber("15") == 15)
        #expect(ZHConstants.parseNumber("2026") == 2026)
        #expect(ZHConstants.parseNumber("３") == 3)
        #expect(ZHConstants.parseNumber("１５") == 15)
        #expect(ZHConstants.parseNumber("２０２６") == 2026)
    }

    @Test func chineseCardinals() {
        #expect(ZHConstants.parseNumber("零") == 0)
        #expect(ZHConstants.parseNumber("〇") == 0)
        #expect(ZHConstants.parseNumber("一") == 1)
        #expect(ZHConstants.parseNumber("二") == 2)
        #expect(ZHConstants.parseNumber("九") == 9)
    }

    /// 两/兩 is the counting form of "two" and is what actually appears before a measure word:
    /// 两天 (two days), never 二天.
    @Test func liangIsTwo() {
        #expect(ZHConstants.parseNumber("两") == 2)
        #expect(ZHConstants.parseNumber("兩") == 2)
    }

    /// A leading 十 means *one* ten: 十五 is 15, not 5.
    @Test func tensStructure() {
        #expect(ZHConstants.parseNumber("十") == 10)
        #expect(ZHConstants.parseNumber("十一") == 11)
        #expect(ZHConstants.parseNumber("十五") == 15)
        #expect(ZHConstants.parseNumber("二十") == 20)
        #expect(ZHConstants.parseNumber("二十三") == 23)
        #expect(ZHConstants.parseNumber("三十一") == 31)
        #expect(ZHConstants.parseNumber("五十") == 50)
    }

    @Test func hundredsStructure() {
        #expect(ZHConstants.parseNumber("一百") == 100)
        #expect(ZHConstants.parseNumber("一百二十三") == 123)
        #expect(ZHConstants.parseNumber("一百零五") == 105)
        #expect(ZHConstants.parseNumber("二百") == 200)
    }

    @Test func nonNumbersAreRejected() {
        #expect(ZHConstants.parseNumber("") == nil)
        #expect(ZHConstants.parseNumber("天") == nil)
        #expect(ZHConstants.parseNumber("周末") == nil)
        #expect(ZHConstants.parseNumber("3天") == nil)
        #expect(ZHConstants.parseNumber("abc") == nil)
    }

    /// Years are written as a *digit sequence*, not a cardinal: 二〇二六 is "two-zero-two-six".
    @Test func yearsReadAsDigitSequences() {
        #expect(ZHConstants.parseYear("二〇二六") == 2026)
        #expect(ZHConstants.parseYear("一九九九") == 1999)
        #expect(ZHConstants.parseYear("二零二六") == 2026)
        #expect(ZHConstants.parseYear("2026") == 2026)
        #expect(ZHConstants.parseYear("２０２６") == 2026)
    }

    @Test func twoDigitYearsExpand() {
        #expect(ZHConstants.normalizeYear(26) == 2026)
        #expect(ZHConstants.normalizeYear(49) == 2049)
        #expect(ZHConstants.normalizeYear(50) == 1950)
        #expect(ZHConstants.normalizeYear(85) == 1985)
        #expect(ZHConstants.normalizeYear(2026) == 2026)
    }

    @Test func offsetPrefixes() {
        #expect(ZHConstants.offset(forPrefix: "这") == 0)
        #expect(ZHConstants.offset(forPrefix: "這") == 0)
        #expect(ZHConstants.offset(forPrefix: "本") == 0)
        #expect(ZHConstants.offset(forPrefix: "下") == 1)
        #expect(ZHConstants.offset(forPrefix: "下下") == 2)
        #expect(ZHConstants.offset(forPrefix: "上") == -1)
        #expect(ZHConstants.offset(forPrefix: "上上") == -2)
        #expect(ZHConstants.offset(forPrefix: "明") == nil)
    }

    @Test func weekdayDictionaryUsesSundayZero() {
        // Sun = 0 … Sat = 6, matching every other locale in the library. 日 and 天 both mean Sunday.
        #expect(ZHConstants.WEEKDAY_DICTIONARY["日"] == 0)
        #expect(ZHConstants.WEEKDAY_DICTIONARY["天"] == 0)
        #expect(ZHConstants.WEEKDAY_DICTIONARY["一"] == 1)
        #expect(ZHConstants.WEEKDAY_DICTIONARY["六"] == 6)
    }
}
