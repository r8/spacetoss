{
*********************************************************************
CajScript
Created By Carlo Kok                   http://cajsoft.cjb.net/
Bugreport: cajscript@cajsoft.cjb.net
*********************************************************************
Copyright (C) 2000 by Carlo Kok (ck@cajsoft.cjb.net)
Copyright (C) 2002 by Sergey Storchay (r8@ukr.net)

This software is provided 'as-is', without any expressed or implied
warranty. In no event will the author be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any kind of
application, and to alter it and redistribute it freely, subject to
the following restrictions:
1. The origin of this software must not be misrepresented, you must
   not claim that you wrote the original software.
2. Altered source versions must be plainly marked as such, and must
   not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source
  distribution.
4. You must have a visible line in your programs aboutbox or
  documentation that it is made using CajScript.

Please register by joining the mailling list at http://cajsoft.cjb.net/.
} Unit CS2_UTL; {Cajscript 2.0 Utilities (Parser, Pascal:TList, TStringlist)}
{$B-}
{$IFDEF VER130}{D5}{$DEFINE DELPHI}{$DEFINE P32}{$ENDIF}
{$IFDEF VER120}{D4}{$DEFINE DELPHI}{$DEFINE P32}{$ENDIF}
{$IFDEF VER100}{D3}{$DEFINE DELPHI}{$DEFINE P32}{$ENDIF}
{$IFDEF VER90}{D2}{$DEFINE DELPHI}{$DEFINE P32}{$ENDIF}
{$IFDEF VER80}{D1}{$DEFINE DELPHI}{$DEFINE P16}{$ENDIF}
{$IFDEF VER125}{C4}{$DEFINE CBUILDER}{$DEFINE P32}{$ENDIF}
{$IFDEF VER110}{C3}{$DEFINE CBUILDER}{$DEFINE P32}{$ENDIF}
{$IFDEF VER93}{C1}{$DEFINE CBUILDER}{$DEFINE P32}{$ENDIF}
{$IFDEF VER70}{BP7}{$N+}{$DEFINE BP}{$DEFINE P16}{$ENDIF}
{$IFDEF FPC}{FPC}{$DEFINE FPC}{$DEFINE P32}{$ENDIF}
{$IFDEF DELPHI}{$DEFINE EXTUNIT}{$DEFINE CLASS}{$ENDIF}
{$IFDEF CBUILDER}{$DEFINE EXTUNIT}{$DEFINE CLASS}{$ENDIF}
{$IFDEF FPC}{DEFINE CLASS}{$ENDIF}
Interface

Type
  TCs2TokenId = (
  {Errors}
  CSTI_SyntaxError,
  CSTI_CommentEOFError,
  CSTI_CharError,
  CSTI_StringError,
  {Tokens}
  CSTI_EOF,
  CSTI_Whitespace,
  CSTI_Comment,
  CSTI_Identifier,
  CSTI_SemiColon,
  CSTI_Comma,
  CSTI_Period,
  CSTI_Colon,
  CSTI_OpenRound,
  CSTI_CloseRound,
  CSTI_OpenBlock,
  CSTI_CloseBlock,
  CSTI_Assignment,
  CSTI_Equal,
  CSTI_NotEqual,
  CSTI_Greater,
  CSTI_GreaterEqual,
  CSTI_Less,
  CSTI_LessEqual,
  CSTI_Plus,
  CSTI_Minus,
  CSTI_Divide,
  CSTI_Multiply,
  CSTI_Integer,
  CSTI_Real,
  CSTI_String,
  CSTI_Char,
  CSTI_HexInt,
  {Identifiers}
  CSTII_and,
  CSTII_array,
  CSTII_begin,
  CSTII_case,
  CSTII_const,
  CSTII_div,
  CSTII_do,
  CSTII_downto,
  CSTII_else,
  CSTII_end,
  CSTII_for,
  CSTII_function,
  CSTII_if,
  CSTII_in,
  CSTII_mod,
  CSTII_not,
  CSTII_of,
  CSTII_or,
  CSTII_procedure,
  CSTII_program,
  CSTII_repeat,
  CSTII_set,
  CSTII_shl,
  CSTII_shr,
  CSTII_string,
  CSTII_then,
  CSTII_to,
  CSTII_type,
  CSTII_until,
  CSTII_uses,
  CSTII_var,
  CSTII_while,
  CSTII_with,
  CSTII_xor
  );
  PCs2PascalParser = ^TCs2PascalParser;
  TCs2PascalParser = Record
                       CurrTokenId  : TCs2Tokenid;
                       CurrTokenLen : LongInt;
                       CurrTokenPos : LongInt;
                       Text         : PChar;
                     End;

