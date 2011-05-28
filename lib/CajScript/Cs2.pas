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


Cajscript 2 PascalScript
version: 2.06

Parts ready:
 - Calculation
 - Assignments (a:=b;)
 - External Procedure/Function calls
 - Sub Begins
 - If Then Else
 - Internal Procedure/Functions
 - Variable parameters for internal and extenal functions.
 - Internal Procedure calls from outside the script.
 - Documentation and examples
 - For/To/Downto/Do
 - Cajsoft STDLib
 - While/Begin/End

To do (in this order):
 - Case x Of/End
 - Repeat/Until
}
Unit CS2; {CajScript 2.0}
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
Interface
Uses
  {$IFDEF EXTUNIT} Sysutils, Classes, {$ENDIF} CS2_VAR, CS2_UTL, strings, r8str;

Type
  {$IFDEF CLASS}
  TCs2PascalScript = Class;
  PCs2PascalScript = TCs2PascalScript;
  {$ELSE}
  PCs2PascalScript = ^TCs2PascalScript;
  {$ENDIF}
  TOnUses = Function (Id : Pointer; Sender : PCs2PascalScript; Name : String) : TCs2Error;
  TCs2PascalScript = {$IFDEF CLASS} Class{$ELSE} Object{$ENDIF}
                                       Private
                                       FUses : TStringList;
                                       InternalProcedures : PProcedureManager;

                                       Text : PChar;
                                       MainOffset : LongInt;
                                       FId : Pointer;
                                       Parser : PCs2PascalParser;
                                       FErrorPos : LongInt;
                                       FErrorCode : TCs2Error;
                                       {$IFDEF CLASS}
                                       FOnUses : TOnUses;
                                       {$ENDIF}
                                       Function IdentifierExists (SubVars : PVariableManager; Const S : String) : Boolean;
                                       Function ProcessVars (Vars : PVariableManager) : Boolean;
                                       Procedure RunError (C : TCs2Error);
                                       Function RunBegin (Vars : PVariableManager; Skip : Boolean) : Boolean;
                                       Function Calc (Vars : PVariableManager; res : PCajVariant;
                                       StopOn : TCs2TokenId) : Boolean;
                                       Function DoProc (Vars : PVariableManager; Internal : Boolean): PCajVariant;
                                       Public
                                       Variables : PVariableManager;
                                       Procedures : PProcedureManager;
                                       {$IFDEF CLASS}
                                       Property OnUses : TOnUses Read FOnUses Write FOnUses;
                                       Property ErrorCode : TCs2Error Read FErrorCode;
                                       Property ErrorPos : LongInt Read FErrorPos;
                                       {$ELSE}
                                       OnUses : TOnUses;
                                       Function ErrorCode : TCs2Error;
                                       Function ErrorPos : LongInt;
                                       {$ENDIF}
                                       Procedure RunScript;
                                       Function RunScriptProc (Const Name : String;
                                       Parameters : PVariableManager): PCajVariant;

                                       Procedure SetText (p : Pchar);
                                       Constructor Create (Id : Pointer);
                                       Destructor Destroy;{$IFDEF CLASS}override;{$ENDIF}
                                     End;

