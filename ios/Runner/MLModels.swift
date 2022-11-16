//
//  MLModels.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/14.
//

import Foundation
import CoreML
import NaturalLanguage

@available(iOS 14, *)
class TagPredictor {
    let models: [NLModel]
    let modelCapacity = 25
    
    static let shared = try? TagPredictor()
    
    init() throws {
        // TODO: Use Cloud Deployment
        let config = MLModelConfiguration()
        let tagPredModelME = try NLModel(mlModel:TagPredictorME(configuration: config).model)
        let tagPredModelTL = try NLModel(mlModel:TagPredictorTL(configuration: config).model)
        
        models = [tagPredModelME, tagPredModelTL]
    }
    
    func suggest(_ text: String, threshold: Double = 0.15) -> [String] {
        var suggestions: Set<String> = Set<String>()
        for model in models {
            let labelHypotheses = model.predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: modelCapacity)
            suggestions = suggestions.union(labelHypotheses.filter({ key, value in
                return value >= threshold
            }).keys)
        }
        return suggestions.sorted()
    }
    
    func debugPredictTagForText(_ text: String, modelId: Int = 0) -> String {
        let labelHypotheses = self.models[modelId].predictedLabelHypotheses(for: text.stripToNLProcessableString(), maximumCount: modelCapacity)
        var string = ""
        for (label, confd) in labelHypotheses {
            if confd < 0.1 {
                continue
            }
            let roundedValue = round(confd * 100) / 100.0
            string += " \(label):\(roundedValue)"
        }
        return string
    }
}

extension String {
    /// Replace elements like formula and images to tags for ML to process.
    func stripToNLProcessableString() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Formula]")
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Image]")
        _ = try? NSRegularExpression(pattern: #"\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        _ = try? NSRegularExpression(pattern: #"(http|https)://.*\W"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        
        return String(text)
    }
}
