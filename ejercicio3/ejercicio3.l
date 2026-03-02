/* ejercicio3.l - Tabla de símbolos dinámica con encadenamiento (Chaining) */
%option noyywrap yylineno
%x IFILE

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* Estructura para las referencias (línea y archivo) */
struct ref {
    struct ref *next;
    char *filename;
    int lineno;
};

/* Estructura para el símbolo (palabra y lista de referencias) */
struct symbol {
    char *name;
    struct ref *reflist;
    struct symbol *next;
};

#define NHASH 9997
struct symbol *symtab[NHASH];

struct symbol* lookup(char*);
void addref(int, const char*, const char*);
void printrefs(void);

struct bufstack {
    struct bufstack *prev;
    YY_BUFFER_STATE bs;
    int lineno;
    char *filename;
    FILE *f;
} *curbs = 0;

char *curfilename = NULL;
int newfile(char *fn);
int popfile(void);
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

[a-zA-Z]+ {
    addref(yylineno, curfilename ? curfilename : "(unknown)", yytext);
}

\n { yylineno++; }

[ \t\r]+ { /* ignore whitespace */ }

. { /* ignore other chars */ }

%%

static unsigned symhash(const char *sym) {
    unsigned int hash = 0;
    unsigned char c;
    while ((c = (unsigned char)*sym++)) hash = hash * 9 ^ c;
    return hash;
}

struct symbol * lookup(char* s) {
    unsigned idx = symhash(s) % NHASH;
    struct symbol *sp = symtab[idx];
    while (sp) {
        if (sp->name && strcmp(sp->name, s) == 0) return sp;
        sp = sp->next;
    }
    sp = malloc(sizeof(struct symbol));
    if (!sp) { perror("malloc"); exit(1); }
    sp->name = strdup(s);
    sp->reflist = NULL;
    sp->next = symtab[idx];
    symtab[idx] = sp;
    return sp;
}

void addref(int lineno, const char *filename, const char *word) {
    struct symbol *sp = lookup((char*)word);
    struct ref *r = malloc(sizeof(struct ref));
    if (!r) { perror("malloc"); exit(1); }
    r->lineno = lineno;
    r->filename = strdup(filename);
    r->next = sp->reflist;
    sp->reflist = r;
}

void printrefs(void) {
    struct symbol *sp;
    printf("\nConcordance Report (Dynamic Table):\n");
    for (int i = 0; i < NHASH; i++) {
        sp = symtab[i];
        while (sp) {
            printf("%-20s", sp->name);
            struct ref *r = sp->reflist;
            while (r) {
                printf(" %s:%d", r->filename, r->lineno);
                r = r->next;
            }
            printf("\n");
            sp = sp->next;
        }
    }
}

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
    for (int i = 0; i < NHASH; i++) symtab[i] = NULL;
    if (newfile(argv[1])) yylex();
    printrefs();
    return 0;
}