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
    
    let imageHtmlLooseRegex = try! NSRegularExpression(pattern: #"<img src=.*?>"#)
    processedText = imageHtmlLooseRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let imageMarkDownRegex = try! NSRegularExpression(pattern: #"!\[\]\(.*?\)"#)
    processedText = imageMarkDownRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let htmlTagRegex = try! NSRegularExpression(pattern: #"<.*?>"#)
    processedText = htmlTagRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    let whiteSpaceRegex = try! NSRegularExpression(pattern: #"\s"#)
    processedText = whiteSpaceRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    return processedText
}

struct THPostView: View {
    var discussion: OTHole
    
    let KEY_NO_TAG = "默认"
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // Discussion Tag
            if (discussion.tags != nil && !discussion.tags!.isEmpty && !discussion.tags!.contains(where: {tag in if(tag.name == KEY_NO_TAG) {
                return true;
            }
            return false;
            })) {
                HStack {
                    ForEach(discussion.tags!, id: \.self) { tag in
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
            else {
                Spacer()
                Spacer()
            }
            
            // Begin Content
            if (!discussion.floors.prefetch[0].fold!.isEmpty) {
                /*Collapsible(
                    label: { Text("discussionFolded") },
                    content: {
                        HStack {
                            Text(preprocessTextForHtmlAndImage(text: discussion.posts[0].content))
                                .lineLimit(5)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary)
                    }
                )
                .frame(maxWidth: .infinity)*/
                Label("discussionFolded", systemImage: "eye.slash")
                    .scaleEffect(0.8, anchor: .leading)
            }
            else {
                Text(preprocessTextForHtmlAndImage(text: discussion.floors.prefetch[0].content))
                    .lineLimit(5)
            }
            Spacer()
            
            // Comment Count
            HStack(alignment: .bottom) {
                Label(String(discussion.reply!), systemImage: "ellipsis.bubble")
                    .font(.footnote)
                    .imageScale(.small)
                /*Label(humanReadableDateString(dateString: discussion.date_created) , systemImage: "clock")
                 .lineLimit(1)
                 .font(.footnote)
                 .imageScale(.small)*/
            }
            .padding(.bottom)
        }
    }
}

struct Collapsible<Content: View>: View {
    @State var label: () -> Text
    @State var content: () -> Content
    
    @State private var collapsed: Bool = true
    
    var body: some View {
        VStack {
            Button(
                action: { self.collapsed.toggle() },
                label: {
                    HStack {
                        self.label()
                        Spacer()
                        Image(systemName: self.collapsed ? "chevron.down" : "chevron.up")
                    }
                    .padding(.bottom, 1)
                    .background(Color.white.opacity(0.01))
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            VStack {
                self.content()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
            .clipped()
            .animation(.easeOut)
            .transition(.slide)
        }
    }
}

struct THPostView_Previews: PreviewProvider {
    static var previews: some View {
        Text("too lazy to write preview")
    }
}