Procedure NextNoJunk (data : PCs2PascalParser);
{Go to the next nojunk token}
Function GetToken (data : PCs2PascalParser): String;
{Return the token}
Procedure ParseToken (data : PCs2PascalParser);
{Parse at active position}

{$IFNDEF EXTUNIT}
Type
  PListItem = ^TListItem;
    TListItem = Record
                  Next : PListItem;
                  Ptr : Pointer;
                End;
  TList = Object
            Private
            FCount : LongInt;
            ListItem : PListItem;
            Public
            Function Count : LongInt;
            Function GetItem (Nr : LongInt) : Pointer;
            Procedure SetItem (Nr : LongInt; P : Pointer);
            Procedure Add (P : Pointer);
            Procedure Remove (P : Pointer);
            Procedure Clear;
            Constructor Create;
            Destructor Destroy;
          End;

  TStringList = Object
                  Private
                  List : TList;
                  Public
                  Function Count : LongInt;
                  Function GetItem (Nr : LongInt) : String;
                  Procedure SetItem (Nr : LongInt; Const s : String);
                  Procedure Add (Const P : String);
                  Procedure Delete (NR : LongInt);
                  Procedure Clear;
                  Constructor Create;
                  Destructor Destroy;
                End;
{$ENDIF}
Function FastUpperCase (Const s : String) : String;
{Fast uppercase}

Implementation
{$IFNDEF EXTUNIT}
Procedure TList. Add (P : Pointer);
Var MyListItem : PListItem;
Begin
  MyListItem := Listitem;
  If mylistitem = Nil Then Begin
    New (listitem);
    ListItem^. Ptr := P;
    listitem^. next := Nil;
    Inc (fcount);
    Exit;
  End;
  While mylistitem^. next <> Nil Do
    mylistitem := mylistitem^. Next;
  New (MyListitem^. next);
  MyListItem := MyListitem^. Next;
  MyListItem^. Ptr := P;
  Mylistitem^. next := Nil;
  Inc (fcount);
End;
Procedure TList. Remove (P : Pointer);
Var
  MyListItem : PListItem;
  u : PlistItem;
Begin
  MyListItem := ListItem;
  If mylistitem = Nil Then Exit;
  If mylistitem^. Ptr = p Then Begin
    u := MyListItem^. Next;
    Dispose (myListItem);
    listitem := u;
    Dec (Fcount);
    Exit;
  End;
  While MyListItem^. next <> Nil Do Begin
    If mylistitem^. next^. Ptr = p Then Begin
      u := MyListItem^. Next;
      mylistitem^. next := MyListitem^. Next^. next;
      Dispose (u);
      Dec (Fcount);
      exit;
    End;
    Mylistitem := MyListitem^. Next;
  End;
End;

Constructor TList. Create;
Begin
  ListItem := Nil;
  fCount := 0;
End;

Procedure TList. Clear;
Var
  Next : PListItem;
Begin
  While ListItem <> Nil Do Begin
    Next := listitem^. next;
    Dispose (Listitem);
    Listitem := Next;
  End;
End;

Destructor TList. Destroy;
Var
Next : PListItem;
Begin
  While ListItem <> Nil Do Begin
    Next := listitem^. next;
    Dispose (Listitem);
    Listitem := Next;
  End;
End;

Procedure TList. SetItem (Nr : LongInt; P : Pointer);
Var mylistitem : Plistitem;
Begin
  mylistitem := listItem;
  nr := Nr + 1;
  If nr < 1 Then Exit;
  If nr > count Then Exit;
  While nr > 1 Do Begin
    mylistitem := MyListitem^. next;
    Dec (nr);
  End;
  mylistitem^. Ptr := P;
End;

Function TList. GetItem (Nr : LongInt) : Pointer;
Var mylistitem : Plistitem;
Begin
  getitem := Nil;
  mylistitem := listItem;
  nr := Nr + 1;
  If nr < 1 Then Exit;
  If nr > count Then Exit;
  While nr > 1 Do Begin
    mylistitem := MyListitem^. next;
    Dec (nr);
  End;
  getitem := mylistitem^. Ptr;
