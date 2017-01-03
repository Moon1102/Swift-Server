//
//  RouteHandler.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/11/15.
//
//

import PerfectHTTP
import PerfectHTTPServer
import MongoDB
import Foundation

struct RouteHandler
{
    
    private enum Access:String
    {
        case Login = "Login"
        case Logout = "Logout"
        case Regist = "Regist"
    }
    
    var routes:Routes
    {
        get
        {
            var routes = Routes()
            
            routes.add(method: .get, uri: "/", handler: mainHandler)
            routes.add(method: .get, uri: "/mongo", handler: sqlHandler)
            routes.add(method: .get, uri: "/data", handler: dataHandler)
            
            routes.add(method: .post, uri: "/logout", handler: logoutHandler)
            routes.add(method: .post, uri: "/regist", handler: registHandler)
            routes.add(method: .post, uri: "/login", handler: loginHandler)
            
            return routes
        }
    }
    
    //MARK:默认显示
    private func mainHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        response.setHeader(.contentType, value: "text/html")
        response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
        response.completed()
    }
    
    //MARK:CURD操作
    private func sqlHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        guard request.queryParams.count > 0  else
        {
            return
        }
        
        let (key,value) = request.queryParams[0]
        
        doMongoDB
        {
            switch key
            {
            case "query":
                
                let fnd = $0.find(query:  value == "" ? BSON() : try BSON(json: value.trim()))
                
                var arr = [String]()
                
                for x in fnd!
                {
                    arr.append(x.asString)
                }
                
                response.appendBody(string: "\(arr.joined(separator: ",\n"))")
                
            case "insert":
                let result = $0.save(document: try BSON(json: value.trim()))
                response.appendBody(string: "insert \(result)".uppercased())
                
            case "delete":
                
                let result = $0.remove(selector: value == "" ? BSON() : try BSON(json: value.trim()))
                response.appendBody(string: "delete \(result)".uppercased())
                
            case "modify":
                
                var dataArr = value.trim().components(separatedBy: ",")
                
                for i in 0..<dataArr.count
                {
                    if i<dataArr.count - 1 && dataArr[i].characters.last == "\"" && dataArr[i+1].characters.first == " "
                    {
                        let newElement = "\(dataArr[i]),\(dataArr[i+1])"
                        for _ in 0..<2 { dataArr.remove(at: i) }
                        dataArr.insert(newElement, at: i)
                    }
                }
                
                if dataArr.count > 2 || dataArr.count < 1
                {
                    response.appendBody(string: "modify fail".uppercased())
                }
                else
                {
                    switch dataArr.count
                    {
                    case 1:
                        let result = $0.update(selector: BSON(), update: try BSON(json:dataArr[0]), flag: .none)//collection.update(update: try BSON(json:dataArr[0]), selector: BSON(),flag: .none)
                        response.appendBody(string: "modify \(result)".uppercased())
                    case 2:
                        let result = $0.update(selector:  try BSON(json:dataArr[1]), update: try BSON(json:dataArr[0]), flag: .none)
                        //collection.update(update: try BSON(json:dataArr[0]), selector: try BSON(json:dataArr[1]),flag: .none)
                        response.appendBody(string: "modify \(result)".uppercased())
                    default:break
                    }
                }
            default:break
            }
        }
        
        
        
        response.completed()
    }
    
    //MARK:注册 登录 登出
    private func registHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        handleAccess(method: .Regist, request, response)
    }
    private func loginHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        handleAccess(method: .Login, request, response)
    }
    private func logoutHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        handleAccess(method: .Logout, request, response)
    }
    private func handleAccess(method:Access,_ request:HTTPRequest,_ response:HTTPResponse)
    {
        var result = "success"
        
        var (userName,Password) = ("","")
        
        for (key,value) in request.postParams
        {
            switch key
            {
            case "username":
                userName = value.trim()
            case "pwd":
                Password = value.trim()
            default:
                break
            }
        }
        if userName.characters.count <= 0 || (method.rawValue != "Logout" && Password.characters.count <= 0)
        {
            result = "data false"
        }
        else
        {
            doMongoDB
            {
                let fnd = $0.find(query: try BSON(json: "{\"name\":\"\(userName)\"}"))
                
                var arr = [String]()
                
                for x in fnd!
                {
                    arr.append(x.asString)
                }
                
                switch method.rawValue
                {
                case "Regist":
                    
                    if arr.count == 0
                    {
                        _ = $0.save(document: try BSON(json:"{\"name\":\"\(userName)\",\"password\":\"\(Password)\",\"isLogin\":\"0\"}"))
                    }
                    else if arr.count == 1
                    {
                        result = "id exist"
                    }
                    else
                    {
                        result = "id non-unique"
                        return
                    }
                case "Login":
                    
                    if arr.count == 0
                    {
                        result = "database fail"
                    }
                    else if arr.count == 1
                    {
                        if let decoded = try arr[0].jsonDecode() as? [String:Any],let status = decoded["isLogin"]
                        {
                            if Int(status as! String) == 0
                            {
                                _ = $0.update(selector: try BSON(json: "{\"name\":\"\(userName)\"}"), update: try BSON(json: "{\"$set\" : {\"isLogin\" :\"1\"}}"))
                                //collection.update(update: try BSON(json: "{\"$set\" : {\"isLogin\" :\"1\"}}"), selector: try BSON(json: "{\"name\":\"\(userName)\"}"))
                            }
                            else if Int(status as! String) == 1
                            {
                                result = "repeat"
                            }
                        }
                        else
                        {
                            result = "database fail"
                        }
                    }
                    else
                    {
                        result = "id non-unique"
                    }
                case "Logout":
                    switch arr.count
                    {
                    case 0:  result = "database fail"
                    case 1:
                        if let decoded = try arr[0].jsonDecode() as? [String:Any],let status = decoded["isLogin"]
                        {
                            if Int(status as! String) == 1
                            {
                                _ = $0.update(selector: try BSON(json: "{\"name\":\"\(userName)\"}"), update: try BSON(json: "{\"$set\" : {\"isLogin\" :\"0\"}}"))
                                //collection.update(update: try BSON(json: "{\"$set\" : {\"isLogin\" :\"0\"}}"), selector: try BSON(json: "{\"name\":\"\(userName)\"}"))
                            }
                        }
                        else
                        {
                            result = "database fail"
                        }
                    default: result = "id non-unique"
                    }
                default:break
                }
            }
        }
        response.appendBody(string: (method.rawValue + " \(result)").uppercased())
        response.completed()
    }
    
    //MARK:获取页面展示数据
    private func dataHandler(request:HTTPRequest,_ response:HTTPResponse)
    {
        serverPush.shared.beginPush()
        
        doMongoDB
        {
            //有数据就直接拿
            if  $0.find()?.reversed().count ?? 0 > 0
            {
                debugPrint("直接获取数据")
            }
            else
            {
                //没有就取一下
                let crawler = myCrawler(url:"https://movie.douban.com/")
                
                crawler.start()
                
                debugPrint("重新获取数据")
            }
            
            var results = "{"
            
            //组合数据
            while $0.find()?.reversed().count ?? 0 == 10
            {
                var index = 0
                
                for x in $0.find()!
                {
                    results += "\"\(index)\":\(x.asString),"
                    index += 1
                }
                
                break
            }
            
            response.appendBody(string: results.replace(of: ",", with: "}"))
            response.completed()
        }
    }
}
