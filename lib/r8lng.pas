Unit r8lng;

interface

Uses
  r8objs,
  r8dos,
  r8mcr,
  r8str,
  crt,
  objects;

const
  lngNone           = $0000;
  lngInvalidVersion = $0001;
  lngInvalidFile    = $0002;

Type

  TLngFile = object(TObject)
    Status   : longint;

    FileName : PString;
    ProgName : PString;
    Version  : Longint;

    LngItems : PStringsCollection;
    LngMacros : PMacroEngine;

    Constructor Init(const AFileName, AProgName : string;const AVersion : Longint);
    Destructor  Done; virtual;
    Procedure AddLngItem(const S:string);
    Procedure AddVar(const S:string);
    Function GetString(const l:longint):string;

    Procedure LoadFile;
    Procedure SaveFile;
   end;

   PLngFile = ^TLngFile;

implementation

const
  constSig = 'r8Lng';

Constructor TLngFile.Init(const AFileName, AProgName:string;const AVersion:Longint);
begin
  inherited Init;

  FileName:=NewStr(AFileName);
  ProgName:=NewStr(AProgName);
  Version:=AVersion;

  Status:=lngNone;

  LngItems:=New(PStringsCollection,Init($10,$10));
  LngMacros:=New(PMacroEngine,Init);
end;

Destructor TLngFile.Done;
begin
  objDispose(LngItems);
  objDispose(LngMacros);
  DisposeStr(FileName);
  DisposeStr(ProgName);

  inherited Done;
end;

Procedure ReadStr(var F:file;var S:string);
Var
  c:byte;
  sTemp : string;
begin
  BlockRead(F,c,1);
  sTemp[0]:=Chr(c);
  BlockRead(F,sTemp[1],ord(C));
  S:=sTemp;
end;

Procedure TLngFile.AddLngItem(const S:string);
begin
  LngItems^.Insert(NewStr(S));
end;

Procedure TLngFile.AddVar(const S:string);
begin
  LngMacros^.AddMacro(strIntToStr(LngMacros^.MacroLib^.Count+1),S,True);
end;

Procedure TLngFile.LoadFile;
Var
  St:PStream;

  TempSig : string;
  TempName : string;
  TempVersion : longint;

  sTemp:string;
  lTemp:longint;
begin
  Status:=lngNone;

  If not dosFileExists(FileName^) then
    begin
      Status:=lngInvalidVersion;
      exit;
    end;

  St:=New(PBufStream,Init(FileName^,stOpenRead,cBuffSize));

  TempSig:=objStreamReadStr(St);
  TempName:=objStreamReadStr(St);
  St^.Read(TempVersion,SizeOf(TempVersion));

  If (ProgName=nil) or (St^.Status<>stOk) or (TempSig<>constSig)
     or (TempName<>ProgName^) or (TempVersion<>Version)
  then
    begin
      Status:=lngInvalidVersion;
      exit;
    end;

  lTemp:=St^.GetSize;
  While St^.GetPos<lTemp do
    begin
      sTemp:=objStreamReadStr(St);
      AddLngItem(sTemp);
    end;

  objDispose(St);
end;

Procedure TLngFile.SaveFile;
Var
  St:PStream;
  sTemp:string;

  Procedure WriteItem(Item:pointer);
  begin
    objStreamWriteStr(St,PString(Item)^);
  end;

begin
  St:=New(PBufStream,Init(FileName^,stCreate,cBuffSize));

  sTemp:=constSig;
  objStreamWriteStr(St,sTemp);
  objStreamWriteStr(St,ProgName^);
  St^.Write(Version,SizeOf(Version));

  LngItems^.ForEach(@WriteItem);

  objDispose(St);
end;

Function TLngFile.GetString(const l:longint):string;
Var
  pTemp : pString;
  sTemp : string;
begin
  pTemp:=LngItems^.At(l);
  sTemp:=pTemp^;
  LngMacros^.ProcessString(sTemp);

  GetString:=sTemp;

  LngMacros^.MacroLib^.FreeAll;
end;

end.
