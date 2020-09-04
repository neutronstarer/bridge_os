//
//  AppDelegate.swift
//  Example
//
//  Created by neutronstarer on 2020/9/3.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController=ViewController()
        self.window?.makeKeyAndVisible()
        // Override point for customization after application launch.
        return true
    }

}

