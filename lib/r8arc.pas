{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8Arc;

interface

Uses
  r8objs,
  r8mcr,
  dos,
  r8dos,
  r8str,
  r8ctl,
  objects;

const
  arcOk            = $00;
  arcFileNotFound  = $01;
  arcUnknownPacker = $02;
  arcPackerError   = $03;

Type

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  TArcItem = object(TObject)
    Name : PString;
    OffSet : longint;
    Ident : array[1..16] of char;
    IdentL : integer;

    Add : PString;
    Extract : PString;

    Constructor Init;
    Destructor Done;virtual;
  end;

  PArcItem = ^TArcItem;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TArcBase = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;

  PArcBase  = ^TArcBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TArcEngine = object(TObject)
    Status : byte;
    ErrorLevel : integer;

    Error : string;
    ArcBase : PArcBase;
    ArcCtl : PSectionCTL;
    ArcMcr : PMacroEngine;

    Constructor Init(const WorkDir:string);
    Destructor Done;virtual;

    Function LoadConfig(FileName:string):boolean;
    Function FindArc(Arcname:string):longint;
    Function FindArcName(Arc:string):longint;

    Procedure Extract(Arcname,FileMask:string);
    Procedure Add(Arcname,FileMask, ArcType:string);

    Function GetArcType(Arcname:string):string;
  end;

  PArcEngine = ^TArcEngine;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

implementation

Constructor TArcEngine.Init(const WorkDir:string);
begin
  inherited Init;

  ArcBase:=New(PArcBase,Init($10,$10));
  ArcMcr:=New(PMacroEngine,Init);

  ArcMcr^.AddMacro('%A','',False);
  ArcMcr^.AddMacro('%F','',False);
  ArcMcr^.AddMacro('%P','',False);

  ArcMcr^.ModifyMacro('%P',WorkDir);

  Error:='';
end;

Destructor TArcEngine.Done;
begin
  objDispose(Arcbase);
  objDispose(ArcCtl);
  Dispose(ArcMcr,Done);

  inherited Done;
end;

Procedure TArcBase.FreeItem(Item:pointer);
Begin
  objDispose(PArcItem(Item));
End;

Constructor TArcItem.Init;
begin
  inherited Init;
end;

Destructor TArcItem.Done;
begin
  DisposeStr(Name);
  DisposeStr(Add);
  DisposeStr(Extract);

  inherited Done;
end;

Function TArcEngine.LoadConfig(FileName:string):boolean;
Var
  TempArc:PArcItem;
  i,i2:integer;
  sTemp:string;
  sTemp1:string;
  SR:CTLSR;
begin
  LoadConfig:=False;

  ArcCTL:=New(PSectionCtl,Init('BEGINARC','ENDARC'));

  ArcCTL^.AddKeyword('Name');
  ArcCTL^.AddKeyword('Ident');
  ArcCTL^.AddKeyword('Add');
  ArcCTL^.AddKeyword('Extract');

  ArcCTL^.SetCTLName(FileName);
  ArcCTL^.LoadCTL;

  If ArcCTL^.CTLError<>ctlErrNone then
    begin
      Error:=ArcCTL^.ExplainStatus(ArcCTL^.CTLError);
      Exit;
    end;

  For i:=0 to ArcCTL^.GetSectionCount-1 do
    begin
      sTemp:=ArcCTL^.FindFirstValue(i,'Name',SR);
      If ArcCTL^.CTLError<>0 then continue;

      sTemp1:=ArcCTL^.FindFirstValue(i,'Ident',SR);
      If ArcCTL^.CTLError<>0 then continue;

      TempArc:=New(PArcItem,Init);

      TempArc^.Name:=NewStr(strUpper(sTemp));

      sTemp:=sTemp1;

      sTemp1:=strParser(sTemp1,1,[',']);
      TempArc^.Offset:=strStrToInt(sTemp1);
      sTemp1:=strTrimB(strParser(sTemp,2,[',']),[#32,#8]);

      TempArc^.IdentL:=Length(sTemp1) div 2;

      If TempArc^.IdentL<>(Length(sTemp1) / 2) then
        begin
          objDispose(TempArc);
          continue;
        end;

     FillChar(TempArc^.Ident,SizeOf(TempArc^.Ident),#0);

      For i2:=1 to TempArc^.IdentL do
        begin
          sTemp:=sTemp1[i2*2-1]+sTemp1[i2*2];
          TempArc^.Ident[i2]:=Chr(strHexToInt(sTemp));
        end;

      TempArc^.Add:=NewStr(ArcCTL^.FindFirstValue(i,'Add',SR));
      TempArc^.Extract:=NewStr(ArcCTL^.FindFirstValue(i,'Extract',SR));

      ArcBase^.Insert(TempArc);

    end;

  objDispose(ArcCtl);

  LoadConfig:=True;
end;

Function EqualSig(var Sig1,Sig2:array of char):boolean;
Var
  i:integer;
begin
  EqualSig:=True;

  For i:=0 to 15 do
    if Sig1[i]<>Sig2[i] then
      begin
        EqualSig:=False;
        Exit;
      end;
end;

Function TArcEngine.FindArc(Arcname:string):longint;
Var
  TempArcItem : PArcItem;
  Sig : array[1..16] of char;
  i:integer;
  F:file;
  Size:longint;
begin
  FindArc:=-1;

  Assign(F,Arcname);
{$I-}
  Reset(F,1);
{$I+}

  If IOResult<>0 then exit;

  Size:=FileSize(F);

  If Size=0 then exit;

  For i:=0 to Arcbase^.Count-1 do
    begin
      TempArcItem:=ArcBase^.At(i);

      FillChar(Sig,16,#0);

{$I-}
      Seek(F,TempArcItem^.Offset);

      BlockRead(F,Sig,TempArcItem^.IdentL);
{$I+}
      If IOResult<>0 then continue;

      If EqualSig(TempArcitem^.Ident,Sig) then
        begin
          FindArc:=i;
          break;
        end;

    end;

  Close(F);
end;

Function TArcEngine.FindArcName(Arc:string):longint;
Var
  TempArcItem : PArcItem;
  i:integer;
begin
  FindArcName:=-1;

  For i:=0 to Arcbase^.Count-1 do
    begin
      TempArcItem:=ArcBase^.At(i);

      If TempArcitem^.Name^=strUpper(Arc) then
        begin
          FindArcName:=i;
          break;
        end;

    end;
end;

Procedure TArcEngine.Extract(Arcname,FileMask:string);
var
  iTemp:longint;
  TempArcItem : PArcItem;
  sTemp:string;
  Name,Params:string;
begin
  Status:=arcOk;
  ErrorLevel:=0;

  If not dosFileExists(Arcname) then
    begin
      Status:=arcFileNotFound;
      exit;
    end;

  iTemp:=FindArc(ArcName);
  If iTemp=-1 then
    begin
      Status:=arcUnknownPacker;
      exit;
    end;

  TempArcItem:=ArcBase^.At(iTemp);

  ChDir(dosGetPath(ArcName));

  ArcMcr^.ModifyMacro('%A',ArcName);
  ArcMcr^.ModifyMacro('%F',FileMask);

  sTemp:='';
  If TempArcItem^.Extract<>nil then sTemp:=TempArcItem^.Extract^;

  ArcMcr^.ProcessString(sTemp);

  strSplitWords(sTemp,Name,Params);
  Errorlevel:=dosExec(Name,Params);

  If ErrorLevel<>0 then Status:=arcPackerError;
end;

Procedure TArcEngine.Add(Arcname,FileMask, ArcType:string);
var
  iTemp:longint;
  TempArcItem : PArcItem;
  sTemp:string;
  Name,Params:string;
begin
  Status:=arcOk;
  ErrorLevel:=0;

  iTemp:=FindArcName(ArcType);
  If iTemp=-1 then
    begin
      Status:=arcUnknownPacker;
      exit;
    end;

  TempArcItem:=ArcBase^.At(iTemp);

  ChDir(dosGetPath(ArcName));

  ArcMcr^.ModifyMacro('%A',ArcName);
  ArcMcr^.ModifyMacro('%F',FileMask);

  sTemp:='';
  If TempArcItem^.Add<>nil then sTemp:=TempArcItem^.Add^;

  ArcMcr^.ProcessString(sTemp);

  strSplitWords(sTemp,Name,Params);
  Errorlevel:=dosExec(Name,Params);

  If ErrorLevel<>0 then Status:=arcPackerError;
end;

Function TArcEngine.GetArcType(Arcname:string):string;
var
  i:longint;
begin
  i:=FindArc(Arcname);
end;

end.
