//
//  HeroBackgroundView.swift
//  DirectorStudio
//
//  Cinematic hero background with vintage camera theme
//

import SwiftUI

struct HeroBackgroundView: View {
    var body: some View {
        ZStack {
            // Hero image background
            Image("Hero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay for better text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Subtle gradient overlay for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct HeroBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        HeroBackgroundView()
    }
}
