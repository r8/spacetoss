{
 Dupe Engine for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Dupe;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
  {$PackRecords 1}
{$ENDIF}

interface

Uses
  r8objs,
  r8ftn,
  r8abs,
  r8str,
  r8dtm,
  r8crc,
  r8dos,
  objects;

const
  constDupeSig = 'r8Dupe';

Type
  TDupeItem = record
    Hash      : longint;
    TimeStamp : longint;
  end;
  PDupeItem = ^TDupeItem;

  THashCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PHashCollection = ^THashCollection;

  TTimeStampCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PTimeStampCollection = ^TTimeStampCollection;

  TDupeEngine = object(TObject)
    DupeFileName : PString;
    DupeFile : PStream;
    MaxDupes : longint;

    HashCollection : PHashCollection;
    TimeStampCollection : PTimeStampCollection;

    Procedure OpenDupeFile(const F:string);
    Procedure SaveDupeFile;
    Function CheckDupe(const Message:PAbsMessage):boolean;

    Constructor Init(const AMaxDupes:longint);
    Destructor Done;virtual;
  end;
  PDupeEngine = ^TDupeEngine;

implementation

Constructor TDupeEngine.Init(const AMaxDupes:longint);
begin
  inherited Init;
  DupeFileName:=nil;

  MaxDupes:=AMaxDupes;

  HashCollection:=New(PHashCollection,Init($800,$800));
  TimeStampCollection:=New(PTimeStampCollection,Init($800,$800));

  HashCollection^.Duplicates:=False;
  TimeStampCollection^.Duplicates:=True;
end;

Destructor TDupeEngine.Done;
begin
  DisposeStr(DupeFileName);

  objDispose(HashCollection);
  objDispose(TimeStampCollection);

  inherited Done;
end;

Procedure TDupeEngine.OpenDupeFile(const F:string);
Var
  Sig : string[6];
  TempDupe : PDupeItem;
  i : longint;
begin
  DupeFileName:=NewStr(F);

  If not dosFileExists(F) then exit;

  DupeFile:=New(PBufStream,Init(DupeFileName^,fmOpen or fmRead or fmDenyAll,$4000));

  i:=DupeFile^.GetSize;

  DupeFile^.Read(Sig,SizeOf(Sig));

  If Sig<>constDupeSig then
    begin
      objDispose(DupeFile);
      exit;
    end;

  While DupeFile^.GetPos<i-1 do
    begin
      TempDupe:=New(PDupeItem);
      DupeFile^.Read(TempDupe^,SizeOf(TempDupe^));

      HashCollection^.Insert(TempDupe);
      TimeStampCollection^.AtInsert(TimeStampCollection^.Count,TempDupe);
    end;

  objDispose(DupeFile);
end;

Procedure TDupeEngine.SaveDupeFile;
Var
  Sig:string[6];
  TempDupe : PDupeItem;

  Procedure WriteDupe(P:pointer);far;
  begin
    DupeFile^.Write(PDupeItem(P)^,SizeOf(TDupeItem));
  end;

begin
  dosErase(DupeFileName^);

  If TimeStampCollection^.Count=0 then exit;

  DupeFile:=New(PBufStream,Init(DupeFileName^,fmCreate or fmWrite or fmDenyAll,$4000));

  Sig:=constDupeSig;
  DupeFile^.Write(Sig,SizeOf(Sig));

  While TimeStampCollection^.Count>MaxDupes
    do TimeStampCollection^.AtFree(0);

  TimeStampCollection^.ForEach(@WriteDupe);

  objDispose(DupeFile);
end;

Function TDupeEngine.CheckDupe(const Message:PAbsMessage):boolean;
Var
  TempDupe : PDupeItem;
  sTemp : string;
  lTemp : longint;
begin
  CheckDupe:=True;

  TempDupe:=New(PDupeItem);

  TempDupe^.TimeStamp:=dtmGetDateTimeUnix;

  TempDupe^.Hash:=$FFFFFFFF;

  If Message^.FromName<>nil
    then TempDupe^.Hash:=crcUpdateStringCRC32(Message^.FromName^,TempDupe^.Hash);
  If Message^.ToName<>nil
    then TempDupe^.Hash:=crcUpdateStringCRC32(Message^.ToName^,TempDupe^.Hash);
  If Message^.Area<>nil
    then TempDupe^.Hash:=crcUpdateStringCRC32(Message^.Area^,TempDupe^.Hash);

  TempDupe^.Hash:=crcUpdateStringCRC32(Message^.MessageBody^.Kludgebase^.
    GetKludge('MSGID:'),TempDupe^.Hash);

  lTemp:=dtmDateToUnix(Message^.DateTime);
  TempDupe^.Hash:=crcUpdateCRC32(Hi(Long(lTemp).HighWord),TempDupe^.Hash);
  TempDupe^.Hash:=crcUpdateCRC32(Lo(Long(lTemp).HighWord),TempDupe^.Hash);
  TempDupe^.Hash:=crcUpdateCRC32(Hi(Long(lTemp).LowWord),TempDupe^.Hash);
  TempDupe^.Hash:=crcUpdateCRC32(Lo(Long(lTemp).LowWord),TempDupe^.Hash);

  lTemp:=HashCollection^.Count;
  HashCollection^.Insert(TempDupe);
  If HashCollection^.Count=lTemp then
    begin
      Dispose(TempDupe);
      exit;
    end;

  TimeStampCollection^.Insert(TempDupe);
  CheckDupe:=False;
end;

Procedure THashCollection.FreeItem(Item:pointer);
begin
{  If Item<>nil then Dispose(PDupeItem(Item));}
end;

Procedure TTimeStampCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then Dispose(PDupeItem(Item));
end;

{$IFDEF VER70}
Function THashCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function THashCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  A : PDupeItem absolute Key1;
  B : PDupeItem absolute Key2;
begin
  If A^.Hash>B^.Hash then Compare:=1 else
  If A^.Hash<B^.Hash then Compare:=-1 else
  Compare:=0;
end;

{$IFDEF VER70}
Function TTimeStampCollection.Compare(Key1, Key2: Pointer):integer;
{$ELSE}
Function TTimeStampCollection.Compare(Key1, Key2: Pointer):longint;
{$ENDIF}
Var
  A : PDupeItem absolute Key1;
  B : PDupeItem absolute Key2;
begin
  If A^.TimeStamp>B^.TimeStamp then Compare:=1 else
  If A^.TimeStamp<B^.TimeStamp then Compare:=-1 else
  Compare:=0;
end;

end.
