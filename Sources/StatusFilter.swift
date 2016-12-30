//
//  StatusFilter.swift
//  PerfectTemplate
//
//  Created by Cheer on 16/11/16.
//
//
import PerfectHTTP
import PerfectHTTPServer

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
            response.setBody(string: "\(response.request.path) is not found.")
            response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
            callback(.done)
        }
        else
        {
            callback(.continue)
        }
    }
}
