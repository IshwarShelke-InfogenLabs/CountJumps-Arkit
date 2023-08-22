/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image selection placeholder view and selection state.
*/

import SwiftUI
import PhotosUI
import SceneKit

// The view for each state of image selection.
struct HumanBodyImage: View {
    let imageState: HumanBodyPoseImageModel.ImageState
    var body: some View {
        switch imageState {
        case .success(let image):
            image.resizable()
        case .loading:
//            print(FrameHandler.instanse?.frame)
            ProgressView()
        case .noneselected:
            Image(systemName: "figure.arms.open")
                .font(.system(size: 80))
                .foregroundColor(.white)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
}


struct SelectablePersonPhotoView: View {
    @StateObject private var model = FrameHandler()
    @State var capture : Bool = false
    @State var showCamera : Bool = false
    @State var image: CGImage?
    
    // Displays the PhotosPicker view and the corresponding label view.
    var body: some View {
        VStack {
            
            FrameView(image: image)
                .ignoresSafeArea()
        }
    }
}
