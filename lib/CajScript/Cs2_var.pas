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
} Unit CS2_VAR; {Cajscript 2.0 Variable management, Procedure management}
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
Uses
  {$IFDEF EXTUNIT} Classes, {$ENDIF} CS2_UTL;
Type
  TCS2Error = Word;

Const
  ENoError = 0;
  ECanNotReadProperty = 1;
  ECanNotWriteProperty = 2;
  EUnknownIdentifier = 3;
  EIdentifierExpected = 4;
  ESemicolonExpected = 5;
  EBeginExpected = 6;
  EDuplicateIdentifier = 7;
  EUnexpectedEndOfFile = 8;
  EColonExpected = 9;
  ESyntaxError = 10;
  EStringError = 11;
  EErrorInStatement = 12;
  EAssignmentExpected = 13;
  ETypeMismatch = 14;
  EErrorInExpression = 15;
  ERoundOpenExpected = 16;
  ERoundCloseExpected = 17;
  EVariableExpected = 18;
  ECommaExpected = 19;
  EThenExpected = 20;
  EPeriodExpected = 21;
  EParameterError = 22;
  EToExpected = 23;
  EDoExpected = 24;
  ERangeError = 25;
  EUnknownProcedure = 26;

Const
  CSV_NONE     = 0;  { Void/ERROR }
  CSV_UByte    = 1;  { Byte }
  CSV_SByte    = 2;  { ShortInt }
  CSV_UInt16   = 3;  { Word }
  CSV_SInt16   = 4;  { Integer (Delphi : SmallInt) }
  CSV_UInt32   = 5;  { Longint (Delphi : Cardinal) }
  CSV_SInt32   = 6;  { Longint }
  CSV_Char     = 7;  { Char }
  CSV_String   = 8;  { String }
  CSV_Real     = 9;  { Real }
  CSV_Single   = 10; { Single }
  CSV_Double   = 11; { Double }
  CSV_Extended = 12; { Extended }
  CSV_Comp     = 13; { Comp }
  CSV_Bool     = 14; { Boolean }
  CSV_Var      = 15; { variable }

Type
  PCajVariant = ^TCajVariant;
  TCajVariant = Packed Record
                         VType : Word;
                         Flags : Byte; {Readonly(Const) = 1}
                         {$IFDEF P32}
                         CV_Str      : String;
                         {$ENDIF}
                         Case Word Of
                           CSV_UByte    : (CV_UByte    : Byte);
                           CSV_SByte    : (CV_SByte    : ShortInt);
                           CSV_Char     : (CV_Char     : Char);
                           CSV_UInt16   : (CV_UInt16   : Word);

                           CSV_SInt16   : (CV_SInt16   : {$IFDEF P32} SmallInt{$ELSE} Integer{$ENDIF} );
                           CSV_UInt32   : (CV_UInt32   : {$IFDEF P32} Cardinal{$ELSE} LongInt{$ENDIF} );
                           CSV_SInt32   : (CV_SInt32   : LongInt);
                           CSV_String   : ({$IFNDEF P32} CV_Str      : String{$ENDIF} );
                           CSV_Real     : (CV_Real     : Real);
                           CSV_Single   : (CV_Single   : Single);
                           CSV_Double   : (CV_Double   : Double);
                           CSV_Extended : (CV_Extended : Extended);
                           CSV_Comp     : (CV_Comp     : Comp);
                           CSV_Bool     : (CV_Bool     : Boolean);
                           CSV_Var      : (cv_Var      : Pointer); {Pointer to a CajVariant}
                       End;

Function CreateCajVariant (VType : Word) : PCajVariant;

Function CreateReal (Const e : Extended) : PCajVariant;
Function CreateString (Const s : String) : PCajVariant;
Function CreateInteger (i : LongInt) : PCajVariant;
Function CreateBool (b : Boolean) : PCajVariant;

Procedure DestroyCajVariant (p : PCajVariant);

Type
  PVariableManager = ^TVariableManager;
  TVariableManager = Packed Record
                              Names : TStringList;
                              Ptr   : TList;
                            End;

Function VM_Create (InheritFrom : PVariableManager) : PVariableManager;
Procedure VM_Destroy (p : PVariableManager);
Function VM_Add ( P : PVariableManager; D : PCajVariant; Const Name : String) : PcajVariant;
Procedure VM_Delete (p : PVariableManager; Idx : LongInt);
Function VM_Get (p : PVariableManager; Idx : LongInt) : PCajVariant;
Procedure VM_SetName (p : PVariableManager; Idx : LongInt; S : String);
Function VM_Count (p : PVariableManager) : LongInt;
Function VM_Find (p : PVariableManager; Const Name : String) : LongInt;
Procedure VM_Clear (p : PVariableManager);


Type
  TRegisteredProc = Function (ID : Pointer;
Const ProcName : String; Params : PVariableManager;
                              res : PCajVariant) : TCS2Error;

  PProcedureManager = ^TProcedureManager;
  TProcedureManager = Packed Record
                               Names : TStringList;
                               Ptr   : TList;
                             End;
  {Spec: RESTYPE NAME PARAM1NAME PARAM1TYPE PARAM2NAME PARAM2TYPE
  an ! before the paramname means is VARIABLE
  }

  Function PM_Create : PProcedureManager;
