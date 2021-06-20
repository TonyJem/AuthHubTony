/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AuthenticationServices
import SwiftUI

class SignInViewModel: NSObject, ObservableObject {
  @Published var isShowingRepositoriesView = false
  @Published private(set) var isLoading = false
  
  func signInTapped() {
    print("🟢 signInTapped")
    guard let signInURL = NetworkRequest.RequestType.signIn.networkRequest()?.url else {
      print("🔴 Could not create the sign in URL.")
      return
    }
    
    let callbackURLScheme = NetworkRequest.callbackURLScheme
    let authenticationSession = ASWebAuthenticationSession(url: signInURL, callbackURLScheme: callbackURLScheme) { [weak self] callbackURL, error in
      guard error == nil,
            let callbackURL = callbackURL,
            let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
            let code = queryItems.first(where: { $0.name == "code" })?.value,
            let networkRequest = NetworkRequest.RequestType.codeExchange(code: code).networkRequest()
      else {
        print("🔴 An error occurred when attempting to sign in.")
        return
      }
      
      self?.isLoading = true
      networkRequest.start(responseType: String.self) { result in
        switch result {
        case .success:
          self?.getUser()
        case .failure(let error):
          print("Failed to exchange access code for tokens: \(error)")
          self?.isLoading = false
        }
      }
    }
    
    authenticationSession.presentationContextProvider = self
    
    if !authenticationSession.start() {
      print("Failed to start ASWebAuthenticationSession")
    }
  }
  
  func appeared() {
    // Try to get the user in case the tokens are already stored on this device
    getUser()
  }
  
  private func getUser() {
  }
}

extension SignInViewModel: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession)
  -> ASPresentationAnchor {
    let window = UIApplication.shared.windows.first { $0.isKeyWindow }
    return window ?? ASPresentationAnchor()
  }
}