Procedure RegisterStdLib (P:  PCs2PascalScript);
{Register all standard functions:
{
Install:
  Function StrGet(S : String; I : Integer) : Char;
  Function StrSet(c : Char; I : Integer; var s : String) : Char;
  Function Ord(C : Char) : Byte;
  Function Chr(B : Byte) : Char;
  Function StrToInt(s : string;def : Longint) : Longint;
  Function IntToStr(i : Longint) : String;
  Function Uppercase(s : string) : string;
  Function Copy(S : String; Indx, Count : Integer) : String;
  Procedure Delete(var S : String; Indx, Count : Integer);
  Function Pos(SubStr, S : String) : Integer;
  Procedure Insert(Source : String; var Dest : String; Indx : Integer);
}

Implementation


Function GetType ( Const s : String ) : Word;
Begin
  If S = 'BYTE' Then GetType := CSV_UByte Else
    If S = 'SHORTINT' Then GetType := CSV_SByte Else
      If S = 'CHAR' Then GetType := CSV_Char Else
        If S = 'WORD' Then GetType := CSV_UInt16 Else
          If S = 'SMALLINT' Then GetType := CSV_SInt16 Else
            If S = 'CARDINAL' Then GetType := CSV_UInt32 Else
              If (S = 'LONGINT') Or (S = 'INTEGER') Then GetType := CSV_SInt32 Else
                If S = 'STRING' Then GetType := CSV_String Else
                  If S = 'REAL' Then GetType := CSV_Real Else
                    If S = 'SINGLE' Then GetType := CSV_Single Else
                      If S = 'DOUBLE' Then GetType := CSV_Double Else
                        If S = 'EXTENDED' Then GetType := CSV_Extended Else
                          If S = 'COMP' Then GetType := CSV_Comp Else
                            If S = 'BOOLEAN' Then GetType := CSV_Bool Else Begin
                            GetType := 0;
                          End;
End;

Function IntToStr (I : LongInt) : String;
Var
  s : String;
Begin
  Str ( i, s);
  IntToStr := s;
End;

Function StrToInt (Const S : String) : LongInt;
Var
{$IFDEF VIRTUALPASCAL}
  e : longInt;
{$ELSE}
  e : Integer;
{$ENDIF}
  Res : LongInt;
Begin
  Val (S, Res, e);
  If e <> 0 Then
    StrToInt := - 1
  Else
    StrToInt := Res;
End;

Function StrToIntDef (Const S : String; Def : LongInt) : LongInt;
Var
{$IFDEF VIRTUALPASCAL}
  e : longInt;
{$ELSE}
  e : Integer;
{$ENDIF}
  Res : LongInt;
Begin
  Val (S, Res, e);
  If e <> 0 Then
    StrToIntDef := Def
  Else
    StrToIntDef := Res;
End;

Function StrToReal (Const S : String) : Extended;
Var
{$IFDEF VIRTUALPASCAL}
  e : longInt;
{$ELSE}
  e : Integer;
{$ENDIF}
  Res : Extended;
Begin
  Val (S, Res, e);
  If e <> 0 Then
    StrToReal := - 1
  Else
    StrToReal := Res;
End;

Function Fw (Const S : String): String;
{
First word
}
Begin
  If Pos (' ', s) > 0 Then
    Fw := Copy (S, 1, Pos (' ', s) - 1)
  Else
    Fw := S;
End;
Procedure Rs (Var S : String);
{
  Remove space left (TrimLeft)
}
Begin
  {$IFDEF DELPHI}
  s := TrimLeft (S);
  {$ELSE}
  While (Length (s) > 0) Do Begin
    If s [1] = ' 'Then
      Delete (S, 1, 1)
    Else Break;
  End;
  {$ENDIF}
End;

Function IntProcDefParam (S : String; I : Integer) : Integer;
{
Parse the incode-script procedure definition from a string.
When I=0 this function will return the result type.
When I=-1 this function will return the number of parameters.
When I=1 this function will return the first parameter type.
When I=2 this function will return the second parameter type.
etc.
}
Var
  Res : Integer;
Begin
  If I = 0 Then {Return result-type} IntProcDefParam := StrToInt (Fw (s) ) Else
    If I = - 1 Then {Return param count} Begin
      res := 0;
      Delete (S, 1, Length (Fw (s) ) ); {result}
      Rs (S);
      Delete (S, 1, Length (Fw (s) ) ); {name}
      Rs (S);
      While Length (s) > 0 Do Begin
        Inc (Res);
        Delete (S, 1, Length (Fw (s) ) ); {Delete parameter name}
        Rs (S);
        Delete (S, 1, Length (Fw (s) ) ); {Delete parameter type}
        Rs (S);
      End; {while}
      IntProcDefParam := Res;
    End {else if} Else Begin
    res := 0;
    If I < 1 Then Begin IntProcDefParam := - 1; Exit; End;
    Delete (S, 1, Length (Fw (s) ) ); {result}
    Rs (S);
    Delete (S, 1, Length (Fw (s) ) ); {name}
    Rs (S);
    While Length (s) > 0 Do Begin
      Inc (Res);
      Delete (S, 1, Length (Fw (s) ) ); {delete parameter name}
      Rs (S);
      If Res = I Then Begin IntProcDefParam := StrToInt (Fw (s) ); Exit; End;
      Delete (S, 1, Length (Fw (s) ) ); {delete type}
      Rs (S);
    End; {while}
    IntProcDefParam := 0;
  End {Else Else if}
End; {IntProcDefParam}

Function IntProcDefName (S : String; I : Integer) : String;
{
Parse the incode-script procedure definition from a string.
i=0 will return the procedure name
I=1 will return the first one
}
Var
  Res : Integer;
Begin
  res := 0;
  If i = 0 Then Begin
    Delete (S, 1, Length (Fw (s) ) ); {result}
    Rs (S);
    IntProcDefName := fw (s);
    Exit;
  End;
  If I < 1 Then Begin IntProcDefName := ''; Exit; End;
  Delete (S, 1, Length (Fw (s) ) ); {result}
  Rs (S);
  Delete (S, 1, Length (Fw (s) ) ); {name}
  Rs (S);
  While Length (s) > 0 Do Begin
    Inc (Res);
    If Res = I Then Begin IntProcDefName := Fw (s); Exit; End;
    Delete (S, 1, Length (Fw (s) ) ); {delete parameter name}
    Rs (S);
    Delete (S, 1, Length (Fw (s) ) ); {delete type}
    Rs (S);
  End; {while}
  IntProcDefName := '';
End; {IntProcDefParam}

Function TCs2PascalScript. IdentifierExists (SubVars : PVariableManager; Const S : String) : Boolean;
{ Check if an identifier exists }
  Function UsesExists (s : String) : Boolean;
  Var
    i : Integer;
  Begin
    UsesExists := False;
    For i := 0 To FUses. Count - 1 Do
      If FUses {$IFDEF DELPHI} [i] {$ELSE} .GetItem (i) {$ENDIF} = s Then Begin
        UsesExists := True;
        Break;
      End;
  End; { UsesExists }

Begin
  IdentifierExists := False;
  If UsesExists (FastUppercase (s) ) Then
    IdentifierExists := True
  Else If PM_Find (Procedures, FastUppercase (s) ) <> - 1 Then
    IdentifierExists := True
  Else If PM_Find (InternalProcedures, FastUppercase (s) ) <> - 1 Then
    IdentifierExists := True
  Else If VM_Find (Variables, FastUppercase (s) ) <> - 1 Then
    IdentifierExists := True
  Else If GetType (FastUppercase (s) ) <> 0 Then
    IdentifierExists := True
  Else If Assigned (SubVars) And (VM_Find (subVars, FastUppercase (s) ) <> - 1)  Then Begin
    IdentifierExists := True
  End;
End; {IdentifierExists}

Procedure TCs2PascalScript. SetText (p : PChar);
{ Assign a text to the script engine, this also checks for uses and variables. }
Var
  HaveHadProgram,
  HaveHadUses : Boolean;

Function ProcessUses : Boolean;
  {Process Uses block}
  Var
    i : Integer;
  Begin
    ProcessUses := False;
    While Parser^. CurrTokenId <> CSTI_EOF Do Begin
      If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
        RunError (EIdentifierExpected);
        Exit;
      End; {If}
      If IdentifierExists (Nil, GetToken (Parser) ) Then Begin
        RunError (EDuplicateIdentifier);
        Exit;
      End; {If}
      FUses. Add (FastUpperCase (GetToken (Parser) ) );
      If Assigned (OnUses) Then Begin
        i := OnUses (FId, @Self, GetToken (Parser) );
      End {If}
      Else Begin
        RunError (EUnknownIdentifier);
        Exit;
      End; {Else if}
      If I <> ENoError Then Begin
        RunError (i);
        Exit;
      End; {If}
      NextNoJunk (Parser);
      If (Parser^. CurrTokenId = CSTI_SemiColon) Then Begin
        NextNoJunk (Parser);
        Break;
      End {if}
      Else If (Parser^. CurrTokenId <> CSTI_Comma) Then Begin
        RunError (EDuplicateIdentifier);
        Exit;
      End; {Else if}
    End;
    If Parser^. CurrTokenId = CSTI_EOF Then Begin
      RunError (EUnexpectedEndOfFile);
    End {If}
    Else Begin
      ProcessUses := True;
    End; {Else If}
  End; {ProcessUses}

  Function DoFuncHeader : Boolean;
  Var
    FuncParam : String;
    FuncName : String;
    CurrVar : String;
    CurrType : Word;
    FuncRes : Word;
  Function Duplic (S : String) : Boolean;
    Var
      s2, s3 : String;
      i : Integer;
    Begin
      If s = FuncName Then Begin
        Duplic := True;
        Exit;
      End; {if}
      If (funcRes <> 0) And (s = 'RESULT') Then Begin
        duplic := True;
        Exit;
      End;
      s2 := CurrVar;
      While Pos ('|', s2) > 0 Do Begin
        If Pos ('!', s2) = 1 Then Delete (s2, 1, 1);
        If Copy (s2, 1, Pos ('|', s2) - 1) = s Then Begin
          Duplic := True;
          Exit;
        End; {if}
        Delete (s2, 1, Pos ('|', s2) );
      End; {while}
      s2 := '0 ' + FuncParam;
      For i := 1 To IntProcDefParam (s2, - 1) Do Begin
        s3 := IntProcDefName (s2, 0);
        If Pos ('!', s2) = 1 Then Delete (s2, 1, 1);
        If s3 = s Then Begin
          Duplic := True;
          Exit;
        End; {if}
      End; {for}
      Duplic := False;
    End; {duplic}
  Begin
    DoFuncHeader := False;
    If Parser^. CurrTokenId = CSTII_Procedure Then
      FuncRes := 0
    Else
      FuncRes := 1;
    NextNoJunk (Parser);
    If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
      RunError (EIdentifierExpected);
      Exit;
    End; {if}
    If IdentifierExists (Nil, GetToken (Parser) ) Then Begin
      RunError (EDuplicateIdentifier);
      Exit;
    End; {if}
    FuncName := FastUppercase (GetToken (Parser) );
    FuncParam := FuncName;
    CurrVar := '';
    NextNoJunk (Parser);
    If parser^. CurrTokenId = CSTI_OpenRound Then Begin
      While True Do Begin
        NextNoJunk (Parser);
        If Parser^. CurrTokenId = CSTII_Var Then Begin
          CurrVar := '!';
          NextNoJunk (Parser);
        End; {if}
        While True Do Begin
          If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
            RunError (EIdentifierExpected);
            Exit;
          End; {if}
          If IdentifierExists (Nil, GetToken (Parser) ) Or Duplic (GetToken (Parser) ) Then Begin
            RunError (EDuplicateIdentifier);
            Exit;
          End; {if}
          CurrVar := CurrVar + fastuppercase (GetToken (Parser) ) + '|';
          NextNoJunk (parser);
          If Parser^. CurrTokenId = CSTI_Colon Then Break;
          If Parser^. CurrTokenId <> CSTI_Comma Then Begin
            RunError (ECommaExpected);
            Exit;
          End; {if}
          NextNoJunk (Parser);
        End; {while}
        NextNoJunk (Parser);
        CurrType := GetType (FastUppercase (GetToken (Parser) ) );
        If CurrType = 0 Then Begin
          RunError (EUnknownIdentifier);
          Exit;
        End; {if}
        If Pos ('!', CurrVar) = 1 Then Begin
          Delete (currVar, 1, 1);
          While Pos ('|', CurrVar) > 0 Do Begin
            FuncParam := FuncParam + ' !' + Copy (CurrVar, 1, Pos ('|', CurrVar) - 1) + ' ' + IntToStr (CurrType);
            Delete (CurrVar, 1, Pos ('|', CurrVar) );
          End; {while}
        End Else Begin
          While Pos ('|', CurrVar) > 0 Do Begin
            FuncParam := FuncParam + ' ' + Copy (CurrVar, 1, Pos ('|', CurrVar) - 1) + ' ' + IntToStr (CurrType);
            Delete (CurrVar, 1, Pos ('|', CurrVar) );
          End; {while}
        End; {if}
        NextNoJunk (Parser);
        If Parser^. CurrTokenId = CSTI_CloseRound Then Begin
          NextNoJunk (Parser);
          Break;
        End; {if}
        If Parser^. CurrTokenId <> CSTI_SemiColon Then Begin
          RunError (ESemiColonExpected);
          Exit;
        End; {if}
        NextNoJunk (Parser);
      End; {while}
    End; {if}
    If FuncRes = 1 Then Begin
      If Parser^. CurrTokenId <> CSTI_Colon Then Begin
        RunError (EColonExpected);
        Exit;
      End;
      NextNoJunk (Parser);
      If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
        RunError (EIdentifierExpected);
        Exit;
      End;
      FuncRes :=  GetType (FastUppercase (GetToken (Parser) ) );
      If FuncRes = 0 Then Begin
        RunError (EUnknownIdentifier);
        Exit;
      End;
      NextNoJunk (parser);
    End;
    FuncParam := InttoStr (FuncRes) + ' ' + FuncParam;
    If Parser^. CurrTokenId <> CSTI_Semicolon Then Begin
      RunError (ESemiColonExpected);
      Exit;
    End;
    NextNoJunk (Parser);
    PM_Add (InternalProcedures, FuncParam, Pointer (Parser^. CurrTokenPos) );
    DoFuncHeader := True;
    If Parser^. CurrTokenId = CSTII_Var Then Begin
      While (Parser^. CurrTokenID <> CSTII_Begin) And (Parser^. CurrTokenID <> CSTI_EOF) Do
        NextNoJunk (Parser);
    End;
    RunBegin (Nil, True);
    If Parser^. CurrTokenId <> CSTI_Semicolon Then Begin
      RunError (ESemiColonExpected);
      Exit;
    End;
    NextNoJunk (Parser);
  End; {DoFuncHeader}

Begin
  FUses. Clear;
  VM_Clear (Variables);
  PM_Clear (Procedures);
  PM_Clear (InternalProcedures);
  Vm_Add (Variables, CreateBool (True), 'TRUE');
  Vm_Add (Variables, CreateBool (False), 'FALSE');
  FUses. Add ('SYSTEM');
  If Assigned (OnUses) Then
    OnUses (fId, @Self, 'SYSTEM');
  RunError (ENoError);
  MainOffset := - 1;
  Text := p;
  If Text = Nil Then Begin
    Exit;
  End; {If}
  Parser^. Text := Text;
  Parser^. CurrTokenPos := 0;
  Parser^. CurrTokenLen := 0;
  HaveHadProgram := False;
  HaveHadUses := False;
  NextNoJunk (Parser);
{  ParseToken (Parser);}
  While Parser^. CurrTokenId <> CSTI_EOF Do Begin
    If Parser^. CurrTokenId = CSTI_SyntaxError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_CommentEOFError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_CharError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_StringError Then Begin
      RunError (EStringError);
      Exit;
    End; {if}
    If (Parser^. CurrTokenId = CSTII_Program) And (HaveHadProgram = False) And (HaveHadUses = False) Then Begin
      NextNoJunk (Parser);
      If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
        RunError (EIdentifierExpected);
        Exit;
      End; {if}
      NextNoJunk (Parser);
      If Parser^. CurrTokenId <> CSTI_Semicolon Then Begin
        RunError (ESemicolonExpected);
        Exit;
      End; {if}
      NextNoJunk (Parser);
      HaveHadProgram := True;
    End {if}
    Else If (Parser^. CurrTokenId = CSTII_Uses) And (HaveHadUses = False) Then Begin
      NextNoJunk (Parser);
      If Not ProcessUses Then Exit;
      HaveHadUses := True;
    End {else if}
      Else If (Parser^. CurrTokenId = CSTII_Var) Then Begin
        If Not ProcessVars (Variables) Then Exit;
      End {Else if}
        Else If (Parser^. CurrTokenId = CSTII_Procedure) Or
                (Parser^. CurrTokenId = CSTII_Function)
        Then Begin
          If Not DoFuncHeader Then
            Exit;
        End {else if}
          Else If (Parser^. CurrTokenId = CSTII_Begin) Then Begin
            MainOffset := Parser^. CurrTokenPos;
            Exit;
          End {Else if}
            Else If (Parser^. CurrTokenId = CSTI_EOF) Then Begin
              RunError (EUnexpectedEndOfFile);
            End {Else if}
              Else Begin
                RunError (EBeginExpected);
                Exit;
              End; {Else If}
  End; {While}
End; {SetText}


Function TCs2PascalScript. ProcessVars (Vars : PVariableManager) : Boolean;
        { Process Vars block }
Var
  Names  : String;
  AType  : Word;
Begin
  NextNojunk (Parser);
  Names := '';
  ProcessVars := False;
  If Parser^. CurrTokenId = CSTI_SyntaxError Then Begin
    RunError (ESyntaxError);
    Exit;
  End; {If}
  If Parser^. CurrTokenId = CSTI_CommentEOFError Then Begin
    RunError (ESyntaxError);
    Exit;
  End; {If}
  If Parser^. CurrTokenId = CSTI_CharError Then Begin
    RunError (ESyntaxError);
    Exit;
  End; {if}
  If Parser^. CurrTokenId = CSTI_StringError Then Begin
    RunError (EStringError);
    Exit;
  End; {if}
  If Parser^. CurrTokenId = CSTI_EOF Then Begin
    RunError (EUnexpectedEndOfFile);
    Exit;
  End; {if}
  While True Do Begin
    If Parser^. CurrTokenId = CSTI_SyntaxError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_CommentEOFError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_CharError Then Begin
      RunError (ESyntaxError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId = CSTI_StringError Then Begin
      RunError (EStringError);
      Exit;
    End; {if}
    If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
      RunError (EIdentifierExpected);
      Exit;
    End;
    If IdentifierExists (Vars, GetToken (Parser) ) Then Begin
      RunError (EDuplicateIdentifier);
      Exit;
    End; {if}
    Names := Names + FastUpperCase (GetToken (Parser) ) + '|';
    NextNoJunk (Parser);
    While Parser^. CurrTokenId = CSTI_Comma Do Begin
      NextNoJunk (Parser);
      If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
        RunError (EIdentifierExpected);
        Exit;
      End; {if}
      If IdentifierExists (Nil, GetToken (Parser) ) Then Begin
        RunError (EDuplicateIdentifier);
        Exit;
      End; {if}
      Names := Names + GetToken (Parser) + '|';
    End; {while}
    If Parser^. CurrTokenId <> CSTI_Colon Then Begin
      RunError (EColonExpected);
      Exit;
    End; {if}
    NextNoJunk (Parser);
    If Parser^. CurrTokenId = CSTI_Identifier Then Begin
      AType := GetType (FastUpperCase (GetToken (Parser) ) );
      If AType = 0 Then Begin
        RunError (EUnknownIdentifier);
        Exit;
      End; {if}
      While Pos ('|', names) > 0 Do Begin
        VM_Add (Vars, CreateCajVariant (AType), Copy (names, 1, Pos ('|', names) - 1) );
        Delete (Names, 1, Pos ('|', Names) );
      End; {if}
    End {else if}
    Else Begin
      RunError (EIdentifierExpected);
      Exit;
    End; {if}
    NextNoJunk (Parser);
    If Parser^. CurrTokenId <> CSTI_Semicolon Then Begin
      RunError (ESemicolonExpected);
      Exit;
    End; {if}
    NextNoJunk (Parser);
    If Parser^. CurrTokenId <> CSTI_Identifier Then Break;
  End; {while}
  ProcessVars := True;
End; {ProcessVars}

Constructor TCs2PascalScript. Create (Id : Pointer);
Begin
  {$IFDEF CLASS}
  Inherited Create;
  {$ENDIF}
  {$IFDEF EXTUNIT}
  FUses := TStringList. Create;
  {$ELSE}
  FUses. Create;
  {$ENDIF}
  New (Parser);
  FId := Id;
  RunError (ENoError);
  Text := Nil;
  MainOffset := - 1;
  Procedures := PM_Create;
  InternalProcedures := PM_Create;
  Variables := VM_Create (Nil);
  OnUses := Nil;
End; {Create}

Destructor TCs2PascalScript. Destroy;
Begin
  If Text<>nil then StrDispose(Text);
  Dispose (Parser);
  VM_Destroy (Variables);
  PM_Destroy (InternalProcedures);
  PM_Destroy (Procedures);
  {$IFDEF EXTUNIT}
  FUses. Free;
  {$ELSE}
  FUses. Destroy;
  {$ENDIF}
  {$IFDEF CLASS}
  Inherited Destroy;
  {$ENDIF}
End; {Create}

{$IFNDEF CLASS}
Function TCs2PascalScript. ErrorCode : TCs2Error;
{ Return the error code }
Begin
  ErrorCode := FErrorCode;
End; {Errorcode}

Function TCs2PascalScript. ErrorPos : LongInt;
{ Return the error position }
Begin
  ErrorPos := FErrorPos;
End; {ErrorPos}

{$ENDIF}

Procedure TCs2PascalScript. RunError (C : TCs2Error);
{ Run an error }
Begin
  If c = ENoError Then Begin
    FErrorCode := C;
    FErrorPos := - 1;
  End {if}
  Else Begin
    FErrorCode := C;
    FErrorPos := Parser^. CurrTokenPos;
  End; {else if}
End; {RunError}

Procedure TCs2PascalScript. RunScript;
{ Run the script! }
Begin
  If MainOffset = - 1 Then Begin
    Exit;
  End; {if}
  RunError (ENoError);
  Parser^. CurrTokenPos := MainOffset;
  If RunBegin (Nil, False) Then Begin
    If Parser^. CurrTokenId <> CSTI_Period Then Begin
      RunError (EPeriodExpected);
    End;
  End;
End; {RunScript}

Type
  PCajSmallCalculation = ^TCajSmallCalculation;
  TCajSmallCalculation = Packed Record
                                  TType : Byte;
                                  {
                                  0 = Variant

                                  1 = NOT

                                  2 = *
                                  3 = /
                                  4 = DIV
                                  5 = MOD
                                  6 = AND
                                  7 = SHR
                                  8 = SHL

                                  9 = +
                                  10 = -
                                  11 = OR
                                  12 = XOR

                                  13 = =
                                  14 = >
                                  15 = <
                                  16 = <>
                                  17 = <=
                                  18 = >=
                                  }
                                  CajVariant : PCajVariant;
                                End;
Function TCs2PascalScript. Calc (Vars : PVariableManager; res : PCajVariant; StopOn : TCs2TokenId) : Boolean;
{ Calculate an expression }
  Var
    Items : TList;
    PreCalc : String;
    temp4 : PCajVariant;
    Work : PCajSmallCalculation;
  Function ChrToStr (s : String) : Char;
    {Turn a char intto a string}
  Begin
    Delete (s, 1, 1); {First char : #}
    ChrToStr := Chr (StrToInt (s) );
  End;
    Function PString (s : String) : String;
    { remove the ' from the strings}
  Begin
    s := Copy (s, 2, Length (s) - 2);
    PString := s;
  End;
    Function DoPrecalc (W : pCajvariant) : Boolean;
    {Pre calculate (- not +)}
  Begin
    DoPrecalc := True;
    While Length (Precalc) > 0 Do Begin
      If precalc [1] = '-' Then Begin
        If Not DoMinus (Work^. CajVariant) Then Begin
          RunError (ETypeMismatch);
          Exit;
        End;
      End Else If precalc [1] = '|' Then Begin
        If Not DoNot (Work^. CajVariant) Then Begin
          RunError (ETypeMismatch);
          Exit;
        End;
      End Else If precalc [1] = '+' Then Begin
        {plus has no effect}
      End Else Begin
        DoPreCalc := False;
        Exit;
      End;
      Delete (PreCalc, 1, 1);
    End;
  End;

    Procedure DisposeList;
    { Dispose the items }
  Var
    i : Integer;
    p : PCajSmallCalculation;
  Begin
    For i := 0 To Items. Count - 1 Do Begin
      p := items{$IFDEF DELPHI} [i] {$ELSE} .GetItem (i) {$ENDIF} ;
      If p^. TType = 0 Then DestroyCajVariant (p^. CajVariant);
      Dispose (p);
    End;
    {$IFDEF DELPHI}
    Items. Free;
    {$ELSE}
    Items. Destroy;
    {$ENDIF}
  End;
    Function ParseString : String;
    { Parse a string }
  Var
    temp3 : String;
  Begin
    temp3 := '';
    While (Parser^. CurrTokenId = CSTI_String) Or (Parser^. CurrTokenId = CSTI_Char) Do Begin
      If Parser^. CurrTokenId = CSTI_String Then Begin
        temp3 := temp3 + PString (GetToken (Parser) );
        NextNoJunk (Parser);
        If Parser^. CurrTokenId = CSTI_String Then temp3 := temp3 + #39;
      End {if}
      Else Begin
        temp3 := temp3 + ChrToStr (GetToken (Parser) );
        NextnoJunk (parser);
      End; {else if}
    End; {while}
    ParseString := temp3;
  End;
  Procedure Calculate;
    { Calculate the full expression }
  Var
    l : PCajSmallCalculation;
    i : LongInt;
  Begin
    i := 0;
    While i < (items. count - 1) Div 2 Do Begin
      l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem ( i * 2 + 1) {$ENDIF} );
      If (l^. TType >= 2) And (l^. TType <= 8) Then Begin
        Case l^. TType Of
          2: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtMul)
          Then
            RunError (ETypeMismatch);
          3: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtDiv)
          Then
            RunError (ETypeMismatch);
          4: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtIntDiv)
          Then
            RunError (ETypeMismatch);
          5: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtIntMod)
          Then
            RunError (ETypeMismatch);
          6: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtAnd)
          Then
            RunError (ETypeMismatch);
          7: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtShr)
          Then
            RunError (ETypeMismatch);
          8: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtShl)
          Then
            RunError (ETypeMismatch);
        End;
        If ErrorCode <> 0 Then Exit;
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem (i * 2 + 2) {$ENDIF} );
        DestroycajVariant (l^. CajVariant);
        Dispose (l);
        Items. Remove (l);
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem (i * 2 + 1) {$ENDIF} );
        Dispose (l );
        Items. Remove (l);
      End Else Inc (i);
    End;

    i := 0;
    While i < (items. count - 1) Div 2 Do Begin
      l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem ( i * 2 + 1) {$ENDIF} );
      If (l^. TType >= 9) And (l^. TType <= 12) Then Begin
        Case l^. TType Of
          9: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                ^. CajVariant, PtPlus)
          Then
            RunError (ETypeMismatch);
          10: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtMinus)
          Then
            RunError (ETypeMismatch);
          11: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtOr)
          Then
            RunError (ETypeMismatch);
          12: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtXor)
          Then
            RunError (ETypeMismatch);
        End;
        If ErrorCode <> 0 Then Exit;
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem (i * 2 + 2) {$ENDIF} );
        DestroycajVariant (l^. CajVariant);
        Dispose (l);
        Items. Remove (l);
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem (i * 2 + 1) {$ENDIF} );
        Dispose (l );
        Items. Remove (l);
      End Else Inc (i);
    End;
    i := 0;
    While i < (items. count - 1) Div 2 Do Begin
      l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem ( i * 2 + 1) {$ENDIF} );
      If (l^. TType >= 13) And (l^. TType <= 18) Then Begin
        Case l^. TType Of
          13: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtEqual)
          Then
            RunError (ETypeMismatch);
          14: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtGreater)
          Then
            RunError (ETypeMismatch);
          15: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtLess)
          Then
            RunError (ETypeMismatch);
          16: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtNotEqual)
          Then
            RunError (ETypeMismatch);
          17: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtLessEqual)
          Then
            RunError (ETypeMismatch);
          18: If Not Perform (PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2] {$ELSE} .GetItem ( i * 2) {$ENDIF} )^.
                 CajVariant, PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem ( i * 2 + 2) {$ENDIF} )
                 ^. CajVariant, PtGreaterEqual)
          Then
            RunError (ETypeMismatch);
        End;
        If ErrorCode <> 0 Then Exit;
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 2] {$ELSE} .GetItem (i * 2 + 2) {$ENDIF} );
        DestroycajVariant (l^. CajVariant);
        Dispose (l);
        Items. Remove (l);
        l := PCajSmallCalculation (items{$IFDEF EXTUNIT} [i * 2 + 1] {$ELSE} .GetItem (i * 2 + 1) {$ENDIF} );
        Dispose (l);
        Items. Remove (l);
      End Else Inc (i);
    End;
  End;

