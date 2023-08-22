//  FrameView.swift
//  LiveCamera
//  Created by Ishwar Shelke

import SwiftUI

struct FrameView: View {
    
    var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        ZStack{
            if let image = image {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                Color.black
            }
        }
    }
}

//struct FrameView_Previews: PreviewProvider {
//    static var previews: some View {
//        FrameView()
//    }
//}