End;
Function TList. Count : LongInt;
Begin
  count := Fcount;
End;


Function TStringList. Count : LongInt;
Begin
  count := List. count;
End;

Type TsmallStr = Record
                   Size : Byte;
                   Str : Array [1..255] Of Char;
                 End;

Function TStringList. GetItem (Nr : LongInt) : String;
Var S : ^TSMALLSTR;
  tel : Byte;
Begin
  getitem := '';
  s := List. GetItem (Nr);
  If s = Nil Then Exit;
  GetItem [0] := Chr (S^. Size);
  For tel := 1 To S^. Size Do
    GetItem [tel] := S^. Str [tel];
End;

Procedure TStringList. SetItem (Nr : LongInt; Const s : String);
Var
  p : ^TSMALLSTR;
  tel : LongInt;
Begin
  p := List. GetItem (Nr);
  If p = Nil Then Exit;
  FreeMem (p, p^. Size+1);
  GetMem (p, Length (s) + 1);
  p^. Size := Length (s);
  For tel := 1 To p^. Size Do
    p^. Str [tel] := s [tel];
  List. SetItem (Nr, p);
End;

Procedure TStringList. Add (Const P : String);
Var S : ^TSMALLSTR;
  tel : Byte;
Begin
  GetMem (S, 1 + Length (P) );
  s^. Size := Length (p);
  For tel := 1 To s^. Size Do
    s^. Str [tel] := p [tel];
  List. Add (S);
End;

Procedure TStringList. Delete (NR : LongInt);
Var P : ^TSMALLSTR;
Begin
  p := list. getitem (nr);
  list. Remove (P);
End;

Procedure TStringList. Clear;
Begin
  While List. Count > 0 Do Delete (0);
End;

Constructor TStringList. Create;
Begin
  List. Create;
End;
Destructor TStringList. Destroy;
Var tel : LongInt;
Begin
  For tel := 1 To list. count Do Begin
    Delete (tel - 1);
  End;
  List. Destroy;
End;
{$ENDIF}

