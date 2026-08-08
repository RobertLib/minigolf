//
//  MusicCreditsView.swift
//  Minigolf
//
//  The soundtrack's attribution, as a screen a player can reach.
//

import SwiftUI

/// Every track in the game, grouped by who wrote it.
///
/// This exists because CC-BY asks for the title of the work, the name of the
/// author and a link to the source — not just a thank-you. A markdown file
/// beside the audio satisfies none of that, since nobody who plays the game can
/// open it. The contents come from `MusicLibrary.swift`, which the importer
/// generates from the same manifest the audio is built from, so swapping a
/// track changes this screen with it.
struct MusicCreditsView: View {
    var body: some View {
        List {
            ForEach(MusicWork.byAuthor, id: \.author) { group in
                Section {
                    ForEach(group.works) { work in
                        Link(destination: work.url) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(work.title)
                                    .font(.system(.subheadline, design: .rounded,
                                                  weight: .medium))
                                    .foregroundStyle(.primary)
                                Text(work.licence)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(group.author)
                }
            }

            Section {
                Text("Thank you to everyone who released their music freely.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Music Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}
