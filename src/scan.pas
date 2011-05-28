{
 Scanner Engine for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Scan;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  lng,
  areas,
  arc,
  bats,
  color,
  eJam,

  r8pkt,
  r8abs,
  r8mail,
  r8objs,
  r8str,
  r8ftn,
  r8sqh,

  regexp,

  crt,
  objects;

const
  scnOk = $00000000;

  scnDontUseHighwaters = $00000001;
  scnProcessingFile    = $00000002;

Type

  TScanner = object(TObject)
    Flags : Longint;

    Areas : PAreaCollection;

    QueueDir : PPktDir;
    Exporter : Pointer;
    Arcer : PArcer;
    EchomailJam : PeJam;

    Constructor Init(const AFlags:longint;const AreasToScan:PAreaCollection);
    Destructor  Done; virtual;

    Procedure Scan;virtual;

    Procedure ScanMSG(const Area:PArea);
    Procedure ScanSQH(const Area:PArea);
    Procedure ScanJAM(const Area:PArea);

    Procedure ScanRAW(const Area:PArea);virtual;

    Procedure ExportMessage(const Area:PArea);virtual;

    Procedure OpenBase(const Area:PArea);
    Procedure CloseBase(const Area:PArea);

    Procedure FailedToOpenBase(const BaseName:string);
  end;
  PScanner = ^TScanner;

implementation

Uses
  toss,
  global;

Constructor TScanner.Init(const AFlags:longint;const AreasToScan:PAreaCollection);
begin
  inherited Init;

  Flags:=AFlags;
  Areas:=AreasToScan;
end;

Destructor  TScanner.Done;
begin
  inherited Done;
end;

Procedure TScanner.ExportMessage(const Area:PArea);
Var
  AbsMessage : PAbsMessage;
  sTemp : string;
  lTemp : longint;
begin
  LngFile^.AddVar(Area^.Name^);
  sTemp:=LngFile^.GetString(LongInt(lngExportingMessage));
  GotoXY(1,WhereY);
  WriteLn(strPadR(sTemp,#32,79));
  LogFile^.SendStr(sTemp,'@');

  QueueDir^.CreateNewPkt;
  QueueDir^.Packet^.SetPktAreaType(btEchomail);
  QueueDir^.Packet^.WritePkt;

  QueueDir^.Packet^.CreateNewMsg(False);

  Area^.MessageBase^.OpenMessage;
  AbsMessage:=Area^.MessageBase^.GetAbsMessage;
  AbsMessage^.Area:=NewStr(Area^.Name^);

  QueueDir^.Packet^.SetAbsMessage(AbsMessage,False);
  QueueDir^.Packet^.MessageBody^.KludgeBase^.SetKludge('TID:',constPID);
  lTemp:=QueueDir^.Packet^.GetMsgFlags-flgLocal;
  QueueDir^.Packet^.SetMsgFlags(lTemp);
  QueueDir^.Packet^.WriteMsg;
  QueueDir^.Packet^.MessageBody:=nil;
  QueueDir^.Packet^.ClosePkt;

  objDispose(AbsMessage);

  Area^.MessageBase^.SetFlag(flgSent);
  Area^.MessageBase^.WriteHeader;
  Area^.MessageBase^.CloseMessage;
end;

Procedure TScanner.OpenBase(const Area:PArea);
begin
  If Area^.MessageBase<>nil then exit;

  Area^.MessageBase:=MessageBasesEngine^.OpenOrCreateBase(Area^.Echotype.Path);
  If Area^.MessageBase=nil then
    begin
      FailedToOpenBase(Area^.Name^);
      MessageBasesEngine^.Reset;
      exit;
    end;

  Area^.MessageBase^.Seek(0);
end;

Procedure TScanner.CloseBase(const Area:PArea);
begin
  objDispose(Area^.MessageBase);
end;

Procedure TScanner.ScanMSG(const Area:PArea);
begin
  OpenBase(Area);

  If Area^.MessageBase=nil then exit;

  ScanRAW(Area);

  CloseBase(Area);
end;

Procedure TScanner.ScanSQH(const Area:PArea);
begin
  OpenBase(Area);

  If Area^.MessageBase=nil then exit;

  With PSqhBase(Area^.MessageBase)^ do
    begin
      If (Flags and scnDontUseHighWaters)<>scnDontUseHighWaters
           then SeekByUid(SqhHeader.Highwater);

      Reset;
      Dec(CurrentMessage);

      ScanRAW(Area);

      Reset;
      SetHighwater(CurrentMessage);
    end;

  CloseBase(Area);
end;

Procedure TScanner.ScanJAM(const Area:PArea);
Var
  i:longint;
begin
  OpenBase(Area);

  If Area^.MessageBase=nil then exit;

  If (EchomailJam=nil) or ((Flags and scnDontUseHighWaters)=scnDontUseHighWaters)
   then ScanRAW(Area) else
    begin
      i:=EchomailJam^.FindArea(Area^.Name^);
      While i<>-1 do
        begin
          Area^.MessageBase^.Seek(i);
          Area^.MessageBase^.OpenHeader;

          If (not Area^.MessageBase^.CheckFlag(flgSent)) and
             (Area^.MessageBase^.CheckFlag(flgLocal))
               then ExportMessage(Area);
          i:=EchomailJam^.FindArea(Area^.Name^);
        end;
    end;

  CloseBase(Area);
end;

Procedure TScanner.ScanRAW(const Area:PArea);
begin
  Area^.MessageBase^.SeekNext;
  While Area^.MessageBase^.Status=mlOk do
    begin
      Area^.MessageBase^.OpenHeader;

      If (not Area^.MessageBase^.CheckFlag(flgSent)) and
           (Area^.MessageBase^.CheckFlag(flgLocal))
           then ExportMessage(Area);

      Area^.MessageBase^.SeekNext;
    end;
end;

Procedure TScanner.Scan;
Var
  DupParam : boolean;

  Procedure ProcessArea(P:pointer);far;
  Var
    Area : PArea absolute P;
  begin
    If Area=nil then exit;

    GotoXY(1,WhereY);
    Write(strPadR(Area^.Name^,#32,79));
    Case Area^.Echotype.Storage of
      etMSG : ScanMSG(Area);
      etJAM : ScanJAM(Area);
      etSquish : ScanSQH(Area);
    end;
  end;


  Procedure ProcessParameter(P:pointer);far;
  Var
    S : PString absolute P;
    S2 : String;
    T  : text;

    Procedure CheckWildCard(P:pointer);far;
    Var
      Area : PArea absolute P;
    begin
      If GrepCheck(S^,Area^.Name^,False) then ProcessArea(Area);
    end;
  begin
    Areas^.ForEach(@CheckWildCard);
  end;
begin
  TextColor(7);

  Writeln(LngFile^.GetString(LongInt(lngScanningMessages)));
  WriteLn;
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngScanningMessages)),#32);

  If (Flags and scnDontUseHighwaters)=scnDontUseHighwaters then
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngDisablingHighwaters)),'&');

  If ExportListsPath<>'' then
    begin
      EchomailJam:=New(PeJam,Init(ExportListsPath+'\echomail.jam'));
      If EchomailJam^.Status<>0 then objDispose(EchomailJam);
    end;

  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('P$P');
  QueueDir^.OpenDir(QueuePath);

  DupParam:=False;
  If ParamString^.Parameters^.Count>0 then
    ParamString^.Parameters^.ForEach(@ProcessParameter)
   else
    Areas^.ForEach(@ProcessArea);

  QueueDir^.CloseDir;
  objDispose(QueueDir);
  objDispose(EchomailJam);

  WriteLn;
  WriteLn;

  DoAfterScan;

  Exporter:=New(PTosser,Init(tsrUnSecure+tsrRunProcesses+tsrScanning));
  PTosser(Exporter)^.TossDir(QueuePath,'P$P');
  objDispose(Exporter);

  DoBeforePack;

  Arcer:=New(PArcer,Init);

  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngPackingOutboundMail)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngPackingOutboundMail)),#32);

  Arcer^.PackQueue;
  objDispose(Arcer);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  DoAfterPack;
end;

Procedure TScanner.FailedToOpenBase(const BaseName:string);
var
  sTemp : string;
begin
  LngFile^.AddVar(BaseName);
  sTemp:=LngFile^.GetString(LongInt(lngFailedToOpenBase));
  GotoXY(1,WhereY);
  WriteLn(strPadR(sTemp,#32,79));
  LogFile^.SendStr(sTemp,'!');
end;

end.
