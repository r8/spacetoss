{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8bcl;

interface

Uses
  r8alst,
  r8str,
  r8dtm,
  r8ftn,
  objects,
  r8objs;

Type
  TBCLHead = record
    Sig         : array[1..4] of char;
    ConfMgrName : array[1..31] of char;
    Origin      : array[1..51] of char;
    Date        : longint;
    Flags       : longint;
    Destination : array[1..51] of char;
    Reserved    : array[1..206] of char;
  end;

  TBCLItem = record
    EntryLength : integer;
    Flags1      : longint;
    Flags2      : longint;
  end;

  TBCL = object(TArealist)
    BCLHead : TBCLHead;

    Constructor Init;
    Destructor Done;virtual;

    Procedure Read;virtual;
    Procedure Write;virtual;
    Function GetAddressStr:string;
    Procedure GetAddress(var Address:TAddress);
    Procedure GetAddressDest(var Address:TAddress);
    Function GetAddressDestStr:string;
    Procedure SetAddress(Address:TAddress);
    Procedure SetAddressDest(Address:TAddress);
    Procedure SetMgrName(S:string);
  end;

  PBCL = ^TBCL;

implementation

Constructor TBCL.Init;
begin
  inherited Init;
end;

Destructor TBCL.Done;
begin
  inherited Done;
end;

Procedure TBCL.Read;
Var
 S:PBufStream;
 TempArea : PEArealistitem;
 BCLItem : TBCLItem;
 iTemp:longint;
 sTemp:string;
 Name, Desc : string;
begin
  S:=New(PBufStream,Init(FileName^,stOpen,$1000));

  If (IOResult<>0) or (S^.Status<>stOk) then
    begin
      Status:=alstCantOpenFile;
      exit;
    end;

  iTemp:=S^.GetSize;

  S^.Read(BCLHead,SizeOf(BCLHead));

  While S^.GetPos<iTemp-1 do
    begin
      S^.Read(BCLItem,SizeOf(BCLItem));

      Name:=objStreamReadLn(S);
      Desc:=objStreamReadLn(S);
      sTemp:=objStreamReadLn(S);

      TempArea:=New(PEArealistitem,Init(Name,Desc));

      ListAreas^.Insert(TempArea);
    end;

  objDispose(S);
end;

Function TBCL.GetAddressStr:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(BCLHead.Origin));
  Move(BCLHead.Origin,sTemp[1],SizeOf(BCLHead.Origin));
  GetAddressStr:=strTrimR(sTemp,[#0]);
end;

Procedure TBCL.SetAddress(Address:TAddress);
Var
  sTemp:string;
begin
  sTemp:=ftnAddressToStrEx(Address);

  FillChar(BCLHead.Origin,SizeOf(BCLHead.Origin),#0);

  Move(sTemp[1],BCLHead.Origin,Length(sTemp));
end;

Function TBCL.GetAddressDestStr:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(BCLHead.Destination));
  Move(BCLHead.Destination,sTemp[1],SizeOf(BCLHead.Destination));
  GetAddressDestStr:=strTrimR(sTemp,[#0]);
end;

Procedure TBCL.SetAddressDest(Address:TAddress);
Var
  sTemp:string;
begin
  sTemp:=ftnAddressToStrEx(Address);

  FillChar(BCLHead.Destination,SizeOf(BCLHead.Destination),#0);

  Move(sTemp[1],BCLHead.Destination,Length(sTemp));
end;

Procedure TBCL.SetMgrName(S:string);
begin
  FillChar(BCLHead.ConfMgrName,SizeOf(BCLHead.ConfMgrName),#0);

  Move(S[1],BCLHead.ConfMgrName,Length(S));
end;

Procedure TBCL.Write;
Var
 S:PBufStream;
 TempArea : PEArealistitem;
 BCLItem : TBCLItem;
 i:longint;
begin
  S:=New(PBufStream,Init(FileName^,stCreate,$1000));

  BCLHead.Sig[1]:='B';
  BCLHead.Sig[2]:='C';
  BCLHead.Sig[3]:='L';
  BCLHead.Sig[4]:=#0;
  BCLHead.Date:=dtmGetDateTimeUnix;
  BCLHead.Flags:=1;

  S^.Write(BCLHead,SizeOf(BCLHead));

  For i:=0 to ListAreas^.Count-1 do
    begin
      TempArea:=ListAreas^.At(i);

      FillChar(BCLItem,SizeOf(BCLItem),#0);
      BCLItem.EntryLength:=SizeOf(BCLItem)+Length(TempArea^.AreaName^)+2;

      If TempArea^.AreaDesc<>nil then
         BCLItem.EntryLength:=BCLItem.EntryLength+Length(TempArea^.AreaDesc^)+1;

      BCLitem.Flags1:=8;


      S^.Write(BCLItem,SizeOf(BCLItem));
      objStreamWrite(S,TempArea^.AreaName^+#0);
      If TempArea^.AreaDesc<>nil then
        objStreamWrite(S,TempArea^.AreaDesc^+#0);
      objStreamWrite(S,#0);
    end;

  objDispose(S);
end;

Procedure TBCL.GetAddress(var Address:TAddress);
begin
  ftnStrToAddress(GetAddressStr,Address);
end;

Procedure TBCL.GetAddressDest(var Address:TAddress);
begin
  ftnStrToAddress(GetAddressDestStr,Address);
end;

end.
