import Foundation

/**
 * Abstract parser that checks for word boundaries around the matched text.
 * This helps prevent partial matches within larger words.
 */
public class AbstractParserWithWordBoundaryChecking: Parser, @unchecked Sendable {
    public func pattern(context: ParsingContext) -> String {
        return innerPattern(context: context)
    }
    
    public func extract(context: ParsingContext, match: TextMatch) -> Any? {
        return innerExtract(context: context, match: match)
    }
    
    /**
     * The pattern to use for matching. Subclasses must override this.
     */
    func innerPattern(context: ParsingContext) -> String {
        fatalError("Subclasses must override innerPattern")
    }
    
    /**
     * Extract date components from a match. Subclasses must override this.
     */
    func innerExtract(context: ParsingContext, match: TextMatch) -> Any? {
        fatalError("Subclasses must override innerExtract")
    }
}