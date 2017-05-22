//
//  main.swift
//  json_swift
//
//  Created by nst on 22.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Foundation

func main() {
    
    let args = CommandLine.arguments
    
    guard args.count == 2 else {
        let url = NSURL(fileURLWithPath: args[0])
        guard let programName = url.lastPathComponent else { exit(1) }
        print("Usage: ./\(programName) file.json")
        exit(1)
    }
    
    let path = args[1]
    let url = NSURL.fileURL(withPath:path)
    
    guard let data = try? Data(contentsOf:url) else { exit(1) }
    
    do {
        let _ = try JSON.parse(data)
        exit(0)
    } catch let e {
        print(e)
        exit(1)
    }
}

main()
