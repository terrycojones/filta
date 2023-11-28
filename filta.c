/*
**
** filta.c
**
** Build filters and things. See filta.doc
** This code is something of a hack - I was just looking for an excuse 
** to write code one night. As a result it's not very easy to add to the 
** language. Comments are scarce too. Whatever.
**
** Terry Jones. (tcjones@watdragon)
**
*/

#include "filta.h"
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <ctype.h>

#ifdef mips
#include <sys/fcntl.h>
#endif

void do_header();
void do_tailer();
void do_splitter();
void finish_printf();
void emit();
int do_args();
void usage();
int lex();
int start_lex();
int fill_buf();
void lex_err();
int skip_white();
extern FILE *fopen();
extern char *index();

FILE *in_f;
FILE *cmp_f;
char *source = "Filta.c";
char *object = "a.out";
char *argline;
char *myname;
int saved_string = 0;
int saved_field = 0;
char args[1024];
char compile_cmd[100];
int input;
int auto_split = 1;
int lp_count = 0;
int save_source = 0;
int auto_exec = 1;
char buf[1024];
char *bufp = buf;
char lexeme[1024];
int end_of_file = 0;
int first_tok = 1;


main(argc, argv)
int argc;
char **argv;
{
	int lexval;
	int in_if = 0;
	int in_printf = 0;
	int indent = 2;
	int saved_indent;
	int just_seen_if = 0;
	char saved_args[1024];
	int comp_type;

	myname = *argv++;
	argline = args;
	saved_args[0] = '\0';
	input = do_args(argc, argv);
	if (save_source)
		start_save_compile();
	else
#ifdef CAN_FAST_COMPILE
		start_fast_compile();
#else
		start_save_compile();
#endif

	do_header();

	if (start_lex() == AUTO_SPLIT) 
		emit(indent, cmp_f, "f_count = splitter(\" \\t\");\n");

	while((lexval = lex()) != EOF){
		switch (lexval){

			case QUOTE:{
				if (just_seen_if == 1){
					lp_count++;
					emit(0, cmp_f, "\"%s\"", lexeme);
					just_seen_if = 0;
				}
				else if (in_if == 1){
					emit(0, cmp_f, "\"%s\"", lexeme);
				}
				else if (in_printf == 0){
					emit(indent, cmp_f, "printf(\"%s", lexeme);
					in_printf = 1;
				}
				else{
					emit(0, cmp_f, "%s", lexeme);
				}
				saved_string = 1;
				saved_field = 0;
				break;
			}

			case LPAREN:{
				if (just_seen_if != 1){   /* Let them omit the keyword "if" */
					emit(indent, cmp_f, "if (strcmp(");
					indent++;
					in_if = 1;
				}
				else
					just_seen_if = 0;
				lp_count++;
				break;
			}

			case RPAREN:{
				char comp[3];

				if (in_if != 1 && in_printf != 1){
					fprintf(stderr, "%s: ) not inside an if.\n", myname);
					exit(1);
				}

				lp_count--;

				if (lp_count < 0){
					fprintf(stderr, "%s: Too many )'s\n", myname);
					exit(1);
				}

				if (in_printf == 1){
					finish_printf(saved_args);
					in_printf = 0;
					break;
				}

				comp[2] = '\0';
				switch (comp_type){
					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
					case NEQ: comp[0] = '!'; comp[1] = '='; break;
					case LT: comp[0] = '<'; comp[1] = '\0'; break;
					case GT: comp[0] = '>'; comp[1] = '\0'; break;
				}

				if (lp_count == 0){
					saved_string = saved_field = 0;
					emit(0, cmp_f, ") %s 0)\n", comp);
					in_if = 0;
				}
				else{
	 				emit(0, cmp_f, ") %s 0", comp);
				}

				break;
			}

			case LBRACE:{
				emit(indent - 1, cmp_f, "{\n");
				saved_indent = indent - 1;
				break;
			}

			case RBRACE:{
				if (in_printf == 1){
					finish_printf(saved_args);
					in_printf = 0;
				}
				indent = saved_indent;
				emit(indent, cmp_f, "}\n");
				break;
			}

			case IF:{
				if (in_printf == 1){
					finish_printf(saved_args);
					in_printf = 0;
				}
				emit(indent, cmp_f, "if (strcmp(");
				indent++;
				just_seen_if = 1;
				in_if = 1;
				break;
			}

			case ELSE:{
				if (in_printf == 1){
					finish_printf(saved_args);
					in_printf = 0;
				}

				emit(indent - 1, cmp_f, "else\n");
				break;
			}

			case NEQ:
			case LT:
			case GT:
			case EQ:
			case EQEQ:{
				if (saved_string != 1 && saved_field != 1){
					fprintf(stderr, "%s: == without left operand.\n", myname);
					exit(1);
				}
				comp_type = lexval;
				emit(0, cmp_f, ", ");
				break;
			}

			case AND:{
				char comp[3];
				comp[2] = '\0';
				switch (comp_type){
					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
					case NEQ: comp[0] = '!'; comp[1] = '='; break;
					case LT: comp[0] = '<'; comp[1] = '\0'; break;
					case GT: comp[0] = '>'; comp[1] = '\0'; break;
				}
				if (saved_string == 1 || saved_field == 1){
	 				emit(0, cmp_f, ") %s 0", comp);
				}
				emit(0, cmp_f, " && strcmp(");
				break;
			}

			case OR:{
				char comp[3];
				comp[2] = '\0';
				switch (comp_type){
					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
					case NEQ: comp[0] = '!'; comp[1] = '='; break;
					case LT: comp[0] = '<'; comp[1] = '\0'; break;
					case GT: comp[0] = '>'; comp[1] = '\0'; break;
				}
				if (saved_string == 1 || saved_field == 1){
	 				emit(0, cmp_f, ") %s 0", comp);
				}
				emit(0, cmp_f, " || strcmp(");
				break;
			}

			case SPLIT:{
				if (lex() != QUOTE){
					fprintf(stderr, "%s: Split must be followed by a string\n",
						myname);
					exit(1);
				}

				if (in_if == 1){
					fprintf(stderr, "\n%s: split inside an if?\n", myname);
					exit(1);
				}

				if (in_printf == 1){
					finish_printf(saved_args);
					in_printf = 0;
				}

				if (strlen(lexeme) == 0) break;
				emit(indent, cmp_f, "f_count = splitter(\"%s\");\n", lexeme);
				break;
			}

			default:{
				/* Field spec. */

				char fld_str[100];

				if (lexval == FIELD + LASTFIELD){
					sprintf(fld_str, "f[f_count]");
				}
				else{
					sprintf(fld_str, "f[%d]", lexval - FIELD);
				}

				if (in_if == 1){
					emit(0, cmp_f, "%s", fld_str);
				}
				else{
					if (in_printf == 0){
						emit(indent, cmp_f, "printf(\"%%s");
						sprintf(saved_args, ", %s", fld_str);
						in_printf = 1;
					}
					else{
						emit(0, cmp_f, "%%s");
						sprintf(saved_args, "%s, %s", saved_args, fld_str);
					}
				}
				saved_field = 1;
				break;
			}
		}
	}

	if (in_if == 1){
		fprintf(stderr, "\n%s: EOF inside an if?\n", myname);
		exit(1);
	}

	if (in_printf == 1){
		finish_printf(saved_args);
	}

	do_tailer();
	do_splitter();
	if (save_source)
		do_save_compile();
	else
#ifdef CAN_FAST_COMPILE
		do_fast_compile();
#else
		do_save_compile();
#endif
	return 0;
}