Begin
  {$IFDEF EXTUNIT}
  Items := TList. Create;
  {$ELSE}
  Items. Create;
  {$ENDIF}
  Calc := False;
  While True Do Begin
    If Parser^. CurrTokenId = StopOn Then Break;
    Case Parser^. CurrTokenId Of
      CSTII_Else,
      CSTII_To,
      CSTII_DownTo,
      CSTII_do,
      CSTI_Semicolon,
      CSTII_End,
      CSTI_Comma,
      CSTI_CloseRound:
                      Begin
                        Break;
                      End; {Csti_Else...}
      CSTI_EOF :
                Begin
                  RunError (EUnexpectedEndOfFile);
                  DisposeList;
                  Exit;
                End; {CSTI_Eof}
      CSTI_SyntaxError,
      CSTI_CommentEOFError,
      CSTI_CharError:
                     Begin
                       RunError (ESyntaxError);
                       DisposeList;
                       Exit;
                     End; {Csti_SyntaxError...}
      CSTI_StringError:
                       Begin
                         RunError (EStringError);
                         DisposeList;
                         Exit;
                       End; {csti_Stringerror}
    End; {case}
    If (Items. Count And $1) = 0 Then Begin
      PreCalc := '';
      While (Parser^. CurrTokenId = CSTI_Minus) Or
            (Parser^. CurrTokenId = CSTII_Not) Or
            (Parser^. CurrTokenId = CSTI_Plus)
      Do Begin
        If (Parser^. CurrTokenId = CSTI_Minus) Then PreCalc := PreCalc + '-';
        If (Parser^. CurrTokenId = CSTII_Not) Then PreCalc := PreCalc + '|';
        If (Parser^. CurrTokenId = CSTI_Plus) Then PreCalc := PreCalc + '+';
        NextNoJunk (Parser);
      End; {While}

      New (Work);
      Case Parser^. CurrTokenId Of
        CSTI_OpenRound:
                       Begin
                         Work^. CajVariant := CreateCajVariant (res^. VType);
                         Work^. TType := 0;
                         NextNoJunk (Parser);
                         If Not Calc (vars, Work^. CajVariant, CSTI_CloseRound) Then Begin
                           DestroyCajVariant (Work^. CajVariant);
                           Dispose (Work);
                           DisposeList;
                           Exit;
                         End; {if}
                         If Not DoPreCalc (Work^. CajVariant) Then Begin
                           DestroyCajVariant (Work^. CajVariant);
                           Dispose (Work);
                           DisposeList;
                           Exit;
                         End; {if}
                         NextNoJunk (Parser);
                         Items. Add (Work);
                       End; {CSTI_OpenRound}
        CSTI_Identifier:
                        Begin
                          If Assigned (vars) And (Vm_Find (Vars, FastUppercase (GetToken (Parser) ) ) <> - 1) Then Begin
                            Temp4 := GetVarLink (Vm_Get (Vars,  Vm_Find (Vars, FastUppercase (GetToken (Parser) ) ) ) );
                            NextNoJunk (Parser);
                            Work^. CajVariant := CreateCajVariant (Temp4^. VType);
                            Work^. TType := 0;
                            If Not PerForm (Work^. CajVariant, Temp4, ptSet) Then Begin
                              DestroyCajVariant (Work^. CajVariant);
                              Dispose (Work);
                              DisposeList;
                              Exit;
                            End; {if}
                          End {if}
                          Else If Vm_Find (Variables, FastUppercase (GetToken (Parser) ) ) <> - 1 Then Begin
                            Temp4 := GetVarLink (Vm_Get (Variables,
                            Vm_Find (Variables, FastUppercase (GetToken (Parser) ) ) ) );
                            NextNoJunk (Parser);
                            Work^. CajVariant := CreateCajVariant (Temp4^. VType);
                            Work^. TType := 0;
                            If Not PerForm (Work^. CajVariant, Temp4, ptSet) Then Begin
                              DestroyCajVariant (Work^. CajVariant);
                              Dispose (Work);
                              DisposeList;
                              Exit;
                            End; {if}
                          End {if}
                            Else If PM_Find (Procedures, FastUpperCase (GetToken (Parser) ) ) <> - 1 Then Begin
                              Temp4 := DoProc (vars, False);
                              If Temp4 = Nil Then Begin
                                Dispose (Work);
                                DisposeList;
                                Exit;
                              End; {if}
                              Work^. CajVariant := CreateCajVariant (Temp4^. VType);
                              Work^. TType := 0;
                              PerForm (Work^. CajVariant, Temp4, ptSet);
                            End {else if}
                              Else If PM_Find (InternalProcedures, FastUpperCase (GetToken (Parser) ) ) <> - 1 Then Begin
                                Temp4 := DoProc (vars, True);
                                If ErrorCode <> ENoError Then Begin
                                  Dispose (Work);
                                  DisposeList;
                                  Exit;
                                End; {if}
                                Work^. CajVariant := CreateCajVariant (Temp4^. VType);
                                Work^. TType := 0;
                                PerForm (Work^. CajVariant, Temp4, ptSet);
                              End {else if}
                                Else Begin
                                  RunError (EUnknownIdentifier);
                                  Dispose (Work);
                                  DisposeList;
                                  Exit;
                                End; {else else if}
                          Items. Add (Work);
                        End; {CSTI_Identifier}
        CSTI_Integer:
                     Begin
                       If (Res^. VType >= csv_SByte) And (Res^. VType <= Csv_SInt32) Then
                         Work^. CajVariant := CreateCajVariant (res^. VType)
                       Else
                         Work^. CajVariant := CreateCajVariant (csv_SInt32);
                       Work^. TType := 0;
                       SetInteger (Work^. CajVariant, StrToInt (GetToken (Parser) ) );
                       If Not DoPreCalc (Work^. CajVariant) Then Begin
                         DestroyCajVariant (Work^. CajVariant);
                         Dispose (Work);
                         DisposeList;
                         Exit;
                       End; {if}
                       NextNoJunk (Parser);
                       Items. Add (Work);
                     End; {CSTI_Integer}
        CSTI_Real:
                  Begin
                    If (Res^. VType >= CSV_Real) And (Res^. VType <= CSV_Comp) Then
                      Work^. CajVariant := CreateCajVariant (res^. VType)
                    Else
                      Work^. CajVariant := CreateCajVariant (CSV_Extended);
                    Work^. TType := 0;
                    SetReal (Work^. CajVariant, StrToReal (GetToken (Parser) ) );
                    If Not DoPreCalc (Work^. CajVariant) Then Begin
                      DestroyCajVariant (Work^. CajVariant);
                      Dispose (Work);
                      DisposeList;
                      Exit;
                    End;
                    NextNoJunk (Parser);
                    Items. Add (Work);
                  End; {CSTI_Real}
        CSTI_String, CSTI_Char:
                               Begin
                                 Work^. CajVariant := CreateCajVariant (CSV_String);
                                 Work^. TType := 0;
                                 Work^. CajVariant^. CV_Str := ParseString;
                                 If Not DoPreCalc (Work^. CajVariant) Then Begin
                                   DestroyCajVariant (Work^. CajVariant);
                                   Dispose (Work);
                                   DisposeList;
                                   Exit;
                                 End; {if}
                                 Items. Add (Work);
                               End; {CSTI_String}
        CSTI_HexInt:
                    Begin
                      Work^. TType := 0;
                      If (Res^. VType >= csv_SByte) And (Res^. VType <= Csv_SInt32) Then
                        Work^. CajVariant := CreateCajVariant (res^. VType)
                      Else
                        Work^. CajVariant := CreateCajVariant (csv_SInt32);
                      SetInteger (Work^. CajVariant, StrToInt (GetToken (Parser) ) );
                      If Not DoPreCalc (Work^. CajVariant) Then Begin
                        DestroyCajVariant (Work^. CajVariant);
                        Dispose (Work);
                        DisposeList;
                        Exit;
                      End; {if}
                      NextNoJunk (Parser);
                      Items. Add (Work);
                    End; {CSTI_HexInt}
        Else Begin
          RunError (EErrorInExpression);
          Dispose (Work);
          DisposeList;
          Exit;
        End;
      End; {case}
    End {if}
    Else Begin
      New (Work);
      Case Parser^. CurrTokenId Of
        CSTI_Equal: Work^. TType := 13;
        CSTI_NotEqual: Work^. TType := 16;
        CSTI_Greater: Work^. TType := 14;
        CSTI_GreaterEqual: Work^. TType := 18;
        CSTI_Less: Work^. TType := 15;
        CSTI_LessEqual: Work^. TType := 17;
        CSTI_Plus: Work^. TType := 9;
        CSTI_Minus: Work^. TType := 10;
        CSTI_Divide: Work^. TType := 3;
        CSTI_Multiply: Work^. TType := 2;
        CSTII_and: Work^. TType := 6;
        CSTII_div: Work^. TType := 4;
        CSTII_mod: Work^. TType := 5;
        CSTII_or: Work^. TType := 11;
        CSTII_shl: Work^. TType := 8;
        CSTII_shr: Work^. TType := 7;
        CSTII_xor: Work^. TType := 12;
        Else Begin
          RunError (EErrorInExpression);
          Dispose (Work);
          DisposeList;
          Exit;
        End; {else case}
      End; {case}
      Items. Add (Work);
      NextnoJunk (parser);
    End; {else if}
  End; {while}
  Calculate;
  If ErrorCode = 0 Then Begin
    If Items. Count <> 1 Then Begin
      {There is an internal script error, this should not occur!}
      RunError (255);
    End Else Begin
      Work := Items{$IFDEF EXTUNIT} [0] {$ELSE} .GetItem (0) {$ENDIF} ;
      If Perform (Res, Work^. CajVariant, PtSet) Then
        Calc := True
      Else RunError (ETypeMismatch);
    End; {if}
  End; {if}
  DisposeList;
