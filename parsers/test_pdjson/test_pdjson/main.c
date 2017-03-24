#include <stdio.h>

#include "json.h"

int testFile(const char *filename) {
    enum json_type t;
    json_stream json;
    FILE *f;
    
    f = fopen(filename,"rb");
    if(f == NULL) {
        return -1;
    }

    json_open_stream(&json, f);
    json_set_streaming(&json, false);

    do {
        t = json_next(&json);
    } while (t != JSON_ERROR && t != JSON_DONE);

    json_close(&json);

    return t == JSON_ERROR ? 1 : 0;
}

int main(int argc, const char * argv[]) {
    if (argc < 2) { return -1; }
    return testFile(argv[1]);
}
