//
//  main.cpp
//  test_nlohmann_json
//
//  Created by Nicolas Seriot on 24.07.17.
//  Copyright © 2017 ch.seriot. All rights reserved.
//

#include <iostream>
#include "json.hpp"

using nlohmann::json;

typedef enum testStatus {ERROR, PASS, FAIL} TestStatus;

TestStatus parseData(char *data) {
    json o = json::parse(data);
    return (o != NULL) ? PASS : FAIL;
}

TestStatus testFile(const char *filename) {
    FILE *f=fopen(filename,"rb");
    if(f == NULL) { return ERROR; };
    fseek(f,0,SEEK_END);
    long len=ftell(f);
    fseek(f,0,SEEK_SET);
    char *data=(char*)malloc(len+1);
    fread(data,1,len,f);
    data[len]='\0';
    fclose(f);
    TestStatus status = parseData(data);
    free(data);
    return status;
}


int main(int argc, const char * argv[]) {

    try {
        const char* path = argv[1];
        TestStatus status = testFile(path);
        return (status == PASS) ? 0 : 1;
    } catch (...) {
        return 1;
    }

}
