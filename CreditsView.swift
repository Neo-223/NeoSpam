import SwiftUI

struct CreditsView: View {
    var body: some View {
        ZStack {
            Image("backgroundImage")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Credits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .shadow(radius: 10)
                
                Button(action: openReddit) {
                    Text("Reddit")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .frame(width: 200, height: 50)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                
                Button(action: openGitHub) {
                    Text("GitHub")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .frame(width: 200, height: 50)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func openReddit() {
        openURL(appURL: "reddit://www.reddit.com/u/Neo-223", webURL: "https://www.reddit.com/u/Neo-223/s/oHaDO24kUn")
    }
    
    func openGitHub() {
        openURL(appURL: "github://GitHub.com/Neo-223/NeoSpam", webURL: "https://GitHub.com/Neo-223/NeoSpam")
    }
    
    func openURL(appURL: String, webURL: String) {
        if let appURL = URL(string: appURL), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: webURL) {
            UIApplication.shared.open(webURL)
        }
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
