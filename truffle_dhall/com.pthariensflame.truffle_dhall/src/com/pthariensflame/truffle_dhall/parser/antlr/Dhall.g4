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
      '\u000A'     // "\n"
    | ('\u000D' '\u000A');  // "\r\n"

// This rule matches all characters that are not:
//
// * not ASCII
// * not part of a surrogate pair
// * not a "non-character"
VALID_NON_ASCII :
      '\u0080'..'\uD7FF'
    // %xD800-DFFF = surrogate pairs
    | '\uE000'..'\uFFFD'
    // %xFFFE-FFFF = non-characters
    | '\u10000'..'\u1FFFD'
    // %x1FFFE-1FFFF = non-characters
    | '\u20000'..'\u2FFFD'
    // %x2FFFE-2FFFF = non-characters
    | '\u30000'..'\u3FFFD'
    // %x3FFFE-3FFFF = non-characters
    | '\u40000'..'\u4FFFD'
    // %x4FFFE-4FFFF = non-characters
    | '\u50000'..'\u5FFFD'
    // %x5FFFE-5FFFF = non-characters
    | '\u60000'..'\u6FFFD'
    // %x6FFFE-6FFFF = non-characters
    | '\u70000'..'\u7FFFD'
    // %x7FFFE-7FFFF = non-characters
    | '\u80000'..'\u8FFFD'
    // %x8FFFE-8FFFF = non-characters
    | '\u90000'..'\u9FFFD'
    // %x9FFFE-9FFFF = non-characters
    | '\uA0000'..'\uAFFFD'
    // %xAFFFE-AFFFF = non-characters
    | '\uB0000'..'\uBFFFD'
    // %xBFFFE-BFFFF = non-characters
    | '\uC0000'..'\uCFFFD'
    // %xCFFFE-CFFFF = non-characters
    | '\uD0000'..'\uDFFFD'
    // %xDFFFE-DFFFF = non-characters
    | '\uE0000'..'\uEFFFD'
    // %xEFFFE-EFFFF = non-characters
    | '\uF0000'..'\uFFFFD'
    // %xFFFFE-FFFFF = non-characters
    | '\u100000'..'\u10FFFD';
    // %x10FFFE-10FFFF = non-characters

TAB : '\u0009';  // "\t"

block_comment : ('{' '-') block_comment_continue;

block_comment_char :
      '\u0020'..'\u007F'
    | VALID_NON_ASCII
    | TAB
    | END_OF_LINE;

block_comment_continue :
    ('-' '}')
    | (block_comment block_comment_continue)
    | (block_comment_char block_comment_continue);

not_end_of_line : '\u0020'..'\u007F' | VALID_NON_ASCII | TAB;

// NOTE: Slightly different from Haskell-style single-line comments because this
// does not require a space after the dashes
line_comment : ('-' '-') not_end_of_line* END_OF_LINE;

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
ALPHA : '\u0041'..'\u005A' | '\u0061'..'\u007A';

// ASCII digit
DIGIT : '\u0030'..'\u0039';  // 0-9

alphanum : ALPHA | DIGIT;

hexdig : DIGIT | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd') | ('E' | 'e') | ('F' | 'f');

// A simple label cannot be one of the reserved keywords
// listed in the `keyword` rule.
// A PEG parser could use negative lookahead to
// enforce this, e.g. as follows:
// simple-label =
//       keyword 1*simple-label-next-char
//     / !keyword (simple-label-first-char *simple-label-next-char)
simple_label_first_char : ALPHA | '_';
simple_label_next_char : alphanum | '-' | '/' | '_';
simple_label : simple_label_first_char simple_label_next_char*;

QUOTED_LABEL_CHAR :
      '\u0020'..'\u005F'
        // %x60 = '`'
    | '\u0061'..'\u007E';

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
any_label_or_some : any_label | SOME;

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
    | ('\u005C' double_quote_escaped)
    | double_quote_char;

