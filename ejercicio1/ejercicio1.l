/* fb2-3 handling multiple input files - adapted for Exercise 1 */
%option noyywrap
%x IFILE

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct bufstack {
    struct bufstack *prev;    /* previous entry */
    YY_BUFFER_STATE bs;       /* saved buffer */
    int lineno;               /* saved line number in this file */
    char *filename;           /* name of this file */
    FILE *f;                  /* current file */
} *curbs = 0;

char *curfilename;            /* name of current input file */
FILE *tempfile;               /* temporary file for word references */

int newfile(char *fn);
int popfile(void);
%}

%%

^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }

<IFILE>[^ \t\n\">]+ {
    {
        int c;
        while((c = input()) && c != '\n');
    }
    yylineno++;
    if(!newfile(yytext))
        yyterminate(); /* no such file */
    BEGIN INITIAL;
}

<IFILE>.|\n {
    fprintf(stderr, "%d bad include line\n", yylineno);
    yyterminate();
}

<<EOF>> { if(!popfile()) yyterminate(); }

[a-zA-Z]+ {
    fprintf(tempfile, "%s %d %s\n", yytext, yylineno, curfilename);
}

\n { yylineno++; }

. { /* ignore other characters */ }

%%

int
newfile(char *fn)
{
    FILE *f = fopen(fn, "r");
    struct bufstack *bs = malloc(sizeof(struct bufstack));

    if(!f) { perror(fn); return 0; }
    if(!bs) { perror("malloc"); exit(1); }

    if(curbs) curbs->lineno = yylineno;

    bs->prev = curbs;
    bs->f = f;
    bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
    bs->filename = strdup(fn); // Guardar copia del nombre
    yy_switch_to_buffer(bs->bs);
    curbs = bs;
    yylineno = 1;
    curfilename = bs->filename;
    return 1;
}

int
popfile(void)
{
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;

    if(!bs) return 0;

    fclose(bs->f);
    yy_delete_buffer(bs->bs);

    prevbs = bs->prev;
    free(bs->filename);
    free(bs);

    if(!prevbs) return 0;

    yy_switch_to_buffer(prevbs->bs);
    curbs = prevbs;
    yylineno = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}

int main(int argc, char **argv)
{
    if(argc < 2) {
        fprintf(stderr, "Usage: %s <input-file>\n", argv[0]);
        return 1;
    }

    tempfile = fopen("temp_refs.txt", "w");
    if (!tempfile) {
        perror("Could not create temp file");
        return 1;
    }

    if(newfile(argv[1])) {
        yylex();
    }

    fclose(tempfile);

    // Ordenar el archivo temporal
    system("sort temp_refs.txt > sorted_refs.txt");

    // Imprimir el reporte desde el archivo ordenado
    FILE *sorted = fopen("sorted_refs.txt", "r");
    char word[256], file[256];
    int line;

    printf("\nConcordance Report:\n");
    while (fscanf(sorted, "%s %d %[^\n]", word, &line, file) == 3) {
        printf("%-20s %4d %s\n", word, line, file);
    }

    fclose(sorted);
    return 0;
}