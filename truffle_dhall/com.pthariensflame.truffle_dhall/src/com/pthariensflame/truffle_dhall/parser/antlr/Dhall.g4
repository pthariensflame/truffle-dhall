// -*- mode: antlr; -*-

// This grammar was autoconverted from Dhall's official ABNF grammar,
// with minor hand modifications both before and after.
grammar Dhall;

// NOTE: There are many line endings in the wild
//
// See: https://en.wikipedia.org/wiki/Newline
//
// For simplicity this supports Unix and Windows line-endings, which are the most
// common
END_OF_LINE :
      '\n'
    | '\r\n';

// This rule matches all characters that are not:
//
// * not ASCII
// * not part of a surrogate pair
// * not a "non-character"
VALID_NON_ASCII :
      [\u{0080}-\u{D7FF}]
    // %xD800-DFFF = surrogate pairs
    | [\u{E000}-\u{FFFD}]
    // %xFFFE-FFFF = non-characters
    | [\u{10000}-\u{1FFFD}]
    // %x1FFFE-1FFFF = non-characters
    | [\u{20000}-\u{2FFFD}]
    // %x2FFFE-2FFFF = non-characters
    | [\u{30000}-\u{3FFFD}]
    // %x3FFFE-3FFFF = non-characters
    | [\u{40000}-\u{4FFFD}]
    // %x4FFFE-4FFFF = non-characters
    | [\u{50000}-\u{5FFFD}]
    // %x5FFFE-5FFFF = non-characters
    | [\u{60000}-\u{6FFFD}]
    // %x6FFFE-6FFFF = non-characters
    | [\u{70000}-\u{7FFFD}]
    // %x7FFFE-7FFFF = non-characters
    | [\u{80000}-\u{8FFFD}]
    // %x8FFFE-8FFFF = non-characters
    | [\u{90000}-\u{9FFFD}]
    // %x9FFFE-9FFFF = non-characters
    | [\u{A0000}-\u{AFFFD}]
    // %xAFFFE-AFFFF = non-characters
    | [\u{B0000}-\u{BFFFD}]
    // %xBFFFE-BFFFF = non-characters
    | [\u{C0000}-\u{CFFFD}]
    // %xCFFFE-CFFFF = non-characters
    | [\u{D0000}-\u{DFFFD}]
    // %xDFFFE-DFFFF = non-characters
    | [\u{E0000}-\u{EFFFD}]
    // %xEFFFE-EFFFF = non-characters
    | [\u{F0000}-\u{FFFFD}]
    // %xFFFFE-FFFFF = non-characters
    | [\u{100000}-\u{10FFFD}];
    // %x10FFFE-10FFFF = non-characters

TAB : '\t';

block_comment : ('{' '-') block_comment_continue;

BLOCK_COMMENT_CHAR :
      [\u{0020}-\u{007F}]
    | VALID_NON_ASCII
    | TAB
    | END_OF_LINE;

block_comment_continue :
    ('-' '}')
    | (block_comment block_comment_continue)
    | (BLOCK_COMMENT_CHAR block_comment_continue);

NOT_END_OF_LINE : [\u{0020}-\u{007F}] | VALID_NON_ASCII | TAB;

// NOTE: Slightly different from Haskell-style single-line comments because this
// does not require a space after the dashes
line_comment : ('-' '-') NOT_END_OF_LINE* END_OF_LINE;

whitespace_chunk :
      ' '
    | TAB
    | END_OF_LINE
    | line_comment
    | block_comment;

whsp : whitespace_chunk*;

// nonempty whitespace
whsp1 : whitespace_chunk+;

// Uppercase or lowercase ASCII letter
ALPHA : [A-Za-z];

// ASCII digit
DIGIT : [0-9];

ALPHANUM : ALPHA | DIGIT;

ALPHA_HEX_DIG : [A-Fa-f];

hexdig : DIGIT | ALPHA_HEX_DIG;

// A simple label cannot be one of the reserved keywords
// listed in the `keyword` rule.
// A PEG parser could use negative lookahead to
// enforce this, e.g. as follows:
// simple-label =
//       keyword 1*simple-label-next-char
//     / !keyword (simple-label-first-char *simple-label-next-char)
simple_label_first_char : ALPHA | '_';
simple_label_next_char : ALPHANUM | '-' | '/' | '_';
simple_label : simple_label_first_char simple_label_next_char*;

QUOTED_LABEL_CHAR :
      [\u{0020}-\u{005F}]
        // %x60 = '`'
    | [\u{0061}-\u{007E}];

