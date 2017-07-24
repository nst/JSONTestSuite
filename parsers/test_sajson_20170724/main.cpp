//
//  main.c
//  test_sajson
//
//  Created by Nicolas Seriot on 24.07.17.
//  Copyright © 2017 ch.seriot. All rights reserved.
//

#include "sajson.h"

using namespace sajson;

typedef enum testStatus {ERROR, PASS, FAIL} TestStatus;

TestStatus parseData(char *data, long length) {
    const sajson::document& document = sajson::parse(sajson::dynamic_allocation(), mutable_string_view(length, data));

    bool isValid = document.is_valid();
    
    if (isValid == false) {
        fprintf(stderr, "%s\n", document.get_error_message_as_cstring());
    }
    
    return isValid ? PASS : FAIL;
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
    TestStatus status = parseData(data, len);
    free(data);
    return status;
}

int main(int argc, const char * argv[]) {
    
    const char* path = argv[1];
    
    int result = testFile(path);
    
    if (result == PASS) {
        return 0;
    } else {
        return 1;
    }
}
