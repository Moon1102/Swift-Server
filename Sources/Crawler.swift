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
import MongoDB
import PerfectLogger
import PerfectThread
import PerfectCURL

struct myCrawler
{
    private var url:String
    
    init(url:String)
    {
        self.url = url
    }
    
    internal func start()
    {
        setUp(urlString: url){

            if $0.count == 0
            {
                throw crawlerError(msg:"数据初始化失败")
            }
            
            self.handleData(data: $0){
                
                data in
                
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
                
                (head,foot) = data.contains(string: "<span class=\"all hidden\">") ? ("<span class=\"all hidden\">","</span>") : ("<span property=\"v:summary\" class=\"\">","</span>")
                
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
        }
    }
    
    private func setUp(urlString:String,handle:@escaping (_ URLArray:[String]) throws ->Void = {_ in })
    {
        CURL(url: urlString).perform{
            
            code, header, body in
            
            if let data = String(bytes: body, encoding: .utf8)
            {
                debugPrint("开始获取url")
            
                do
                {
                    try handle(self.scanWith(data:data,head:"{from:'mv_rk'})\" href=\"",foot:"\">"))
                }
                catch
                {
                    print(error)
                }
                
                debugPrint("获取url结束")
            }
        }
    }
    
    private func handleData(data:[String],handle:@escaping (_ data:String)->Void = {_ in })
    {
        debugPrint("开始获取信息")
        
        var index = 0

        for url in data.map({ CURL(url:$0) })
        {
            url.perform{
                
                code, header, body in
                
                if let data = String(bytes: body, encoding: .utf8)
                {
                    handle(data)
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