End; {Calc}

Function TCs2PascalScript. RunScriptProc (Const Name : String; Parameters : PVariableManager): PCajVariant;
Var
  ProcCall : LongInt;
  ProcDef : String;
  w : PCajVariant;
  i : LongInt;
Function IRem (S : String) : String;
  {Remove the !}
  Begin
    Delete (s, 1, 1);
    IRem := s;
  End; {irem}
Begin
  RunError (ENoError);
  RunScriptProc := Nil;
  If MainOffset = - 1 Then Begin
    Parser^. CurrTokenPos := - 1;
    RunError (EBeginExpected);
    Exit;
  End; {if}
  If PM_Find (InternalProcedures, FastUpperCase (Name ) ) = - 1 Then Begin
    RunError (EUnknownProcedure);
    Exit;
  End; {if}
  ProcCall := LongInt (PM_Get (InternalProcedures, PM_Find (InternalProcedures, FastUpperCase (Name ) ) ) );
  ProcDef := PM_GetSpec (InternalProcedures, PM_Find (InternalProcedures, FastUpperCase (Name ) ) );
  If IntProcDefParam (ProcDef, - 1) <> VM_Count (Parameters) Then Begin
    Parser^. CurrTokenPos := - 1;
    RunError (EParameterError);
    Exit;
  End;
  For i := 1 To IntProcDefParam (ProcDef, - 1) Do Begin
    If Pos ('!', IntProcDefName (ProcDef, I) ) = 1 Then Begin
      w := GetVarLink (VM_Get (Parameters, i - 1) );
      If (w^. VType <> IntProcDefParam (ProcDef, I) ) Or ( (W^. Flags And $1) <> 0) Then Begin
        Parser^. CurrTokenPos := I - 1;
        RunError (EParameterError);
        Exit;
      End; {if}
      VM_SetName (Parameters, I - 1, IRem (IntProcDefName (ProcDef, I) ) );
    End {if} Else Begin
      w := GetVarLink (VM_Get (Parameters, i - 1) );
      If IntProcDefParam (ProcDef, i) <> w^. VType  Then Begin
        Parser^. CurrTokenPos := I - 1;
        RunError (EParameterError);
        Exit;
      End; {if}
      VM_SetName (Parameters, I - 1, IntProcDefName (ProcDef, I) );
    End; {else if}
  End; {for}
  If IntProcDefParam (ProcDef, 0) <> 0 Then Begin
    w := CreateCajVariant (IntProcDefParam (ProcDef, 0) );
    VM_Add (Parameters, CreateCajVariant (CSV_Var), 'RESULT')^. Cv_Var := w;
  End {if}
  Else w := Nil;
  Parser^. CurrTokenPos := ProcCall;
  ParseToken (Parser);
  If Parser^. CurrTokenId = CSTII_Var Then Begin
    If Not ProcessVars (Parameters) Then Begin
      DestroyCajVariant (w);
      Exit;
    End; {if}
  End; {if}
  If Not RunBegin (Parameters, False) Then Begin
    DestroycajVariant (w);
    Exit;
  End; {if}
  ParseToken (Parser);
  RunScriptProc := w;