Const chartab : Array [Char] Of Char = (
{Char tab is used for making a string in uppercase. This way is much faster}
  #0, #1, #2, #3, #4, #5, #6, #7, #8, #9, #10, #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
  #21, #22, #23, #24, #25, #26, #27, #28, #29, #30, #31, #32, #33, #34, #35, #36, #37, #38, #39,
  #40, #41, #42, #43, #44, #45, #46, #47, #48, #49, #50, #51, #52, #53, #54, #55, #56, #57, #58,
  #59, #60, #61, #62, #63, #64, #65, #66, #67, #68, #69, #70, #71, #72, #73, #74, #75, #76, #77,
  #78, #79, #80, #81, #82, #83, #84, #85, #86, #87, #88, #89, #90, #91, #92, #93, #94, #95, #96,
  #65, #66, #67, #68, #69, #70, #71, #72, #73, #74, #75, #76, #77, #78, #79, #80, #81, #82, #83,
  #84, #85, #86, #87, #88, #89, #90, #123, #124, #125, #126, #127, #128, #129, #130, #131,
  #132, #133, #134, #135, #136, #137, #138, #139, #140, #141, #142, #143, #144, #145, #146,
  #147, #148, #149, #150, #151, #152, #153, #154, #155, #156, #157, #158, #159, #160, #161,
  #162, #163, #164, #165, #166, #167, #168, #169, #170, #171, #172, #173, #174, #175, #176,
  #177, #178, #179, #180, #181, #182, #183, #184, #185, #186, #187, #188, #189, #190, #191,
  #192, #193, #194, #195, #196, #197, #198, #199, #200, #201, #202, #203, #204, #205, #206,
  #207, #208, #209, #210, #211, #212, #213, #214, #215, #216, #217, #218, #219, #220, #221,
  #222, #223, #224, #225, #226, #227, #228, #229, #230, #231, #232, #233, #234, #235, #236,
  #237, #238, #239, #240, #241, #242, #243, #244, #245, #246, #247, #248, #249, #250, #251,
  #252, #253, #254, #255);

Function FastUpperCase (Const s : String) : String;
{Fast uppercase}
Var
  i : Integer;
Begin
  FastUpperCase := s;
  For i := 1 To Length (s) Do FastUpperCase [i] := chartab [s [i] ]; {Fast uppercase}
End;

Function CheckIdent (data : PCs2PascalParser) : Boolean;
{Check if an identifier is a reserved word}
Var
  s : String;
Begin
  s := FastUppercase (GetToken (Data) );
  If s = 'AND' Then Data^. CurrTokenId := CSTII_and Else
    If s = 'ARRAY' Then Data^. CurrTokenId := CSTII_array Else
      If s = 'BEGIN' Then Data^. CurrTokenId := CSTII_begin Else
        If s = 'CASE' Then Data^. CurrTokenId := CSTII_case Else
          If s = 'CONST' Then Data^. CurrTokenId := CSTII_const Else
            If s = 'DIV' Then Data^. CurrTokenId := CSTII_div Else
              If s = 'DO' Then Data^. CurrTokenId := CSTII_do Else
                If s = 'DOWNTO' Then Data^. CurrTokenId := CSTII_downto Else
                  If s = 'ELSE' Then Data^. CurrTokenId := CSTII_else Else
                    If s = 'END' Then Data^. CurrTokenId := CSTII_end Else
                      If s = 'FOR' Then Data^. CurrTokenId := CSTII_for Else
                        If s = 'FUNCTION' Then Data^. CurrTokenId := CSTII_function Else
                          If s = 'IF' Then Data^. CurrTokenId := CSTII_if Else
                            If s = 'IN' Then Data^. CurrTokenId := CSTII_in Else
                              If s = 'MOD' Then Data^. CurrTokenId := CSTII_mod Else
                                If s = 'NOT' Then Data^. CurrTokenId := CSTII_not Else
                                  If s = 'OF' Then Data^. CurrTokenId := CSTII_of Else
                                    If s = 'OR' Then Data^. CurrTokenId := CSTII_or Else
                                      If s = 'PROCEDURE' Then Data^. CurrTokenId := CSTII_procedure Else
                                        If s = 'PROGRAM' Then Data^. CurrTokenId := CSTII_program Else
                                          If s = 'REPEAT' Then Data^. CurrTokenId := CSTII_repeat Else
                                            If s = 'SET' Then Data^. CurrTokenId := CSTII_set Else
                                              If s = 'SHL' Then Data^. CurrTokenId := CSTII_shl Else
                                                If s = 'SHR' Then Data^. CurrTokenId := CSTII_shr Else
                                                  If s = 'THEN' Then Data^. CurrTokenId := CSTII_then Else
                                                    If s = 'TO' Then Data^. CurrTokenId := CSTII_to Else
                                                      If s = 'TYPE' Then Data^. CurrTokenId := CSTII_type Else
                                                        If s = 'UNTIL' Then Data^. CurrTokenId := CSTII_until Else
                                                          If s = 'USES' Then Data^. CurrTokenId := CSTII_uses Else
                                                            If s = 'VAR' Then Data^. CurrTokenId := CSTII_var Else
                                                              If s = 'WHILE' Then Data^. CurrTokenId := CSTII_while Else
                                                                If s = 'WITH' Then Data^. CurrTokenId := CSTII_with Else
                                                                  If s = 'XOR' Then Data^. CurrTokenId := CSTII_xor Else Begin
                                                                    CheckIdent := False;
                                                                    Exit;
                                                                  End;
  CheckIdent := True;
End;
Procedure ParseToken (data : PCs2PascalParser);
{Parse the token}
Var
  ct, ci : LongInt;
  hs : Boolean;
Begin

  ct := data^. CurrTokenPos;
  Case data^. Text [ct] Of
    #0:
        Begin
          Data^. CurrTokenId := CSTI_EOF;
          Data^. CurrTokenLen := 0;
        End;
    'A'..'Z', 'a'..'z', '_':
                             Begin
                               ci := ct + 1;
                               While (data^. Text [ci] In ['_', '0'..'9', 'a'..'z', 'A'..'Z'] ) Do Begin
                                 Inc (ci);
                               End;
                               Data^. CurrTokenLen := ci - ct;
                               If Not CheckIdent (data) Then Begin
                                 Data^. CurrTokenId := CSTI_Identifier;
                               End;
                             End;
    '$':
         Begin
           ci := ct + 1;
           While (data^. Text [ci] In ['0'..'9', 'a'..'z', 'A'..'Z'] ) Do Begin
             Inc (ci);
           End;
           Data^. CurrTokenId := CSTI_HexInt;
           Data^. CurrTokenLen := ci - ct;
         End;

    '0'..'9':
              Begin
                hs := False;
                ci := ct + 1;
                While (data^. Text [ci] In ['0'..'9'] ) Do Begin
                  Inc (ci);
                  If (data^. Text [ci] = '.') And (Not hs) Then Begin
                    hs := True;
                    Inc (ci);
                  End;
                End;
                If hs Then
                  Data^. CurrTokenId := CSTI_Real
                Else
                  Data^. CurrTokenId := CSTI_Integer;
                Data^. CurrTokenLen := ci - ct;
              End;
    #39:
         Begin
           ci := ct + 1;
           While (data^. Text [ci] <> #0) And (data^. Text [ci] <> #13) And
                 (data^. Text [ci] <> #10) And (data^. Text [ci] <> #39)
           Do Begin
             Inc (ci);
           End;
           If data^. Text [ci] = #39 Then
             Data^. CurrTokenId := CSTI_String
           Else
             Data^. CurrTokenId := CSTI_StringError;
           Data^. CurrTokenLen := ci - ct + 1;
         End;
    '#':
         Begin
           ci := ct + 1;
           If data^. Text [ci] = '$' Then Begin
             While (data^. Text [ci] In ['A'..'Z', 'a'..'z', '0'..'9'] ) Do Begin
               Inc (ci);
             End;
             Data^. CurrTokenId := CSTI_Char;
             Data^. CurrTokenLen := ci - ct - 1;
           End Else Begin
             While (data^. Text [ci] In ['0'..'9'] ) Do Begin
               Inc (ci);
             End;
             If data^. Text [ci] In ['A'..'Z', 'a'..'z', '_'] Then
               Data^. CurrTokenId := CSTI_CharError
             Else
               Data^. CurrTokenId := CSTI_Char;
             Data^. CurrTokenLen := ci - ct;
           End;
         End;
    '=':
         Begin
           Data^. CurrTokenId := CSTI_Equal;
           Data^. CurrTokenLen := 1;
         End;
    '>':
         Begin
           If data^. Text [ct + 1] = '=' Then Begin
             Data^. CurrTokenid := CSTI_GreaterEqual;
             Data^. CurrTokenLen := 2;
           End Else Begin
             Data^. CurrTokenid := CSTI_Greater;
             Data^. CurrTokenLen := 1;
           End;
         End;
    '<':
         Begin
           If data^. Text [ct + 1] = '=' Then Begin
             Data^. CurrTokenId := CSTI_LessEqual;
             Data^. CurrTokenLen := 2;
           End Else If data^. Text [ct + 1] = '>' Then Begin
             Data^. CurrTokenId := CSTI_NotEqual;
             Data^. CurrTokenLen := 2;
           End Else Begin
             Data^. CurrTokenId := CSTI_Less;
             Data^. CurrTokenLen := 1;
           End;
         End;
    ')':
         Begin
           Data^. CurrTokenId := CSTI_CloseRound;
           Data^. CurrTokenLen := 1;
         End;
    '(':
         Begin
           If Data^. Text [ct + 1] = '*' Then Begin
             ci := ct + 1;
             While (Data^. Text [ci] <> #0) Do Begin
               If (Data^. Text [ci] = '*') And (Data^. Text [ci + 1] = ')') Then
                 Break;
               Inc (ci);
             End;
             If (Data^. Text [ci] = #0) Then
               Data^. CurrTokenId := CSTI_CommentEOFError
             Else Begin
               Data^. CurrTokenId := CSTI_Comment;
               Inc (ci);
             End;
             Data^. CurrTokenLen := ci - ct;
           End
           Else Begin
             Data^. CurrTokenId := CSTI_OpenRound;
             Data^. CurrTokenLen := 1;
           End;
         End;
    '[':
         Begin
           Data^. CurrTokenId := CSTI_OpenBlock;
           Data^. CurrTokenLen := 1;
         End;
    ']':
         Begin
           Data^. CurrTokenId := CSTI_CloseBlock;
           Data^. CurrTokenLen := 1;
         End;
    ',':
         Begin
           Data^. CurrTokenId := CSTI_Comma;
           Data^. CurrTokenLen := 1;
         End;
    '.':
         Begin
           Data^. CurrTokenId := CSTI_Period;
           Data^. CurrTokenLen := 1;
         End;
    ';':
         Begin
           Data^. CurrTokenId := CSTI_Semicolon;
           Data^. CurrTokenLen := 1;
         End;
    ':':
         Begin
           If Data^. Text [ct + 1] = '=' Then Begin
             Data^. CurrTokenId := CSTI_Assignment;
             Data^. CurrTokenLen := 2;
           End Else Begin
             Data^. CurrTokenId := CSTI_Colon;
             Data^. CurrTokenLen := 1;
           End;
         End;
    '+':
         Begin
           Data^. CurrTokenId := CSTI_Plus;
           Data^. CurrTokenLen := 1;
         End;
    '-':
         Begin
           Data^. CurrTokenId := CSTI_Minus;
           Data^. CurrTokenLen := 1;
         End;
    '*':
         Begin
           Data^. CurrTokenId := CSTI_Multiply;
           Data^. CurrTokenLen := 1;
         End;
    '/':
         Begin
           If data^. Text [ct + 1] = '/' Then Begin
             ci := ct + 1;
             While (Data^. Text [ci] <> #0) And (Data^. Text [ci] <> #13) And (Data^. Text [ci] <> #10) Do Begin
               Inc (ci);
             End;
             If (Data^. Text [ci] = #0) Then
               Data^. CurrTokenId := CSTI_CommentEOFError
             Else
               Data^. CurrTokenId := CSTI_Comment;
             Data^. CurrTokenLen := ci - ct;
           End Else Begin
             Data^. CurrTokenId := CSTI_Divide;
             Data^. CurrTokenLen := 1;
           End;
         End;
    #32, #9, #13, #10:
                       Begin
                         ci := ct + 1;
                         While (Data^. Text [ci] In [#32, #9, #13, #10] ) Do Begin
                           Inc (ci);
                         End;
                         Data^. CurrTokenId := CSTI_Whitespace;
                         Data^. CurrTokenLen := ci - ct;
                       End;
    '{':
         Begin
           ci := ct + 1;
           While (Data^. Text [ci] <> #0) And (Data^. Text [ci] <> '}') Do Begin
             Inc (ci);
           End;
           If (Data^. Text [ci] = #0) Then
             Data^. CurrTokenId := CSTI_CommentEOFError
           Else
             Data^. CurrTokenId := CSTI_Comment;
           Data^. CurrTokenLen := ci - ct+1;
         End;
    Else
      Data^. CurrTokenId := CSTI_SyntaxError;
    Data^. CurrTokenLen := 1;
  End;
End;

Function GetToken (data : PCs2PascalParser): String;
{Return the token}
Var
  i : LongInt;
  len : LongInt;
  s : String;
Begin
  len := data^. CurrTokenLen;
  {$IFDEF P32}
  setlength (s, len);
  {$ELSE}
  len := len And $FF;
  s [0] := Chr (len);
  {$ENDIF}
  For i := 1 To Len Do Begin
    s [i] := data^. Text [data^. CurrTokenPos + i - 1];
  End;
  GetToken := s;
End;

Procedure NextNoJunk (data : PCs2PascalParser);
{Next no junk}
Begin
  Data^. CurrTokenPos := Data^. CurrTokenPos + Data^. CurrTokenLen;
  ParseToken (data);
  While (Data^. CurrTokenId = CSTI_COMMENT) Or (Data^. CurrTokenId = CSTI_WHITESPACE) Do Begin
    If (Data^. CurrTokenId = CSTI_EOF) Or (Data^. CurrTokenId = CSTI_SyntaxError) Or
       (Data^. CurrTokenId = CSTI_CommentEOFError) Or (Data^. CurrTokenId = CSTI_CharError) Or
       (Data^. CurrTokenId = CSTI_StringError)
    Then Begin
      Break;
    End;
    Data^. CurrTokenPos := Data^. CurrTokenPos + Data^. CurrTokenLen;
    ParseToken (data);
  End;
End;

End.