quoted_label : QUOTED_LABEL_CHAR+;

// NOTE: Dhall does not support Unicode labels, mainly to minimize the potential
// for code obfuscation
label : (('`' quoted_label '`') | simple_label);

// A nonreserved-label cannot not be any of the reserved identifiers for builtins
// (unless quoted).
// Their list can be found in the `builtin` rule.
// The only place where this restriction applies is bound variables.
// A PEG parser could use negative lookahead to avoid parsing those identifiers,
// e.g. as follows:
// nonreserved-label =
//      builtin 1*simple-label-next-char
//    / !builtin label
nonreserved_label : label;

// An any-label is allowed to be one of the reserved identifiers (but not a keyword).
any_label : label;

// Allow specifically `Some` in record and union labels.
any_label_or_some : any_label | some;

// Dhall's double-quoted strings are similar to JSON strings (RFC7159) except:
//
// * Dhall strings support string interpolation
//
// * Dhall strings also support escaping string interpolation by adding a new
//   `\$` escape sequence
//
// * Dhall strings also allow Unicode escape sequences of the form `\u{XXX}`
double_quote_chunk :
      interpolation
      // '\'    Beginning of escape sequence
    | ('\\' double_quote_escaped)
    | DOUBLE_QUOTE_CHAR;

double_quote_escaped :
      '"'                 // '"'    quotation mark  U+0022
    | '$'                 // '$'    dollar sign     U+0024
    | '\\'                // '\'    reverse solidus U+005C
    | '/'                 // '/'    solidus         U+002F
    | 'b'                 // 'b'    backspace       U+0008
    | 'f'                 // 'f'    form feed       U+000C
    | 'n'                 // 'n'    line feed       U+000A
    | 'r'                 // 'r'    carriage return U+000D
    | 't'                 // 't'    tab             U+0009
    | ('u' unicode_escape);  // 'uXXXX' / 'u{XXXX}'    U+XXXX

// Valid Unicode escape sequences are as follows:
//
// * Exactly 4 hexadecimal digits without braces:
//       `\uXXXX`
// * 1-6 hexadecimal digits within braces (with optional zero padding):
//       `\u{XXXX}`, `\u{000X}`, `\u{XXXXX}`, `\u{00000XXXXX}`, etc.
//   Any number of leading zeros are allowed within the braces preceding the 1-6
//   digits specifying the codepoint.
//
// From these sequences, the parser must also reject any codepoints that are in
// the following ranges:
//
// * Surrogate pairs: `%xD800-DFFF`
// * Non-characters: `%xNFFFE-NFFFF` / `%x10FFFE-10FFFF` for `N` in `{ 0 .. F }`
//
// See the `valid-non-ASCII` rule for the exact ranges that are not allowed
unicode_escape : unbraced_escape | ('{' braced_escape '}');

