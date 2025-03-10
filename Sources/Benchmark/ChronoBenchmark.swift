// ChronoBenchmark.swift - Performance benchmarking for Chrono.swift
import Foundation
import Chrono

@main
struct ChronoBenchmark {
    static func main() {
        print("Chrono.swift Performance Benchmark")
        print("=================================\n")
        
        benchmarkEnglishParsers()
        benchmarkGermanParsers()
        benchmarkJapaneseParsers()
        benchmarkFrenchParsers()
        benchmarkSpanishParsers()
        benchmarkPortugueseParsers()
        // benchmarkDutchParsers() // Will be enabled once fully implemented
    }
    
    /// Benchmarks English parsers with various test cases
    static func benchmarkEnglishParsers() {
        print("\nEnglish Parsers Benchmark")
        print("------------------------")
        
        let testCases = [
            "Let's meet tomorrow at 2pm",
            "I need this done by January 15, 2024",
            "The meeting is scheduled for next Monday at 10:30am",
            "Please complete this by the end of this week",
            "The deadline is in 3 days",
            "The conference runs from March 15 to March 20, 2024",
            "The store opens at 9am and closes at 9pm",
            "Their flight arrives at 5:45pm on Tuesday",
            "We had dinner together last Friday evening",
            "The payment is due within 30 days"
        ]
        
        benchmarkParser(name: "English Casual", parser: Chrono.casual, testCases: testCases)
        benchmarkParser(name: "English Strict", parser: Chrono.strict, testCases: testCases)
    }
    
    /// Benchmarks German parsers with various test cases
    static func benchmarkGermanParsers() {
        print("\nGerman Parsers Benchmark")
        print("-----------------------")
        
        let testCases = [
            "Treffen wir uns morgen um 14 Uhr",
            "Dies muss bis zum 15. Januar 2024 erledigt sein",
            "Das Meeting ist für nächsten Montag um 10:30 Uhr geplant",
            "Bitte erledige das bis zum Ende dieser Woche",
            "Die Frist ist in 3 Tagen",
            "Die Konferenz läuft vom 15. März bis zum 20. März 2024",
            "Der Laden öffnet um 9 Uhr und schließt um 21 Uhr",
            "Ihr Flug kommt am Dienstag um 17:45 Uhr an",
            "Wir haben letzten Freitagabend zusammen zu Abend gegessen",
            "Die Zahlung ist innerhalb von 30 Tagen fällig"
        ]
        
        benchmarkParser(name: "German Casual", parser: Chrono.de.casual, testCases: testCases)
        benchmarkParser(name: "German Strict", parser: Chrono.de.strict, testCases: testCases)
    }
    
    /// Benchmarks Japanese parsers with various test cases
    static func benchmarkJapaneseParsers() {
        print("\nJapanese Parsers Benchmark")
        print("-------------------------")
        
        let testCases = [
            "明日の午後2時に会いましょう",
            "2024年1月15日までにこれを完了する必要があります",
            "会議は来週の月曜日の午前10時30分に予定されています",
            "今週末までにこれを完了してください",
            "締め切りは3日後です",
            "会議は2024年3月15日から3月20日まで開催されます",
            "店は午前9時に開店し、午後9時に閉店します",
            "彼らの飛行機は火曜日の午後5時45分に到着します",
            "先週の金曜日の夕方に一緒に夕食を食べました",
            "支払いは30日以内に行われます"
        ]
        
        benchmarkParser(name: "Japanese Casual", parser: Chrono.ja.casual, testCases: testCases)
        benchmarkParser(name: "Japanese Strict", parser: Chrono.ja.strict, testCases: testCases)
    }
    
    /// Benchmarks French parsers with various test cases
    static func benchmarkFrenchParsers() {
        print("\nFrench Parsers Benchmark")
        print("-----------------------")
        
        let testCases = [
            "Rencontrons-nous demain à 14h",
            "Cela doit être fait d'ici le 15 janvier 2024",
            "La réunion est prévue pour lundi prochain à 10h30",
            "Veuillez compléter ceci d'ici la fin de cette semaine",
            "La date limite est dans 3 jours",
            "La conférence se déroule du 15 mars au 20 mars 2024",
            "Le magasin ouvre à 9h et ferme à 21h",
            "Leur avion arrive à 17h45 mardi",
            "Nous avons dîné ensemble vendredi dernier soir",
            "Le paiement est dû dans 30 jours"
        ]
        
        benchmarkParser(name: "French Casual", parser: Chrono.fr.casual, testCases: testCases)
        benchmarkParser(name: "French Strict", parser: Chrono.fr.strict, testCases: testCases)
    }
    