Procedure PM_Destroy (p : PProcedureManager);
Procedure PM_Clear (p : PProcedureManager);
Procedure PM_Add (p : PProcedureManager; Const Spec : String; Addr : Pointer);
Procedure PM_Delete (p : PProcedureManager; I : LongInt);
Function PM_Find (p : PProcedureManager; Const Name : String) : Integer;
Function PM_Get (p : PProcedureManager; i : LongInt) : Pointer;
Function PM_GetSpec (p : PProcedureManager; i : LongInt) : String;

Function DoMinus (p : PCajVariant) : Boolean;
Function DoNot (p : PCajVariant) : Boolean;
Type
  TPerformType = (PtSet, ptMinus, PtPlus, PtMul, ptDiv, PtIntDiv, PtIntMod, PtAnd,
  ptOr, ptXor, PtShl, PtShr, PtGreater, PtLess, PtEqual, PtNotEqual, PtGreaterEqual, PtLessEqual);
Function Perform (V1 : pCajVariant; v2 : pCajVariant; T : TPerformType) : Boolean;

Procedure SetInteger (p : PCajVariant;  I : LongInt);
Procedure SetReal (p : PCajVariant; i : Extended);
Procedure SetString (p : PCajVariant; Const I : String);

Function IsStringType (v : PCajVariant) : Boolean;
Function IsIntRealType (v : PCajVariant) : Boolean;
Function IsIntegerType (v : PCajVariant) : Boolean;
Function IsRealType (v : PCajVariant) : Boolean;
Function IsBooleanType (v : PCajVariant) : Boolean;

Function GetStr (v : PCajVariant) : String;
Function GetReal (v : PCajVariant) : Extended;
Function GetInt (v : PCajVariant) : LongInt;
Function GetBool (v : PCajVariant) : Boolean;

Function GetVarLink (V : PCajVariant) : PCajVariant;
{Always use this function when using VM_Get}

Implementation

Function GetVarLink (V : PCajVariant) : PCajVariant;
Begin
  If Assigned (v) Then
    While v^. VType = CSV_Var Do Begin
      If Assigned (V^. CV_Var) Then
        v := V^. Cv_Var
      Else
        Break;
    End;
  GetVarLink := v;
End;

Function CreateCajVariant (VType : Word) : PCajVariant;
{
  Creates an instance of a CajVariant, is not really needed, but when I add
  more variable types as arrays and records, it will be!
}
Var
  p : PCajVariant;
Begin
  New (p);
  p^. VType := VType;
  p^. Flags := 0;
  If VType = CSV_Var Then
    p^. CV_Var := Nil;
  CreateCajVariant := p;
End;

Function CreateReal (Const e : Extended) : PCajVariant;
Var
  p : PCajVariant;
Begin
  p := CreateCajVariant (CSV_Extended);
  p^. Cv_Extended := e;
  CreateReal := p;
End;

Function CreateString (Const s : String) : PCajVariant;
Var
  p : PCajVariant;
Begin
  p := CreateCajVariant (CSV_String);
  p^. Cv_Str := s;
  CreateString := p;
End;

Function CreateInteger (i : LongInt) : PCajVariant;
Var
  p : PCajVariant;
Begin
  p := CreateCajVariant (CSV_SInt32);
  p^. Cv_sInt32 := i;
  CreateInteger := p;
End;

Function CreateBool (b : Boolean) : PCajVariant;
Var
  p : PCajVariant;
Begin
  p := CreateCajVariant (CSV_Bool);
  p^. Cv_Bool := b;
  Createbool := p;
End;

Procedure DestroyCajVariant (p : PCajVariant);
{ Destroys an instance of a CajVariant.}
Begin
  If Assigned (p) Then
    Dispose (p);
End;

Function VM_Create (InheritFrom : PVariableManager) : PVariableManager;
{Creates an instance of a VariableManger}
Var
  p : PVariableManager;
  i : Integer;
Begin
  New (p);
  {$IFDEF EXTUNIT}
  p^. names := TStringList. Create;
  p^. Ptr := TList. Create;
  {$ELSE}
  p^. names. Create;
  p^. Ptr. Create;
  {$ENDIF}
  If Assigned (InheritFrom) Then Begin
    For i := 0 To InheritFrom^. names. count - 1 Do Begin
      p^. names. Add (InheritFrom^. names{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} );
      p^. Ptr. Add (InheritFrom^. Ptr{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} );
    End;
  End;
  VM_Create := p;
End;

Procedure VM_Destroy (p : PVariableManager);
{Destroys an instance of a VariableManager}
Var
  i : Integer;
Begin
  For i := 0 To p^. Ptr. count - 1 Do Begin
    DestroyCajVariant (p^. Ptr{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} );
  End;
  {$IFDEF PASCAL}
  p^. names. Free;
  p^. Ptr. Free;
  {$ELSE}
  p^. names. Destroy;
  p^. Ptr. Destroy;
  {$ENDIF}
  Dispose (p);
End;

Function VM_Add ( P : PVariableManager; D : PCajVariant; Const Name : String) : PCajVariant;
Var
  i : Integer;
Begin
  For i := 0 To p^. Names. Count - 1 Do Begin
    If p^. names{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} = Name Then Begin
      VM_Add := Nil;
      Exit;
    End;
  End;
  p^. Names. Add (Name);
  p^. Ptr. Add (D);
  VM_Add := D;
End;

Procedure VM_Clear (p : PVariableManager);
Var
  i : Integer;
