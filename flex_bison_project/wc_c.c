#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    FILE *f = stdin;
    if (argc > 1) {
        f = fopen(argv[1], "rb");
        if (!f) { perror("fopen"); return 1; }
    }
    const size_t BUF = 1<<16; /* 64KB */
    char *buf = malloc(BUF);
    if (!buf) { perror("malloc"); return 1; }
    long lines=0, words=0, chars=0;
    int in_word = 0;
    size_t n;
    while ((n = fread(buf, 1, BUF, f)) > 0) {
        chars += n;
        for (size_t i=0;i<n;i++) {
            char c = buf[i];
            if (c == '\n') lines++;
            if (c==' ' || c=='\n' || c=='\t' || c=='\r' || c=='\v' || c=='\f') {
                if (in_word) { words++; in_word = 0; }
            } else {
                in_word = 1;
            }
        }
    }
    if (in_word) words++;
    printf("%ld %ld %ld\n", lines, words, chars);
    free(buf);
    if (f != stdin) fclose(f);
    return 0;
}