void
do_header()
{
	fprintf(cmp_f,"#include <stdio.h>\n\n#define MAXLINE 4096\n");
	fprintf(cmp_f,"#define MAXFLDS 20\n\n");
	fprintf(cmp_f, "char line[MAXLINE];\nchar copy[MAXLINE];\n");
	fprintf(cmp_f, "char *f[MAXFLDS + 1];\n\n");
	fprintf(cmp_f, "main(argc, argv)\nint argc;\nchar **argv;\n{\n");
	fprintf(cmp_f, "\tregister int f_count;\n");
	fprintf(cmp_f, "\tint i;\n\n\tfor (i = 0; i <= MAXFLDS; i++)");
	fprintf(cmp_f, "f[i] = NULL;\n");
	fprintf(cmp_f, "\twhile (gets(line)) {\n\t\tf[0] = line;\n");
}

void
do_tailer()
{
	fprintf(cmp_f, "\t}\n}\n");
}

void
do_splitter()
{
	fprintf(cmp_f, 
		"\n\nsplitter(sep)\nchar *sep;\n");
	fprintf(cmp_f, "{\n\textern char *index();\n");
	fprintf(cmp_f, "\tchar *tmp = copy;\n\tregister int fld;\n\n");
	fprintf(cmp_f, "\tfor (fld = 1; fld <= MAXFLDS; fld++) f[fld] = NULL;\n");
	fprintf(cmp_f, "\tif (!strlen(sep) || !strlen(line)) return 0;\n");
	fprintf(cmp_f, "\tfld = 1;\n\tsprintf(copy, \"%%s\", line);\n");
	fprintf(cmp_f, "\twhile (fld < MAXFLDS){\n\t\twhile (index(sep, *tmp))\n");
	fprintf(cmp_f, "\t\t\tif (!*++tmp) return fld;\n");
	fprintf(cmp_f, "\t\tf[fld++] = tmp++;\n\t\twhile (!index(sep, *tmp))\n");
	fprintf(cmp_f, "\t\t\tif (!*++tmp) return fld;\n");
	fprintf(cmp_f, "\t\t*tmp++ = '\\0';\n\t}\n\treturn fld;\n}\n");
}


