import Foundation

/// Drops a result that the words immediately around it contradict.
///
/// A date parser sees digits and month names; it cannot see that "version 2.4" is a release,
/// "Kapitel 12.4" a section, "3/4 inch" a measurement or "um 5 cm" a length. Each of those parses
/// perfectly well as a date or a time, and in a to-do app the result is worse than a miss: a wrong
/// day is booked *and* the words are stripped out of the task name.
///
/// What tells them apart is the company they keep. A number introduced by a word that names
/// something numbered — version, chapter, model, flight, room — is an identifier. A number followed
/// by a unit is a measurement. A pair introduced by "ratio" is a proportion. None of them are ever
/// dates, in any language, so a locale can simply list its words.
///
/// Deliberately narrow, for the same reason the lists are hand-written rather than clever:
///
/// - Only words *immediately* adjacent to the match, so an unrelated date elsewhere in the line
///   survives — "call the plumber about the 3/4 inch pipe tomorrow" still schedules tomorrow.
/// - Whole words only, so "m" does not fire inside "monday" and "no" not inside "november".
/// - It removes readings; it never adds one. A phrase this drops comes back unrecognised, with the
///   task name intact, which is the right answer for something that was never a date.
struct AdjacentWordGuardRefiner: Refiner {
    /// Words that, standing immediately before a match, mean it is not a date: the nouns that
    /// introduce a numbered thing, and the ones that introduce a proportion.
    let precedingWords: [String]

    /// Words that, following a match directly, mean the same: units of measure, and the suffixes
    /// that turn a number into a quantity.
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
                if precedingWords.contains(where: { endsWithWord(before, $0) }) { return false }
            }

            if !followingWords.isEmpty {
                let after = text.substring(from: end)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if followingWords.contains(where: { startsWithWord(after, $0) }) { return false }
            }

            return true
        }
    }

    /// `haystack` ends with `word` *as a word* — so "version" fires on "to version" but not on
    /// "subversion".
    private func endsWithWord(_ haystack: String, _ word: String) -> Bool {
        guard haystack.hasSuffix(word) else { return false }
        let boundary = haystack.index(haystack.endIndex, offsetBy: -word.count)
        guard boundary > haystack.startIndex else { return true }
        return !haystack[haystack.index(before: boundary)].isLetter
    }

    /// `haystack` starts with `word` *as a word* — so "cm" fires on "cm long" but not on "cmd".
    private func startsWithWord(_ haystack: String, _ word: String) -> Bool {
        guard haystack.hasPrefix(word) else { return false }
        let boundary = haystack.index(haystack.startIndex, offsetBy: word.count)
        guard boundary < haystack.endIndex else { return true }
        return !haystack[boundary].isLetter
    }
}