Begin
  For i := 0 To p^. Ptr. count - 1 Do Begin
    DestroyCajVariant (p^. Ptr{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} );
  End;
  p^. names. Clear;
  p^. Ptr. Clear;
End;

Procedure VM_Delete (p : PVariableManager; Idx : LongInt);
Begin
  p^. Names. Delete (idx);
  DestroyCajVariant (p^. Ptr{$IFDEF EXTUNIT} [idx] {$ELSE} .GetItem (idx) {$ENDIF}  );
  p^. Ptr. Remove (p^. Ptr {$IFDEF EXTUNIT} [idx] {$ELSE} .GetItem (idx) {$ENDIF} );
End;

Function VM_Find (p : PVariableManager; Const Name : String) : LongInt;
Var
  i : Integer;
Begin
  For i := 0 To p^. Names. Count - 1 Do Begin
    If p^. names{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} = Name Then Begin
      VM_Find := I;
      Exit;
    End;
  End;
  VM_Find := - 1;
End;

Function VM_Count (p : PVariableManager) : LongInt;
Begin
  If p=nil then VM_Count :=0 else VM_Count := P^. Ptr. Count;
End;

Function VM_Get (p : PVariableManager; Idx : LongInt) : PCajVariant;
Begin
  VM_Get := P^. Ptr{$IFDEF EXTUNIT} [idx] {$ELSE} .GetItem (idx) {$ENDIF} ;
End;

Procedure VM_SetName (p : PVariableManager; Idx : LongInt; S : String);
Begin
  P^. Names{$IFDEF EXTUNIT} [idx] := s {$ELSE} .SetItem (idx, s) {$ENDIF} ;
End;


Function PM_Create : PProcedureManager;
{Creates an instance of a Procedure Manager}
Var
  p : PProcedureManager;
Begin
  New (p);
  {$IFDEF EXTUNIT}
  p^. names := TStringList. Create;
  p^. Ptr := TList. Create;
  {$ELSE}
  p^. names. Create;
  p^. Ptr. Create;
  {$ENDIF}
  PM_Create := p;
End;

Procedure PM_Clear (p : PProcedureManager);
Begin
  p^. names. Clear;
  p^. Ptr. Clear;
End;

Procedure PM_Destroy (p : PProcedureManager);
{Destroys an instance of a Procedure Manager}
Begin
  {$IFDEF EXTUNIT}
  p^. names. Free;
  p^. Ptr. Free;
  {$ELSE}
  p^. names. Destroy;
  p^. Ptr. Destroy;
  {$ENDIF}
  Dispose (p);
End;

Procedure PM_Add (p : PProcedureManager; Const Spec : String; Addr : Pointer);
Var
  w : String;
Begin
  w := spec;
  Delete (w, 1, Pos (' ', w) );
  w := Copy (w, 1, Pos (' ', w) - 1);
  If Pm_Find (p, w) = - 1 Then Begin
    p^. Names. Add (Spec);
    p^. Ptr. Add (Addr);
  End;
End;

Procedure PM_Delete (p : PProcedureManager; I : LongInt);
Begin
  p^. Names. Delete (i);
  p^. Ptr. Remove (p^. Ptr{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} );
End;

Function PM_Find (p : PProcedureManager; Const Name : String) : Integer;
Var
  i : Integer;
  s : String;
Begin
  For i := 0 To p^. names. count - 1 Do Begin
    s := p^. names{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} ;
    Delete (s, 1, Pos (' ', s) );
    If Pos (' ', s)<>0 then s := Copy (s, 1, Pos (' ', s) - 1);
    If s = Name Then Begin
      PM_Find := i;
      Exit;
    End;
  End;
  PM_Find := - 1;
End;
Function PM_Get (p : PProcedureManager; i : LongInt) : Pointer;
Begin
  PM_Get := p^. Ptr{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} ;
End;

Function PM_GetSpec (p : PProcedureManager; i : LongInt) : String;
Begin
  PM_GetSpec := p^. Names{$IFDEF EXTUNIT} [i] {$ELSE} .GetItem (i) {$ENDIF} ;
End;

Function DoMinus (p : PCajVariant) : Boolean;
Begin
  p := GetVarLink (p);
  DoMinus := True;
  Case P^. VType Of
    CSV_UByte : p^. Cv_UByte := - p^. Cv_UByte;
    CSV_SByte : p^. Cv_SByte := - p^. Cv_SByte;
    CSV_UInt16 : p^. Cv_UInt16 := - p^. Cv_UInt16;
    CSV_SInt16 : p^. Cv_SInt16 := - p^. Cv_SInt16;
    CSV_UInt32 : p^. Cv_UInt32 := - p^. Cv_UInt32;
    CSV_SInt32 : p^. Cv_SInt32 := - p^. Cv_SInt32;
    CSV_Real     : p^. Cv_Real := - p^. Cv_Real;
    CSV_Single   : p^. Cv_Single := - p^. cv_Single;
    CSV_Double   : p^. Cv_Double := - p^. Cv_Double;
    CSV_Extended : p^. Cv_Extended := - p^. Cv_Extended;
    CSV_Comp     : p^. Cv_Comp := - p^. Cv_Comp;
    Else
      DoMinus := False;
  End;
End;

