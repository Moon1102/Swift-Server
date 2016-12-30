//
//  ServerPush.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/12/8.
//
//

#if os(Linux)
    import SwiftGlibc
#else
    import Cocoa
#endif
import PerfectLib
import PerfectNet
import PerfectNotifications

struct serverPush
{
    static let shared = serverPush()
    private let configurationName = "moviePush"
   
    private init()
    {
        //准备通知并只初始化一次。
        NotificationPusher.addConfigurationIOS(name: configurationName)
        {
            (net:NetTCPSSL) in
            
            // This code will be called whenever a new connection to the APNS service is required.
            // Configure the SSL related settings.
            
            net.keyFilePassword = "cheergo1975"

            guard
                net.useCertificateChainFile(cert: "./webroot/Cer/ck.pem") &&
                net.useCertificateFile(cert: "./webroot/Cer/PushChatCert.pem") &&
                net.usePrivateKeyFile(cert: "./webroot/Cer/PushChatKey.pem") &&
                net.checkPrivateKey()
            else
            {
                print("Error validating private key file: \(net.errorStr(forCode: Int32(net.errorCode())))")
                return
            }
        }
        
        NotificationPusher.development = true // set to toggle to the APNS sandbox server
        // END one-time initialization code
    }
    
    // BEGIN - individual notification push
    func beginPush()
    {
        let deviceId = ["ee340c55cfde6115d071807918f83f87e3e8a2e112dac0192e8204fe7335ed5f"]
        let ary = [IOSNotificationItem.alertBody("收到通知了，做点什么好呢?"), IOSNotificationItem.sound("default")]
        
        let n = NotificationPusher()
        n.apnsTopic = "com.joekoe.push"
        n.pushIOS(configurationName: configurationName, deviceTokens: deviceId, expiration: 0, priority: 10, notificationItems: ary)
        {
            for response in $0
            {
                if case .ok = response.status{} else
                {
                    debugPrint("NotificationResponse: \(response.status)" + (String(data: Data(bytes: response.body), encoding: .utf8) ?? ""))
                }
            }
        }
    }
}
