//
//  StatusFilter.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/11/16.
//
//
import PerfectHTTP
import PerfectHTTPServer
import PerfectLib

import Foundation

struct Filter: HTTPResponseFilter
{
    internal func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ())
    {
        callback(.continue)
    }
    
    internal func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ())
    {
        if case .notFound = response.status
        {
            response.bodyBytes.removeAll()
            
            var body = "\(response.request.path) is not found."

            if let data = FileManager.default.contents(atPath:"./webroot/Html/pnf.html")
            {
                body = String(data: data, encoding: .utf8) ?? body
            }
            
            response.setBody(string: body)
            response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
            callback(.done)
        }
        else
        {
            callback(.continue)
        }
    }
}
