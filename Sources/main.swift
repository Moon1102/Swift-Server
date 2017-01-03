//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

#if os(Linux)
    import SwiftGlibc
#else
    import Darwin
#endif

// Create HTTP server.
let server = HTTPServer()

// Register your own routes and handlers
var hanlder = RouteHandler()

//Add the routes to the server.
server.addRoutes(hanlder.routes)

// Set a listen port of 8181
server.serverPort = 8181

// Set a document root.
// This is optional. If you do not want to serve static content then do not set this.
// Setting the document root will automatically add a static file handler for the route /**
//server.documentRoot = "./webroot"

// Gather command line options and further configure the server.
// Run the server with --help to see the list of supported arguments.
// Command line arguments will supplant any of the values set above.
configureServer(server)

////启动定时任务
//timerTask(with: 86400)
//{
//    var crawler = myCrawler(url:"https://movie.douban.com/")
//    crawler.start()
//}

do
{
	try server
    .setResponseFilters([(Filter(), .high)])
    .start()
    
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}

