import Foundation

/// Drops a result that an adjacent "end of the period" word contradicts.
///
/// Chrono does not read end-of-period phrases — except in Chinese, where 月底 and 年底 are single
/// lexical words rather than preposition phrases. Everywhere else the words go unread, and that
/// would be unremarkable if the phrase simply came back unrecognised. It did not: the relative
/// month inside it was claimed on its own and resolved to the **first**, so "end of next month"
/// booked 1 September rather than the 30th — the opposite end, a month out — and left the "end of"
/// stranded in the task name.
///
/// So a phrase Chrono cannot read must come back unrecognised, never reversed. This refiner drops a
/// result when an end-word sits immediately outside its match.
///
/// Two distinctions keep it narrow:
///
/// - Only *end* words. "beginning of next month" resolves to the 1st, which is exactly right, so
///   start-words are deliberately absent and those phrases keep working.
/// - Only words the match left behind. Japanese 来週末 ("next weekend") consumes its own 末 and is
///   correct; it is 来月末, where the 末 is stranded outside the match, that is wrong.
struct PeriodEndGuardRefiner: Refiner {
    /// End-words that stand *before* the date phrase, as in "end of next month" (matched
    /// case-insensitively against the text immediately preceding the result).
    let precedingWords: [String]

    /// End-words that follow the date phrase directly, as the Japanese and Korean suffixes do.
    let followingWords: [String]

    init(precedingWords: [String] = [], followingWords: [String] = []) {
        self.precedingWords = precedingWords
        self.followingWords = followingWords
    }

    func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        guard !precedingWords.isEmpty || !followingWords.isEmpty else { return results }
        let text = context.text as NSString

        return results.filter { result in
            let start = max(0, min(result.index, text.length))
            let end = max(start, min(result.index + (result.text as NSString).length, text.length))

            if !precedingWords.isEmpty {
                let before = text.substring(to: start)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if precedingWords.contains(where: { before.hasSuffix($0) }) { return false }
            }

            if !followingWords.isEmpty {
                let after = text.substring(from: end)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if followingWords.contains(where: { after.hasPrefix($0) }) { return false }
            }

            return true
        }
    }
}