Function DoNot (p : PCajVariant) : Boolean;
Begin
  p := GetVarLink (p);
  DoNot := True;
  Case P^. VType Of
    CSV_UByte : p^. Cv_UByte := Not p^. Cv_UByte;
    CSV_SByte : p^. Cv_SByte := Not p^. Cv_SByte;
    CSV_UInt16 : p^. Cv_UInt16 := Not p^. Cv_UInt16;
    CSV_SInt16 : p^. Cv_SInt16 := Not p^. Cv_SInt16;
    CSV_UInt32 : p^. Cv_UInt32 := Not p^. Cv_UInt32;
    CSV_SInt32 : p^. Cv_SInt32 := Not p^. Cv_SInt32;
    CSV_Bool : p^. CV_Bool := Not p^. CV_Bool;
    Else
      DoNot := False;
  End;
End;

Procedure SetInteger (p : PCajVariant;  I : LongInt);
Begin
  p := GetVarLink (p);
  Case P^. VType Of
    CSV_UByte : p^. Cv_UByte := i;
    CSV_SByte : p^. Cv_SByte := i;
    CSV_UInt16 : p^. Cv_UInt16 := i;
    CSV_SInt16 : p^. Cv_SInt16 := i;
    CSV_UInt32 : p^. Cv_UInt32 := i;
    CSV_SInt32 : p^. Cv_SInt32 := i;
  End;
End;

Procedure SetReal (p : PCajVariant; i : Extended);
Begin
  p := GetVarLink (p);
  Case P^. VType Of
    CSV_Real: P^. CV_Real := i;
    CSV_Single: P^. CV_Single := i;
    CSV_Double: P^. CV_Double := i;
    CSV_Extended: P^. CV_Extended := i;
    CSV_Comp: P^. CV_Comp := i;
  End;
End;

Procedure SetString (p : PCajVariant; Const I : String);
Begin
  p := GetVarLink (p);
  Case P^. VType Of
    CSV_String: P^. Cv_Str := i;
  End;
End;

