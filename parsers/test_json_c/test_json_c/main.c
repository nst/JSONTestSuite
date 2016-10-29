//
//  main.c
//  test-json-c
//
//  Created by nst on 06/08/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include "json_object.h"
#include "json_tokener.h"

typedef enum testStatus {ERROR, PASS, FAIL} TestStatus;

/* Parse text to JSON, then render back to text, and print! */
TestStatus parseData(char *data, int printParsingResults) {
    struct json_tokener *tokener = json_tokener_new();
    struct json_object *json = json_tokener_parse_ex(tokener, data, strlen(data));
    if (!json) {
        printf("-- no json\n");
        //        if (printParsingResults) {
        //            printf("Error before: [%s]\n",cJSON_GetErrorPtr());
        //        }
        return FAIL;
    }
    
    const char *out=json_object_to_json_string(json);
    json_object_put(json);
    if (printParsingResults) {
        printf("--  in: %s\n", data);
        printf("-- out: %s\n", out);
    }
    return PASS;
}

/* Read a file, parse, render back, etc. */
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
    
    int printParsingResults = 1;
    
    int result = testFile(path, printParsingResults);
    
    printf("-- result: %d\n", result);
    
    if (result == PASS) {
        return 0;
    } else {
        return 1;
    }
}
