
I am leaving the net world soon and have decided to post a few silly
things to comp.sources.misc. This code is not wonderful or beautiful
etc, but it does work and is fun. I don't think I'll be around for more
than a couple more months at most and so wont be doing much in the way
of bug hunting etc.


This is called "filta" and it is a filter builder. It writes C programs
to carry out simple filtering tasks. It is not intended to compete with
awk or sed or perl or other such things, but it does make some things
easier and faster, and it gives you C code to play with. I use it very
often when I want to do the same filtering job over and over again
(this produces an a.out file for you), or when I want to write a
special purpose filter for large amounts of input that I don't feel
like feeding to something that is an interpreter.

See the README for details. This will probably only work on BSD-like
systems.

Terry Jones

    Department Of Computer Science,  University Of Waterloo
    Waterloo Ontario Canada N2L 3G1. Phone: 1-519-8884674
    UUCP:                    ...!watmath!watdragon!tcjones
    CSNET, Internet, CDNnet: tcjones@dragon.waterloo.{cdn,edu}
    BITNET:                  tcjones@WATER.bitnet
    Canadian domain:         tcjones@dragon.uwaterloo.ca



#! /bin/sh
# This is a shell archive.  Remove anything before this line, then unpack
# it by saving it into a file and typing "sh file".  To overwrite existing
# files, type "sh file -c".  You can also feed this as standard input via
# unshar, or by typing "sh <file", e.g..  If this archive is complete, you
# will see the following message at the end:
#		"End of archive 1 (of 1)."
# Contents:  filta filta/Makefile filta/README filta/filta.c
#   filta/filta.h filta/tags
# Wrapped by tcjones@watdragon on Wed Mar 15 12:17:34 1989
PATH=/bin:/usr/bin:/usr/ucb ; export PATH
if test ! -d 'filta' ; then
    echo shar: Creating directory \"'filta'\"
    mkdir 'filta'
fi
if test -f 'filta/Makefile' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'filta/Makefile'\"
else
echo shar: Extracting \"'filta/Makefile'\" \(67 characters\)
sed "s/^X//" >'filta/Makefile' <<'END_OF_FILE'
CFLAGS = -O
X
filta: filta.o filta.h
X	cc $(CFLAGS) -o filta filta.o
END_OF_FILE
if test 67 -ne `wc -c <'filta/Makefile'`; then
    echo shar: \"'filta/Makefile'\" unpacked with wrong size!
