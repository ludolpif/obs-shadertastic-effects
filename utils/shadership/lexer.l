WS        [ \t\v\f]
NL        \n|\r\n

%x mlcomment string

%%
"//".*          { return Tokens::COMMENT; }
"/*"            {
                    more();
                    begin(StartCondition_::mlcomment);
                }
<mlcomment>{
    "*/"        {
                    begin(StartCondition_::INITIAL);
                    return Tokens::COMMENT;
                }
    {NL}|.      more();
}

\"              {
                    more();
                    begin(StartCondition_::string);
                }

<string>{
    \"          {
                    begin(StartCondition_::INITIAL);
                    return Tokens::STRING;
                }
    \\.|.       more();
}

[A-Za-z_][A-Za-z0-9_]*  { return Tokens::IDENTIFIER; }

#include        { return Tokens::PP_INCLUDE; }
#define         { return Tokens::PP_DEFINE; }
#undef          { return Tokens::PP_UNDEF; }
#ifdef          { return Tokens::PP_IFDEF; }
#ifndef         { return Tokens::PP_IFNDEF; }
#endif          { return Tokens::PP_ENDIF; }
#[a-z]+         { return Tokens::PP_OTHER; }

{WS}+           { return Tokens::WS; }
{NL}+           { return Tokens::NL; }
.               { return Tokens::CHAR; }