/* VARARGS1 */
void
emit(in, dest, fmt, a, b, c, d, e, f, g)
int in;
FILE *dest;
char *fmt, *a, *b, *c, *d, *e, *f, *g;
{
	register int i;

	for (i=0; i<in; i++) putc('\t', dest);
	fprintf(dest, fmt, a, b, c, d, e, f, g);
}


void
finish_printf(save)
char *save;
{
	if (*save){
		emit(0, cmp_f, "\"%s);\n", save);
		*save = '\0';
	}
	else{
		emit(0, cmp_f, "\");\n");
	}
	saved_string = 0;
}

int
do_args(argc, argv)
int argc;
char **argv;
{
	if (argc == 2 && !strcmp(*argv, "-s")){
		save_source = 1;
		auto_exec = 0;
		in_f = stdin;
		return IN_FILE;
	}

	if (argc == 1){
		usage();
		exit(1);
	}

	if (!strcmp(*argv, "-s")){
		save_source = 1;
		argc--;
		argv++;
	}

	if (argc == 3 && !strcmp(*argv, "-f")){
		in_f = fopen(*++argv, "r");
		if (!in_f){
			fprintf(stderr, "%s: Could not open %s\n", myname, *argv);
			exit(1);
		}
		return IN_FILE;
	}

	/* Must be a program on the argument line. */

	args[0] = '\0';
	while (--argc)
		sprintf(args, "%s %s", args, *argv++);
	return IN_ARGLINE;
}

void
usage()
{
	fprintf(stderr, 
	"Usage: %s [-s] [-f file | program]\n", myname, myname, myname);
}


start_save_compile()
{
	extern char *mktemp();
	char *tsrc = "/tmp/.__compile.srcXXXXXX";
	char *obj = "/tmp/.__compile.objXXXXXX";
	static char src[100];
	struct stat sbuf;
	extern int errno;
	FILE *fopen();

	cmp_f = fopen("Filta.c", "w");

	if (!cmp_f){
		/* Have to use our own names in /tmp */
		if (mktemp(tsrc) == (char *)-1){
			fprintf(stderr, "Could not mktemp()\n");
			exit(1);
		}
		sprintf(src, "%s.c", tsrc);

		errno = 0;
		if (!(stat(src, sbuf) == -1 && errno == ENOENT)){
			fprintf(stderr, "Could not mktemp()\n");
			exit(1);
		}

		if (mktemp(obj) == (char *)-1){
			fprintf(stderr, "Could not mktemp()\n");
			exit(1);
		}

		cmp_f = fopen(src, "w");

		if (!cmp_f){
			fprintf(stderr, "Could not fopen()\n");
			exit(1);
		}

		source = src;
		object = obj;

		sprintf(compile_cmd, "cd /tmp && cc -O -o %s %s", obj, src);
		fprintf(stderr, "%s source is in \"%s\"\n", myname, source);
		fprintf(stderr, "%s object is in \"%s\"\n", myname, object);
	}
	else{
		sprintf(compile_cmd, "cc -O Filta.c");
	}
}

do_save_compile()
{
	fclose(cmp_f);
	if (system(compile_cmd) == 0){
		if (auto_exec == 1){
			execl(object, 0);
			fprintf(stderr, "Could not execl(%s, 0)\n", object);
			exit(1);
		}
	}
	else{
		fprintf(stderr, "%s: Compilation did not suceed!\n", myname);
		exit(1);
	}
}



