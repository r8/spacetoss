{
 ParamStr Stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit r8PStr;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

Interface
Uses
  objects,
  r8dos,
  r8objs,
  r8str;

const
  TParsDefCharset : set of char = ['-','/'];

Type

  TKey = object(TObject)
    Name : PString;
    Value : PString;

    Constructor Init(const AName,AValue:string);
    Destructor  Done; virtual;
  end;
  PKey=^TKey;

  TKeyCollection = object(TCollection)
    Procedure FreeItem(Item:Pointer);virtual;
  end;
  PKeyCollection = ^TKeyCollection;

  TParamString = object(TObject)
    Present : boolean;
    Command : PString;
    Keys : PKeyCollection;
    Parameters : PStringsCollection;
    KeyChar : set of char;

    Constructor Init;
    Destructor  Done;virtual;
    Procedure Read;
    Function CheckKey(Key:string):boolean;
    Function GetKey(Key:string):string;
    Function CheckParameter(Parameter:string):boolean;
  end;
  PParamString = ^TParamString;


implementation

Constructor TKey.Init(const AName,AValue:string);
begin
  inherited Init;

  Name:=nil;
  Value:=nil;

  AssignStr(Name,AName);
  AssignStr(Value,AValue);
end;

Destructor TKey.Done;
begin
  DisposeStr(Name);
  DisposeStr(Value);

  inherited Done;
end;

Procedure TKeyCollection.FreeItem(Item:Pointer);
begin
  objDispose(PKey(Item));
end;

Constructor  TParamString.Init;
Begin
  inherited Init;

  Present:=False;
  Command:=nil;
  Keys:=New(PKeyCollection,Init($10,$10));
  Parameters:=New(PStringsCollection,Init($10,$10));
  KeyChar:=TParsDefCharSet;
End;

Destructor TParamString.Done;
Begin
  Present:=False;
  DisposeStr(Command);

  objDispose(Keys);
  objDispose(Parameters);

  inherited Done;
end;

Procedure TParamString.Read;
Var
  i:longint;
  sTemp:string;
  Key, Value : string;
  AllParams : string;

  T:text;
  S:string;
begin
  if ParamCount=0 then exit;
  Present:=True;

  AllParams:=dosGetCommandLine;

  i:=1;
  while i<=strNumbOfTokensEx(AllParams,[#32],strBrackets) do
    begin
      sTemp:=strParserEx(AllParams,i,[#32],strBrackets);

      If  sTemp[1] in KeyChar then
        begin
          sTemp:=Copy(sTemp,2,Length(sTemp)-1);
          Key := strParser(sTemp,1,[':']);
          Value := Copy(sTemp,Pos(':',sTemp)+1,Length(sTemp)-Pos(':',sTemp)+1);
          Keys^.Insert(New(PKey,Init(Key,Value)));
        end
       else

        if sTemp[1]='@' then
          begin
            AllParams:=Copy(AllParams,1,Pos(sTemp,AllParams)-1);
            Assign(T,dosMakeValidString(Copy(sTemp,2,Length(sTemp)-1)));
           {$I-}
            Reset(T);
           {$I+}
            If IOResult=0 then
              begin
                While not Eof(T) do
                  begin
                    ReadLn(T,S);
                    AllParams:=AllParams+S+#32;
                  end;
                Close(T);
                continue;
              end;
          end
         else

           If Command=nil then Command:=NewStr(sTemp)
            else Parameters^.Insert(NewStr(sTemp));
      Inc(I)
    end;
end;

Function TParamString.CheckKey(Key:string):boolean;
  Function Check(P:Pointer):boolean;far;
  Var
    TempKey : PKey absolute P;
  begin
     Check:=false;
     If strUpper(TempKey^.Name^)=strUpper(Key) then Check:=true;
  end;
begin
  CheckKey:=False;
  If Keys^.FirstThat(@Check)<>nil then CheckKey:=True;
end;

Function TParamString.GetKey(Key:string):string;
var
  PTemp : PKey;

  Function Check(P:Pointer):boolean;far;
  Var
    TempKey : PKey absolute P;
  begin
     Check:=false;
     If strUpper(TempKey^.Name^)=strUpper(Key) then Check:=true;
  end;
begin
  GetKey:='';

  PTemp:=Keys^.FirstThat(@Check);
  If (PTemp<>nil) and (PTemp^.Value<>nil) then GetKey:=PTemp^.Value^;
end;


Function TParamString.CheckParameter(Parameter:string):boolean;
  Function Check(P:Pointer):boolean;far;
  Var
    TempParameter : PString absolute P;
  begin
     Check:=false;
     If strUpper(TempParameter^)=strUpper(Parameter) then Check:=true;
  end;
Begin
  CheckParameter:=False;

  If Parameters^.FirstThat(@Check)<>nil then CheckParameter:=True;
end;

end.