fi
# end of 'filta/Makefile'
fi
if test -f 'filta/README' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'filta/README'\"
else
echo shar: Extracting \"'filta/README'\" \(4915 characters\)
sed "s/^X//" >'filta/README' <<'END_OF_FILE'
What I have often wanted was some semi-automated way to produce filters
written in C. That way, with some little language, one could produce a
filter, compile it and run it repeatedly. Not only that, adding to the
produced filter would be possible, since you would have the C code.
Plus it would run quickly. I wrote enough small filters do do
specialised little tasks to be sick of doing it, and so I wrote "filta"
to do the job.
X
The language of filta is currently very small. I'd go so far as to say
it's tiny. But I have found it very useful - which is more than I can
say for some of the other things I've done. Here are the only tokens
recognised in the language...
X
X
X== = != < > && || if else ( ) { } f# $# n t s "string" split
X
Like awk, filta splits all input lines by white space (' ' and TAB).
This can be changed or even turned off. The only action available is to
print. The only other things you can do are comparisons and
line-splitting. In the above, # refers to a positive integer. f# is
equivalent to $# and refers to the #'th field on the current input
line. f0 (and $0) refer to the whole line, f$ (and $$) refer to the
last field.
X
A string enclosed in double quotes is printed - C character
representations ("\n", "\t" etc etc) may be used. n, t and s are
equivalent to "\n", "\t" and " " respectively. (n = newline, t = tab, s
X= space).
X
if, else, (, ), {, }, &&, ||, ==, !=, <, and > are all used as in C. 
X= is entirely equivalent to ==.
X
The word "split" should be followed by a string of characters that the
input line should be split up on. Thus split " \t" splits on white
space, split ":" splits on colons. split "" does nothing. In
particular, if the first command in a filta program is a split, then
the default splitting on white space is not done. So to turn off
splitting altogether one does split "" first off.
X
There is no need to separate commands with white space. Thus f1f2 means
print field one and field two, as does f1 f2 and $1$2 and $1 $2.
X
Here is a simple use of filta.
X
X    cat file | filta 'f1 "\n"'
X
which prints the first white space separated field of each line and
then a newline. This could have also been done more simply as "filta
f1n".  Here is a more complicated example.
X
X    cat file | filta 'if (f1 = f2) f3 else f4'
X
And you can probably work out what this does. Of course this could have
been written as filta 'if(f1=f2)f3elsef4' for those that don't like
spaces. Note the hard single quotes around the program to hide the
parentheses (or double quotes) from the shell.
X
X    cat /etc/passwd | 
X    filta 'split":" if (f1 = "tcjones") "Terry's home directory is " f6n'
X
etc. It is possible to leave out the "if" as well. Thus the above could
have started off filta 'split":" (f1="tcjones")' etc etc.
X
It is also possible to split a line more than once. For example
X(assuming my encrypted password contains no commas!)
X
X    cat /etc/passwd 
X    | filta -s 'split":" if ($1="tcjones") {split"," "my office is " f2n}'
X
And so on.
X
X
So what does filta actually do? Your small program is read and parsed
and a simple (usually 50 odd lines) C program is produced. This is then
executed by filta and as a result gets the standard input that filta
was supplied with. By necessity the resulting a.out file is left in the
current directory (if possible) and can (and SHOULD) be re-used. By
default the source is removed before the a.out file is executed. You
can arrange for the source to be kept with the -s flag.  So
X
X    cat file | filta -s f1 s f2n
X
is a filter that prints the first field, a space, the second field and
a newline BUT in addition you get to keep the C source. If you want to
run it again you just say
X
X    cat file | a.out
X
The source is placed in Filta.c in the current directory (if
possible).  The filter program that is built can handle input lines of
length up to 4K with up to 20 fields. But that's easily changed, seeing
as -s gives you the source.
X
If you just type
X
X    filta -s
X
filta will wait for you to enter a program. This will be translated
into C, the resulting code will be compiled but NOT executed. Saying
X
X    filta -s f1n
X
is not the same. This will write the C program, compile it and execute
it (and will therefore sit there waiting for you to type input at it).
X
If filta is unable to write the current directory it puts the source in
strangely named files in under /tmp and tells you where they may be found.
X
Also valid is 
X
X    filta -f <filename>
X
which reads the program from the file <filename>.
X
X
X
Anyway I'm not going to go any more. There are more details it is handy
to know, but if you want them send me mail or read the code. filta is
not meant to be an awk replacement, it just makes it easier to do some
things with greater speed, and easier and MUCH faster to repeat (using
the a.out produced).  It is also very useful as a starting point for
the writing of your own special purpose filters. Have fun.
END_OF_FILE
if test 4915 -ne `wc -c <'filta/README'`; then
    echo shar: \"'filta/README'\" unpacked with wrong size!
