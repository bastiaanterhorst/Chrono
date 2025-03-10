import Foundation

/**
 * When the parsed date is before the reference date but close (within a day or two),
 * this refiner adjusts it to a future date instead.
 *
 * For example, if today is Sept 15 and the parsed date is Sept 14,
 * it likely refers to next year's Sept 14 rather than yesterday.
 */
public final class ForwardDateRefiner: Refiner {
    
    public func refine(context: ParsingContext, results: [ParsingResult]) -> [ParsingResult] {
        // If the option is disabled, skip this refiner
        if !context.options.forwardDate {
            return results
        }
        
        // Get the reference date
        let refDate = context.reference.instant
        
        return results.map { result in
            // Skip if already has year
            if result.start.isCertain(.year) {
                return result
            }
            
            // Skip if the component isn't a DateTime
            guard let date = result.start.date() else {
                return result
            }
            
            // If the date is in the past by more than a few days, and not certain about the year,
            // then we shift the date forward
            if date < refDate {
                let dayDifference = Calendar.current.dateComponents([.day], from: date, to: refDate).day ?? 0
                
                // Only adjust if it's within a day or two, suggesting it's likely a reference to a future date
                if dayDifference > 0 && dayDifference <= 3 {
                    let calendar = Calendar.current
                    
                    // Try adjusting to next year
                    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                    components.year = (components.year ?? 0) + 1
                    
                    if let forwardDate = calendar.date(from: components) {
                        // Create a new components and mark year as certain
                        var updatedComponents = result.start.clone()
                        if let year = components.year {
                            updatedComponents.assign(.year, value: year)
                            updatedComponents.setCertain(.year)
                        }
                        
                        // Create a new result with updated components
                        return ParsingResult(
                            reference: result.reference,
                            index: result.index,
                            text: result.text,
                            start: updatedComponents,
                            end: result.end
                        )
                    }
                }
            }
            
            return result
        }
    }
}