#ifdef CAN_FAST_COMPILE
start_fast_compile()
{
	extern char *mktemp();
	char *tsrc = "/tmp/.__compile.srcXXXXXX";
	static char src[100];
	extern int errno;
	struct stat sbuf;
	FILE *popen();
	register int fd;

	if (mktemp(tsrc) == (char *)-1){
		fprintf(stderr, "Could not mktemp()\n");
		exit(1);
	}
	sprintf(src, "%s.c", tsrc);

	errno = 0;
	if (!(stat(src, sbuf) == -1 && errno == ENOENT)){
		fprintf(stderr, "Could not mktemp()\n");
		exit(1);
	}

	if ((fd = open(src, O_CREAT | O_WRONLY, 0666)) == -1){
		fprintf(stderr, "%s: Could not open() %s\n", myname, src);
		exit(1);
	}

	if (write(fd, "#include \"/dev/stdin\"\n", 22) != 22){
		fprintf(stderr, "%s: Could not write() %s\n", myname, src);
		exit(1);
	}

	if (close(fd) == -1){
		fprintf(stderr, "%s: Could not close() %s\n", myname, src);
		exit(1);
	}

	source = src;

	sprintf(compile_cmd, "/bin/cc -O %s", src);
	cmp_f = popen(compile_cmd, "w");

	if (!cmp_f){
		fprintf(stderr, "Could not popen(%s)\n", compile_cmd);
		exit(1);
	}
}

do_fast_compile()
{
	pclose(cmp_f); /* This waits for the cc to complete. */
	if (unlink(source) == -1)
		fprintf(stderr, "%s: Warning! could not unlink %s\n", myname, source);
	execl(object, 0);
	fprintf(stderr, "Could not execl(%s, 0)\n", object);
	exit(1);
}
#endif /* CAN_FAST_COMPILE */



int
start_lex()
{
	if (input == IN_FILE){
		if (fill_buf(in_f) == 0)
			return EOF;
	}
	else{
		sprintf(buf, "%s", argline);
	}

	if (skip_white() == 0) return EOF;

	if (!strncmp(buf, tokens[SPLIT], strlen(tokens[SPLIT]))){
		return NO_AUTO_SPLIT;
	}

	return AUTO_SPLIT;
}

int
lex()
{
	register int tok;
	
	if (end_of_file == 1) return EOF;
	if (skip_white() == 0) return EOF;
	
	for (tok = 0; tok < TOKENS; tok++){
		register int tmp = strlen(tokens[tok]);
		if (strncmp(bufp, tokens[tok], tmp) == 0){
			bufp += tmp;
			if (tok != QUOTE && skip_white() == 0) end_of_file = 1;

			switch (tok){
				case QUOTE:{
					register char *q = index(bufp, '"');

					if (!q){
						fprintf(stderr, "%s: Unmatched \" in string.\n",myname);
						exit(1);
					}
					lexeme[0] = '\0';
					strncat(lexeme, bufp, q - bufp);
					bufp = q + 1;
					return QUOTE;
				}

				default:{
					return tok;
				}
			}

		}
	}

	if ((*bufp == 'f' || *bufp == '$') && isdigit(*(bufp + 1))){

		int field_no;

		bufp++;
		field_no = atoi(bufp);
		if (field_no > MAX_FIELDS){
			fprintf(stderr, "%s: Maximum number of fields (%d) exceeeded.\n",
				myname, MAX_FIELDS);
			fprintf(stderr, "Line was \n%s\n", buf);
			exit(1);
		}
		while (isdigit(*bufp)) bufp++;
		return(FIELD + field_no);
	}

	if ((*bufp == 'f' || *bufp == '$') && *(bufp + 1) == '$'){
		bufp += 2;
		return FIELD + LASTFIELD;
	}

	if (*bufp == 'n'){
		sprintf(lexeme, "\\n");
		bufp++;
		return QUOTE;
	}

	if (*bufp == 't'){
		sprintf(lexeme, "\\t");
		bufp++;
		return QUOTE;
	}

	if (*bufp == 's'){
		sprintf(lexeme, " ");
		bufp++;
		return QUOTE;
	}


	lex_err();
	exit(1);

}

int
fill_buf()
{
	char *nl;
	if (fgets(buf, 1024, in_f) == NULL) return 0;
	if ((nl = index(buf, '\n'))) *nl = '\0';
	bufp = buf;
	return 1;
}

void
lex_err()
{
	fprintf(stderr, "%s: Could not lex input line\n%s\n", myname, buf);
	fprintf(stderr, "Lex broke at %s\n", bufp);
}

int
skip_white()
{
	while (*bufp == ' ' || *bufp == '\t') bufp++;

	if (*bufp == '\0'){
		if (input == IN_ARGLINE) return 0;
		if (fill_buf() == 0) 
			return 0;
		if (skip_white() == 0) return 0;
	}

	return 1;
}
