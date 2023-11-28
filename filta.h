#define TOKENS       15
static char *tokens[TOKENS] = {   
					              "\"",
								  "(",
					              ")", 
					              "{", 
					              "}", 
					              "if", 
					              "else", 
					              "==", 
					              "=", 
								  "!=",
								  "<",
								  ">",
					              "&&", 
					              "||", 
					              "split"
				              };

#define MAX_FIELDS   20

#define NO_AUTO_SPLIT -1000
#define AUTO_SPLIT -1001

#define IN_ARGLINE 1
#define IN_FILE    2

/*
 *  Make sure that these names refer to the right spots in the array 
#define LASTFIELD    1000000
 */

#define QUOTE        0
#define LPAREN       1
#define RPAREN       2
#define LBRACE       3
#define RBRACE       4
#define IF           5
#define ELSE         6
#define EQEQ         7
#define EQ           8
#define NEQ          9
#define LT           10
#define GT           11
#define AND          12
#define OR           13
#define SPLIT        14

#define FIELD        1000
#define LASTFIELD    1000000
