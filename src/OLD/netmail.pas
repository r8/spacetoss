{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Netmail;

interface

Uses
  r8mail,
  r8abs,
  dos,
  r8dtm,
  r8mbe,
  r8objs,
  r8ftn,
  r8str,
  crt,
  afix,
  objects;

Type

 TNetmailItem = object(TObject)
   Address : PString;
   Name : PString;
   Run : PString;
   Path : PString;
   AutoExport : boolean;

   Constructor Init;
   Destructor  Done; virtual;
 end;

 PNetmailItem = ^TNetmailItem;

 TNetmailCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
 end;

 PNetmailCollection = ^TNetmailCollection;

 TNetmailBase = object(TObject)
   Netmails : PNetmailCollection;
   Runs : PStringsCollection;

   Constructor Init;
   Destructor Done;virtual;
   Procedure AddRun(S:string);
   Function FindNetmail(const Path:string):longint;
 end;

 PNetmailBase = ^TNetmailBase;

Procedure DoImport;
Procedure DoExport;

implementation
Uses
   global;


Constructor TNetmailItem.Init;
begin
  inherited Init;

  Address:=nil;
  Name:=nil;
  Run:=nil;
  Path:=nil;
end;

Destructor  TNetmailItem.Done;
begin
  DisposeStr(Address);
  DisposeStr(Name);
  DisposeStr(Run);
  DisposeStr(Path);

  inherited Done;
end;

Procedure TNetmailCollection.FreeItem(item:pointer);
begin
  objDispose(PNetmailItem(Item));
end;

Constructor TNetmailBase.Init;
begin
  inherited init;

  Netmails:=New(PNetmailCollection,Init($10,$10));
  Runs:=New(PStringsCollection,Init($10,$10));
end;

Destructor TNetmailBase.Done;
begin
  objDispose(Netmails);
  objDispose(Runs);
  inherited done;
end;

Procedure CopyMessage(TempNetmail : PNetmailItem);
Var
  TempBase : PMessageBase;
  TempAddress:TAddress;
  BodyStream : PStream;
  Flags  : longint;
  Datetime : TDatetime;
begin
{  TempBase:=MessageBasesEngine^.OpenOrCreateBase(TempNetmail^.Path^);
  TempBase^.SetBaseType(btNetmail);

  TempBase^.CreateMessage(False);

  TempBase^.SetTo(NetmailDir^.GetTo);
  TempBase^.SetFrom(NetmailDir^.GetFrom);
  TempBase^.SetSubj(NetmailDir^.GetSubj);
  NetmailDir^.GetFlags(Flags);
  TempBase^.SetFlags(Flags);

  TempBase^.ClearFlag(flgLocal);
  TempBase^.ClearFlag(flgHold);
  TempBase^.ClearFlag(flgKill);
  TempBase^.ClearFlag(flgTransit);

  NetmailDir^.GetDateWritten(DateTime);
  TempBase^.SetDateWritten(DateTime);

  BodyStream:=NetmailDir^.MessageBody^.GetMsgBodyStream;
  TempBase^.MessageBody^.AddToMsgBodyStream(BodyStream);

  objDispose(BodyStream);

  NetmailDir^.GetFromAddress(TempAddress);
  TempBase^.SetFromAddress(TempAddress);

  WriteLn('Importing message from ',ftnAddressToStrEx(TempAddress),'...');

  NetmailDir^.GetToAddress(TempAddress);
  TempBase^.SetToAddress(TempAddress);

  AddressBase^.FindNearest(TempAddress,TempAddress);
  objStreamWriteLn(TempBase^.MessageBody^.ViaLink,
      #1'Forwarded by '+constPid+' '+ftnAddressToStrExDomain(TempAddress)+', '
      +dtmGetDateTimeStr);

  TempBase^.WriteMessage;
  TempBase^.CloseMessage;
  TempBase^.Close;

  NetmailDir^.SetFlag(flgSent);
  NetmailDir^.WriteMessage;
  If (NetmailDir^.CheckFlag(flgKill))
     or (KillAfterImport)
        then NetmailDir^.KillMessage;

  MessageBasesEngine^.DisposeBase(TempBase);}
end;

Procedure TNetmailBase.AddRun(S:string);
Var
 i:integer;
 pTemp:pString;
begin
  For i:=0 to Runs^.Count-1 do
    begin
      pTemp:=Runs^.At(i);
      If pTemp^=S then exit;
    end;

  Runs^.Insert(NewStr(S));
end;

Procedure ScanMainNetmail;
Var
  i,i2:integer;
  TempAddress : TAddress;
  StringAddress : string;
  StringAddressFull : string;
  TempTo : string;

  TempNetmail : PNetmailItem;
  iTemp:longint;
begin
{  NetmailDir^.Seek(0);

  For i:=0 to NetmailDir^.GetCount-1 do
    begin
      NetmailDir^.OpenMessage;

      NetmailDir^.GetToAddress(TempAddress);
      TempTo:=strUpper(NetmailDir^.GetTo);

      StringAddressFull:=ftnAddressToStr(TempAddress);
      StringAddress:=ftnAddressToStrEx(TempAddress);

    If (not NetmailDir^.CheckFlag(flgLocked)) and
     (not NetmailDir^.CheckFlag(flgSent))
    then
      for i2:=0 to NetmailBase^.Netmails^.Count-1 do
        begin

          TempNetmail:=NetmailBase^.Netmails^.At(i2);


          If (strWildCard(TempTo,TempNetmail^.Name^))
           and
           ((strWildCard(StringAddress,TempNetmail^.Address^)) or
             (strWildCard(StringAddressFull,TempNetmail^.Address^)))
             then
               begin
                 CopyMessage(TempNetmail);
                 If TempNetmail^.Run^<>'' then
                          NetmailBase^.AddRun(TempNetmail^.Run^);
                 break;
               end;
        end;

      NetmailDir^.CloseMessage;
      NetmailDir^.SeekNext;
    end;

  NetmailDir^.Close;}
end;

Procedure DoRuns;
Var
 i:integer;
 pTemp:pString;
begin
  Writeln('Executing processes...');
  Writeln;

  For i:=0 to NetmailBase^.Runs^.Count-1 do
    begin
      pTemp:=NetmailBase^.Runs^.At(i);

      WriteLn('Executing ',pTemp^,'...');
      Writeln(constLongLine);
      Exec(GetEnv('COMSPEC'),' /C '+pTemp^);
      Writeln(constLongLine);
      writeln;
    end;

end;

Procedure DoImport;
begin
  TextColor(7);

  Writeln('Importing netmail messages...');
  WriteLn;

  LogFile^.SendStr('Importing netmail messages...',#32);

  ScanMainNetmail;
  WriteLn;

  LogFile^.SendStr('Done!',#32);

  DoRuns;

  If ParamString^.CheckKey('A') then Areafix^.ScanNetmail;
end;

Procedure ExportMessage(TempBase:PMessageBase);
Var
  TempAddress:TAddress;
  BodyStream : PStream;
  Flags  : longint;
  Datetime : TDatetime;
  AbsMessage : PAbsMessage;
begin
(*  NetmailDir^.CreateMessage(False);

  AbsMessage:=TempBase^.GetAbsMessage;

  WriteLn('Exporting message to ',ftnAddressToStrEx(AbsMessage^.FromAddress),'...');

  NetmailDir^.SetAbsMessage(AbsMessage);

  TempBase^.SetFlag(flgSent);
  NetmailDir^.ClearFlag(flgLocal);
  NetmailDir^.ClearFlag(flgKill);
  NetmailDir^.SetFlag(flgTransit);

{  AddressBase^.FindNearest(TempAddress,TempAddress);
  objStreamWriteLn(NetmailDir^.MessageBody^.ViaLink,
      #1'Forwarded by '+constPid+' '+ftnAddressToStrExDomain(TempAddress)+', '
      +dtmGetDateTimeStr);}

  NetmailDir^.WriteMessage;
  NetmailDir^.MessageBody:=nil;
  NetmailDir^.CloseMessage;

  TempBase^.WriteMessage;

  If TempBase^.CheckFlag(flgKill)
            then TempBase^.KillMessage;
  TempBase^.CloseMessage; *)
end;

Procedure ProcessArea(TempNetmail:PNetmailItem);
Var
  i:integer;
begin
{  EchoBase:=MessageBasesEngine^.OpenOrCreateBase(TempNetmail^.Path^);
  If EchoBase=nil then exit;
  EchoBase^.SetBaseType(btNetmail);
  EchoBase^.Seek(0);

  EchoBase^.SeekNext;
  While EchoBase^.Status=mlOk do
    begin
      EchoBase^.OpenMessage;

      If (EchoBase^.CheckFlag(flgLocal))
        and (not EchoBase^.CheckFlag(flgSent))
         and (not EchoBase^.CheckFlag(flgLocked))
          then ExportMessage(EchoBase);

      EchoBase^.CloseMessage;
      EchoBase^.SeekNext;
    end;

  EchoBase^.Close;
  MessageBasesEngine^.DisposeBase(EchoBase);}
end;

Procedure DoExport;
Var
  i:integer;
  TempNetmail : PNetmailItem;
begin
  TextColor(7);

  Writeln('Exporting netmail messages...');
  WriteLn;

  LogFile^.SendStr('Exporting netmail messages...',#32);

  For i:=0 to NetmailBase^.Netmails^.Count-1 Do
    begin
      TempNetmail:=NetmailBase^.Netmails^.At(i);
      ProcessArea(TempNetmail);
    end;

  LogFile^.SendStr('Done!',#32);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}

Function TNetmailBase.FindNetmail(const Path:string):longint;
Var
  TempNetmail : PNetmailItem;
  i:longint;
begin
  FindNetmail:=-1;

  For i:=0 to Netmails^.Count-1 do
    begin
      TempNetmail:=Netmails^.At(i);
      If strUpper(TempNetmail^.Path^)=strUpper(Path) then FindNetmail:=i;
    end;
end;

end.