End;

Function TCs2PascalScript. DoProc (Vars : PVariableManager; Internal : Boolean): PCajVariant;
{Call an internal/external Procedure}
Var
  ProcCall : TRegisteredProc;
  ProcCall2 : LongInt;
  ProcDef : String;
  w : PCajVariant;
  i : LongInt;
  Params : PVariableManager;
Function IRem (S : String) : String;
  {Remove the !}
  Begin
    Delete (s, 1, 1);
    IRem := s;
  End; {irem}
Begin
  DoProc := Nil;
  If Internal Then Begin
    ProcCall2 := LongInt (PM_Get (InternalProcedures, PM_Find (InternalProcedures, FastUpperCase (GetToken (Parser) ) ) ) );
    ProcDef := PM_GetSpec (InternalProcedures, PM_Find (InternalProcedures, FastUpperCase (GetToken (Parser) ) ) );
  End Else Begin
    @ProcCall := PM_Get (Procedures, PM_Find (Procedures, FastUpperCase (GetToken (Parser) ) ) );
    ProcDef := PM_GetSpec (Procedures, PM_Find (Procedures, FastUpperCase (GetToken (Parser) ) ) );
  End;
  Params := VM_Create (Nil);
  NextnoJunk (Parser);
  If (IntProcDefParam (ProcDef, - 1) <> 0) And (Parser^. CurrTokenId <> CSTI_OpenRound) Then Begin
    RunError (ERoundOpenExpected);
    VM_Destroy (params);
    Exit;
  End; {if}
  If (IntProcDefParam (ProcDef, - 1) = 0) And (Parser^. CurrTokenId = CSTI_OpenRound) Then Begin
    RunError (ESemiColonExpected);
    VM_Destroy (params);
    Exit;
  End; {if}
  If Parser^. CurrTokenId = CSTI_OpenRound Then Begin
    For i := 1 To IntProcDefParam (ProcDef, - 1) Do Begin
      NextNoJunk (Parser);
      If Pos ('!', intProcDefName (ProcDef, i) ) = 1 Then Begin
        {Expect a variable}
        If Assigned (Vars) And (VM_Find (Vars, FastUppercase (GetToken (Parser) ) ) <> - 1) Then
          w := GetVarLink (VM_Get (Vars, VM_Find (Vars, FastUppercase (GetToken (Parser) ) ) ) )
        Else If VM_Find (Variables, FastUppercase (GetToken (Parser) ) ) <> - 1 Then
          w := GetVarLink (VM_Get (Variables, VM_Find (Variables, FastUppercase (GetToken (Parser) ) ) ) )
        Else Begin
          RunError (EVariableExpected);
          VM_Destroy (params);
          Exit;
        End; {else else if}
        If (w^. Flags And $1) <> 0 Then Begin
          RunError (EVariableExpected);
          VM_Destroy (params);
          Exit;
        End; {if}
        VM_Add (Params, CreateCajVariant (CSV_Var), FastUppercase (IRem (IntProcDefName (ProcDef, i) ) ) ) ^. Cv_var := w;
        NextNoJunk (Parser);
      End {if}
      Else Begin
        w := VM_Add (Params, CreateCajVariant (IntProcDefParam (ProcDef, i) ), IntProcDefName (ProcDef, i) );
        If Not Calc (vars, w, CSTI_CloseRound) Then Begin
          VM_Destroy (params);
          Exit;
        End; {if}
      End; {else if}
      If i = IntProcDefParam (ProcDef, - 1) Then Begin
        If parser^. CurrTokenId <> CSTI_CloseRound Then Begin
          RunError (ERoundCloseExpected);
          VM_Destroy (params);
          Exit;
        End; {if}
      End {if}
      Else Begin
        If parser^. CurrTokenId <> CSTI_Comma Then Begin
          RunError (ECommaExpected);
          VM_Destroy (params);
          Exit;
        End; {if}
      End; {else if}
    End; {for}
    NextNoJunk (Parser);
  End; {if}
  {Now we have all the parameters}
  If Internal Then Begin
    If IntProcDefParam (ProcDef, 0) <> 0 Then Begin
      w := CreateCajVariant (IntProcDefParam (ProcDef, 0) );
      VM_Add (Params, CreateCajVariant (CSV_Var), 'RESULT')^. Cv_Var := w;
    End {if}
    Else w := Nil;
    i := Parser^. CurrTokenPos;
    Parser^. CurrTokenPos := ProcCall2;
    ParseToken (Parser);
    If Parser^. CurrTokenId = CSTII_Var Then Begin
      If Not ProcessVars (Params) Then Begin
        DestroyCajVariant (w);
        Exit;
      End; {if}
    End; {if}
    If Not RunBegin (Params, False) Then Begin
      DestroycajVariant (w);
      Exit;
    End; {if}
    Parser^. CurrTokenPos := I;
    ParseToken (Parser);
    DoProc := w;
  End {if}
  Else Begin
    If IntProcDefParam (ProcDef, 0) <> 0 Then
      w := CreateCajVariant (IntProcDefParam (ProcDef, 0) )
    Else
      w := Nil;
    RunError (ProcCall (fId, IntProcDefName (ProcDef, 0), Params, w) );
    If ErrorCode <> ENoError Then Begin
      VM_Destroy (params);
      DestroyCajVariant (w);
      Exit;
    End; {if}
    VM_Destroy (params);
    DoProc := w;
  End; {if}
