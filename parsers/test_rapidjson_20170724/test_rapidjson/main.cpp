//
//  main.cpp
//  test_rapidjson
//
//  Created by Nicolas Seriot on 24.07.17.
//  Copyright © 2017 ch.seriot. All rights reserved.
//

#include <iostream>

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include "document.h"

// RapidJSON does crash when parsing many nested array (stack overflow)
// a flag can prevent this, but is not the default
// https://github.com/miloyip/rapidjson/issues/1027

typedef enum testStatus {ERROR, PASS, FAIL} TestStatus;

TestStatus parseData(char *data, int printParsingResults) {
    rapidjson::Document document;
    if (document.Parse(data).HasParseError()) {
        return FAIL;
    }
    return PASS;
}

TestStatus testFile(const char *filename, int printParsingResults) {
    FILE *f=fopen(filename,"rb");
    if(f == NULL) { return ERROR; };
    fseek(f,0,SEEK_END);
    long len=ftell(f);
    fseek(f,0,SEEK_SET);
    char *data=(char*)malloc(len+1);
    fread(data,1,len,f);
    data[len]='\0';
    fclose(f);
    TestStatus status = parseData(data, printParsingResults);
    free(data);
    return status;
}

int main(int argc, const char * argv[]) {
    
    const char* path = argv[1];
    
    int printParsingResults = 0;
    
    int result = testFile(path, printParsingResults);
    
    if (result == PASS) {
        return 0;
    } else {
        return 1;
    }
}