fi
# end of 'filta/README'
fi
if test -f 'filta/filta.c' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'filta/filta.c'\"
else
echo shar: Extracting \"'filta/filta.c'\" \(13179 characters\)
sed "s/^X//" >'filta/filta.c' <<'END_OF_FILE'
X/*
X**
X** filta.c
X**
X** Build filters and things. See filta.doc
X** This code is something of a hack - I was just looking for an excuse 
X** to write code one night. As a result it's not very easy to add to the 
X** language. Comments are scarce too. Whatever.
X**
X** Terry Jones. (tcjones@watdragon)
X**
X*/
X
X#include "filta.h"
X#include <stdio.h>
X#include <errno.h>
X#include <sys/types.h>
X#include <sys/stat.h>
X#include <sys/file.h>
X#include <ctype.h>
X
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
X
XFILE *in_f;
XFILE *cmp_f;
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
X
X
main(argc, argv)
int argc;
char **argv;
X{
X	int lexval;
X	int in_if = 0;
X	int in_printf = 0;
X	int indent = 2;
X	int saved_indent;
X	int just_seen_if = 0;
X	char saved_args[1024];
X	int comp_type;
X
X	myname = *argv++;
X	argline = args;
X	saved_args[0] = '\0';
X	input = do_args(argc, argv);
X	if (save_source)
X		start_save_compile();
X	else
X		start_fast_compile();
X
X	do_header();
X
X	if (start_lex() == AUTO_SPLIT) 
X		emit(indent, cmp_f, "f_count = splitter(\" \\t\");\n");
X
X	while((lexval = lex()) != EOF){
X		switch (lexval){
X
X			case QUOTE:{
X				if (just_seen_if == 1){
X					lp_count++;
X					emit(0, cmp_f, "\"%s\"", lexeme);
X					just_seen_if = 0;
X				}
X				else if (in_if == 1){
X					emit(0, cmp_f, "\"%s\"", lexeme);
X				}
X				else if (in_printf == 0){
X					emit(indent, cmp_f, "printf(\"%s", lexeme);
X					in_printf = 1;
X				}
X				else{
X					emit(0, cmp_f, "%s", lexeme);
X				}
X				saved_string = 1;
X				saved_field = 0;
X				break;
X			}
X
X			case LPAREN:{
X				if (just_seen_if != 1){   /* Let them omit the keyword "if" */
X					emit(indent, cmp_f, "if (strcmp(");
X					indent++;
X					in_if = 1;
X				}
X				else
X					just_seen_if = 0;
X				lp_count++;
X				break;
X			}
X
X			case RPAREN:{
X				char comp[3];
X
X				if (in_if != 1 && in_printf != 1){
X					fprintf(stderr, "%s: ) not inside an if.\n", myname);
X					exit(1);
X				}
X
X				lp_count--;
X
X				if (lp_count < 0){
X					fprintf(stderr, "%s: Too many )'s\n", myname);
X					exit(1);
X				}
X
X				if (in_printf == 1){
X					finish_printf(saved_args);
X					in_printf = 0;
X					break;
X				}
X
X				comp[2] = '\0';
X				switch (comp_type){
X					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
X					case NEQ: comp[0] = '!'; comp[1] = '='; break;
X					case LT: comp[0] = '<'; comp[1] = '\0'; break;
X					case GT: comp[0] = '>'; comp[1] = '\0'; break;
X				}
X
X				if (lp_count == 0){
X					saved_string = saved_field = 0;
X					emit(0, cmp_f, ") %s 0)\n", comp);
X					in_if = 0;
X				}
X				else{
X	 				emit(0, cmp_f, ") %s 0", comp);
X				}
X
X				break;
X			}
X
X			case LBRACE:{
X				emit(indent - 1, cmp_f, "{\n");
X				saved_indent = indent - 1;
X				break;
X			}
X
X			case RBRACE:{
X				if (in_printf == 1){
X					finish_printf(saved_args);
X					in_printf = 0;
X				}
X				indent = saved_indent;
X				emit(indent, cmp_f, "}\n");
X				break;
X			}
X
X			case IF:{
X				if (in_printf == 1){
X					finish_printf(saved_args);
X					in_printf = 0;
X				}
X				emit(indent, cmp_f, "if (strcmp(");
X				indent++;
X				just_seen_if = 1;
X				in_if = 1;
X				break;
X			}
X
X			case ELSE:{
X				if (in_printf == 1){
X					finish_printf(saved_args);
X					in_printf = 0;
X				}
X
X				emit(indent - 1, cmp_f, "else\n");
X				break;
X			}
X
X			case NEQ:
X			case LT:
X			case GT:
X			case EQ:
X			case EQEQ:{
X				if (saved_string != 1 && saved_field != 1){
X					fprintf(stderr, "%s: == without left operand.\n", myname);
X					exit(1);
X				}
X				comp_type = lexval;
X				emit(0, cmp_f, ", ");
X				break;
X			}
X
X			case AND:{
X				char comp[3];
X				comp[2] = '\0';
X				switch (comp_type){
X					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
X					case NEQ: comp[0] = '!'; comp[1] = '='; break;
X					case LT: comp[0] = '<'; comp[1] = '\0'; break;
X					case GT: comp[0] = '>'; comp[1] = '\0'; break;
X				}
X				if (saved_string == 1 || saved_field == 1){
X	 				emit(0, cmp_f, ") %s 0", comp);
X				}
X				emit(0, cmp_f, " && strcmp(");
X				break;
X			}
X
X			case OR:{
X				char comp[3];
X				comp[2] = '\0';
X				switch (comp_type){
X					case EQ: case EQEQ: comp[0] = comp[1] = '='; break;
X					case NEQ: comp[0] = '!'; comp[1] = '='; break;
X					case LT: comp[0] = '<'; comp[1] = '\0'; break;
X					case GT: comp[0] = '>'; comp[1] = '\0'; break;
X				}
X				if (saved_string == 1 || saved_field == 1){
X	 				emit(0, cmp_f, ") %s 0", comp);
X				}
X				emit(0, cmp_f, " || strcmp(");
X				break;
X			}
X
X			case SPLIT:{
X				if (lex() != QUOTE){
X					fprintf(stderr, "%s: Split must be followed by a string\n",
X						myname);
X					exit(1);
X				}
X
X				if (in_if == 1){
X					fprintf(stderr, "\n%s: split inside an if?\n", myname);
X					exit(1);
X				}
X
X				if (in_printf == 1){
X					finish_printf(saved_args);
X					in_printf = 0;
X				}
X
X				if (strlen(lexeme) == 0) break;
X				emit(indent, cmp_f, "f_count = splitter(\"%s\");\n", lexeme);
X				break;
X			}
X
X			default:{
X				/* Field spec. */
X
X				char fld_str[100];
X
X				if (lexval == FIELD + LASTFIELD){
X					sprintf(fld_str, "f[f_count]");
X				}
X				else{
X					sprintf(fld_str, "f[%d]", lexval - FIELD);
X				}
X
X				if (in_if == 1){
X					emit(0, cmp_f, "%s", fld_str);
X				}
X				else{
X					if (in_printf == 0){
X						emit(indent, cmp_f, "printf(\"%%s");
X						sprintf(saved_args, ", %s", fld_str);
X						in_printf = 1;
X					}
X					else{
X						emit(0, cmp_f, "%%s");
X						sprintf(saved_args, "%s, %s", saved_args, fld_str);
X					}
X				}
X				saved_field = 1;
X				break;
X			}
X		}
X	}
X
X	if (in_if == 1){
X		fprintf(stderr, "\n%s: EOF inside an if?\n", myname);
X		exit(1);
X	}
X
X	if (in_printf == 1){
X		finish_printf(saved_args);
X	}
X
X	do_tailer();
X	do_splitter();
X	if (save_source)
X		do_save_compile();
X	else
X		do_fast_compile();
X	return 0;
X}
X
void
do_header()
X{
X	fprintf(cmp_f,"#include <stdio.h>\n\n#define MAXLINE 4096\n");
X	fprintf(cmp_f,"#define MAXFLDS 20\n\n");
X	fprintf(cmp_f, "char line[MAXLINE];\nchar copy[MAXLINE];\n");
X	fprintf(cmp_f, "char *f[MAXFLDS + 1];\n\n");
X	fprintf(cmp_f, "main(argc, argv)\nint argc;\nchar **argv;\n{\n");
X	fprintf(cmp_f, "\tregister int f_count;\n");
X	fprintf(cmp_f, "\tint i;\n\n\tfor (i = 0; i <= MAXFLDS; i++)");
X	fprintf(cmp_f, "f[i] = NULL;\n");
X	fprintf(cmp_f, "\twhile (gets(line))\n\t{\n\t\tf[0] = line;\n");
X}
X
void
do_tailer()
X{
X	fprintf(cmp_f, "\t}\n}\n");
X}
X
void
do_splitter()
X{
X	fprintf(cmp_f, 
X		"\n\nsplitter(sep)\nchar *sep;\n");
X	fprintf(cmp_f, "{\n\textern char *index();\n");
X	fprintf(cmp_f, "\tchar *tmp = copy;\n\tregister int fld;\n\n");
X	fprintf(cmp_f, "\tfor (fld = 1; fld <= MAXFLDS; fld++) f[fld] = NULL;\n");
X	fprintf(cmp_f, "\tif (!strlen(sep) || !strlen(line)) return 0;\n");
X	fprintf(cmp_f, "\tfld = 1;\n\tsprintf(copy, \"%%s\", line);\n");
X	fprintf(cmp_f, "\twhile (fld < MAXFLDS){\n\t\twhile (index(sep, *tmp))\n");
X	fprintf(cmp_f, "\t\t\tif (!*++tmp) return fld;\n");
X	fprintf(cmp_f, "\t\tf[fld++] = tmp++;\n\t\twhile (!index(sep, *tmp))\n");
X	fprintf(cmp_f, "\t\t\tif (!*++tmp) return fld;\n");
X	fprintf(cmp_f, "\t\t*tmp++ = '\\0';\n\t}\n\treturn fld;\n}\n");
X}
X
X
X/* VARARGS1 */
void
emit(in, dest, fmt, a, b, c, d, e, f, g)
int in;
XFILE *dest;
char *fmt, *a, *b, *c, *d, *e, *f, *g;
X{
X	register int i;
X
X	for (i=0; i<in; i++) putc('\t', dest);
X	fprintf(dest, fmt, a, b, c, d, e, f, g);
X}
X
X
void
finish_printf(save)
char *save;
X{
X	if (*save){
X		emit(0, cmp_f, "\"%s);\n", save);
X		*save = '\0';
X	}
X	else{
X		emit(0, cmp_f, "\");\n");
X	}
X	saved_string = 0;
X}
X
int
do_args(argc, argv)
int argc;
char **argv;
X{
X	if (argc == 2 && !strcmp(*argv, "-s")){
X		save_source = 1;
X		auto_exec = 0;
X		in_f = stdin;
X		return IN_FILE;
X	}
X
X	if (argc == 1){
X		usage();
X		exit(1);
X	}
X
X	if (!strcmp(*argv, "-s")){
X		save_source = 1;
X		argc--;
X		argv++;
X	}
X
X	if (argc == 3 && !strcmp(*argv, "-f")){
X		in_f = fopen(*++argv, "r");
X		if (!in_f){
X			fprintf(stderr, "%s: Could not open %s\n", myname, *argv);
X			exit(1);
X		}
X		return IN_FILE;
X	}
X
X	/* Must be a program on the argument line. */
X
X	args[0] = '\0';
X	while (--argc)
X		sprintf(args, "%s %s", args, *argv++);
X	return IN_ARGLINE;
X}
X
void
usage()
X{
X	fprintf(stderr, 
X	"Usage: %s [-s] [-f file | program]\n", myname, myname, myname);
X}
X
X
start_save_compile()
X{
X	extern char *mktemp();
X	char *tsrc = "/tmp/.__compile.srcXXXXXX";
X	char *obj = "/tmp/.__compile.objXXXXXX";
X	static char src[100];
X	struct stat sbuf;
X	extern int errno;
X	FILE *fopen();
X
X	cmp_f = fopen("Filta.c", "w");
X
X	if (!cmp_f){
X		/* Have to use our own names in /tmp */
X		if (mktemp(tsrc) == (char *)-1){
X			fprintf(stderr, "Could not mktemp()\n");
X			exit(1);
X		}
X		sprintf(src, "%s.c", tsrc);
X
X		errno = 0;
X		if (!(stat(src, sbuf) == -1 && errno == ENOENT)){
X			fprintf(stderr, "Could not mktemp()\n");
X			exit(1);
X		}
X
X		if (mktemp(obj) == (char *)-1){
X			fprintf(stderr, "Could not mktemp()\n");
X			exit(1);
X		}
X
X		cmp_f = fopen(src, "w");
X
X		if (!cmp_f){
X			fprintf(stderr, "Could not fopen()\n");
X			exit(1);
X		}
X
X		source = src;
X		object = obj;
X
X		sprintf(compile_cmd, "cd /tmp && /bin/cc -O -o %s %s", obj, src);
X		fprintf(stderr, "%s source is in \"%s\"\n", myname, source);
X		fprintf(stderr, "%s object is in \"%s\"\n", myname, object);
X	}
X	else{
X		sprintf(compile_cmd, "/bin/cc -O Filta.c");
X	}
X}
X
do_save_compile()
X{
X	fclose(cmp_f);
X	if (system(compile_cmd) == 0){
X		if (auto_exec == 1){
X			execl(object, 0);
X			fprintf(stderr, "Could not execl(%s, 0)\n", object);
X			exit(1);
X		}
X	}
X	else{
X		fprintf(stderr, "%s: Compilation did not suceed!\n", myname);
X		exit(1);
X	}
X}
X
X
X
start_fast_compile()
X{
X	extern char *mktemp();
X	char *tsrc = "/tmp/.__compile.srcXXXXXX";
X	static char src[100];
X	extern int errno;
X	struct stat sbuf;
X	FILE *popen();
X	register int fd;
X
X	if (mktemp(tsrc) == (char *)-1){
X		fprintf(stderr, "Could not mktemp()\n");
X		exit(1);
X	}
X	sprintf(src, "%s.c", tsrc);
X
X	errno = 0;
X	if (!(stat(src, sbuf) == -1 && errno == ENOENT)){
X		fprintf(stderr, "Could not mktemp()\n");
X		exit(1);
X	}
X
X	if ((fd = open(src, O_CREAT | O_WRONLY, 0666)) == -1){
X		fprintf(stderr, "%s: Could not open() %s\n", myname, src);
X		exit(1);
X	}
X
X	if (write(fd, "#include \"/dev/stdin\"\n", 22) != 22){
X		fprintf(stderr, "%s: Could not write() %s\n", myname, src);
X		exit(1);
X	}
X
X	if (close(fd) == -1){
X		fprintf(stderr, "%s: Could not close() %s\n", myname, src);
X		exit(1);
X	}
X
X	source = src;
X
X	sprintf(compile_cmd, "/bin/cc -O %s", src);
X	cmp_f = popen(compile_cmd, "w");
X
X	if (!cmp_f){
X		fprintf(stderr, "Could not popen(%s)\n", compile_cmd);
X		exit(1);
X	}
X}
X
do_fast_compile()
X{
X	pclose(cmp_f); /* This waits for the cc to complete. */
X	if (unlink(source) == -1)
X		fprintf(stderr, "%s: Warning! could not unlink %s\n", myname, source);
X	execl(object, 0);
X	fprintf(stderr, "Could not execl(%s, 0)\n", object);
X	exit(1);
X}
X
X
X
int
start_lex()
X{
X	if (input == IN_FILE){
X		if (fill_buf(in_f) == 0)
X			return EOF;
X	}
X	else{
X		sprintf(buf, "%s", argline);
X	}
X
X	if (skip_white() == 0) return EOF;
X
X	if (!strncmp(buf, tokens[SPLIT], strlen(tokens[SPLIT]))){
X		return NO_AUTO_SPLIT;
X	}
X
X	return AUTO_SPLIT;
X}
X
int
lex()
X{
X	register int tok;
X	
X	if (end_of_file == 1) return EOF;
X	if (skip_white() == 0) return EOF;
X	
X	for (tok = 0; tok < TOKENS; tok++){
X		register int tmp = strlen(tokens[tok]);
X		if (strncmp(bufp, tokens[tok], tmp) == 0){
X			bufp += tmp;
X			if (tok != QUOTE && skip_white() == 0) end_of_file = 1;
X
X			switch (tok){
X				case QUOTE:{
X					register char *q = index(bufp, '"');
X
X					if (!q){
X						fprintf(stderr, "%s: Unmatched \" in string.\n",myname);
X						exit(1);
X					}
X					lexeme[0] = '\0';
X					strncat(lexeme, bufp, q - bufp);
X					bufp = q + 1;
X					return QUOTE;
X				}
X
X				default:{
X					return tok;
X				}
X			}
X
X		}
X	}
X
X	if ((*bufp == 'f' || *bufp == '$') && isdigit(*(bufp + 1))){
X
X		int field_no;
X
X		bufp++;
X		field_no = atoi(bufp);
X		if (field_no > MAX_FIELDS){
X			fprintf(stderr, "%s: Maximum number of fields (%d) exceeeded.\n",
X				myname, MAX_FIELDS);
X			fprintf(stderr, "Line was \n%s\n", buf);
X			exit(1);
X		}
X		while (isdigit(*bufp)) bufp++;
X		return(FIELD + field_no);
X	}
X
X	if ((*bufp == 'f' || *bufp == '$') && *(bufp + 1) == '$'){
X		bufp += 2;
X		return FIELD + LASTFIELD;
X	}
X
X	if (*bufp == 'n'){
X		sprintf(lexeme, "\\n");
X		bufp++;
X		return QUOTE;
X	}
X
X	if (*bufp == 't'){
X		sprintf(lexeme, "\\t");
X		bufp++;
X		return QUOTE;
X	}
X
X	if (*bufp == 's'){
X		sprintf(lexeme, " ");
X		bufp++;
X		return QUOTE;
X	}
X
X
X	lex_err();
X	exit(1);
X
X}
X
int
fill_buf()
X{
X	char *nl;
X	if (fgets(buf, 1024, in_f) == NULL) return 0;
X	if ((nl = index(buf, '\n'))) *nl = '\0';
X	bufp = buf;
X	return 1;
X}
X
void
lex_err()
X{
X	fprintf(stderr, "%s: Could not lex input line\n%s\n", myname, buf);
X	fprintf(stderr, "Lex broke at %s\n", bufp);
X}
X
int
skip_white()
X{
X	while (*bufp == ' ' || *bufp == '\t') bufp++;
X
X	if (*bufp == '\0'){
X		if (input == IN_ARGLINE) return 0;
X		if (fill_buf() == 0) 
X			return 0;
X		if (skip_white() == 0) return 0;
X	}
X
X	return 1;
X}
END_OF_FILE
if test 13179 -ne `wc -c <'filta/filta.c'`; then
    echo shar: \"'filta/filta.c'\" unpacked with wrong size!
