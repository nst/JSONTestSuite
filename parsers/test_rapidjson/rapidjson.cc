//
//  main.c
//  test-rapidjson
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
#include "rapidjson/document.h"

typedef enum testStatus {ERROR, PASS, FAIL} TestStatus;

/* Parse text to JSON, then render back to text, and print! */
TestStatus parseData(char *data, int printParsingResults) {
  rapidjson::Document document;
  if (document.Parse(data).HasParseError()) {
    return FAIL;
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

  int printParsingResults = 0;

  int result = testFile(path, printParsingResults);

  if (result == PASS) {
    return 0;
  } else {
    return 1;
  }
}
