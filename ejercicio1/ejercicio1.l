/* ejercicio1.l */
%option noyywrap yylineno
%x IFILE

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

struct bufstack {
    struct bufstack *prev;
    YY_BUFFER_STATE bs;
    int lineno;
    char *filename;
    FILE *f;
} *curbs = 0;

char *curfilename;
FILE *tempfile;

int newfile(char *fn);
int popfile(void);

void process_chunk(const char *s, int lineno, const char *filename) {
    const char *p = s;
    char word[512];
    int i = 0;
    while (*p) {
        if (isalpha((unsigned char)*p)) {
            i = 0;
            while (*p && isalpha((unsigned char)*p) && i < (int)sizeof(word)-1) {
                word[i++] = *p++;
            }
            word[i] = '\0';
            fprintf(tempfile, "%s %d %s\n", word, lineno, filename);
        } else {
            p++;
        }
    }
}
%}

%%

^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }

<IFILE>[^ \t\n\">]+ {
    {
        int c;
        while ((c = input()) && c != '\n');
    }
    yylineno++;
    if (!newfile(yytext))
        yyterminate();
    BEGIN INITIAL;
}

<IFILE>.|\n {
    fprintf(stderr, "%d bad include line\n", yylineno);
    yyterminate();
}

<<EOF>> { if (!popfile()) yyterminate(); }

[^\n#]+ {
    process_chunk(yytext, yylineno, curfilename);
}

\n { yylineno++; }

# { /* ignore standalone # */ }

. { /* ignore others */ }

%%

int newfile(char *fn) {
    FILE *f = fopen(fn, "r");
    struct bufstack *bs = malloc(sizeof(struct bufstack));
    if (!f) { perror(fn); return 0; }
    if (!bs) { perror("malloc"); exit(1); }
    if (curbs) curbs->lineno = yylineno;
    bs->prev = curbs;
    bs->f = f;
    bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
    bs->filename = strdup(fn);
    yy_switch_to_buffer(bs->bs);
    curbs = bs;
    yylineno = 1;
    curfilename = bs->filename;
    return 1;
}

int popfile(void) {
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;
    if (!bs) return 0;
    fclose(bs->f);
    yy_delete_buffer(bs->bs);
    prevbs = bs->prev;
    free(bs->filename);
    free(bs);
    if (!prevbs) return 0;
    yy_switch_to_buffer(prevbs->bs);
    curbs = prevbs;
    yylineno = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input-file>\n", argv[0]);
        return 1;
    }
    tempfile = fopen("temp_refs.txt", "w");
    if (!tempfile) { perror("tempfile"); return 1; }
    if (newfile(argv[1])) yylex();
    fclose(tempfile);
    system("sort temp_refs.txt > sorted_refs.txt");
    FILE *sorted = fopen("sorted_refs.txt", "r");
    if (!sorted) return 1;
    char word[512], filename[512];
    int line;
    printf("\nConcordance Report:\n");
    while (fscanf(sorted, "%s %d %s", word, &line, filename) == 3) {
        printf("%-20s %5d %s\n", word, line, filename);
    }
    fclose(sorted);
    return 0;
}