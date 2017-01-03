//
//  Extension.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/11/16.
//
//

import MongoDB
#if os(Linux)
    import SwiftGlibc
    import Foundation
#else
    import Cocoa
#endif

extension String
{
    func trim() -> String
    {
        return self == "" ? self : trimmingCharacters(in: CharacterSet(charactersIn: ", \n"))
    }
}


func doMongoDB(code:(_ collection:MongoCollection) throws -> Void)
{
    do
    {
        let client = try! MongoClient(uri: "mongodb://localhost:27017")
        
        let db = client.getDatabase(name: "test")
        
        guard let collection = db.getCollection(name: "movie-data") else { return }
        
        try code(collection)
        
        defer
        {
            collection.close()
            db.close()
            client.close()
        }
    }
    catch
    {
        print(error)
    }
}

//func timerTask(with timeInterval:UInt32,code:@escaping ()->Void)
//{
//    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
//        code()
//        sleep(timeInterval)
//        timerTask(with: timeInterval, code: code)
//    }
//    
//}
