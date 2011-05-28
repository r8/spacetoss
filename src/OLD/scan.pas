{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Scan;

interface
Uses
  areas,
  crt,
  bats,
  arc,
  r8ftn,
  r8dtm,
  r8pkt,
  r8mbe,
  r8mail,
  r8objs,
  toss,
  objects,
  tsl,
  global;

var
  QueueDir : PPktDir;

Procedure DoScan;

implementation

Procedure ExportMessage(Area:PArea;EchoBase:PMessageBase);
Var
  TempAddress :tAddress;
  DateTime : TDateTime;
  S : PStream;
begin
  WriteLn('Exporting message from ',Area^.Name^,'...');
  LogFile^.SendStr('Exporting message from '+Area^.Name^+'...','@');

  QueueDir^.CreateNewPkt;
  QueueDir^.Packet^.SetPktAreaType(btEchomail);
  QueueDir^.Packet^.WritePkt;

  QueueDir^.Packet^.CreateNewMsg(False);

  QueueDir^.Packet^.SetMsgTo(EchoBase^.GetTo);
  QueueDir^.Packet^.SetMsgFrom(EchoBase^.GetFrom);
  QueueDir^.Packet^.SetMsgSubj(EchoBase^.GetSubj);
  QueueDir^.Packet^.SetMsgArea(Area^.Name^);

  EchoBase^.GetFromAddress(TempAddress);
  QueueDir^.Packet^.SetMsgFromAddress(TempAddress);

  EchoBase^.GetToAddress(TempAddress);
  QueueDir^.Packet^.SetMsgToAddress(TempAddress);

  S:=EchoBase^.MessageBody^.GetMsgBodyStream;
  QueueDir^.Packet^.MessageBody^.AddToMsgBodyStream(S);
  objDispose(S);

  QueueDir^.Packet^.MessageBody^.KludgeBase^.SetKludge('TID:',constPID);

  EchoBase^.GetDateWritten(DateTime);
  QueueDir^.Packet^.SetMsgDateTime(DateTime);

  QueueDir^.Packet^.WriteMsg;
  QueueDir^.Packet^.CloseMsg;

  EchoBase^.SetFlag(flgSent);
  EchoBase^.WriteMessage;

  QueueDir^.ClosePkt;
end;

Procedure ProcessArea(Area:PArea);
Var
  i:integer;
  TempExport : PExportItem;
  lTemp : LINT;
  Delta : integer;
  sTemp : string;
begin

  If (Area^.EchoType.Storage=etJam) and (ExportListsPath<>'') then
    begin
      sTemp:=Copy(Area^.Echotype.Path,4,Length(Area^.Echotype.Path)-3);

      i:=EchomailJam^.FindArea(sTemp);
      If i=-1 then exit;

      TempExport:=EchomailJam^.Areas^.At(i);
      EchoBase:=MessageBasesEngine^.OpenOrCreateBase(Area^.EchoType.Path);
      If EchoBase=nil then exit;

      Delta:=0;

      For i:=0 to TempExport^.Numbers^.Count-1 do
        begin
          lTemp:=TempExport^.Numbers^.At(i);

          EchoBase^.Seek(lTemp^-Delta-1);
          EchoBase^.OpenMessage;
          If (not EchoBase^.CheckFlag(flgSent))
               and (EchoBase^.CheckFlag(flgLocal)) then
            begin
               ExportMessage(Area,EchoBase);
{               Inc(Delta);}
            end;
          EchoBase^.CloseMessage;

        end;

     EchoBase^.Close;
     objDispose(EchoBase);
     exit;
    end;

  EchoBase:=MessageBasesEngine^.OpenOrCreateBase(Area^.EchoType.Path);
  If EchoBase=nil then exit;

      For i:=0 to EchoBase^.GetCount-1 do
        begin
          EchoBase^.Seek(i);
          EchoBase^.OpenMessage;
          If (not EchoBase^.CheckFlag(flgSent))
               and (EchoBase^.CheckFlag(flgLocal))
               then ExportMessage(Area,EchoBase);
          EchoBase^.CloseMessage;
        end;

  EchoBase^.Close;
  objDispose(EchoBase);
end;

Procedure ScanAll;
var
  i:longint;
  TempArea : PArea;
begin
  For i:=0 to AreaBase^.Areas^.Count-1 Do
    begin
      TempArea:=AreaBase^.Areas^.At(i);
      If (TempArea^.Echotype.Storage<>etPassthrough)
{         and (TempArea^.Echotype.Storage<>etHudson)}
         and (not TempArea^.CheckFlag('L'))
            then ProcessArea(TempArea);
    end;
end;

Procedure ScanAreas;
begin
  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('P$P');
  QueueDir^.OpenDir(QueuePath);

  ScanAll;

  QueueDir^.CloseDir;
  objDispose(QueueDir);
end;

Procedure DoScan;
begin
  TextColor(7);

  Writeln('Scanning for outgoing messages...');
  WriteLn;
  LogFile^.SendStr('Scanning for outgoing messages...',#32);

  If ParamString^.CheckKey('E') then
    begin
      LogFile^.SendStr('Disabling use of echomail.jam...','#');
      ExportListsPath:='';
    end;

  EchoMailJAM:=New(PExportList,Init);
  If ExportListsPath<>'' then
    begin
      EchoMailJAM^.Path:=NewStr(ExportListsPath+'\echomail.jam');
      EchoMailJAM^.Read;
    end;

  ScanAreas;

  objDispose(EchoMailJAM);

{  CheckSecurity:=False;
  Scanning:=True;
  ProcessTrack:=True;   }
  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('QQQ');
  ExportNodes:=New(PNodelist,Init($10,$10));
  QueueDir^.OpenDir(QueuePath);
  QueueDir^.FastOpen:=True;

  DoAfterScan;

{  TossPackets(QueuePath,'P$P');}

  DoBeforePack;

  WriteLn;
  Writeln('Packing outbound mail...');
  WriteLn;

{  PackQueue;}

  DoAfterPack;
end;

end.