double_quote_escaped :
      '\u0022'                 // '"'    quotation mark  U+0022
    | '\u0024'                 // '$'    dollar sign     U+0024
    | '\u005C'                 // '\'    reverse solidus U+005C
    | '\u002F'                 // '/'    solidus         U+002F
    | '\u0062'                 // 'b'    backspace       U+0008
    | '\u0066'                 // 'f'    form feed       U+000C
    | '\u006E'                 // 'n'    line feed       U+000A
    | '\u0072'                 // 'r'    carriage return U+000D
    | '\u0074'                 // 't'    tab             U+0009
    | ('\u0075' unicode_escape);  // 'uXXXX' / 'u{XXXX}'    U+XXXX

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
// See the `valid-non-ascii` rule for the exact ranges that are not allowed
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
// See the `valid-non-ascii` rule for the exact ranges that are not allowed
braced_codepoint :
      (('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | ('A' | 'a') | ('B' | 'b') | ('C' | 'c') | ('D' | 'd') | ('E' | 'e') | ('F' | 'f') | ('1' '0')) unicode_suffix)// (Planes 1-16)
    | unbraced_escape // (Plane 0)
    | (hexdig ((hexdig hexdig) | hexdig?)); // %x000-FFF

// Allow zero padding for braced codepoints
braced_escape : '0'* braced_codepoint;

// Printable characters except double quote and backslash
double_quote_char :
      '\u0020'..'\u0021'
        // %x22 = '"'
    | '\u0023'..'\u005B'
        // %x5C = "\"
    | '\u005D'..'\u007F'
    | VALID_NON_ASCII;

double_quote_literal : '\u0022' double_quote_chunk* '\u0022';

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
    | (single_quote_char single_quote_continue);

// Escape two single quotes (i.e. replace this sequence with "''")
ESCAPED_QUOTE_PAIR : ('\'' '\'' '\'');

// Escape interpolation (i.e. replace this sequence with "${")
ESCAPED_INTERPOLATION : ('\'' '\'' '$' '{');

single_quote_char :
      '\u0020'..'\u007F'
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
IF_1                    : ('\u0069' '\u0066');
THEN                  : ('\u0074' '\u0068' '\u0065' '\u006E');
ELSE_1                  : ('\u0065' '\u006C' '\u0073' '\u0065');
LET                   : ('\u006C' '\u0065' '\u0074');
IN_1                    : ('\u0069' '\u006E');
AS_1                    : ('\u0061' '\u0073');
USING_1                 : ('\u0075' '\u0073' '\u0069' '\u006E' '\u0067');
MERGE                 : ('\u006D' '\u0065' '\u0072' '\u0067' '\u0065');
MISSING               : ('\u006D' '\u0069' '\u0073' '\u0073' '\u0069' '\u006E' '\u0067');
INFINITY              : ('\u0049' '\u006E' '\u0066' '\u0069' '\u006E' '\u0069' '\u0074' '\u0079');
NAN                   : ('\u004E' '\u0061' '\u004E');
SOME                  : ('\u0053' '\u006F' '\u006D' '\u0065');
TOMAP                 : ('\u0074' '\u006F' '\u004D' '\u0061' '\u0070');
ASSERT_1                : ('\u0061' '\u0073' '\u0073' '\u0065' '\u0072' '\u0074');
FORALL                : '\u2200' | ('\u0066' '\u006F' '\u0072' '\u0061' '\u006C' '\u006C');
WITH                  : ('\u0077' '\u0069' '\u0074' '\u0068');

// Unused rule that could be used as negative lookahead in the
// `simple-label` rule for parsers that support this.
keyword :
      IF_1 | THEN | ELSE_1
    | LET | IN_1
    | USING_1 | MISSING
    | ASSERT_1 | AS_1
    | INFINITY | NAN
    | MERGE | SOME | TOMAP
    | FORALL
    | WITH;

builtin :
      NATURAL_FOLD
    | NATURAL_BUILD
    | NATURAL_ISZERO
    | NATURAL_EVEN
    | NATURAL_ODD
    | NATURAL_TOINTEGER
    | NATURAL_SHOW
    | INTEGER_TODOUBLE
    | INTEGER_SHOW
    | INTEGER_NEGATE
    | INTEGER_CLAMP
    | NATURAL_SUBTRACT
    | DOUBLE_SHOW
    | LIST_BUILD
    | LIST_FOLD
    | LIST_LENGTH
    | LIST_HEAD
    | LIST_LAST
    | LIST_INDEXED
    | LIST_REVERSE
    | OPTIONAL_FOLD
    | OPTIONAL_BUILD
    | TEXT_SHOW
    | BOOL_1
    | TRUE_1
    | FALSE_1
    | OPTIONAL
    | NONE
    | NATURAL
    | INTEGER
    | DOUBLE_1
    | TEXT
    | LIST
    | TYPE
    | KIND
    | SORT;

// Reserved identifiers, needed for some special cases of parsing
OPTIONAL              : ('\u004F' '\u0070' '\u0074' '\u0069' '\u006F' '\u006E' '\u0061' '\u006C');
TEXT                  : ('\u0054' '\u0065' '\u0078' '\u0074');
LIST                  : ('\u004C' '\u0069' '\u0073' '\u0074');
LOCATION              : ('\u004C' '\u006F' '\u0063' '\u0061' '\u0074' '\u0069' '\u006F' '\u006E');

// Reminder of the reserved identifiers, needed for the `builtin` rule
BOOL_1              : ('\u0042' '\u006F' '\u006F' '\u006C');
TRUE_1              : ('\u0054' '\u0072' '\u0075' '\u0065');
FALSE_1             : ('\u0046' '\u0061' '\u006C' '\u0073' '\u0065');
NONE              : ('\u004E' '\u006F' '\u006E' '\u0065');
NATURAL           : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C');
INTEGER           : ('\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072');
DOUBLE_1            : ('\u0044' '\u006F' '\u0075' '\u0062' '\u006C' '\u0065');
TYPE              : ('\u0054' '\u0079' '\u0070' '\u0065');
KIND              : ('\u004B' '\u0069' '\u006E' '\u0064');
SORT              : ('\u0053' '\u006F' '\u0072' '\u0074');
NATURAL_FOLD      : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0066' '\u006F' '\u006C' '\u0064');
NATURAL_BUILD     : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0062' '\u0075' '\u0069' '\u006C' '\u0064');
NATURAL_ISZERO    : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0069' '\u0073' '\u005A' '\u0065' '\u0072' '\u006F');
NATURAL_EVEN      : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0065' '\u0076' '\u0065' '\u006E');
NATURAL_ODD       : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u006F' '\u0064' '\u0064');
NATURAL_TOINTEGER : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0074' '\u006F' '\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072');
NATURAL_SHOW      : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0073' '\u0068' '\u006F' '\u0077');
NATURAL_SUBTRACT  : ('\u004E' '\u0061' '\u0074' '\u0075' '\u0072' '\u0061' '\u006C' '\u002F' '\u0073' '\u0075' '\u0062' '\u0074' '\u0072' '\u0061' '\u0063' '\u0074');
INTEGER_TODOUBLE  : ('\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072' '\u002F' '\u0074' '\u006F' '\u0044' '\u006F' '\u0075' '\u0062' '\u006C' '\u0065');
INTEGER_SHOW      : ('\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072' '\u002F' '\u0073' '\u0068' '\u006F' '\u0077');
INTEGER_NEGATE    : ('\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072' '\u002F' '\u006E' '\u0065' '\u0067' '\u0061' '\u0074' '\u0065');
INTEGER_CLAMP     : ('\u0049' '\u006E' '\u0074' '\u0065' '\u0067' '\u0065' '\u0072' '\u002F' '\u0063' '\u006C' '\u0061' '\u006D' '\u0070');
DOUBLE_SHOW       : ('\u0044' '\u006F' '\u0075' '\u0062' '\u006C' '\u0065' '\u002F' '\u0073' '\u0068' '\u006F' '\u0077');
LIST_BUILD        : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u0062' '\u0075' '\u0069' '\u006C' '\u0064');
LIST_FOLD         : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u0066' '\u006F' '\u006C' '\u0064');
LIST_LENGTH       : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u006C' '\u0065' '\u006E' '\u0067' '\u0074' '\u0068');
LIST_HEAD         : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u0068' '\u0065' '\u0061' '\u0064');
LIST_LAST         : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u006C' '\u0061' '\u0073' '\u0074');
LIST_INDEXED      : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u0069' '\u006E' '\u0064' '\u0065' '\u0078' '\u0065' '\u0064');
LIST_REVERSE      : ('\u004C' '\u0069' '\u0073' '\u0074' '\u002F' '\u0072' '\u0065' '\u0076' '\u0065' '\u0072' '\u0073' '\u0065');
OPTIONAL_FOLD     : ('\u004F' '\u0070' '\u0074' '\u0069' '\u006F' '\u006E' '\u0061' '\u006C' '\u002F' '\u0066' '\u006F' '\u006C' '\u0064');
OPTIONAL_BUILD    : ('\u004F' '\u0070' '\u0074' '\u0069' '\u006F' '\u006E' '\u0061' '\u006C' '\u002F' '\u0062' '\u0075' '\u0069' '\u006C' '\u0064');
TEXT_SHOW         : ('\u0054' '\u0065' '\u0078' '\u0074' '\u002F' '\u0073' '\u0068' '\u006F' '\u0077');

// Operators
COMBINE       : '\u2227' | ('/' '\\');
COMBINE_TYPES : '\u2A53' | ('/' '/' '\\' '\\');
EQUIVALENT    : '\u2261' | ('=' '=' '=');
PREFER        : '\u2AFD' | ('/' '/');
LAMBDA        : '\u03BB'  | '\\';
ARROW         : '\u2192' | ('-' '>');
COMPLETE      : (':' ':');

exponent : ('E' | 'e') ( '+' | '-' )? DIGIT+;

numeric_double_literal : ( '+' | '-' )? DIGIT+ ( ('.' DIGIT+ ( exponent )?) | exponent);

minus_infinity_literal : '-' INFINITY;
plus_infinity_literal : INFINITY;

double_literal :
    // "2.0"
      numeric_double_literal
    // "-Infinity"
    | minus_infinity_literal
    // "Infinity"
    | plus_infinity_literal
    // "NaN"
    | NAN;

natural_literal :
    // Hexadecimal with "0x" prefix
      ('0' '\u0078' hexdig+)
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
      '\u0021'
        // %x22 = "\""
        // %x23 = "#"
    | '\u0024'..'\u0027'
        // %x28 = "("
        // %x29 = ")"
    | '\u002A'..'\u002B'
        // %x2C = ","
    | '\u002D'..'\u002E'
        // %x2F = "/"
    | '\u0030'..'\u003B'
        // %x3C = "<"
    | '\u003D'
        // %x3E = ">"
        // %x3F = "?"
    | '\u0040'..'\u005A'
        // %x5B = "["
        // %x5C = "\"
        // %x5D = "]"
    | '\u005E'..'\u007A'
        // %x7B = "{"
    | '\u007C'
        // %x7D = "}"
    | '\u007E';

quoted_path_character :
      '\u0020'..'\u0021'
        // %x22 = "\""
    | '\u0023'..'\u002E'
        // %x2F = "/"
    | '\u0030'..'\u007F'
    | VALID_NON_ASCII;

unquoted_path_component : PATH_CHARACTER+;
quoted_path_component : quoted_path_character+;

path_component : '/' ( unquoted_path_component | ('\u0022' quoted_path_component '\u0022') );

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

SCHEME : ('\u0068' '\u0074' '\u0074' '\u0070' )( '\u0073' )?;  // "http" [ "s" ]

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

// NOTE: Backtrack when parsing these alternatives
dec_octet : (('2' '5') '\u0030'..'\u0035')       // 250-255
          | ('2' '\u0030'..'\u0034' DIGIT)  // 200-249
          | ('1' (DIGIT DIGIT))         // 100-199
          | ('\u0031'..'\u0039' DIGIT)      // 10-99
          | DIGIT;              // 0-9

// Look in RFC3986 3.2.2 for
// "A registered name intended for lookup in the DNS"
domain : domainlabel ('.' domainlabel)* ( '.' )?;

domainlabel : alphanum+ ('-'+ alphanum+)*;

segment : pchar*;

pchar : unreserved | pct_encoded | SUB_DELIMS | ':' | '@';

query : ( pchar | '/' | '?' )*;

pct_encoded : '%' hexdig hexdig;

unreserved  : alphanum | '-' | '.' | '_' | '~';

// this is the RFC3986 sub-delims rule, without "(", ")" or ","
// see comments above the `http-raw` rule above
SUB_DELIMS : '!' | '$' | '&' | '\'' | '*' | '+' | ';' | '=';

http : http_raw ( whsp USING_1 whsp1 import_expression )?;

// Dhall supports unquoted environment variables that are Bash-compliant or
// quoted environment variables that are POSIX-compliant
env : (('E' | 'e') ('N' | 'n') ('V' | 'v') ':')
    ( bash_environment_variable
    | ('\u0022' posix_environment_variable '\u0022')
    );

// Bash supports a restricted subset of POSIX environment variables.  From the
// Bash `man` page, an environment variable name is:
//
// > A word consisting only of  alphanumeric  characters  and  under-scores,  and
// > beginning with an alphabetic character or an under-score
bash_environment_variable : (ALPHA | '_') (alphanum | '_')*;

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
      ('\u005C'                 // '\'    Beginning of escape sequence
      ( '\u0022'               // '"'    quotation mark  U+0022
      | '\u005C'               // '\'    reverse solidus U+005C
      | '\u0061'               // 'a'    alert           U+0007
      | '\u0062'               // 'b'    backspace       U+0008
      | '\u0066'               // 'f'    form feed       U+000C
      | '\u006E'               // 'n'    line feed       U+000A
      | '\u0072'               // 'r'    carriage return U+000D
      | '\u0074'               // 't'    tab             U+0009
      | '\u0076'               // 'v'    vertical tab    U+000B
      ))
    // Printable characters except double quote, backslash and equals
    | '\u0020'..'\u0021'
        // %x22 = '"'
    | '\u0023'..'\u003C'
        // %x3D = '='
    | '\u003E'..'\u005B'
        // %x5C = "\"
    | '\u005D'..'\u007E';

import_type : MISSING | local | http | env;

hash : ('\u0073' '\u0068' '\u0061' '\u0032' '\u0035' '\u0036' '\u003A' )(hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig hexdig); // "sha256:XXX...XXX"

import_hashed : import_type ( whsp1 hash )?;

// "http://example.com"
// "./foo/bar"
// "env:FOO"
import_1 : import_hashed ( whsp AS_1 whsp1 (TEXT | LOCATION) )?;

expression :
    // "\(x : a) -> b"
      (LAMBDA whsp '(' whsp nonreserved_label whsp ':' whsp1 expression whsp ')' whsp ARROW whsp expression)

    // "if a then b else c"
    | (IF_1 whsp1 expression whsp THEN whsp1 expression whsp ELSE_1 whsp1 expression)

    // "let x : t = e1 in e2"
    // "let x     = e1 in e2"
    // We allow dropping the `in` between adjacent let-expressions; the following are equivalent:
    // "let x = e1 let y = e2 in e3"
    // "let x = e1 in let y = e2 in e3"
    | (let_binding+ IN_1 whsp1 expression)

    // "forall (x : a) -> b"
    | (FORALL whsp '(' whsp nonreserved_label whsp ':' whsp1 expression whsp ')' whsp ARROW whsp expression)

    // "a -> b"
    //
    // NOTE: Backtrack if parsing this alternative fails
    | (operator_expression whsp ARROW whsp expression)

    // "merge e1 e2 : t"
    //
    // NOTE: Backtrack if parsing this alternative fails since we can't tell
    // from the keyword whether there will be a type annotation or not
    | (MERGE whsp1 import_expression whsp1 import_expression whsp ':' whsp1 application_expression)

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
    | (TOMAP whsp1 import_expression whsp ':' whsp1 application_expression)

    // "assert : Natural/even 1 === False"
    | (ASSERT_1 whsp ':' whsp1 expression)

    // "x : t"
    | annotated_expression;

// Nonempty-whitespace to disambiguate `env:VARIABLE` from type annotations
annotated_expression : operator_expression ( whsp ':' whsp1 expression )?;

// "let x = e1"
let_binding : LET whsp1 nonreserved_label whsp ( ':' whsp1 expression whsp )? '=' whsp expression whsp;

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
combine_expression       : prefer_expression        (whsp COMBINE whsp prefer_expression)*;
prefer_expression        : combine_types_expression (whsp PREFER whsp combine_types_expression)*;
combine_types_expression : times_expression         (whsp COMBINE_TYPES whsp times_expression)*;
times_expression         : equal_expression         (whsp '*' whsp equal_expression)*;
equal_expression         : not_equal_expression     (whsp ('=' '=') whsp not_equal_expression)*;
not_equal_expression     : equivalent_expression    (whsp ('!' '=') whsp equivalent_expression)*;
equivalent_expression    : with_expression          (whsp EQUIVALENT whsp with_expression)*;

with_expression : application_expression (whsp1 WITH whsp1 with_clause)*;

with_clause :
    any_label_or_some (whsp '.' whsp any_label_or_some)* whsp '=' whsp application_expression;


// Import expressions need to be separated by some whitespace, otherwise there
// would be ambiguity: `./ab` could be interpreted as "import the file `./ab`",
// or "apply the import `./a` to label `b`"
application_expression :
    first_application_expression (whsp1 import_expression)*;

first_application_expression :
    // "merge e1 e2"
      (MERGE whsp1 import_expression whsp1 import_expression)

    // "Some e"
    | (SOME whsp1 import_expression)

    // "toMap e"
    | (TOMAP whsp1 import_expression)

    | import_expression;

import_expression : import_1 | completion_expression;

completion_expression :
    selector_expression ( whsp COMPLETE whsp selector_expression )?;

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
      EMPTY_RECORD_LITERAL
    | non_empty_record_type_or_literal
    | EMPTY_RECORD_TYPE;

EMPTY_RECORD_LITERAL : '=';
EMPTY_RECORD_TYPE : ;

non_empty_record_type_or_literal :
    (non_empty_record_type | non_empty_record_literal);

non_empty_record_type :
    record_type_entry (whsp ',' whsp record_type_entry)*;

record_type_entry : any_label_or_some whsp ':' whsp1 expression;

non_empty_record_literal :
    record_literal_entry (whsp ',' whsp record_literal_entry)*;

record_literal_entry :
    any_label_or_some (record_literal_normal_entry | RECORD_LITERAL_PUNNED_ENTRY);

record_literal_normal_entry :
    (whsp '.' whsp any_label_or_some)* whsp '=' whsp expression;
RECORD_LITERAL_PUNNED_ENTRY : ;


union_type :
      non_empty_union_type
    | EMPTY_UNION_TYPE;

EMPTY_UNION_TYPE : ;

non_empty_union_type :
    union_type_entry (whsp '|' whsp union_type_entry)*;

// x : Natural
// x
union_type_entry : any_label_or_some ( whsp ':' whsp1 expression )?;


non_empty_list_literal :
    '[' whsp ( ',' whsp )? expression whsp (',' whsp expression whsp)* ']';

// This just adds surrounding whitespace for the top-level of the program
complete_expression : whsp expression whsp;
