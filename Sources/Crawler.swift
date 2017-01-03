//
//  Crawler.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/12/5.
//
//

#if os(Linux)
    import SwiftGlibc
#endif

import Foundation
import PerfectThread
import MongoDB
import PerfectLogger

struct myCrawler
{
    private var url:String
    
    init(url:String)
    {
        self.url = url
    }
    
    internal mutating func start()
    {
        do
        {
            try handleData(data: setUp(urlString: url))
        }
        catch
        {
            debugPrint(error)
        }
    }
    
    private func setUp(urlString:String) throws ->[String]
    {
        if let url = URL(string:urlString)
        {
            debugPrint("开始获取url")
            
            let URLArray = scanWith(data:try String(contentsOf:url),head:"{from:'mv_rk'})\" href=\"",foot:"\">")

            if URLArray.count == 0
            {
                throw crawlerError(msg:"数据初始化失败")
            }
            
            debugPrint("获取url结束")
            
            return URLArray
        }
        else
        {
            throw crawlerError(msg:"查询URL初始化失败")
        }
    }
    
    private func handleData(data:[String]) throws
    {
        debugPrint("开始获取信息")
        
        var index = 0

        for case let url in data.map({ URL(string:$0) })
        {
            guard let _ = url else { throw crawlerError(msg:"数据\(index)初始化失败") }
            
            Threading.getQueue(name: "sync", type: .serial).dispatch{
                
                do{
                    let data = try String(contentsOf:url!)
                    
                    var (head,foot) = ("data-name=",".jpg")
                    
                    //电影模型
                    var tempStr = (head + self.scanWith(data:data, head: head, foot: foot).first! + foot).components(separatedBy: "data-").map{
                        "\"\($0)".replacingOccurrences(of: "=", with: "\":").trim(string:" ")
                    }
                    
                    tempStr.removeFirst()
                    
                    var content = ""
                    
                    _ = tempStr.map{ content += "\($0),\n" }
                    
                    var id = 0
                    
                    for str in tempStr
                    {
                        if str.contains("href")
                        {
                            id = Int(str.components(separatedBy: ":").last!.components(separatedBy: "/").dropLast().last!)!
                        }
                    }
                    
                    content = content.replace(of: ",", with: "\"")
                    
                    //电影简介
                    var intro = ""
                    
                    (head,foot) = try String(contentsOf:url!).contains(string: "<span class=\"all hidden\">") ? ("<span class=\"all hidden\">","</span>") : ("<span property=\"v:summary\" class=\"\">","</span>")
                    
                    _ = self.scanWith(data:data,head:head,foot:foot).first!.components(separatedBy: "<br />").map{
                        intro += $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    
                    doMongoDB{
                        
                        let selector = try BSON(json:"{\"id\":\(id)}")
                        //数据已满
                        if let count = $0.find()?.reversed().count,count > 9
                        {
                            for x in $0.find(query: selector)!
                            {
                                if x.asString.isEmpty { serverPush.shared.beginPush() }
                            }
                        }
                        else
                        {
                            if case .success = $0.update(selector: selector, update: try BSON(json: "{\"id\":\(id),\"content\":{\(content)},\"intro\":\"\(intro)\"}"), flag: .upsert) {} else
                            {
                                throw crawlerError(msg: "数据保存有误")
                            }
                        }
                    }
                }
                catch
                {
                    debugPrint(error)
                }
            }
            index += 1
            if index == data.count - 1 { debugPrint("获取信息结束") }
        }
    }
    
    private func scanWith(data:String,head:String,foot:String)->[String]
    {
        var temp = data.components(separatedBy: head)
        temp.removeFirst()
        return temp.map{ $0.components(separatedBy: foot).first ?? "" }
    }
}



extension String
{
    func trim(string:String) -> String
    {
        return self == "" ? "" : trimmingCharacters(in: CharacterSet(charactersIn:string))
    }
    func replace(of pre:String,with next:String)->String
    {
        return replacingOccurrences(of: pre, with: next, options: .backwards, range: index(endIndex, offsetBy: -2)..<endIndex)
    }
}

struct crawlerError:Error
{
    var message:String
    
    init(msg:String)
    {
        message = msg
    }
}