fi
# end of 'filta/filta.c'
fi
if test -f 'filta/filta.h' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'filta/filta.h'\"
else
echo shar: Extracting \"'filta/filta.h'\" \(1061 characters\)
sed "s/^X//" >'filta/filta.h' <<'END_OF_FILE'
X#define TOKENS       15
static char *tokens[TOKENS] = {   
X					              "\"",
X								  "(",
X					              ")", 
X					              "{", 
X					              "}", 
X					              "if", 
X					              "else", 
X					              "==", 
X					              "=", 
X								  "!=",
X								  "<",
X								  ">",
X					              "&&", 
X					              "||", 
X					              "split"
X				              };
X
X#define MAX_FIELDS   20
X
X#define NO_AUTO_SPLIT -1000
X#define AUTO_SPLIT -1001
X
X#define IN_ARGLINE 1
X#define IN_FILE    2
X
X/*
X *  Make sure that these names refer to the right spots in the array 
X#define LASTFIELD    1000000
X */
X
X#define QUOTE        0
X#define LPAREN       1
X#define RPAREN       2
X#define LBRACE       3
X#define RBRACE       4
X#define IF           5
X#define ELSE         6
X#define EQEQ         7
X#define EQ           8
X#define NEQ          9
X#define LT           10
X#define GT           11
X#define AND          12
X#define OR           13
X#define SPLIT        14
X
X#define FIELD        1000
X#define LASTFIELD    1000000
END_OF_FILE
if test 1061 -ne `wc -c <'filta/filta.h'`; then
    echo shar: \"'filta/filta.h'\" unpacked with wrong size!
