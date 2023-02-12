//
//  SceneDelegate.swift
//  TUSKitExample
//
//  Created by Tjeerd in ‘t Veen on 14/09/2021.
//

import UIKit
import SwiftUI
import TUSKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var tusClient: TUSClient!

    @State var isPresented = false
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        do {
            tusClient = try TUSClient(server: URL(string: "https://tusd.tusdemo.net/files")!, sessionIdentifier: "TUS DEMO", storageDirectory: URL(string: "/TUS")!)
            tusClient.delegate = self
            let remainingUploads = tusClient.start()
            switch remainingUploads.count {
            case 0:
                print("No files to upload")
            case 1:
                print("Continuing uploading single file")
            case let nr:
                print("Continuing uploading \(nr) file(s)")
            }
            
            // When starting, you can retrieve the locally stored uploads that are marked as failure, and handle those.
            // E.g. Maybe some uploads failed from a last session, or failed from a background upload.
            let ids = try tusClient.failedUploadIDs()
            for id in ids {
                // You can either retry a failed upload...
                try tusClient.retry(id: id)
                // ...alternatively, you can delete them too
                // tusClient.removeCacheFor(id: id)
            }
        } catch {
            assertionFailure("Could not fetch failed id's from disk, or could not instantiate TUSClient \(error)")
        }
        
        let photoPicker = PhotoPicker(tusClient: tusClient)
        
        let contentView = ContentView(photoPicker: photoPicker)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // We can already trigger background tasks. Once the background-scheduler runs, the tasks will upload.
        tusClient.scheduleBackgroundTasks()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}

extension SceneDelegate: TUSClientDelegate {
    
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
       print("TUSClient total upload progress: \(bytesUploaded) of \(totalBytes) bytes.")
    }
    
    func progressFor(id: UUID, context: [String: String]?, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
       print("TUSClient single upload progress: \(bytesUploaded) / \(totalBytes)")
    }
    
    func didStartUpload(id: UUID, context: [String : String]?, client: TUSClient) {
        print("TUSClient started upload, id is \(id)")
        print("TUSClient remaining is \(client.remainingUploads)")
    }
    
    func didFinishUpload(id: UUID, url: URL, context: [String : String]?, client: TUSClient) {
        print("TUSClient finished upload, id is \(id) url is \(url)")
        print("TUSClient remaining is \(client.remainingUploads)")
        if client.remainingUploads == 0 {
            print("Finished uploading")
        }
    }
    
    func uploadFailed(id: UUID, error: Error, context: [String : String]?, client: TUSClient) {
        print("TUSClient upload failed for \(id) error \(error)")
    }
    
    func fileError(error: TUSClientError, client: TUSClient) {
        print("TUSClient File error \(error)")
    }
    
    func didCreateUpload(id: UUID, url: URL, client: TUSClient) {
        print(url)
        client.scheduleTaskWithRemoteUrl(url: url)
    }
}
