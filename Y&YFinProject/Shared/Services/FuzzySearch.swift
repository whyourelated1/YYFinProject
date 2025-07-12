import Foundation

protocol FuzzySearchable {
    func fuzzyMatch(query: String) -> Bool
    func fuzzyMatchWithWeight(query: String) -> FuzzySearchMatchResult
}

struct FuzzySearchMatchResult {
    let weight: Int
    let matchedParts: [NSRange]
}

extension String: FuzzySearchable {
    func fuzzyMatch(query: String) -> Bool {
        let compareString = self.lowercased()
        let searchString = query.lowercased()
        
        var searchIndex = searchString.startIndex
        
        for char in compareString {
            if searchIndex < searchString.endIndex && char == searchString[searchIndex] {
                searchIndex = searchString.index(after: searchIndex)
                if searchIndex == searchString.endIndex {
                    return true
                }
            }
        }
        
        return false
    }
    
    func fuzzyMatchWithWeight(query: String) -> FuzzySearchMatchResult {
        let compareString = Array(self.lowercased())
        let searchString = query.lowercased()
        
        var totalScore = 0
        var matchedParts = [NSRange]()
        var patternIndex = 0
        var currentScore = 0
        var currentMatchedPart = NSRange(location: 0, length: 0)
        
        for (index, character) in compareString.enumerated() {
            if patternIndex < searchString.count && character == Array(searchString)[patternIndex] {
                patternIndex += 1
                currentScore += 1
                currentMatchedPart.length += 1
            } else {
                currentScore = 0
                if currentMatchedPart.length != 0 {
                    matchedParts.append(currentMatchedPart)
                }
                currentMatchedPart = NSRange(location: index + 1, length: 0)
            }
            totalScore += currentScore
        }
        
        if currentMatchedPart.length != 0 {
            matchedParts.append(currentMatchedPart)
        }
        
        let totalMatchedLength = matchedParts.reduce(0) { $0 + $1.length }
        if searchString.count == totalMatchedLength {
            return FuzzySearchMatchResult(weight: totalScore, matchedParts: matchedParts)
        } else {
            return FuzzySearchMatchResult(weight: 0, matchedParts: [])
        }
    }
}