// All valid last 4 digits for unicode codepoints (outside Plane 0): `0000-FFFD`
unicode_suffix : ((DIGIT | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd') | ('E' | 'e')) (hexdig hexdig hexdig))
               | (('F' | 'f') (hexdig hexdig) (DIGIT | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd')));

// All 4-hex digit unicode escape sequences that are not:
//
// * Surrogate pairs (i.e. `%xD800-DFFF`)
// * Non-characters (i.e. `%xFFFE-FFFF`)
//
unbraced_escape :
      ((DIGIT | ('A' | 'a') | ('B' | 'b') | ('C' | 'c')) (hexdig hexdig hexdig))
    | (('D' | 'd') ('0' | '1' | '2' | '3' | '4' | '5' | '6' | '7') hexdig hexdig)
    // %xD800-DFFF Surrogate pairs
    | (('E' | 'e') (hexdig hexdig hexdig))
    | (('F' | 'f') (hexdig hexdig) (DIGIT | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd')));
    // %xFFFE-FFFF Non-characters

// All 1-6 digit unicode codepoints that are not:
//
// * Surrogate pairs: `%xD800-DFFF`
// * Non-characters: `%xNFFFE-NFFFF` / `%x10FFFE-10FFFF` for `N` in `{ 0 .. F }`
//
// See the `valid-non-ASCII` rule for the exact ranges that are not allowed
braced_codepoint :
      (('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd') | ('E' | 'e') | ('F' | 'f') | ('1' '0')) unicode_suffix)// (Planes 1-16)
    | unbraced_escape // (Plane 0)
    | (hexdig ((hexdig hexdig) | hexdig?)); // %x000-FFF

// Allow zero padding for braced codepoints
braced_escape : '0'* braced_codepoint;

// Printable characters except double quote and backslash
DOUBLE_QUOTE_CHAR :
      [\u{0020}-\u{0021}]
        // %x22 = '"'
    | [\u{0023}-\u{005B}]
        // %x5C = "\"
    | [\u{005D}-\u{007F}]
    | VALID_NON_ASCII;

double_quote_literal : '"' double_quote_chunk* '"';

// NOTE: The only way to end a single-quote string literal with a single quote is
// to either interpolate the single quote, like this:
//
//     ''ABC${"'"}''
//
// ... or concatenate another string, like this:
//
//     ''ABC'' ++ "'"
//
// If you try to end the string literal with a single quote then you get "'''",
// which is interpreted as an escaped pair of single quotes
single_quote_continue :
      (interpolation single_quote_continue)
    | (ESCAPED_QUOTE_PAIR single_quote_continue)
    | (ESCAPED_INTERPOLATION single_quote_continue)
    | ('\'' '\'') // End of text literal
    | (SINGLE_QUOTE_CHAR single_quote_continue);

// Escape two single quotes (i.e. replace this sequence with "''")
ESCAPED_QUOTE_PAIR : ('\'' '\'' '\'');

// Escape interpolation (i.e. replace this sequence with "${")
ESCAPED_INTERPOLATION : ('\'' '\'' '$' '{');

SINGLE_QUOTE_CHAR :
      [\u{0020}-\u{007F}]
    | VALID_NON_ASCII
    | TAB
    | END_OF_LINE;

single_quote_literal : ('\'' '\'') END_OF_LINE single_quote_continue;

interpolation : ('$' '{') complete_expression '}';

text_literal : (double_quote_literal | single_quote_literal);

// RFC 5234 interprets string literals as case-insensitive and recommends using
// hex instead for case-sensitive strings
//
// If you don't feel like reading hex, these are all the same as the rule name.
// Keywords that should never be parsed as identifiers
if_1 : 'i' 'f';
then : 't' 'h' 'e' 'n';
else_1 : 'e' 'l' 's' 'e';
let : 'l' 'e' 't';
in_1 : 'i' 'n';
as_1 : 'a' 's';
using_1 : 'u' 's' 'i' 'n' 'g';
merge : 'm' 'e' 'r' 'g' 'e';
missing : 'm' 'i' 's' 's' 'i' 'n' 'g';
infinity : 'I' 'n' 'f' 'i' 'n' 'i' 't' 'y';
nan : 'N' 'a' 'N';
some : 'S' 'o' 'm' 'e';
to_map : 't' 'o' 'M' 'a' 'p';
assert_1 : 'a' 's' 's' 'e' 'r' 't';
FORALL_SYMBOL : [\u{2200}];
forall : FORALL_SYMBOL | 'f' 'o' 'r' 'a' 'l' 'l';
with : 'w' 'i' 't' 'h';

// Unused rule that could be used as negative lookahead in the
// `simple-label` rule for parsers that support this.
keyword :
      if_1 | then | else_1
    | let | in_1
    | using_1 | missing
    | assert_1 | as_1
    | infinity | nan
    | merge | some | to_map
    | forall
    | with;

builtin :
      natural_fold
    | natural_build
    | natural_iszero
    | natural_even
    | natural_odd
    | natural_tointeger
    | natural_show
    | integer_todouble
    | integer_show
    | integer_negate
    | integer_clamp
    | natural_subtract
    | double_show
    | list_build
    | list_fold
    | list_length
    | list_head
    | list_last
    | list_indexed
    | list_reverse
    | optional_fold
    | optional_build
    | text_show
    | bool_1
    | true_1
    | false_1
    | optional
    | none
    | natural
    | integer
    | double_1
    | text
    | list
    | type
    | kind
    | sort;

// Reserved identifiers, needed for some special cases of parsing
optional : 'O' 'p' 't' 'i' 'o' 'n' 'a' 'l';
text : 'T' 'e' 'x' 't';
list : 'L' 'i' 's' 't';
location : 'L' 'o' 'c' 'a' 't' 'i' 'o' 'n';

// Reminder of the reserved identifiers, needed for the `builtin` rule
bool_1 : 'B' 'o' 'o' 'l';
true_1 : 'T' 'r' 'u' 'e';
false_1 : 'F' 'a' 'l' 's' 'e';
none : 'N' 'o' 'n' 'e';
natural : 'N' 'a' 't' 'u' 'r' 'a' 'l';
integer : 'I' 'n' 't' 'e' 'g' 'e' 'r';
double_1 : 'D' 'o' 'u' 'b' 'l' 'e';
type : 'T' 'y' 'p' 'e';
kind : 'K' 'i' 'n' 'd';
sort : 'S' 'o' 'r' 't';
natural_fold : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 'f' 'o' 'l' 'd';
natural_build : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 'b' 'u' 'i' 'l' 'd';
natural_iszero : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 'i' 's' 'Z' 'e' 'r' 'o';
natural_even : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 'e' 'v' 'e' 'n';
natural_odd : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 'o' 'd' 'd';
natural_tointeger : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 't' 'o' 'I' 'n' 't' 'e' 'g' 'e' 'r';
natural_show : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 's' 'h' 'o' 'w';
natural_subtract : 'N' 'a' 't' 'u' 'r' 'a' 'l' '/' 's' 'u' 'b' 't' 'r' 'a' 'c' 't';
integer_todouble : 'I' 'n' 't' 'e' 'g' 'e' 'r' '/' 't' 'o' 'D' 'o' 'u' 'b' 'l' 'e';
integer_show : 'I' 'n' 't' 'e' 'g' 'e' 'r' '/' 's' 'h' 'o' 'w';
integer_negate : 'I' 'n' 't' 'e' 'g' 'e' 'r' '/' 'n' 'e' 'g' 'a' 't' 'e';
integer_clamp : 'I' 'n' 't' 'e' 'g' 'e' 'r' '/' 'c' 'l' 'a' 'm' 'p';
double_show : 'D' 'o' 'u' 'b' 'l' 'e' '/' 's' 'h' 'o' 'w';
list_build : 'L' 'i' 's' 't' '/' 'b' 'u' 'i' 'l' 'd';
list_fold : 'L' 'i' 's' 't' '/' 'f' 'o' 'l' 'd';
list_length : 'L' 'i' 's' 't' '/' 'l' 'e' 'n' 'g' 't' 'h';
list_head : 'L' 'i' 's' 't' '/' 'h' 'e' 'a' 'd';
list_last : 'L' 'i' 's' 't' '/' 'l' 'a' 's' 't';
list_indexed : 'L' 'i' 's' 't' '/' 'i' 'n' 'd' 'e' 'x' 'e' 'd';
list_reverse : 'L' 'i' 's' 't' '/' 'r' 'e' 'v' 'e' 'r' 's' 'e';
optional_fold : 'O' 'p' 't' 'i' 'o' 'n' 'a' 'l' '/' 'f' 'o' 'l' 'd';
optional_build : 'O' 'p' 't' 'i' 'o' 'n' 'a' 'l' '/' 'b' 'u' 'i' 'l' 'd';
text_show : 'T' 'e' 'x' 't' '/' 's' 'h' 'o' 'w';

// Operators
COMBINE_SYMBOL : [\u{2227}];
combine : COMBINE_SYMBOL | ('/' '\\');
COMBINE_TYPES_SYMBOL : [\u{2A53}];
combine_types : COMBINE_TYPES_SYMBOL | ('/' '/' '\\' '\\');
EQUIVALENT_SYMBOL : [\u{2261}];
equivalent : EQUIVALENT_SYMBOL | ('=' '=' '=');
PREFER_SYMBOL : [\u{2AFD}];
prefer : PREFER_SYMBOL | ('/' '/');
LAMBDA_SYMBOL : [\u{03BB}];
lambda : LAMBDA_SYMBOL  | '\\';
ARROW_SYMBOL : [\u{2192}];
arrow : ARROW_SYMBOL | ('-' '>');
complete : (':' ':');

exponent : ('E' | 'e') ( '+' | '-' )? DIGIT+;

numeric_double_literal : ( '+' | '-' )? DIGIT+ ( ('.' DIGIT+ ( exponent )?) | exponent);

minus_infinity_literal : '-' infinity;
plus_infinity_literal : infinity;

double_literal :
    // "2.0"
      numeric_double_literal
    // "-Infinity"
    | minus_infinity_literal
    // "Infinity"
    | plus_infinity_literal
    // "NaN"
    | nan;

natural_literal :
    // Hexadecimal with "0x" prefix
      ('0' 'x' hexdig+)
    // Decimal; leading 0 digits are not allowed
    | (('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') DIGIT*)
    // ... except for 0 itself
    | '0';

integer_literal : ( '+' | '-' ) natural_literal;

// If the identifier matches one of the names in the `builtin` rule, then it is a
// builtin, and should be treated as the corresponding item in the list of
// "Reserved identifiers for builtins" specified in the `standard/README.md` document.
// It is a syntax error to specify a de Bruijn index in this case.
// Otherwise, this is a variable with name and index matching the label and index.
identifier : variable | builtin;

variable : nonreserved_label ( whsp '@' whsp natural_literal )?;

// Printable characters other than " ()[]{}<>/\,"
//
// Excluding those characters ensures that paths don't have to end with trailing
// whitespace most of the time
PATH_CHARACTER :
        // %x20 = " "
      [\u{0021}]
        // %x22 = "\""
        // %x23 = "#"
    | [\u{0024}-\u{0027}]
        // %x28 = "("
        // %x29 = ")"
    | [\u{002A}-\u{002B}]
        // %x2C = ","
    | [\u{002D}-\u{002E}]
        // %x2F = "/"
    | [\u{0030}-\u{003B}]
        // %x3C = "<"
    | [\u{003D}]
        // %x3E = ">"
        // %x3F = "?"
    | [\u{0040}-\u{005A}]
        // %x5B = "["
        // %x5C = "\"
        // %x5D = "]"
    | [\u{005E}-\u{007A}]
        // %x7B = "{"
    | [\u{007C}]
        // %x7D = "}"
    | [\u{007E}];

QUOTED_PATH_CHARACTER :
      [\u{0020}-\u{0021}]
        // %x22 = "\""
    | [\u{0023}-\u{002E}]
        // %x2F = "/"
    | [\u{0030}-\u{007F}]
    | VALID_NON_ASCII;

unquoted_path_component : PATH_CHARACTER+;
quoted_path_component : QUOTED_PATH_CHARACTER+;

path_component : '/' ( unquoted_path_component | ('"' quoted_path_component '"') );

// The last path-component matched by this rule is referred to as "file" in the semantics,
// and the other path-components as "directory".
path : path_component+;

local :
    parent_path
    | here_path
    | home_path
    // NOTE: Backtrack if parsing this alternative fails
    //
    // This is because the first character of this alternative will be "/", but
    // if the second character is "/" or "\" then this should have been parsed
    // as an operator instead of a path
    | absolute_path;

parent_path : ('.' '.') path;  // Relative path
here_path : '.'  path;  // Relative path
home_path : '~'  path;  // Home-anchored path
absolute_path : path;  // Absolute path

// `http[s]` URI grammar based on RFC7230 and RFC 3986 with some differences
// noted below

SCHEME : 'h' 't' 't' 'p' ('s'?);  // "http" [ "s" ]

// NOTE: This does not match the official grammar for a URI.  Specifically:
//
// * path segments may be quoted instead of using percent-encoding
// * this does not support fragment identifiers, which have no meaning within
//   Dhall expressions and do not affect import resolution
// * the characters "(" ")" and "," are not included in the `sub-delims` rule:
//   in particular, these characters can't be used in authority, path or query
//   strings.  This is because those characters have other meaning in Dhall
//   and it would be confusing for the comma in
//       [http://example.com/foo, bar]
//   to be part of the URL instead of part of the list.  If you need a URL
//   which contains parens or a comma, you must percent-encode them.
//
// Reserved characters in quoted path components should be percent-encoded
// according to https://tools.ietf.org/html/rfc3986#section-2
http_raw : SCHEME (':' '/' '/') authority url_path ( '?' query )?;

// Temporary rule to allow old-style `path-component`s and RFC3986 `segment`s in
// the same grammar. Eventually we can just use `path-abempty` from the same
// RFC. See issue #581

url_path : (path_component | ('/' segment))*;

// NOTE: Backtrack if parsing the optional user info prefix fails
authority : ( userinfo '@' )? host ( ':' port )?;

userinfo : ( unreserved | pct_encoded | SUB_DELIMS | ':' )*;

host : ip_literal | ipv4address | domain;

port : DIGIT*;

ip_literal : '[' ( ipv6address | ipvfuture  ) ']';

ipvfuture : ('V' | 'v') hexdig+ '.' ( unreserved | SUB_DELIMS | ':' )+;

// NOTE: Backtrack when parsing each alternative
ipv6address :                            ((( h16 ':' ) (h16 ':') (h16 ':') (h16 ':') (h16 ':') (h16 ':')) ls32)
            |                       ((':' ':') (( h16 ':' ) (h16 ':') (h16 ':') (h16 ':') (h16 ':')) ls32)
            | (( h16               )? (':' ':') (( h16 ':' ) (h16 ':') (h16 ':') (h16 ':')) ls32)
            | (( h16 ( ':' h16 )? )? (':' ':') (( h16 ':' ) (h16 ':') (h16 ':')) ls32)
            | (( h16 (((( ':' h16 ) (':' h16)) | (':' h16)?)) )? (':' ':') (( h16 ':' ) (h16 ':')) ls32)
            | (( h16 (((( ':' h16 ) (':' h16) (':' h16)) | ((':' h16) (':' h16)) | (':' h16)?)) )? (':' ':')    h16 ':'   ls32)
            | (( h16 (((( ':' h16 ) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16)) | (':' h16)?)) )? (':' ':')              ls32)
            | (( h16 (((( ':' h16 ) (':' h16) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16)) | (':' h16)?)) )? (':' ':')              h16)
            | (( h16 (((( ':' h16 ) (':' h16) (':' h16) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16) (':' h16)) | ((':' h16) (':' h16)) | (':' h16)?)) )? (':' ':'));

h16 : (hexdig ((hexdig hexdig hexdig) | (hexdig hexdig) | hexdig?));

ls32 : (h16 ':' h16) | ipv4address;

ipv4address : dec_octet '.' dec_octet '.' dec_octet '.' dec_octet;

DEC_OCTET_CHAR_HIGH : [\u{0030}-\u{0035}];

DEC_OCTET_CHAR_MID : [\u{0030}-\u{0034}];

DEC_OCTET_CHAR_LOW : [\u{0031}-\u{0039}];

// NOTE: Backtrack when parsing these alternatives
dec_octet : (('2' '5') DEC_OCTET_CHAR_HIGH)       // 250-255
          | ('2' DEC_OCTET_CHAR_MID DIGIT)  // 200-249
          | ('1' (DIGIT DIGIT))         // 100-199
          | (DEC_OCTET_CHAR_LOW DIGIT)      // 10-99
          | DIGIT;              // 0-9

// Look in RFC3986 3.2.2 for
// "A registered name intended for lookup in the DNS"
domain : domainlabel ('.' domainlabel)* ( '.' )?;

domainlabel : ALPHANUM+ ('-'+ ALPHANUM+)*;

segment : pchar*;

pchar : unreserved | pct_encoded | SUB_DELIMS | ':' | '@';

query : ( pchar | '/' | '?' )*;

pct_encoded : '%' hexdig hexdig;

unreserved  : ALPHANUM | '-' | '.' | '_' | '~';

// this is the RFC3986 sub-delims rule, without "(", ")" or ","
// see comments above the `http-raw` rule above
SUB_DELIMS : '!' | '$' | '&' | '\'' | '*' | '+' | ';' | '=';

http : http_raw ( whsp using_1 whsp1 import_expression )?;

// Dhall supports unquoted environment variables that are Bash-compliant or
// quoted environment variables that are POSIX-compliant
env : (('E' | 'e') ('N' | 'n') ('V' | 'v') ':')
    ( bash_environment_variable
    | ('"' posix_environment_variable '"')
    );

// Bash supports a restricted subset of POSIX environment variables.  From the
// Bash `man` page, an environment variable name is:
//
// > A word consisting only of  ALPHANUMeric  characters  and  under-scores,  and
// > beginning with an alphabetic character or an under-score
bash_environment_variable : (ALPHA | '_') (ALPHANUM | '_')*;

// The POSIX standard is significantly more flexible about legal environment
// variable names, which can contain alerts (i.e. '\a'), whitespace, or
// punctuation, for example.  The POSIX standard says about environment variable
// names:
//
// > The value of an environment variable is a string of characters. For a
// > C-language program, an array of strings called the environment shall be made
// > available when a process begins. The array is pointed to by the external
// > variable environ, which is defined as:
// >
// >     extern char **environ;
// >
// > These strings have the form name=value; names shall not contain the
// > character '='. For values to be portable across systems conforming to IEEE
// > Std 1003.1-2001, the value shall be composed of characters from the portable
// > character set (except NUL and as indicated below).
//
// Note that the standard does not explicitly state that the name must have at
// least one character, but `env` does not appear to support this and `env`
// claims to be POSIX-compliant.  To be safe, Dhall requires at least one
// character like `env`
posix_environment_variable : POSIX_ENVIRONMENT_VARIABLE_CHARACTER+;

// These are all the characters from the POSIX Portable Character Set except for
// '\0' (NUL) and '='.  Note that the POSIX standard does not explicitly state
// that environment variable names cannot have NUL.  However, this is implicit
// in the fact that environment variables are passed to the program as
// NUL-terminated `name=value` strings, which implies that the `name` portion of
// the string cannot have NUL characters
POSIX_ENVIRONMENT_VARIABLE_CHARACTER :
      ('\\'                // '\'    Beginning of escape sequence
      ( '"'               // '"'    quotation mark  U+0022
      | '\\'               // '\'    reverse solidus U+005C
      | 'a'               // 'a'    alert           U+0007
      | 'b'               // 'b'    backspace       U+0008
      | 'f'               // 'f'    form feed       U+000C
      | 'n'               // 'n'    line feed       U+000A
      | 'r'               // 'r'    carriage return U+000D
      | 't'               // 't'    tab             U+0009
      | 'v'               // 'v'    vertical tab    U+000B
      ))
    // Printable characters except double quote, backslash and equals
    | [\u{0020}-\u{0021}]
        // %x22 = '"'
    | [\u{0023}-\u{003C}]
        // %x3D = '='
    | [\u{003E}-\u{005B}]
        // %x5C = "\"
    | [\u{005D}-\u{007E}];

import_type : missing | local | http | env;

hash : 's' 'h' 'a' '2' '5' '6' ':' (hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig); // "sha256:XXX...XXX"

import_hashed : import_type ( whsp1 hash )?;

// "http://example.com"
// "./foo/bar"
// "env:FOO"
import_1 : import_hashed ( whsp as_1 whsp1 (text | location) )?;

expression :
    // "\(x : a) -> b"
      (lambda whsp '(' whsp nonreserved_label whsp ':' whsp1 expression whsp ')' whsp arrow whsp expression)

    // "if a then b else c"
    | (if_1 whsp1 expression whsp then whsp1 expression whsp else_1 whsp1 expression)

    // "let x : t = e1 in e2"
    // "let x     = e1 in e2"
    // We allow dropping the `in` between adjacent let-expressions; the following are equivalent:
    // "let x = e1 let y = e2 in e3"
    // "let x = e1 in let y = e2 in e3"
    | (let_binding+ in_1 whsp1 expression)

    // "forall (x : a) -> b"
    | (forall whsp '(' whsp nonreserved_label whsp ':' whsp1 expression whsp ')' whsp arrow whsp expression)

    // "a -> b"
    //
    // NOTE: Backtrack if parsing this alternative fails
    | (operator_expression whsp arrow whsp expression)

    // "merge e1 e2 : t"
    //
    // NOTE: Backtrack if parsing this alternative fails since we can't tell
    // from the keyword whether there will be a type annotation or not
    | (merge whsp1 import_expression whsp1 import_expression whsp ':' whsp1 application_expression)

    // "[] : t"
    //
    // NOTE: Backtrack if parsing this alternative fails since we can't tell
    // from the opening bracket whether or not this will be an empty list or
    // a non-empty list
    | empty_list_literal

    // "toMap e : t"
    //
    // NOTE: Backtrack if parsing this alternative fails since we can't tell
    // from the keyword whether there will be a type annotation or not
    | (to_map whsp1 import_expression whsp ':' whsp1 application_expression)

    // "assert : Natural/even 1 === False"
    | (assert_1 whsp ':' whsp1 expression)

    // "x : t"
    | annotated_expression;

// Nonempty-whitespace to disambiguate `env:VARIABLE` from type annotations
annotated_expression : operator_expression ( whsp ':' whsp1 expression )?;

// "let x = e1"
let_binding : let whsp1 nonreserved_label whsp ( ':' whsp1 expression whsp )? '=' whsp expression whsp;

// "[] : t"
empty_list_literal :
    '[' whsp ( ',' whsp )? ']' whsp ':' whsp1 application_expression;

operator_expression : import_alt_expression;

// Nonempty-whitespace to disambiguate `http://a/a?a`
import_alt_expression    : or_expression            (whsp '?' whsp1 or_expression)*;
or_expression            : plus_expression          (whsp ('|' '|') whsp plus_expression)*;
// Nonempty-whitespace to disambiguate `f +2`
plus_expression          : text_append_expression   (whsp '+' whsp1 text_append_expression)*;
text_append_expression   : list_append_expression   (whsp ('+' '+') whsp list_append_expression)*;
list_append_expression   : and_expression           (whsp '#' whsp and_expression)*;
and_expression           : combine_expression       (whsp ('&' '&') whsp combine_expression)*;
combine_expression       : prefer_expression        (whsp combine whsp prefer_expression)*;
prefer_expression        : combine_types_expression (whsp prefer whsp combine_types_expression)*;
combine_types_expression : times_expression         (whsp combine_types whsp times_expression)*;
times_expression         : equal_expression         (whsp '*' whsp equal_expression)*;
equal_expression         : not_equal_expression     (whsp ('=' '=') whsp not_equal_expression)*;
not_equal_expression     : equivalent_expression    (whsp ('!' '=') whsp equivalent_expression)*;
equivalent_expression    : with_expression          (whsp equivalent whsp with_expression)*;

with_expression : application_expression (whsp1 with whsp1 with_clause)*;

with_clause :
    any_label_or_some (whsp '.' whsp any_label_or_some)* whsp '=' whsp application_expression;


// Import expressions need to be separated by some whitespace, otherwise there
// would be ambiguity: `./ab` could be interpreted as "import the file `./ab`",
// or "apply the import `./a` to label `b`"
application_expression :
    first_application_expression (whsp1 import_expression)*;

first_application_expression :
    // "merge e1 e2"
      (merge whsp1 import_expression whsp1 import_expression)

    // "Some e"
    | (some whsp1 import_expression)

    // "toMap e"
    | (to_map whsp1 import_expression)

    | import_expression;

import_expression : import_1 | completion_expression;

completion_expression :
    selector_expression ( whsp complete whsp selector_expression )?;

// `record.field` extracts one field of a record
//
// `record.{ field0, field1, field2 }` projects out several fields of a record
//
// NOTE: Backtrack when parsing the `*("." ...)`.  The reason why is that you
// can't tell from parsing just the period whether "foo." will become "foo.bar"
// (i.e. accessing field `bar` of the record `foo`) or `foo./bar` (i.e. applying
// the function `foo` to the relative path `./bar`)
selector_expression : primitive_expression (whsp '.' whsp selector)*;

selector : any_label | labels | type_selector;

labels : '{' whsp ( any_label_or_some whsp (',' whsp any_label_or_some whsp)* )? '}';

type_selector : '(' whsp expression whsp ')';
// NOTE: Backtrack when parsing the first three alternatives (i.e. the numeric
// literals).  This is because they share leading characters in common
primitive_expression :
    // "2.0"
      double_literal

    // "2"
    | natural_literal

    // "+2"
    | integer_literal

    // '"ABC"'
    | text_literal

    // "{ foo = 1      , bar = True }"
    // "{ foo : Integer, bar : Bool }"
    | ('{' whsp ( ',' whsp )? record_type_or_literal whsp '}')

    // "< Foo : Integer | Bar : Bool >"
    // "< Foo | Bar : Bool >"
    | ('<' whsp ( '|' whsp )? union_type whsp '>')

    // "[1, 2, 3]"
    | non_empty_list_literal

    // "x"
    // "x@2"
    | identifier

    // "( e )"
    | ('(' complete_expression ')');


record_type_or_literal :
      empty_record_literal
    | non_empty_record_type_or_literal
    | empty_record_type;

empty_record_literal : '=';
empty_record_type : ;

non_empty_record_type_or_literal :
    (non_empty_record_type | non_empty_record_literal);

non_empty_record_type :
    record_type_entry (whsp ',' whsp record_type_entry)*;

record_type_entry : any_label_or_some whsp ':' whsp1 expression;

non_empty_record_literal :
    record_literal_entry (whsp ',' whsp record_literal_entry)*;

record_literal_entry :
    any_label_or_some (record_literal_normal_entry | record_literal_punned_entry);

record_literal_normal_entry :
    (whsp '.' whsp any_label_or_some)* whsp '=' whsp expression;
record_literal_punned_entry : ;


union_type :
      non_empty_union_type
    | empty_union_type;

empty_union_type : ;

non_empty_union_type :
    union_type_entry (whsp '|' whsp union_type_entry)*;

// x : Natural
// x
union_type_entry : any_label_or_some ( whsp ':' whsp1 expression )?;


non_empty_list_literal :
    '[' whsp ( ',' whsp )? expression whsp (',' whsp expression whsp)* ']';

// This just adds surrounding whitespace for the top-level of the program
complete_expression : whsp expression whsp;