    /// Benchmarks Spanish parsers with various test cases
    static func benchmarkSpanishParsers() {
        print("\nSpanish Parsers Benchmark")
        print("------------------------")
        
        let testCases = [
            "Reunámonos mañana a las 2 de la tarde",
            "Esto debe estar hecho para el 15 de enero de 2024",
            "La reunión está programada para el próximo lunes a las 10:30 de la mañana",
            "Por favor complete esto antes del final de esta semana",
            "La fecha límite es en 3 días",
            "La conferencia va del 15 de marzo al 20 de marzo de 2024",
            "La tienda abre a las 9 de la mañana y cierra a las 9 de la noche",
            "Su vuelo llega a las 5:45 de la tarde el martes",
            "Cenamos juntos el viernes pasado por la noche",
            "El pago vence en 30 días"
        ]
        
        benchmarkParser(name: "Spanish Casual", parser: Chrono.es.casual, testCases: testCases)
        benchmarkParser(name: "Spanish Strict", parser: Chrono.es.strict, testCases: testCases)
    }
    
    /// Benchmarks Portuguese parsers with various test cases
    static func benchmarkPortugueseParsers() {
        print("\nPortuguese Parsers Benchmark")
        print("---------------------------")
        
        let testCases = [
            "Vamos nos encontrar amanhã às 2 da tarde",
            "Isso precisa ser feito até 15 de janeiro de 2024",
            "A reunião está marcada para a próxima segunda-feira às 10:30 da manhã",
            "Por favor, complete isso até o final desta semana",
            "O prazo é em 3 dias",
            "A conferência ocorre de 15 de março a 20 de março de 2024",
            "A loja abre às 9 da manhã e fecha às 9 da noite",
            "O voo deles chega às 5:45 da tarde na terça-feira",
            "Jantamos juntos na sexta-feira passada à noite",
            "O pagamento deve ser feito em 30 dias"
        ]
        
        benchmarkParser(name: "Portuguese Casual", parser: Chrono.pt.casual, testCases: testCases)
        benchmarkParser(name: "Portuguese Strict", parser: Chrono.pt.strict, testCases: testCases)
    }
    
    /// Helper function to benchmark a parser with given test cases
    static func benchmarkParser(name: String, parser: Chrono, testCases: [String]) {
        print("\n\(name):")
        
        // Run a warmup to avoid initial JIT compilation effects
        for _ in 0..<10 {
            for testCase in testCases {
                _ = parser.parse(text: testCase)
            }
        }
        
        // Number of iterations for accurate timing
        let iterations = 100
        
        // Benchmark each test case
        var totalTime: Double = 0
        var totalResults: Int = 0
        
        for testCase in testCases {
            let start = Date()
            
            var resultCount = 0
            for _ in 0..<iterations {
                let results = parser.parse(text: testCase)
                resultCount += results.count
            }
            
            let end = Date()
            let timeElapsed = end.timeIntervalSince(start)
            let avgTimePerParse = (timeElapsed * 1000) / Double(iterations)
            
            totalTime += timeElapsed
            totalResults += resultCount / iterations
            
            print("  '\(testCase)': \(String(format: "%.3f", avgTimePerParse)) ms")
        }
        
        let avgTimePerCaseSet = (totalTime * 1000) / Double(testCases.count) / Double(iterations)
        print("  Average: \(String(format: "%.3f", avgTimePerCaseSet)) ms per parse")
        print("  Results found: \(totalResults/testCases.count) on average")
    }
    
    /// Dutch parsers benchmark will be enabled once fully implemented
    static func benchmarkDutchParsers() {
        print("\nDutch Parsers Benchmark")
        print("----------------------")
        
        let testCases = [
            "Laten we morgen om 14 uur afspreken",
            "Dit moet gedaan zijn voor 15 januari 2024",
            "De vergadering staat gepland voor volgende maandag om 10:30",
            "Gelieve dit voor het einde van deze week af te maken",
            "De deadline is over 3 dagen",
            "De conferentie loopt van 15 maart tot 20 maart 2024",
            "De winkel opent om 9 uur 's ochtends en sluit om 9 uur 's avonds",
            "Hun vlucht komt dinsdag om 17:45 aan",
            "We hebben vorige vrijdagavond samen gegeten",
            "De betaling moet binnen 30 dagen gedaan worden"
        ]
        
        benchmarkParser(name: "Dutch Casual", parser: Chrono.nl.casual, testCases: testCases)
        benchmarkParser(name: "Dutch Strict", parser: Chrono.nl.strict, testCases: testCases)
    }
}
