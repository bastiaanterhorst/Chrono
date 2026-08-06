// ZHDeadlineParticleRefiner.swift - Pull a trailing 之前 / 前 / 内 into the matched date text.
import Foundation

/// Extends a result's matched text over an immediately following deadline particle — 之前, 以前,
/// 前, 之内, 以内, 内 — so that the host strips it along with the date.
///
/// The particle never changes *which* day is meant: `周五前提交报告` and `周五提交报告` are both due
/// Friday. It only decides whether the word survives into the task's name, and in Chinese that
/// matters more than it does in a Latin script. English leaves behind a recognisable stray word
/// ("before send email"); Chinese has no spaces, so the orphan fuses with whatever follows it into
/// something that reads as a different word — `周五前提交` strips to 「前提交」, which a reader parses
/// as 前提 ("premise") + 交. The name looks like a typo rather than a leftover.
///
/// ## Why the single-character forms need a guard
///
/// 之前/以前/之内/以内 are unambiguous: they cannot begin another word. A bare 前 or 内 can — 前往
/// ("to head for"), 前台 ("front desk"), 内容 ("content"), 内部 ("internal") — and swallowing the
/// first character of those would mangle the name in exactly the way this refiner exists to prevent.
/// So each bare form carries a list of the characters that would make it a word-opening rather than
/// a particle. `明天前往北京` keeps its 前; `周五前提交` loses it.
///
/// 提 is deliberately *not* in the 前 list. `前提` is a word, but after a date the deadline reading
/// (`周五前` + `提交`) is overwhelmingly the intended one, and 提交/提出/提醒 are among the commonest
/// verbs in a to-do list.
public struct ZHDeadlineParticleRefiner: Refiner {
    public init() {}

    /// The two-character particles, which need no guard, longest-first.
    private static let unambiguous = ["之前", "以前", "之内", "之內", "以内", "以內"]

    /// The one-character particles and the characters that would make each the start of a word
    /// instead. 前后/前後 is listed under 前 because 明天前后 ("around tomorrow") is a range, not a
    /// deadline, and this refiner has no business claiming it.
    private static let guarded: [(particle: String, notFollowedBy: Set<Character>)] = [
        ("前", Set("台檯往面方夕辈輩景后後线線身世任妻夫男女排沿头頭卫衛程期因者车車门門厅廳场場端锋鋒")),
        ("内", Set("容部心存在幕涵疚陆陸地外科衣裤褲饰飾分行勤")),
        ("內", Set("容部心存在幕涵疚陸地外科衣褲飾分行勤"))
    ]

    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        let characters = Array(context.text)

        return results.map { result in
            let end = result.index + result.text.count
            guard end < characters.count,
                  let particle = particle(after: end, in: characters) else {
                return result
            }

            let extended = ParsingResult(
                reference: result.reference,
                index: result.index,
                text: result.text + particle,
                start: result.start,
                end: result.end
            )
            for tag in result.getTags() {
                extended.addTag(tag)
            }
            extended.addTag("ZHDeadlineParticleRefiner")
            return extended
        }
    }

    /// The deadline particle beginning at `offset`, or nil when what follows is not one.
    private func particle(after offset: Int, in characters: [Character]) -> String? {
        let remaining = String(characters[offset...])

        for particle in Self.unambiguous where remaining.hasPrefix(particle) {
            return particle
        }

        for (particle, notFollowedBy) in Self.guarded where remaining.hasPrefix(particle) {
            let next = characters.count > offset + 1 ? characters[offset + 1] : nil
            if let next, notFollowedBy.contains(next) {
                return nil // 前往 / 内容 — the particle is the first character of another word
            }
            return particle
        }

        return nil
    }
}
