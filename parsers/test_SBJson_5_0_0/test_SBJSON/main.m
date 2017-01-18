//
//  main.m
//  test_SBJSON
//
//  Created by nst on 04/09/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson5.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        SBJson5Parser *parser = [SBJson5Parser parserWithBlock:^(id item, BOOL *stop) {}
                                                  errorHandler:^(NSError *error) {
                                                      //NSLog(@"%@", error);
                                                      exit(1);
                                                  }];

        NSString *path = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSData *data = [NSData dataWithContentsOfFile:path];
        SBJson5ParserStatus status = [parser parse:data];

        if (status == SBJson5ParserComplete) exit(0);
        if (status == SBJson5ParserStopped) exit(1);
        if (status == SBJson5ParserWaitingForData) exit(1);
        if (status == SBJson5ParserError) exit(1);

        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
