//
//  THPostView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import Foundation
import SwiftUI

func nsRange(self: String) -> NSRange {
    return NSRange(self.startIndex..., in: self)
}

func preprocessTextForHtmlAndImage(text: String) -> String {
    var processedText: String
    
    let imageHtmlRegex = try! NSRegularExpression(pattern: #"<img src=.*?>.*?</img>"#)
    processedText = imageHtmlRegex.stringByReplacingMatches(in: text, range: nsRange(self: text), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let imageMarkDownRegex = try! NSRegularExpression(pattern: #"!\[\]\(.*?\)"#)
    processedText = imageMarkDownRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let htmlTagRegex = try! NSRegularExpression(pattern: #"<.*?>"#)
    processedText = htmlTagRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    let whiteSpaceRegex = try! NSRegularExpression(pattern: #"\s"#)
    processedText = whiteSpaceRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    return processedText
}

struct THPostView: View {
    var discussion: THDiscussion
    
    var body: some View {
        VStack(alignment: .leading) {
            if (discussion.tag != nil && !discussion.tag!.isEmpty) {
                HStack {
                    ForEach(discussion.tag!, id: \.self) { tag in
                        Text(tag.name)
                            .padding(EdgeInsets(top: 2,leading: 6,bottom: 2,trailing: 6))
                            .background(RoundedRectangle(cornerRadius: 24, style: .circular).stroke(Color.accentColor))
                            .foregroundColor(.accentColor)
                            .font(.system(size: 14))
                            .lineLimit(1)
                    }
                }
                .padding(.top)
            }
            Text(preprocessTextForHtmlAndImage(text: discussion.posts[0].content))
                .lineLimit(2)
            Spacer()
            HStack(alignment: .bottom) {
                Label("\(discussion.count)", systemImage: "ellipsis.bubble")
                    .font(.footnote)
                    .imageScale(.small)
                Label(discussion.date_created, systemImage: "clock")
                    .lineLimit(1)
                    .font(.footnote)
                    .imageScale(.small)
            }
            .padding(.bottom)
        }
    }
}

struct THPostView_Previews: PreviewProvider {
    static var previews: some View {
        THPostView(discussion: THDiscussion(id: 123, count: 21, posts: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "2021-10-01", reply_to: nil, is_me: false)], last_post: nil, is_folded: false, date_created: "xxx", date_updated: "xxx", tag: [THTag(name: "test", color: "red", count: 5)]))
    }
}