End; {DoExternalProc}

Function TCs2PascalScript. RunBegin (Vars : PVariableManager; Skip : Boolean) : Boolean;
      { Run the Script, this is the main part of the script engine }
Var
  StopOnSemicolon : Boolean;
  c : PCajVariant;
  IPos,
  IStart,
  II,
  IEnd : LongInt;
  PDownto : Boolean;

Begin
  RunBegin := False;
  If Skip Then Begin
    If Parser^. CurrTokenId = CSTII_Begin Then Begin
      NextNoJunk (Parser);
      IPos := 1;
      While True Do Begin
        If Parser^. CurrTokenId = CSTI_EOF Then Begin RunError (EUnexpectedEndOfFile); Exit; End;
        If Parser^. CurrTokenId = CSTI_SyntaxError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_CommentEOFError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_CharError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_StringError Then Begin RunError (EStringError); Exit; End;
        If Parser^. CurrTokenId = CSTII_Begin Then Inc (IPos);
        If Parser^. CurrTokenId = CSTII_End Then Begin
          Dec (IPos);
          If IPos = 0 Then Break;
        End;
        NextNoJunk (Parser);
      End; {While}
      NextNoJunk (Parser); {Skip end}
    End {If}
    Else Begin
      IPos := 1;
      While True Do Begin
        If Parser^. CurrTokenId = CSTI_EOF Then Begin RunError (EUnexpectedEndOfFile); Exit; End;
        If Parser^. CurrTokenId = CSTI_SyntaxError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_CommentEOFError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_CharError Then Begin RunError (ESyntaxError); Exit; End;
        If Parser^. CurrTokenId = CSTI_StringError Then Begin RunError (EStringError); Exit; End;
        If Parser^. CurrTokenId = CSTI_SemiColon Then Break;
        If Parser^. CurrTokenId = CSTII_Else Then Begin
          Dec (IPos);
          If Ipos = 0 Then Break;
        End;
        If Parser^. CurrTokenId = CSTII_If Then Inc (IPos);
        If Parser^. CurrTokenId = CSTII_End Then Break;
        NextNoJunk (Parser);
      End; {While}
      If Parser^. CurrTokenId = CSTI_SemiColon Then NextNoJunk (Parser);
    End; {Else If}
    RunBegin := True;
    Exit;
  End; {If}
  If Parser^. CurrTokenId = CSTII_Begin Then Begin
    StopOnSemicolon := False;
    NextNoJunk (Parser); {skip begin}
  End Else
    StopOnSemicolon := True;
  While True Do Begin
    Case Parser^. CurrTokenId Of
      CSTI_EOF: Begin RunError (EUnexpectedEndOfFile); Exit; End;
      CSTI_SyntaxError: Begin RunError (ESyntaxError); Exit; End;
      CSTI_CommentEOFError: Begin RunError (ESyntaxError); Exit; End;
      CSTI_CharError: Begin RunError (ESyntaxError); Exit; End;
      CSTI_StringError: Begin RunError (EStringError); Exit; End;
      CSTII_Else: Begin
        If StopOnSemicolon Then Begin
          RunBegin := True;
          Exit;
        End;
        RunError (EErrorInStatement);
        Exit;
      End;
      CSTII_End:
                Begin
                  RunBegin := True;
                  NextNoJunk (Parser);
                  Exit;
                End; {CSTII_End}
      CSTI_Semicolon:
                     Begin
                       If StopOnSemicolon Then Begin
                         RunBegin := True;
                         Exit;
                       End;
                       NextNojunk (Parser);
                     End; {CSTI_SemiColon}
      CSTII_If:
               Begin
                 NextNoJunk (Parser);
                 c := CreateCajVariant (CSV_Bool);
                 If Not Calc (vars, c, CSTII_Then) Then Begin
                   DestroyCajVariant (c);
                   Exit;
                 End; {if}
                 If Parser^. CurrTokenId <> CSTII_Then Then Begin
                   RunError (EThenExpected);
                   DestroyCajVariant (c);
                   Exit;
                 End;
                 NextNoJunk (Parser); {skip THEN}
                 If c^. Cv_Bool Then Begin
                   If Not RunBegin (Vars, False) Then Begin
                     DestroyCajVariant (c);
                     Exit;
                   End; {if}
                   If Parser^. CurrTokenId = CSTII_Else Then Begin
                     NextnoJunk (Parser);
                     If Not RunBegin (Vars, True) Then Begin
                       DestroyCajVariant (c);
                       Exit;
                     End; {if}
                   End; {if}
                 End {if}
                 Else Begin
                   If Not RunBegin (Vars, True) Then Begin
                     DestroyCajVariant (c);
                     Exit;
                   End; {if}
                   If Parser^. CurrTokenId = CSTII_Else Then Begin
                     NextnoJunk (Parser);
                     If Not RunBegin (Vars, False) Then Begin
                       DestroyCajVariant (c);
                       Exit;
                     End; {if}
                   End; {if}
                 End; {if}
               End; {CSTII_If}
      CSTII_While:
                  Begin
                    NextNoJunk(Parser);
                    C:=CreateCajVariant(CSV_Bool);
                    Ipos:=Parser^.CurrTokenPos;
                    If Not Calc(Vars, c, CSTII_Do) Then Begin
                      DestroyCajVariant(c);
                      Exit;
                    End; {if}
                    If Parser^.CurrTokenID<>CSTII_Do Then Begin
                      RunError(EDoExpected);
                      DestroyCajVariant(c);
                      Exit;
                    End; {if}
                    NextNoJunk(Parser);
                    IStart:=Parser^.CurrTokenPos;
                    While C^.Cv_Bool Do Begin
                      if not RunBegin(Vars, False) then begin
                        DestroyCajVariant(c);
                        Exit;
                      end;
                      Parser^.CurrTokenPos:=IPos;
                      ParseToken(Parser);
                      If Not Calc(Vars, c, CSTII_Do) Then Begin
                        DestroyCajVariant(c);
                        Exit;
                      End; {if}
                      Parser^.CurrTokenPos:=IStart;
                      ParseToken(Parser);
                    End; {While}
                    DestroyCajVariant(c);
                    If Not RunBegin(Vars, True) Then
                      Exit;
                  End; {CSTII_While}
      CSTII_For:
                Begin
                  NextNoJunk (Parser);
                  If Parser^. CurrTokenId <> CSTI_Identifier Then Begin
                    RunError (EIdentifierExpected);
                    Exit;
                  End; {if}
                  If Assigned (Vars) And (VM_Find (Vars, FastUppercase (GetToken (Parser) ) ) <> - 1) Then
                    C := GetVarLink (VM_Get (Vars, VM_Find (Vars, FastUppercase (GetToken (Parser) ) ) ) )
                  Else If VM_Find (Variables, FastUppercase (GetToken (Parser) ) ) <> - 1 Then
                    c := GetVarLink (VM_Get (Variables, VM_Find (Variables, FastUppercase (GetToken (Parser) ) ) ) )
                  Else Begin
                    RunError (EUnknownIdentifier);
                    Exit;
                  End; {if}
                  If (c^. Flags And $1) <> 0 Then Begin
                    RunError (EVariableExpected);
                    Exit;
                  End; {if}
                  If Not IsIntegerType (c) Then Begin
                    RunError (ETypeMismatch);
                  End; {if}
                  NextNoJunk (Parser);
                  If Parser^. CurrTokenId <> CSTI_Assignment Then Begin
                    RunError (EAssignmentExpected);
                    Exit;
                  End; {if}
                  NextNoJunk (Parser);
                  If Not Calc (Vars, c, CSTII_To) Then Exit;
                  IStart := GetInt (c);
                  If Parser^. CurrTokenId = CSTII_To Then Begin
                    PDownTo := False;
                  End {if}
                  Else If Parser^. CurrTokenId = CSTII_DownTo Then Begin
                    PDownTo := True;
                  End {if}
                    Else Begin
                      RunError (EToExpected);
                      Exit;
                    End; {if}
                  NextNoJunk (Parser);
                  If Not Calc (Vars, c, CSTII_Do) Then Exit;
                  IEnd := GetInt (c);
                  If Parser^. CurrTokenId <> CSTII_Do Then Begin
                    RunError (EDoExpected);
                    Exit;
                  End; {if}
                  NextNoJunk (Parser);
                  IPos := Parser^. CurrTokenPos;
                  If PDownTo Then Begin
                    c^. Flags := c^. Flags Or $1;
                    For II := IStart Downto IEnd Do Begin
                      SetInteger (C, II);
                      If Not RunBegin (Vars, False) Then Begin
                        c^. Flags := c^. Flags And Not $1;
                        Exit;
                      End;
                      Parser^. CurrTokenPos := IPos;
                      ParseToken (Parser);
                    End;
                    c^. Flags := c^. Flags And Not $1;
                    If Not RunBegin (Vars, True) Then Exit;
                  End {if}
                  Else Begin
                    c^. Flags := c^. Flags Or $1;
                    For II := IStart To IEnd Do Begin
                      SetInteger (C, II);
                      If Not RunBegin (Vars, False) Then Begin
                        c^. Flags := c^. Flags And Not $1;
                        Exit;
                      End;
                      Parser^. CurrTokenPos := IPos;
                      ParseToken (Parser);
                    End;
                    c^. Flags := c^. Flags And Not $1;
                    If Not RunBegin (Vars, True) Then Exit;
                  End {if}
                End;
      CSTII_Repeat:
                   Begin
                     RunError (EErrorInStatement);
                     Exit;
                   End; {CSTII_Repeat}
      CSTII_Begin:
                  Begin
                    If Not RunBegin (Vars, False) Then Exit;
                  End; {CSTII_Begin}
      CSTII_Case:
                 Begin
                   RunError (EErrorInStatement);
                   Exit;
                 End; {CSTII_Case}
      CSTI_Identifier:
                      Begin
                        If PM_Find (InternalProcedures, FastUppercase (GetToken (Parser) ) ) <> - 1 Then Begin
                          DestroyCajVariant (DoProc (Vars, True) );
                          If ErrorCode <> ENoError Then
                            Exit;
                        End {if}
                        Else If Assigned (vars) And (Vm_Find (Vars, FastUppercase (GetToken (Parser) ) ) <> - 1) Then Begin
                          c := GetVarLink (VM_Get (Vars, Vm_Find (Vars, FastUppercase (GetToken (Parser) ) ) ) );
                          NextNoJunk (Parser);
                          If Parser^. CurrTokenId <> CSTI_Assignment Then Begin
                            RunError (EAssignmentExpected);
                            Exit;
                          End; {if}
                          NextNoJunk (Parser);
                          If (1 And c^. Flags) <> 0 Then Begin
                            RunError (EErrorInStatement);
                            Exit;
                          End; {else if}
                          If Not Calc (vars, c, CSTI_Semicolon) Then Exit;
                        End{if}
                          Else If Vm_Find (Variables, FastUppercase (GetToken (Parser) ) ) <> - 1 Then Begin
                            c := GetVarLink (VM_Get (Variables,
                            Vm_Find (Variables, FastUppercase (GetToken (Parser) ) ) ) );
                            NextNoJunk (Parser);
                            If Parser^. CurrTokenId <> CSTI_Assignment Then Begin
                              RunError (EAssignmentExpected);
                              Exit;
                            End;
                            NextNoJunk (Parser);
                            If (1 And c^. Flags) <> 0 Then Begin
                              RunError (EErrorInStatement);
                              Exit;
                            End;
                            If Not Calc (vars, c, CSTI_Semicolon) Then Exit;
                          End {if}
                            Else If PM_Find (Procedures, FastUppercase (GetToken (Parser) ) ) <> - 1 Then Begin
                              DestroyCajVariant (DoProc (Vars, False) );
                              If ErrorCode <> ENoError Then
                                Exit;
                            End {else if}
                              Else Begin
                                RunError (EUnknownIdentifier);
                                Exit;
                              End; {if}
                      End; {CSTI_Identifier}
      Else
      Begin
        RunError (EErrorInStatement);
        Exit;
      End; {Else case}
    End; {Case}
  End; {While}
  RunBegin := True;
