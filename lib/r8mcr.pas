{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit R8Mcr;

Interface

Uses
  r8objs,
  objects;

Type

TMacro = record
  MacroName : PString;
  MacroValue : PString;
  Ex : boolean;
end;

PMacro = ^TMacro;

TMacroLib = object(TCollection)
  Procedure FreeItem(Item:pointer);virtual;
end;

PMacroLib = ^TMacroLib;

TMacroEngine = object(TObject)
  MacroLib : PMacroLib;
  MacroError : byte;

  Constructor Init;
  Destructor  Done;virtual;

  Procedure AddMacro(MacroName:string;Value:string;Ex:boolean);
  Procedure ModifyMacro(MacroName:string;NewValue:string);

  Procedure ProcessString(Var S:string);virtual;
  Function  ProcessFile(Var fIn:text;Var fOut:text):boolean;
end;

PMacroEngine = ^TMacroEngine;

Implementation
Uses
  r8Str;

Procedure TMacroLib.FreeItem(Item:Pointer);
begin
  DisposeStr(PMacro(Item)^.MacroName);
  DisposeStr(PMacro(Item)^.MacroValue);
  Dispose(PMacro(Item));
end;

Constructor TMacroEngine.Init;
Begin
  inherited Init;
  MacroLib:=New(PMacroLib,Init($10,$10));
  MacroError:=0;
End;

Destructor TMacroEngine.Done;
Begin
  inherited done;
  objDispose(MacroLib);
End;

Procedure TMacroEngine.AddMacro(MacroName:string;Value:string;Ex:boolean);
Var
  TempMacro:PMacro;
Begin
    TempMacro:=New(PMacro);
    TempMacro^.MacroName:=NewStr(strUpper(MacroName));
    TempMacro^.MacroValue:=NewStr(Value);
    TempMacro^.Ex:=Ex;
    MacroLib^.Insert(TempMacro);
End;

Procedure TMacroEngine.ModifyMacro(MacroName:string;NewValue:string);
Var
  i:integer;
  TempMacro:PMacro;
Begin
  For i:=0 To MacroLib^.Count-1 Do
    Begin
      TempMacro:=MacroLib^.At(i);
      If TempMacro^.MacroName^=strUpper(MacroName) Then
        begin
         DisposeStr(TempMacro^.MacroValue);
         TempMacro^.MacroValue:=NewStr(NewValue);
        end;
    End;
End;

Function TMacroEngine.ProcessFile(Var fIn:text;Var fOut:text):boolean;
Var
  sTemp : string;
Begin
  ProcessFile:=True;
{$I-}
  Reset(fIn);
{$I+}
  If IOResult<>0 Then
    Begin
      MacroError:=1;
      ProcessFile:=False;
      Exit;
    End;
{$I-}
  Rewrite(FOut);
{$I+}
  If IOResult<>0 Then
    Begin
      MacroError:=1;
      ProcessFile:=False;
      Exit;
    End;
  While Not Eof(fIn) Do
    Begin
      ReadLn(fIn, sTemp);
      ProcessString(sTemp);
      WriteLn(fOut,sTemp);
    End;
  Close(fIn);
  Close(fOut);
End;

Procedure TMacroEngine.ProcessString(Var S:string);
Var
  i,i2,i3:integer;
  p:integer;
  TempMacro:PMacro;
  Command:string;
  sTemp:string;
  sTemp2:string;
Begin
  For i:=0 To MacroLib^.Count-1 Do
    Begin
      TempMacro:=MacroLib^.At(i);

      If TempMacro^.Ex then sTemp:='@'+TempMacro^.MacroName^+'@'
            else sTemp:=TempMacro^.MacroName^;

      sTemp2:='';
      if TempMacro^.MacroValue<>nil then sTemp2:=TempMacro^.MacroValue^;

      P:=Pos(sTemp,strUpper(S));
      While P<>0 Do
        begin
          S:=Copy(S,1,P-1)+sTemp2+
                 Copy(S,P+Length(sTemp),Length(S)-Length(sTemp)-p+2);
          P:=Pos(sTemp,strUpper(S));
        end;

      P:=Pos('@'+TempMacro^.MacroName^+'(',strUpper(S));
      While P<>0 Do
        begin
          i2:=P+2+Length(TempMacro^.MacroName^);
          Command:='';
          While S[i2+1]<>'@' do
            begin
              Command:=Command+S[i2];
              Inc(i2);
            end;

          sTemp:='';
          If TempMacro^.MacroValue<>nil then sTemp:=TempMacro^.MacroValue^;
          Command:=strUpper(Command);

          If strParser(Command,1,[','])='R' then
            sTemp:=strPadR(sTemp,#32,
               strStrToInt(strParser(Command,2,[','])));

          If strParser(Command,1,[','])='L' then
            sTemp:=strPadL(sTemp,#32,
               strStrToInt(strParser(Command,2,[','])));

          If strParser(Command,1,[','])='C' then
            begin
              i2:=strStrToInt(strParser(Command,2,[',']));
              sTemp:=strPadL(sTemp,#32,i2-(Length(sTemp)+(i2 div 2)));
              sTemp:=strPadR(sTemp,#32,i2 div 2);
            end;

          S:=Copy(S,1,P-1)+sTemp+
                 Copy(S,P+Length(TempMacro^.MacroName^)+Length(Command)+4
                 ,Length(S)-(Length(TempMacro^.MacroName^)+Length(Command)+3)
                  -p+1);

          P:=Pos('@'+TempMacro^.MacroName^+'(',strUpper(S));
        end;
    End;
End;

End.