Function IsRealType (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  IsRealType := (V^. VType = CSV_Real) Or
  (v^. Vtype = CSV_Single) Or
  (v^. Vtype = CSV_Double) Or
  (v^. Vtype = CSV_Extended) Or
  (v^. Vtype = CSV_Comp);
End;

Function IsIntegerType (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  IsIntegerType := (v^. Vtype = CSV_UByte) Or
  (v^. Vtype = CSV_SByte) Or
  (v^. Vtype = CSV_UInt16) Or
  (v^. Vtype = CSV_SInt16) Or
  (v^. Vtype = CSV_UInt32) Or
  (v^. Vtype = CSV_SInt32);
End;

Function IsIntRealType (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  IsIntRealType := (v^. Vtype = CSV_UByte) Or
  (v^. Vtype = CSV_SByte) Or
  (v^. Vtype = CSV_UInt16) Or
  (v^. Vtype = CSV_SInt16) Or
  (v^. Vtype = CSV_UInt32) Or
  (v^. Vtype = CSV_SInt32) Or
  (V^. VType = CSV_Real) Or
  (v^. Vtype = CSV_Single) Or
  (v^. Vtype = CSV_Double) Or
  (v^. Vtype = CSV_Extended) Or
  (v^. Vtype = CSV_Comp);
End;

Function IsStringType (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  IsStringType := (v^. Vtype = CSV_Char) Or
  (v^. Vtype = CSV_String);
End;

Function IsBooleanType (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  IsBooleanType := (v^. Vtype = CSV_Bool);
End;

Function GetInt (v : PCajVariant) : LongInt;
Begin
  v := GetVarLink (v);
  Case v^. Vtype Of
    CSV_UByte: GetInt := V^. CV_UByte;
    CSV_SByte: GetInt := V^. CV_SByte;
    CSV_UInt16: GetInt := V^. CV_UInt16;
    CSV_SInt16: GetInt := V^. CV_SInt16;
    CSV_UInt32: GetInt := V^. CV_UInt32;
    CSV_SInt32: GetInt := V^. CV_SInt32;
  End;
End;

Function GetReal (v : PCajVariant) : Extended;
Begin
  v := GetVarLink (v);
  Case v^. Vtype Of
    CSV_Real: GetReal := V^. CV_Real;
    CSV_Single: GetReal := V^. CV_single;
    CSV_Double: GetReal := V^. CV_double;
    CSV_Extended: GetReal := V^. CV_Extended;
    CSV_Comp: GetReal := V^. CV_Comp;
    CSV_UByte: GetReal := V^. CV_UByte;
    CSV_SByte: GetReal := V^. CV_SByte;
    CSV_UInt16: GetReal := V^. CV_UInt16;
    CSV_SInt16: GetReal := V^. CV_SInt16;
    CSV_UInt32: GetReal := V^. CV_UInt32;
    CSV_SInt32: GetReal := V^. CV_SInt32;
  End;
End;

Function GetStr (v : PCajVariant) : String;
Begin
  v := GetVarLink (v);
  Case v^. Vtype Of
    CSV_String: GetStr := V^. CV_Str;
    CSV_Char: GetStr := V^. CV_Char;
  End;
End;

Function GetBool (v : PCajVariant) : Boolean;
Begin
  v := GetVarLink (v);
  Case v^. Vtype Of
    CSV_Bool: GetBool := V^. CV_Bool;
  End;
End;


Function Perform (V1 : pCajVariant; v2 : pCajVariant; T : TPerformType) : Boolean;

Var
  err : Boolean;

Procedure MakeItReal (v : Extended);
  Begin
    V1^. VType := CSV_Extended;
    v1^. Cv_Extended := v;
  End;

  Procedure MakeItBool (v : Boolean);
  Begin
    v1^. VType := CSV_Bool;
    v1^. Cv_Bool := v;
  End;


Begin
  v1 := GetVarLink (v1);
  v2 := GetVarLink (v2);
  If (v1^. Vtype <> v2^. VType) And
     Not (IsIntRealType (v1) And IsIntRealType (v2) ) And
     Not (IsStringType (v1) And IsStringType (v2) )
  Then Begin
    Perform := False;
    Exit;
  End;
  Err := False;
  Case T Of
    PtSet: Case V1^. VType Of
      CSV_UByte: v1^. Cv_UByte := GetInt (v2);
      CSV_SByte: v1^. Cv_SByte := GetInt (v2);
      CSV_Char:
                Begin
                  v1^. Cv_Str := GetStr (v2);
                  If Length (v1^. Cv_Str) > 1 Then Err := True Else
                    v1^. Cv_Char := v1^. Cv_Str [1];
                End;
      CSV_UInt16: v1^. Cv_UInt16 := GetInt (v2);
      CSV_SInt16: v1^. Cv_SInt16 := GetInt (v2);
      CSV_UInt32: v1^. Cv_UInt32 := GetInt (v2);
      CSV_SInt32: v1^. Cv_SInt32 := GetInt (v2);
      CSV_String: v1^. Cv_Str := GetStr (v2);
      CSV_Real: v1^. CV_Real := GetReal (v2);
      CSV_Single: v1^. CV_Single := GetReal (v2);
      CSV_Double: v1^. CV_Double := GetReal (v2);
      CSV_Extended: v1^. CV_Extended := GetReal (v2);
      CSV_Comp: v1^. CV_comp := GetReal (v2);
      CSV_Bool:
               Begin
                 If v2^. VType = CSV_Bool Then
                   v1^. Cv_Bool := v2^. Cv_Bool
                 Else
                   err := True;
               End;
    End;
    ptMinus:
               Case v1^. VType Of
                 CSV_UByte:
                            Begin
                              If IsRealType (v2) Then
                                MakeItReal (v1^. CV_UByte - GetReal (v2) )
                              Else
                                v1^. CV_UByte := v1^. CV_UByte- GetInt (V2);
                            End;
                 CSV_SByte:
                           Begin
                             If IsRealType (v2) Then
                               MakeItReal (v1^. CV_SByte - GetReal (v2) )
                             Else
                               v1^. CV_SByte := v1^. CV_SByte- GetInt (V2);
                           End;
                 CSV_UInt16:
                            Begin
                              If IsRealType (v2) Then
                                MakeItReal (v1^. Cv_UInt16 - GetReal (v2) )
                              Else
                                v1^. CV_UInt16 := v1^. CV_UInt16 - GetInt (V2);
                            End;
                 CSV_SInt16:
                            Begin
                              If IsRealType (v2) Then
                                MakeItReal (v1^. CV_SInt16 - GetReal (v2) )
                              Else
                                v1^. CV_SInt16 := v1^. CV_SInt16 - GetInt (V2);
                            End;
                 CSV_UInt32:
                            Begin
                              If IsRealType (v2) Then
                                MakeItReal (V1^. Cv_Uint32 - GetReal (v2) )
                              Else
                                v1^. CV_UInt32 := v1^. CV_UInt32 - GetInt (V2);
                            End;
                 CSV_SInt32:
                            Begin
                              If IsRealType (v2) Then
                                MakeItReal (v1^. Cv_Sint32 - GetReal (v2) )
                              Else
                                v1^. CV_SInt32 := v1^. CV_SInt32 - GetInt (V2);
                            End;
                 CSV_Real:
                          Begin
                            v1^. CV_Real := v1^. CV_Real - GetReal (V2);
                          End;
                 CSV_Single:
                            Begin
                              v1^. CV_Single := v1^. CV_Single- GetReal (V2);
                            End;
                 CSV_Double:
                            Begin
                              v1^. CV_Double := v1^. CV_Double- GetReal (V2);
                            End;
                 CSV_Extended:
                              Begin
                                v1^. CV_Extended := v1^. CV_Extended - GetReal (V2);
                              End;
                 CSV_Comp:
                          Begin
                            v1^. cv_Comp := v1^. cv_Comp - GetReal (V2);
                          End;
                 Else
                   Err := True;
               End { CASE } ;
    ptPlus:
             Case v1^. VType Of
               CSV_UByte:
                          Begin
                            If IsRealType (v2) Then
                              MakeItReal (v1^. CV_UByte + GetReal (v2) )
                            Else
                              v1^. CV_UByte := v1^. CV_UByte+ GetInt (V2);
                          End;
               CSV_SByte:
                         Begin
                           If IsRealType (v2) Then
                             MakeItReal (v1^. CV_SByte + GetReal (v2) )
                           Else
                             v1^. CV_SByte := v1^. CV_SByte+ GetInt (V2);
                         End;
               CSV_UInt16:
                          Begin
                            If IsRealType (v2) Then
                              MakeItReal (v1^. Cv_UInt16 + GetReal (v2) )
                            Else
                              v1^. CV_UInt16 := v1^. CV_UInt16 + GetInt (V2);
                          End;
               CSV_SInt16:
                          Begin
                            If IsRealType (v2) Then
                              MakeItReal (v1^. CV_SInt16 + GetReal (v2) )
                            Else
                              v1^. CV_SInt16 := v1^. CV_SInt16 + GetInt (V2);
                          End;
               CSV_UInt32:
                          Begin
                            If IsRealType (v2) Then
                              MakeItReal (V1^. Cv_Uint32 + GetReal (v2) )
                            Else
                              v1^. CV_UInt32 := v1^. CV_UInt32 + GetInt (V2);
                          End;
               CSV_SInt32:
                          Begin
                            If IsRealType (v2) Then
                              MakeItReal (v1^. Cv_Sint32 + GetReal (v2) )
                            Else
                              v1^. CV_SInt32 := v1^. CV_SInt32 + GetInt (V2);
                          End;
               CSV_Real:
                        Begin
                          v1^. CV_Real := v1^. CV_Real + GetReal (V2);
                        End;
               CSV_Single:
                          Begin
                            v1^. CV_Single := v1^. CV_Single+ GetReal (V2);
                          End;
               CSV_Double:
                          Begin
                            v1^. CV_Double := v1^. CV_Double+ GetReal (V2);
                          End;
               CSV_Extended:
                            Begin
                              v1^. CV_Extended := v1^. CV_Extended + GetReal (V2);
                            End;
               CSV_Comp:
                        Begin
                          v1^. cv_Comp := v1^. cv_Comp + GetReal (V2);
                        End;
               CSV_String:
                           Begin
                             v1^. cv_Str := v1^. cv_str + GetStr (v2);
                           End;
               Else
                 Err := True;
             End { CASE } ;
    ptMul:
            Case v1^. VType Of
              CSV_UByte:
                        Begin
                          If IsRealType (v2) Then
                            MakeItReal (v1^. CV_UByte * GetReal (v2) )
                          Else
                            v1^. CV_UByte := v1^. CV_UByte * GetInt (V2);
                        End;
              CSV_SByte:
                        Begin
                          If IsRealType (v2) Then
                            MakeItReal (v1^. CV_SByte * GetReal (v2) )
                          Else
                            v1^. CV_SByte := v1^. CV_SByte * GetInt (V2);
                        End;
              CSV_UInt16:
                         Begin
                           If IsRealType (v2) Then
                             MakeItReal (v1^. Cv_UInt16 * GetReal (v2) )
                           Else
                             v1^. CV_UInt16 := v1^. CV_UInt16 * GetInt (V2);
                         End;
              CSV_SInt16:
                         Begin
                           If IsRealType (v2) Then
                             MakeItReal (v1^. CV_SInt16 * GetReal (v2) )
                           Else
                             v1^. CV_SInt16 := v1^. CV_SInt16 * GetInt (V2);
                         End;
              CSV_UInt32:
                         Begin
                           If IsRealType (v2) Then
                             MakeItReal (V1^. Cv_Uint32 * GetReal (v2) )
                           Else
                             v1^. CV_UInt32 := v1^. CV_UInt32 * GetInt (V2);
                         End;
              CSV_SInt32:
                         Begin
                           If IsRealType (v2) Then
                             MakeItReal (v1^. Cv_Sint32 * GetReal (v2) )
                           Else
                             v1^. CV_SInt32 := v1^. CV_SInt32 * GetInt (V2);
                         End;
              CSV_Real:
                       Begin
                         v1^. CV_Real := v1^. CV_Real * GetReal (V2);
                       End;
              CSV_Single:
                         Begin
                           v1^. CV_Single := v1^. CV_Single * GetReal (V2);
                         End;
              CSV_Double:
                         Begin
                           v1^. CV_Double := v1^. CV_Double * GetReal (V2);
                         End;
              CSV_Extended:
                           Begin
                             v1^. CV_Extended := v1^. CV_Extended * GetReal (V2);
                           End;
              CSV_Comp:
                       Begin
                         v1^. cv_Comp := v1^. cv_Comp * GetReal (V2);
                       End;
              Else
                Err := True;
            End { CASE } ;
    ptDiv:
           Begin
             If Not isRealType (V2) Then Begin
               Perform := True;
               Exit;
             End;
             Case v1^. VType Of
               CSV_Real:
                        Begin
                          v1^. CV_Real := v1^. CV_Real / GetInt (V2);
                        End;
               CSV_Single:
                          Begin
                            v1^. CV_Single := v1^. CV_Single / GetInt (V2);
                          End;
               CSV_Double:
                          Begin
                            v1^. CV_Double := v1^. CV_Double / GetInt (V2);
                          End;
               CSV_Extended:
                            Begin
                              v1^. CV_Extended := v1^. CV_Extended / GetInt (V2);
                            End;
               CSV_Comp:
                        Begin
                          v1^. cv_Comp := v1^. cv_Comp / GetInt (V2);
                        End;
               Else
                 Err := True;
             End { CASE } ;
           End; { begin }
    ptIntDiv:
              Begin
                If Not isIntegerType (V2) Then Begin
                  Perform := True;
                  Exit;
                End;
                Case v1^. VType Of
                  CSV_UByte:
                             Begin
                               v1^. CV_UByte := v1^. CV_UByte Div GetInt (V2);
                             End;
                  CSV_SByte:
                            Begin
                              v1^. CV_SByte := v1^. CV_SByte Div GetInt (V2);
                            End;
                  CSV_UInt16:
                             Begin
                               v1^. CV_UInt16 := v1^. CV_UInt16 Div GetInt (V2);
                             End;
                  CSV_SInt16:
                             Begin
                               v1^. CV_SInt16 := v1^. CV_SInt16 Div GetInt (V2);
                             End;
                  CSV_UInt32:
                             Begin
                               v1^. CV_UInt32 := v1^. CV_UInt32 Div GetInt (V2);
                             End;
                  CSV_SInt32:
                             Begin
                               v1^. CV_SInt32 := v1^. CV_SInt32 Div GetInt (V2);
                             End;
                  Else
                    Err := True;
                End;
              End;
    ptIntMod:
              Begin
                If Not isIntegerType (V2) Then Begin
                  Perform := True;
                  Exit;
                End;
                Case v1^. VType Of
                  CSV_UByte:
                            Begin
                              v1^. CV_UByte := v1^. CV_UByte Mod GetInt (V2);
                            End;
                  CSV_SByte:
                            Begin
                              v1^. CV_SByte := v1^. CV_SByte Mod GetInt (V2);
                            End;
                  CSV_UInt16:
                             Begin
                               v1^. CV_UInt16 := v1^. CV_UInt16 Mod GetInt (V2);
                             End;
                  CSV_SInt16:
                             Begin
                               v1^. CV_SInt16 := v1^. CV_SInt16 Mod GetInt (V2);
                             End;
                  CSV_UInt32:
                             Begin
                               v1^. CV_UInt32 := v1^. CV_UInt32 Mod GetInt (V2);
                             End;
                  CSV_SInt32:
                             Begin
                               v1^. CV_SInt32 := v1^. CV_SInt32 Mod GetInt (V2);
                             End;
                  Else
                    Err := True;
                End;
              End;
    ptAnd:
           Begin
             If Not ((isIntegerType(V2)) or (isBooleanType(V2))) Then Begin
               Perform := True;
               Exit;
             End;
             Case v1^. VType Of
               CSV_UByte:
                          Begin
                            v1^. CV_UByte := v1^. CV_UByte And GetInt (V2);
                          End;
               CSV_SByte:
                         Begin
                           v1^. CV_SByte := v1^. CV_SByte And GetInt (V2);
                         End;
               CSV_UInt16:
                          Begin
                            v1^. CV_UInt16 := v1^. CV_UInt16 And GetInt (V2);
                          End;
               CSV_SInt16:
                          Begin
                            v1^. CV_SInt16 := v1^. CV_SInt16 And GetInt (V2);
                          End;
               CSV_UInt32:
                          Begin
                            v1^. CV_UInt32 := v1^. CV_UInt32 And GetInt (V2);
                          End;
               CSV_SInt32:
                          Begin
                            v1^. CV_SInt32 := v1^. CV_SInt32 And GetInt (V2);
                          End;
               CSV_Bool:
                          Begin
                            MakeItBool (V1^.Cv_Bool AND V2^. Cv_Bool );
                          End;
               Else
                 Err := True;
             End;
           End;
    ptOr:
          Begin
            If Not ((isIntegerType(V2)) or (isBooleanType(V2))) Then Begin
              Perform := True;
              Exit;
            End;
            Case v1^. VType Of
              CSV_UByte:
                         Begin
                           v1^. CV_UByte := v1^. CV_UByte Or GetInt (V2);
                         End;
              CSV_SByte:
                        Begin
                          v1^. CV_SByte := v1^. CV_SByte Or GetInt (V2);
                        End;
              CSV_UInt16:
                         Begin
                           v1^. CV_UInt16 := v1^. CV_UInt16 Or GetInt (V2);
                         End;
              CSV_SInt16:
                         Begin
                           v1^. CV_SInt16 := v1^. CV_SInt16 Or GetInt (V2);
                         End;
              CSV_UInt32:
                         Begin
                           v1^. CV_UInt32 := v1^. CV_UInt32 Or GetInt (V2);
                         End;
              CSV_SInt32:
                         Begin
                           v1^. CV_SInt32 := v1^. CV_SInt32 Or GetInt (V2);
                         End;
              CSV_Bool:
                         Begin
                           MakeItBool (V1^.Cv_Bool OR V2^. Cv_Bool );
                         End;
              Else
                Err := True;
            End;
          End;
    ptXor:
           Begin
             If Not ((isIntegerType(V2)) or (isBooleanType(V2))) Then Begin
               Perform := True;
               Exit;
             End;
             Case v1^. VType Of
               CSV_UByte:
                         Begin
                           v1^. CV_UByte := v1^. CV_UByte XOr GetInt (V2);
                         End;
               CSV_SByte:
                         Begin
                           v1^. CV_SByte := v1^. CV_SByte XOr GetInt (V2);
                         End;
               CSV_UInt16:
                          Begin
                            v1^. CV_UInt16 := v1^. CV_UInt16 XOr GetInt (V2);
                          End;
               CSV_SInt16:
                          Begin
                            v1^. CV_SInt16 := v1^. CV_SInt16 XOr GetInt (V2);
                          End;
               CSV_UInt32:
                          Begin
                            v1^. CV_UInt32 := v1^. CV_UInt32 XOr GetInt (V2);
                          End;
               CSV_SInt32:
                          Begin
                            v1^. CV_SInt32 := v1^. CV_SInt32 XOr GetInt (V2);
                          End;
              CSV_Bool:
                         Begin
                           MakeItBool (V1^.Cv_Bool XOR V2^. Cv_Bool );
                         End;
               Else
                 Err := True;
             End;
           End;
    ptShr:
           Begin
             If Not isIntegerType (V2) Then Begin
               Perform := True;
               Exit;
             End;
             Case v1^. VType Of
               CSV_UByte:
                         Begin
                           v1^. CV_UByte := v1^. CV_UByte ShR GetInt (V2);
                         End;
               CSV_SByte:
                         Begin
                           v1^. CV_SByte := v1^. CV_SByte ShR GetInt (V2);
                         End;
               CSV_UInt16:
                          Begin
                            v1^. CV_UInt16 := v1^. CV_UInt16 ShR GetInt (V2);
                          End;
               CSV_SInt16:
                          Begin
                            v1^. CV_SInt16 := v1^. CV_SInt16 ShR GetInt (V2);
                          End;
               CSV_UInt32:
                          Begin
                            v1^. CV_UInt32 := v1^. CV_UInt32 ShR GetInt (V2);
                          End;
               CSV_SInt32:
                          Begin
                            v1^. CV_SInt32 := v1^. CV_SInt32 ShR GetInt (V2);
                          End;
               Else
                 Err := True;
             End;
           End;
    ptShl:
           Begin
             If Not isIntegerType (V2) Then Begin
               Perform := True;
               Exit;
             End;
             Case v1^. VType Of
               CSV_UByte:
                          Begin
                            v1^. CV_UByte := v1^. CV_UByte ShL GetInt (V2);
                          End;
               CSV_SByte:
                         Begin
                           v1^. CV_SByte := v1^. CV_SByte ShL GetInt (V2);
                         End;
               CSV_UInt16:
                          Begin
                            v1^. CV_UInt16 := v1^. CV_UInt16 ShL GetInt (V2);
                          End;
               CSV_SInt16:
                          Begin
                            v1^. CV_SInt16 := v1^. CV_SInt16 ShL GetInt (V2);
                          End;
               CSV_UInt32:
                          Begin
                            v1^. CV_UInt32 := v1^. CV_UInt32 ShL GetInt (V2);
                          End;
               CSV_SInt32:
                          Begin
                            v1^. CV_SInt32 := v1^. CV_SInt32 ShL GetInt (V2);
                          End;
               Else
                 Err := True;
             End;
           End;
    PtGreater: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte > GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte > GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte > GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte > GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char > v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str > v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 > GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 > GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 > GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 > GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 > GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 > GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 > GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 > GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real > GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single > GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double > GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended > GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp > GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool > V2^. Cv_Bool );
    End; {case item}
    PtLess: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte < GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte < GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte < GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte < GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char < v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str < v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 < GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 < GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 < GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 < GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 < GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 < GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 < GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 < GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real < GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single < GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double < GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended < GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp < GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool < V2^. Cv_Bool );
    End; {case item}
    PtGreaterEqual: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte >= GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte >= GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte >= GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte >= GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char >= v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str >= v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 >= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 >= GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 >= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 >= GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 >= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 >= GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 >= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 >= GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real >= GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single >= GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double >= GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended >= GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp >= GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool >= V2^. Cv_Bool );
    End; {case item}
    PtLessEqual: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte <= GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte <= GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte <= GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte <= GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char <= v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str <= v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 <= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 <= GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 <= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 <= GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 <= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 <= GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 <= GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 <= GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real <= GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single <= GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double <= GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended <= GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp <= GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool <= V2^. Cv_Bool );
    End; {case item}
    PtEqual: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte = GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte = GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte = GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte = GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char = v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str = v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 = GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 = GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 = GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 = GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 = GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 = GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 = GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 = GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real = GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single = GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double = GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended = GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp = GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool = V2^. Cv_Bool );
    End; {case item}
    PtNotEqual: Case V1^. VType Of
      CSV_UByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_UByte <> GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_UByte <> GetInt (V2) );
      CSV_SByte: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_SByte <> GetReal (v2) )
      Else
        MakeItBool (v1^. Cv_SByte <> GetInt (V2) );
      CSV_Char: If v2^. VType = CSV_Char Then
        MakeItBool (V1^. Cv_Char <> v2^. CV_Char )
      Else
        Err := True;
      CSV_String: If v2^. VType = CSV_String Then
        MakeItBool (V1^.Cv_Str <> v2^.CV_Str )
      Else
        Err := True;
      CSV_UInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint16 <> GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt16 <> GetInt (V2) );
      CSV_SInt16: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint16 <> GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt16 <> GetInt (V2) );
      CSV_UInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Uint32 <> GetReal (v2) )
      Else
        MakeItBool (v1^. CV_UInt32 <> GetInt (V2) );
      CSV_SInt32: If IsRealType (v2) Then
        MakeItBool (V1^. Cv_Sint32 <> GetReal (v2) )
      Else
        MakeItBool (v1^. CV_SInt32 <> GetInt (V2) );
      CSV_Real: MakeItBool (V1^. Cv_Real <> GetReal (v2) );
      CSV_Single: MakeItBool (V1^. Cv_Single <> GetReal (v2) );
      CSV_Double: MakeItBool (V1^. Cv_Double <> GetReal (v2) );
      CSV_Extended: MakeItBool (V1^. Cv_Extended <> GetReal (v2) );
      CSV_Comp: MakeItBool (V1^. Cv_Comp <> GetReal (v2) );
      CSV_Bool: MakeItBool (V1^. Cv_Bool <> V2^. Cv_Bool );
    End; {case item}
  End;
  PerForm := Not Err;
End;

End.