End; {RunBegin}

Function StdProc (ID : Pointer; Const ProcName : String; Params : PVariableManager; res : PCajVariant) : TCS2Error; Far;
Var
  c : PCajVariant;
  i1, i2 : LongInt;
Function mkchr (c : PCajVariant): Integer;
  Begin
    If c^. vtype = CSV_String Then Begin
      If Length (c^. cv_str) = 1 Then Begin
        mkChr := Ord (c^. CV_str [1] );
      End Else
        mkchr := - 1;
    End Else Begin
      mkChr := Ord (c^. CV_Char);
    End;
  End;
Begin
  StdProc := ENoError;
  If ProcName = 'STRGET' Then Begin
    c := GetVarLink (VM_Get (params, 0) );
    i1 := GetInt (GetVarLink (VM_Get (params, 1) ) );
    If (i1 < 1) Or (i1 > Length (c^. cv_Str) ) Then Begin
      StdProc := ERangeError;
      Exit;
    End;
    Res^. CV_Char := c^. cv_Str [i1];
  End Else If ProcName = 'STRSET' Then Begin
    c := GetVarLink (VM_Get (params, 2) );
    i1 := GetInt (GetVarLink (VM_Get (params, 1) ) );
    If (i1 < 1) Or (i1 > Length (c^. cv_Str) ) Then Begin
      StdProc := ERangeError;
      Exit;
    End;
    i2 := MkChr (GetVarLink (VM_Get (params, 2) ) );
    If i2 = - 1 Then Begin
      StdProc := ERangeError;
      Exit;
    End;
    C^. CV_Str [i1] := Chr (i2);
  End Else If ProcName = 'ORD' Then Begin
    i1 := MkChr (GetVarLink (VM_Get (params, 0) ) );
    If i1 = - 1 Then Begin
      StdProc := ERangeError;
      Exit;
    End;
    res^. cv_UByte := i1;
  End Else If ProcName = 'CHR' Then Begin
    res^. Cv_Char := Chr (GetInt (GetVarLink (VM_Get (Params, 0) ) ) );
  End Else If ProcName = 'UPPERCASE' Then Begin
    SetString (Res, strUpper(GetStr (GetVarLink (VM_Get (Params, 0) ) ) ) );
  End Else If ProcName = 'LOWERCASE' Then Begin
    SetString (Res, strLower(GetStr (GetVarLink (VM_Get (Params, 0) ) ) ) );
  End Else If ProcName = 'POS' Then Begin
    SetInteger (Res, Pos (GetStr (GetVarLink (VM_Get (Params, 0) ) ), GetStr (GetVarLink (VM_Get (Params, 1) ) ) ) );
  End Else If ProcName = 'INTTOSTR' Then Begin
    SetString (Res, IntToStr (GetInt (GetVarLink (VM_Get (Params, 0) ) ) ) );
  End Else If ProcName = 'STRTOINT' Then Begin
    SetInteger (Res, StrToIntDef (GetStr (GetVarLink (VM_Get (Params, 0) ) ), GetInt (GetVarLink (VM_Get (Params, 1) ) ) ) );
  End Else If ProcName = 'COPY' Then Begin
    SetString (Res, Copy (GetStr (GetVarLink (VM_Get (Params, 0) ) ), GetInt (GetVarLink (VM_Get (Params, 1) ) ),
    GetInt (GetVarLink (VM_Get (Params, 2) ) ) ) );
  End Else If ProcName = 'DELETE' Then Begin
    c := GetVarLink (VM_Get (params, 0) );
    Delete (c^. cv_Str, GetInt (GetVarLink (VM_Get (Params, 1) ) ), GetInt (GetVarLink (VM_Get (Params, 2) ) ) );
  End Else If ProcName = 'INSERT' Then Begin
    c := GetVarLink (VM_Get (params, 1) );
    Insert (GetStr (GetVarLink (VM_Get (Params, 0) ) ), c^. cv_Str, GetInt (GetVarLink (VM_Get (Params, 2) ) ) );
  End Else If ProcName = 'INC' Then Begin
    c := GetVarLink (VM_Get (params, 0));
    Inc(c^.CV_SInt32);
  End Else If ProcName = 'DEC' Then Begin
    c := GetVarLink (VM_Get (params, 0));
    Dec(c^.CV_SInt32);
  End;