fi
# end of 'filta/filta.h'
fi
if test -f 'filta/tags' -a "${1}" != "-c" ; then 
  echo shar: Will not clobber existing file \"'filta/tags'\"
else
echo shar: Extracting \"'filta/tags'\" \(662 characters\)
sed "s/^X//" >'filta/tags' <<'END_OF_FILE'
Mfilta	filta.c	/^main(argc, argv)$/
do_args	filta.c	/^do_args(argc, argv)$/
do_fast_compile	filta.c	/^do_fast_compile()$/
do_header	filta.c	/^do_header()$/
do_save_compile	filta.c	/^do_save_compile()$/
do_splitter	filta.c	/^do_splitter()$/
do_tailer	filta.c	/^do_tailer()$/
emit	filta.c	/^emit(in, dest, fmt, a, b, c, d, e, f, g)$/
fill_buf	filta.c	/^fill_buf()$/
finish_printf	filta.c	/^finish_printf(save)$/
lex	filta.c	/^lex()$/
lex_err	filta.c	/^lex_err()$/
skip_white	filta.c	/^skip_white()$/
start_fast_compile	filta.c	/^start_fast_compile()$/
start_lex	filta.c	/^start_lex()$/
start_save_compile	filta.c	/^start_save_compile()$/
usage	filta.c	/^usage()$/
END_OF_FILE
if test 662 -ne `wc -c <'filta/tags'`; then
    echo shar: \"'filta/tags'\" unpacked with wrong size!
fi
# end of 'filta/tags'
fi
echo shar: End of archive 1 \(of 1\).
cp /dev/null ark1isdone
MISSING=""
for I in 1 ; do
    if test ! -f ark${I}isdone ; then
	MISSING="${MISSING} ${I}"
    fi
done
if test "${MISSING}" = "" ; then
    echo You have the archive.
    rm -f ark[1-9]isdone
else
    echo You still need to unpack the following archives:
    echo "        " ${MISSING}
fi
##  End of shell archive.
exit 0