End;

Procedure RegisterStdLib (P: PCs2PascalScript);
{Register standard library}
Begin
  {$IFDEF CLASS}
  PM_Add (p. Procedures, '7 STRGET S 8 I 6', @StdProc);
  PM_Add (p. Procedures, '0 STRSET C 7 I 6 !S 8', @StdProc);
  PM_Add (p. Procedures, '1 ORD C 7', @StdProc);
  PM_Add (p. Procedures, '7 CHR B 1', @StdProc);
  PM_Add (p. Procedures, '6 STRTOINT S 8 I 6', @StdProc);
  PM_Add (p. Procedures, '8 INTTOSTR I 6', @StdProc);
  PM_Add (p. Procedures, '8 UPPERCASE S 8', @StdProc);
  PM_Add (p. Procedures, '8 LOWERCASE S 8', @StdProc);
  PM_Add (p. Procedures, '8 COPY S 8 I1 6 I2 6', @StdProc);
  PM_Add (p. Procedures, '0 DELETE !S 8 I1 6 I2 6', @StdProc);
  PM_Add (p. Procedures, '0 INSERT S1 8 !S 8 I1 6', @StdProc);
  PM_Add (p. Procedures, '6 POS S1 8 S2 8', @StdProc);
  PM_Add (p. Procedures, '0 INC !I 6', @StdProc);
  PM_Add (p. Procedures, '0 DEC !I 6', @StdProc);
  {$ELSE}
  PM_Add (p^. Procedures, '7 STRGET S 8 I 6', @StdProc);
  PM_Add (p^. Procedures, '0 STRSET C 7 I 6 !S 8', @StdProc);
  PM_Add (p^. Procedures, '1 ORD C 7', @StdProc);
  PM_Add (p^. Procedures, '7 CHR B 1', @StdProc);
  PM_Add (p^. Procedures, '6 STRTOINT S 8 I 6', @StdProc);
  PM_Add (p^. Procedures, '8 INTTOSTR I 6', @StdProc);
  PM_Add (p^. Procedures, '8 UPPERCASE S 8', @StdProc);
  PM_Add (p^. Procedures, '8 LOWERCASE S 8', @StdProc);
  PM_Add (p^. Procedures, '8 COPY S 8 I1 6 I2 6', @StdProc);
  PM_Add (p^. Procedures, '0 DELETE !S 8 I1 6 I2 6', @StdProc);
  PM_Add (p^. Procedures, '0 INSERT S1 8 !S 8 I1 6', @StdProc);
  PM_Add (p^. Procedures, '6 POS S1 8 S2 8', @StdProc);
  PM_Add (p^. Procedures, '0 INC !I 6', @StdProc);
  PM_Add (p^. Procedures, '0 DEC !I 6', @StdProc);
  {$ENDIF}
End;


End.
