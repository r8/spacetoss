{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit AreaFix;

interface

Uses
  r8mail,
  r8arc,
  r8log,
  r8dtm,
  color,
  areas,
  r8dos,
  forward,
  nodes,
  uplinks,
  groups,
  crt,
  dos,
  r8str,
  r8mbe,
  r8objs,
  r8ftn,
  poster,

  r8alst,
  r8elst,
  r8sqlst,
  r8felst,
  r8bcl,
  r8xofl,

  regexp,

  objects;

const
  wAll      = $00;
  wLinked   = $01;
  wUnlinked = $02;

Type

  TAreafix = object(TObject)
    AreafixInPath,
    AreafixOutPath : PString;

    AreafixIn,
    AreafixOut,
    CopyBase : PMessageBase;

    ReceiptLink : PStream;

    SendHelp : boolean;
    SendList : boolean;
    SendQuery : boolean;
    SendUnlinked : boolean;
    SendCompress : boolean;
    SendAvail : boolean;
    SendRules : boolean;

    AvailArcs : PStringsCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteGroup(GroupName:string;St:PStream;TPL:PStringsCollection;What:byte;Node:tAddress);
    Procedure WriteArea(Area : PArea;St:PStream;TPL:PStringsCollection;What:byte;Node:tAddress);
    Procedure WriteArc(Arc : String;St:PStream;TPL:PStringsCollection);

    Procedure ScanNetmail;
    Procedure ProcessMessage;
    Procedure CopyMessage;
    Procedure KillMessage;

    Procedure ProcessList;
    Procedure ProcessHelp;
    Procedure ProcessQuery;
    Procedure ProcessUnlinked;
    Procedure ProcessAvail(TempNode:PNode);
    Procedure ProcessRules;
    Procedure SendAreaRules(S:string);
    Procedure ProcessCompress;
    Procedure ProcessSubscribe(S:string; Node : TAddress);
    Procedure ProcessUnSubscribe(S:string; Node : TAddress);
    Procedure ProcessBadPassword;
    Procedure SendRule(TempArea:PArea);

    Function RequestFromUplink(S:string; Node : PNode):boolean;
    Procedure CheckForwards;

    Procedure CheckForBad;

    Procedure ReadUplinksLists;
    Procedure FreeUplinksLists;

    Procedure CreateMessage(From:PNode;const Command:string);
  end;

  PAreafix = ^TAreafix;

Procedure SendBCL(FromAddress, ToAddress:TAddress);
Procedure ReceiveBCL;

implementation

Uses
    acreate,
    global;

Var
  ToAddress : tAddress;
  FromAddress : tAddress;
  FromName:string;

  T : text;

Procedure UnPassiveArea(Area:PArea);
var
  i : longint;
  i2 : longint;
  TempLink : PNodelistItem;
  TempNode : PNode;
  TempUplink : PUplink;
begin
  Area^.ClearFlag('P');
  AreaBase^.Modified:=True;

  For i:=0 to Area^.Links^.Count-1 do
    begin
      TempLink:=Area^.Links^.At(i);
      TempNode:=PNode(TempLink^.Node);

      TempUplink:=UplinkBase^.FindUplink(TempNode^.Address);
      If TempUplink<>nil
         then TempUplink^.Requests^.Insert(NewStr('+'+Area^.Name^));
    end;

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Area '+Area^.Name^+' set to active.',' ');
  LogFile^.SendStr('Area '+Area^.Name^+' set to active.','&');
end;

Procedure UnPassiveNode(Node:PNode);
var
  i : longint;
  TempArea : PArealistItem;
begin
  For i:=0 to Node^.Areas^.Count-1 do
    begin
      TempArea:=Node^.Areas^.At(i);
      If PArea(TempArea^.Area)^.CheckFlag('P')
        then UnPassiveArea(PArea(TempArea^.Area));
    end;
end;

Constructor TAreafix.Init;
begin
  inherited Init;
  AvailArcs:=New(PStringsCollection,Init($10,$10));
  CopyBase:=nil;

  AreafixInPath:=nil;
  AreafixOutPath:=nil;
end;

Destructor TAreafix.Done;
begin

{$IFNDEF SPCTOOL}
  CheckForwards;
{$ENDIF}

  MessageBasesEngine^.DisposeBase(AreafixIn);
  MessageBasesEngine^.DisposeBase(AreafixOut);
  MessageBasesEngine^.DisposeBase(CopyBase);
  objDispose(AvailArcs);

  DisposeStr(AreafixInPath);
  DisposeStr(AreafixOutPath);

  inherited Done;
end;

Procedure TAreafix.WriteArc(Arc : String;St:PStream;TPL:PStringsCollection);
Var
  i:integer;
  pTemp:PString;
  sTemp:string;
begin
  MacroModifier^.SetArcName(Arc);
  MacroModifier^.DoMacros;

  For i:=0 to TPL^.Count-1 do
    begin
      pTemp:=TPL^.At(i);
      sTemp:='';
      if pTemp<>nil then sTemp:=pTemp^;
      MacroEngine^.ProcessString(sTemp);
      objStreamWriteLn(St,sTemp);
    end;

end;

Procedure TAreafix.WriteArea(Area : PArea;St:PStream;TPL:PStringsCollection;What:byte;Node:tAddress);
Var
  i:integer;
  pTemp:PString;
  sTemp:string;
begin
  If Area^.FindLink(Node)=nil then
    begin
      if What=wLinked then exit;
    end
    else if What=wUnlinked then exit;

  MacroModifier^.SetAreaName(Area^.Name^);
  If Area^.Desc=nil then MacroModifier^.SetAreaDesc('')
     else MacroModifier^.SetAreaDesc(Area^.Desc^);
  MacroModifier^.DoMacros;

  For i:=0 to TPL^.Count-1 do
    begin
      pTemp:=TPL^.At(i);
      sTemp:='';
      if pTemp<>nil then sTemp:=pTemp^;
      MacroEngine^.ProcessString(sTemp);
      objStreamWriteLn(St,sTemp);
    end;

end;

Procedure TAreafix.WriteGroup(GroupName:string;St:PStream;TPL:PStringsCollection;What:byte;Node:tAddress);
Var
  i,i2:integer;
  pTemp:PString;
  sTemp:string;
  TempCol : PStringsCollection;
  TempGroup : PGroup;
  TempArea : PArea;
begin
  TempGroup:=Pointer(GroupBase^.FindArea(GroupName));

  MacroModifier^.SetGroupName(TempGroup^.Name^);
  MacroModifier^.SetGroupDesc(TempGroup^.Desc^);
  MacroModifier^.DoMacros;

  For i:=0 to TPL^.Count-1 do
    begin
      pTemp:=TPL^.At(i);
      sTemp:=pTemp^;

      If strUpper(sTemp)='@BEGINAREA@' then
        begin
          TempCol:=New(PStringscollection,Init($10,$10));

          Inc(i);
          pTemp:=TPL^.At(i);
          sTemp:=pTemp^;
          While strUpper(sTemp)<>'@ENDAREA@' do
            begin
              TempCol^.Insert(NewStr(sTemp));

              Inc(i);
              pTemp:=TPL^.At(i);
              sTemp:=pTemp^;
            end;

          for i2:=0 to TempGroup^.ItemBase^.Areas^.Count-1 do
            begin
              TempArea:=TempGroup^.ItemBase^.Areas^.At(i2);

              If TempArea^.FindLink(Node)=nil then
               begin
                if What=wLinked then continue;
               end
              else if What=wUnlinked then continue;

           If (not ListSkip^.ToSkip(TempArea^.Name^,TempArea^.Desc^))
              and (not TempArea^.CheckFlag('L'))
              then WriteArea(TempArea,ReceiptLink,TempCol,What,Node);
            end;

          objDispose(TempCol);
          continue;
        end;

      MacroEngine^.ProcessString(sTemp);
      objStreamWriteLn(St,sTemp);
    end;

end;

Procedure TAreafix.ProcessList;
Var
  sTemp : string;
  TempCol : PStringsCollection;
  Groups : string[50];
  i:integer;
  TempArea : PArea;
  ListPoster : PPoster;
begin
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Sending list of available areas to '
        +ftnAddressToStr(FromAddress),' ');
  LogFile^.SendStr('Sending list of available areas to '
        +ftnAddressToStr(FromAddress),'&');

  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  ListPoster:=New(PPoster,Init);

  ListPoster^.FromName:='AreaFix';
  ListPoster^.ToName:=FromName;
  ListPoster^.Subj:='List of available areas';
  ListPoster^.ToAddress:=FromAddress;
  ListPoster^.FromAddress:=ToAddress;
  ListPoster^.PID:='PID:';
  ListPoster^.CutBytes:=MaxAreafixMsgSize;

  Assign(T,Templates^.List^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        If strUpper(sTemp)='@BEGINGROUP@' then
          begin
            TempCol:=New(PStringscollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDGROUP@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

            Groups:=NodeBase^.GetGroups(FromAddress);

            For i:=1 to Length(Groups) do
              begin
                If GroupBase^.FindArea(Groups[i])<>nil then
                        WriteGroup(Groups[i],ReceiptLink,TempCol,wAll,FromAddress);
              end;

            objDispose(TempCol);
            continue;
          end;

        If strUpper(sTemp)='@BEGINAREA@' then
          begin
            TempCol:=New(PStringscollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDAREA@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

          for i:=0 to AreaBase^.Areas^.Count-1 do
            begin
              TempArea:=AreaBase^.Areas^.At(i);
           If not ListSkip^.ToSkip(TempArea^.Name^,TempArea^.Desc^)
              then WriteArea(TempArea,ReceiptLink,TempCol,wAll,FromAddress);
            end;

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  ListPoster^.MessageBody:=ReceiptLink;
  ListPoster^.TearLine:='--- '+constPID;

  ListPoster^.Post(ptMsg,AreafixOut);

  objDispose(ListPoster);
end;

Procedure TAreafix.ProcessHelp;
Var
  sTemp : string;
begin
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Sending help message to '
        +ftnAddressToStr(FromAddress),' ');
  LogFile^.SendStr('Sending help message to '
        +ftnAddressToStr(FromAddress),'&');

  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  AreafixOut^.CreateMessage(True);

  AreafixOut^.SetFrom('AreaFix');
  AreafixOut^.SetTo(FromName);
  AreafixOut^.SetSubj('Help on using areafix');
  AreafixOut^.SetToAddress(FromAddress);
  AreafixOut^.SetFromAddress(ToAddress);
  AreafixOut^.MessageBody^.KludgeBase^.SetKludge('PID:',constPID);

  Assign(T,Templates^.Help^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);
        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  AreafixOut^.MessageBody^.AddToMsgBodyStream(ReceiptLink);

  AreafixOut^.MessageBody^.SetTearLine('--- '+constPID);

  AreafixOut^.WriteMessage;
  AreafixOut^.CloseMessage;

  objDispose(ReceiptLink);
end;

Procedure TAreafix.ProcessMessage;
Var
  sTemp  : string;
  TempNode : PNode;
  i:longint;
begin
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Processing message from '
        +ftnAddressToStr(FromAddress),' ');
  LogFile^.SendStr('Processing message from '
        +ftnAddressToStr(FromAddress),' ');

  If CopyBase<>nil then CopyMessage;

  MacroModifier^.SetOAddress(ToAddress);
  MacroModifier^.SetDAddress(FromAddress);
  MacroModifier^.SetAddress(FromAddress);
  MacroModifier^.DoMacros;

  TempNode:=NodeBase^.FindNode(FromAddress);

  if TempNode=nil then
    begin
      KillMessage;
      Exit;
    end;

  If (TempNode^.AreafixPassword^<>strUpper(AreafixIn^.GetSubj))
     and (TempNode^.AreafixPassword^<>'')
  then
    begin
      KillMessage;

      ProcessBadPassword;

      Exit;

      If AreafixLogFile<>nil
         then AreafixLogFile^.SendStr('Incorrect password for '
            +ftnAddressToStr(FromAddress),'!');
      LogFile^.SendStr('Incorrect password for '
            +ftnAddressToStr(FromAddress),'!');
    end;

  MacroModifier^.SetCurrentArc(TempNode^.Archiver^);
  MacroModifier^.DoMacros;

  WriteLn('Processing areafix request from ',
     ftnAddressToStr(FromAddress),'...');

  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));
  SendHelp:=False;
  SendList:=False;
  SendQuery:=False;
  SendCompress:=False;
  SendUnlinked:=False;
  SendAvail:=False;
  SendRules:=False;

  AreafixIn^.MessageBody^.SetPos(0);
  While not AreafixIn^.MessageBody^.EndOfMessage do
    begin
      sTemp:=strTrimB(strUpper(AreafixIn^.MessageBody^.GetMsgString),[#32]);
      If sTemp='' then continue;

      objStreamWrite(ReceiptLink,'>');
      objStreamWriteLn(ReceiptLink,sTemp);

      If sTemp='%PASSIVE' then
        begin
          If TempNode^.CheckFlag('P') then
            begin
              objStreamWriteLn(ReceiptLink,'  You are already in passive mode. Use %ACTIVE to resume your activity.');
              objStreamWriteLn(ReceiptLink,'');
              continue;
            end;

          If AreafixLogFile<>nil
             then AreafixLogFile^.SendStr('Node '
                +ftnAddressToStr(FromAddress)+' set to passive mode','&');
          LogFile^.SendStr('Node '+ftnAddressToStr(FromAddress)
                           +' set to passive mode','&');

          TempNode^.SetFlag('P');
          NodeBase^.Modified:=True;

          objStreamWriteLn(ReceiptLink,'  Entering to passive mode. Use %ACTIVE to resume your activity.');
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If sTemp='%ACTIVE' then
        begin
          If not TempNode^.CheckFlag('P') then
            begin
              objStreamWriteLn(ReceiptLink,'  You are not in passive mode.');
              objStreamWriteLn(ReceiptLink,'');
              continue;
            end;

          UnPassiveNode(TempNode);

          TempNode^.ClearFlag('P');
          NodeBase^.Modified:=True;

          objStreamWriteLn(ReceiptLink,'  Entering to active mode.');
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If sTemp='%LIST' then
        begin
          objStreamWriteLn(ReceiptLink,'  List will follow in another message.');
          objStreamWriteLn(ReceiptLink,'');
          SendList:=true;
          continue;
        end;

      If sTemp='%BLIST' then
        begin
          objStreamWriteLn(ReceiptLink,'  BCL will be sent with next bundle.');
          objStreamWriteLn(ReceiptLink,'');
          SendBCL(ToAddress, FromAddress);
          continue;
        end;

      If sTemp='%HELP' then
        begin
          objStreamWriteLn(ReceiptLink,'  Help will follow in another message.');
          objStreamWriteLn(ReceiptLink,'');
          SendHelp:=true;
          continue;
        end;

      If (sTemp='%QUERY') or (sTemp='%LINKED') then
        begin
          objStreamWriteLn(ReceiptLink,'  Linked list will follow in another message.');
          objStreamWriteLn(ReceiptLink,'');
          SendQuery:=true;
          continue;
        end;

      If sTemp='%UNLINKED' then
        begin
          objStreamWriteLn(ReceiptLink,'  Unlinked list will follow in another message.');
          objStreamWriteLn(ReceiptLink,'');
          SendUnlinked:=true;
          continue;
        end;

      If sTemp='%AVAIL' then
        begin
          objStreamWriteLn(ReceiptLink,'  Avail list will follow in another message.');
          objStreamWriteLn(ReceiptLink,'');
          SendAvail:=true;
          continue;
        end;

      If Copy(sTemp,1,4)='%PWD' then
        begin
          sTemp:=strUpper(strParser(sTemp,2,[#32]));
          TempNode^.ChangeAreafixPassword(sTemp);
          NodeBase^.Modified:=true;
          objStreamWriteLn(ReceiptLink,
                    '  New areafix password accepted.');
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If Copy(sTemp,1,7)='%PKTPWD' then
        begin
          sTemp:=strUpper(strParser(sTemp,2,[#32]));
          TempNode^.ChangePktPassword(sTemp);
          NodeBase^.Modified:=true;
          objStreamWriteLn(ReceiptLink,
                    '  New packet password accepted.');
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If Copy(sTemp,1,6)='%RULES' then
        begin
          sTemp:=strUpper(strParser(sTemp,2,[#32]));
          If sTemp='?' then
            begin
              objStreamWriteLn(ReceiptLink,
                '  List of available conference rules will follow in another message.');
               SendRules:=true;
             end
             else
             begin
               SendAreaRules(sTemp);
             end;
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If Copy(sTemp,1,9)='%COMPRESS' then
        begin
          sTemp:=strUpper(strParser(sTemp,2,[#32]));

          If sTemp='?' then
            begin
              objStreamWriteLn(ReceiptLink,
                '  List of available compress methods will follow in another message.');
               SendCompress:=true;
             end
             else
             begin
               If ArcEngine^.FindArcName(sTemp)=-1 then
                 begin
                  objStreamWriteLn(ReceiptLink,
                    '  Unknown compress method.');
                  SendCompress:=true;
                 end
                 else
                 begin
                   TempNode^.ChangeArchiver(sTemp);
                   NodeBase^.Modified:=true;
                   objStreamWriteLn(ReceiptLink,
                    '  New compress method accepted.');
                   MacroModifier^.SetCurrentArc(TempNode^.Archiver^);
                   MacroModifier^.DoMacros;
                 end;
             end;

          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If sTemp[1]='+' then
        begin
          ProcessSubscribe(strTrimL(sTemp,['+']),FromAddress);
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      If sTemp[1]='-' then
        begin
          ProcessUnSubscribe(strTrimL(sTemp,['-']),FromAddress);
          objStreamWriteLn(ReceiptLink,'');
          continue;
        end;

      ProcessSubscribe(sTemp,FromAddress);
      objStreamWriteLn(ReceiptLink,'');
    end;

  KillMessage;

  AreafixOut^.CreateMessage(True);

  AreafixOut^.SetFrom('AreaFix');
  AreafixOut^.SetTo(FromName);
  AreafixOut^.SetSubj('Areafix reply message');
  AreafixOut^.SetToAddress(FromAddress);
  AreafixOut^.SetFromAddress(ToAddress);
  AreafixOut^.MessageBody^.AddToMsgBodyStream(ReceiptLink);
  AreafixOut^.MessageBody^.KludgeBase^.SetKludge('PID:',constPID);

  AreafixOut^.MessageBody^.SetTearLine('--- '+constPID);

  AreafixOut^.SetFlag(flgLocal);
  AreafixOut^.SetFlag(flgPrivate);

  If not KeepReceipts
      then AreafixOut^.SetFlag(flgKill);

  AreafixOut^.WriteMessage;
  AreafixOut^.CloseMessage;

  objDispose(ReceiptLink);
  WriteLn;

  If SendHelp then ProcessHelp;
  If SendList then ProcessList;
  If SendQuery then ProcessQuery;
  If SendUnlinked then ProcessUnlinked;
  If SendCompress then ProcessCompress;
  If SendAvail then ProcessAvail(TempNode);
  If SendRules then ProcessRules;
end;

Procedure TAreafix.ScanNetmail;
Var
  i:integer;
begin

  SendHelp:=False;
  SendList:=False;

  AreafixIn:=MessageBasesEngine^.OpenOrCreateBase(AreafixInPath^);
  AreafixOut:=MessageBasesEngine^.OpenOrCreateBase(AreafixOutPath^);
  If (AreafixIn=nil) or (AreafixOut=nil) then exit;

  If CopyBase<> nil then
    begin
      CopyBase:=MessageBasesEngine^.OpenOrCreateBase(CopyRequests);
      If CopyBase<>nil then CopyBase^.SetBaseType(btNetmail);
    end;

  AreafixIn^.SetBaseType(btNetmail);
  AreafixOut^.SetBaseType(btNetmail);
  AreafixIn^.Seek(0);

  ReadUplinksLists;

  If AreafixLogFile<>nil then
    begin
      AreafixLogFile^.SetLogMode('AREAFIX');

      AreafixLogFile^.Open;
      If AreafixLogFile^.Status<>logOK
         then ErrorOut(AreafixLogFile^.ExplainStatus(AreafixLogFile^.Status));
    end;

  TextColor(7);
  WriteLn('Scanning netmail for areafix requests...');
  Writeln;

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Scanning netmail for areafix requests...',#32);
  LogFile^.SendStr('Scanning netmail for areafix requests...',#32);

  AreafixIn^.SeekNext;
  While AreafixIn^.Status=mlOk do
    begin
      AreafixIn^.OpenMessage;
      AreafixIn^.GetToAddress(ToAddress);
      AreafixIn^.GetFromAddress(FromAddress);
      FromName:=AreafixIn^.GetFrom;

      If not (AreafixIn^.CheckFlag(flgLocked) or
         AreafixIn^.CheckFlag(flgReceived)) then

          If (strUpper(AreafixIn^.GetTo)='AREAFIX')
          and (AddressBase^.FindAddress(ToAddress)<>nil)
             then ProcessMessage;

      AreafixIn^.CloseMessage;
      AreafixIn^.SeekNext;
    end;

  FreeUplinksLists;

  AreafixIn^.Close;
  AreafixOut^.Close;

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Done!',#32);
  LogFile^.SendStr('Done!',#32);
end;

Procedure TAreafix.ProcessSubscribe(S:string; Node : TAddress);
Var
  i:integer;
  sTemp : string;
  TempArea : PArea;
  TempNode : PNode;
  Found : boolean;
  i2 : integer;
  RulesPoster : PPoster;
  TempStream : PStream;
begin
  S:=strTrimB(S,[#32]);
  TempNode:=NodeBase^.FindNode(Node);

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;

      For i2:=0 to AreaBase^.Areas^.Count-1 do
        begin

          TempArea:=AreaBase^.Areas^.At(i2);

          If not GrepCheck(sTemp,TempArea^.Name^,False) then continue;

          Found:=True;

          If (Pos(TempArea^.Group,TempNode^.Groups)=0)
             or (TempArea^.CheckFlag('L'))
          then
            begin
              If TempArea^.Name^=sTemp then
                      objStreamWriteLn(ReceiptLink,
                              #32#32+TempArea^.Name^+': Not available.');
              continue;
            end;

          If TempArea^.FindLink(Node)<>nil then
            begin
              objStreamWriteLn(ReceiptLink,
                   #32#32+TempArea^.Name^+': Already subscribed.');
              continue;
            end;

          objStreamWriteLn(ReceiptLink,#32#32+TempArea^.Name^+': Subscribe accepted...');
          TempArea^.AddLink(Node,modRead or modWrite);

          If TempArea^.CheckFlag('P') then UnPassiveArea(TempArea);

{          If TempArea^.RulesFile<>nil then
            begin
              SendRule(TempArea);
            end;}

          Areabase^.Modified:=True;
          SendQuery:=True;
        end;

      If not Found then
        begin
         If not RequestFromUplink(sTemp,TempNode) then
          objStreamWriteLn(ReceiptLink,'  Unknown area or metacommand.');
        end;

    end;
end;

Procedure TAreafix.ProcessUnSubscribe(S:string; Node : TAddress);
Var
  i:integer;
  sTemp : string;
  TempArea : PArea;
  TempNodelist : PNodelistItem;
  Found : boolean;
  i2 : integer;
begin
  S:=strTrimB(S,[#32]);


  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;

      For i2:=0 to AreaBase^.Areas^.Count-1 do
        begin

          TempArea:=AreaBase^.Areas^.At(i2);

          If not GrepCheck(S,TempArea^.Name^,False) then continue;

          Found:=True;

          TempNodelist:=TempArea^.FindLink(Node);
          If TempNodelist=nil then
            begin
              objStreamWriteLn(ReceiptLink,
                   #32#32+TempArea^.Name^+': Already unsubscribed.');
              continue;
            end;

          If TempNodelist^.Mode=modLocked then
            begin
              objStreamWriteLn(ReceiptLink,
                   #32#32+TempArea^.Name^+': Area is locked.');
              continue;
            end;

          objStreamWriteLn(ReceiptLink,#32#32+TempArea^.Name^+': Unsubscribe accepted...');
          TempArea^.RemoveLink(Node);
          Areabase^.Modified:=True;
          SendQuery:=True;
        end;

      If not Found then
          objStreamWriteLn(ReceiptLink,'  Unknown area or metacommand.');

    end;
end;

Procedure TAreafix.SendAreaRules(S:string);
Var
  i:integer;
  sTemp : string;
  TempArea : PArea;
  Found : boolean;
  i2 : integer;
begin
  S:=strTrimB(S,[#32]);

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;

      For i2:=0 to AreaBase^.Areas^.Count-1 do
        begin
          TempArea:=AreaBase^.Areas^.At(i2);

          If not GrepCheck(sTemp,TempArea^.Name^,False) then continue;

          Found:=True;

{          If TempArea^.RulesFile<>nil then
            begin
              objStreamWriteLn(ReceiptLink,#32#32+TempArea^.Name^+': Rules will follow in another message...');
              SendRule(TempArea);
            end
            else
              objStreamWriteLn(ReceiptLink,#32#32+TempArea^.Name^+': Not available.');}
        end;

      If not Found then
        begin
          objStreamWriteLn(ReceiptLink,'  Not available.');
        end;
    end;
end;

Procedure TAreafix.ProcessQuery;
Var
  sTemp : string;
  TempCol : PStringsCollection;
  Groups : string[50];
  i:integer;
  TempArea : PArea;
  ListPoster: PPoster;
begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  ListPoster:=New(PPoster,Init);

  ListPoster^.FromName:='AreaFix';
  ListPoster^.ToName:=FromName;
  ListPoster^.Subj:='List of linked areas';
  ListPoster^.ToAddress:=FromAddress;
  ListPoster^.FromAddress:=ToAddress;
  ListPoster^.PID:='PID:';
  ListPoster^.CutBytes:=MaxAreafixMsgSize;

  Assign(T,Templates^.Query^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        If strUpper(sTemp)='@BEGINGROUP@' then
          begin
            TempCol:=New(PStringsCollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDGROUP@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

            Groups:=NodeBase^.GetGroups(FromAddress);

            For i:=1 to Length(Groups) do
              begin
                If GroupBase^.FindArea(Groups[i])<>nil then
                        WriteGroup(Groups[i],ReceiptLink,TempCol,wLinked,FromAddress);
              end;

            objDispose(TempCol);
            continue;
          end;

        If strUpper(sTemp)='@BEGINAREA@' then
          begin
            TempCol:=New(PStringsCollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDAREA@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

          for i:=0 to AreaBase^.Areas^.Count-1 do
            begin
              TempArea:=AreaBase^.Areas^.At(i);
              WriteArea(TempArea,ReceiptLink,TempCol,wLinked,FromAddress);
            end;

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  ListPoster^.MessageBody:=ReceiptLink;
  ListPoster^.TearLine:='--- '+constPID;

  ListPoster^.Post(ptMsg,AreafixOut);

  objDispose(ListPoster);
end;

Procedure TAreafix.ProcessUnlinked;
Var
  sTemp : string;
  TempCol : PStringsCollection;
  Groups : string[50];
  i:integer;
  TempArea : PArea;
  ListPoster: PPoster;
begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  ListPoster:=New(PPoster,Init);

  ListPoster^.FromName:='AreaFix';
  ListPoster^.ToName:=FromName;
  ListPoster^.Subj:='List of unlinked areas';
  ListPoster^.ToAddress:=FromAddress;
  ListPoster^.FromAddress:=ToAddress;
  ListPoster^.PID:='PID:';
  ListPoster^.CutBytes:=MaxAreafixMsgSize;

  Assign(T,Templates^.Unlinked^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        If strUpper(sTemp)='@BEGINGROUP@' then
          begin
            TempCol:=New(PStringsCollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDGROUP@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

            Groups:=NodeBase^.GetGroups(FromAddress);

            For i:=1 to Length(Groups) do
              begin
                If GroupBase^.FindArea(Groups[i])<>nil then
                        WriteGroup(Groups[i],ReceiptLink,TempCol,wUnLinked,FromAddress);
              end;

            objDispose(TempCol);
            continue;
          end;

        If strUpper(sTemp)='@BEGINAREA@' then
          begin
            TempCol:=New(PStringsCollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDAREA@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

          for i:=0 to AreaBase^.Areas^.Count-1 do
            begin
              TempArea:=AreaBase^.Areas^.At(i);
              WriteArea(TempArea,ReceiptLink,TempCol,wUnLinked,FromAddress);
            end;

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  ListPoster^.MessageBody:=ReceiptLink;
  ListPoster^.TearLine:='--- '+constPID;

  ListPoster^.Post(ptMsg,AreafixOut);

  objDispose(ListPoster);
end;

Procedure TAreafix.ProcessCompress;
Var
  sTemp : string;
  pTemp:PString;
  TempCol : PStringsCollection;
  Groups : string[50];
  i:integer;
  TempArea : PArea;
begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  AreafixOut^.CreateMessage(True);

  AreafixOut^.SetFrom('AreaFix');
  AreafixOut^.SetTo(FromName);
  AreafixOut^.SetSubj('List of available compress methods');
  AreafixOut^.SetToAddress(FromAddress);
  AreafixOut^.SetFromAddress(ToAddress);
  AreafixOut^.MessageBody^.KludgeBase^.SetKludge('PID:',constPID);

  Assign(T,Templates^.Compress^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        If strUpper(sTemp)='@BEGINARC@' then
          begin
            TempCol:=New(PStringsCollection,Init($10,$10));

            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);
            While strUpper(sTemp)<>'@ENDARC@' do
              begin
                If sTemp='' then sTemp:=' ';
                TempCol^.Insert(NewStr(sTemp));
                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
              end;

          for i:=0 to AvailArcs^.Count-1 do
            begin
              pTemp:=AvailArcs^.At(i);
              WriteArc(pTemp^,ReceiptLink,TempCol);
            end;

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  AreafixOut^.MessageBody^.AddToMsgBodyStream(ReceiptLink);

  AreafixOut^.MessageBody^.SetTearLine('--- '+constPID);

  AreafixOut^.WriteMessage;
  AreafixOut^.CloseMessage;

  objDispose(ReceiptLink);
end;

Procedure TAreafix.ProcessAvail(TempNode:PNode);
Var
  i:longint;
  i2:longint;
  TempUplink : PUplink;
  sTemp : string;
  TempCol : PStringsCollection;
  TempArea : PArea;
  TempAList : PEArealistitem;
  AvailPoster : PPoster;
  bTemp:boolean;
begin
  For i:=0 to UplinkBase^.Uplinks^.Count-1 do
    begin
      TempUplink:=UplinkBase^.Uplinks^.At(i);

      If TempUplink^.Arealist.ListType=ltNone then continue;
      If Pos(TempUplink^.AutocreateGroup,TempNode^.Groups)=0
               then continue;

      MacroModifier^.SetAddress(TempUplink^.Address);
      MacroModifier^.DoMacros;

      ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

      AvailPoster:=New(PPoster,Init);

      AvailPoster^.FromName:='AreaFix';
      AvailPoster^.ToName:=FromName;
      AvailPoster^.Subj:='List of available areas from '+ftnAddressToStrEx(TempUplink^.Address);
      AvailPoster^.ToAddress:=FromAddress;
      AvailPoster^.FromAddress:=ToAddress;
      AvailPoster^.PID:='PID:';
      AvailPoster^.CutBytes:=MaxAreafixMsgSize;

      Assign(T,Templates^.Avail^);
      Reset(T);
        While not Eof(T) do
          begin
            ReadLn(T,sTemp);
            sTemp:=strTrimR(sTemp,[#32]);

            If strUpper(sTemp)='@BEGINAREA@' then
              begin
                TempCol:=New(PStringsCollection,Init($10,$10));

                ReadLn(T,sTemp);
                sTemp:=strTrimR(sTemp,[#32]);
                While strUpper(sTemp)<>'@ENDAREA@' do
                  begin
                    If sTemp='' then sTemp:=' ';
                    TempCol^.Insert(NewStr(sTemp));
                    ReadLn(T,sTemp);
                    sTemp:=strTrimR(sTemp,[#32]);
                  end;

              for i2:=0 to TempUplink^.Arealist.List^.Areas^.Count-1 do
                begin
                  TempAList:=TempUplink^.Arealist.List^.Areas^.At(i2);

                  TempArea:=New(PArea,Init(TempAList^.AreaName^));
                  If TempAList^.AreaDesc<>nil
                      then AssignStr(TempArea^.Desc,TempAList^.AreaDesc^);

                  If TempAList^.AreaDesc=nil
                     then bTemp:=AvailSkip^.ToSkipArea(TempAList^.AreaName^)
                     else bTemp:=AvailSkip^.ToSkip(TempAList^.AreaName^,
                                    TempAList^.AreaDesc^);

                  If not bTemp
                     then WriteArea(TempArea,ReceiptLink,
                           TempCol,wUnLinked,nullAddress);
                  objDispose(TempArea);
                end;

                objDispose(TempCol);
                continue;
              end;

            MacroEngine^.ProcessString(sTemp);
            objStreamWriteLn(ReceiptLink,sTemp);
          end;

      Close(T);

      AvailPoster^.MessageBody:=ReceiptLink;
      AvailPoster^.TearLine:='--- '+constPID;

      AvailPoster^.Post(ptMsg,AreafixOut);

      objDispose(AvailPoster);
    end;
end;

Procedure TAreafix.ProcessBadPassword;
Var
  sTemp : string;
begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  AreafixOut^.CreateMessage(True);

  AreafixOut^.SetFrom('AreaFix');
  AreafixOut^.SetTo(FromName);
  AreafixOut^.SetSubj('Bad password');
  AreafixOut^.SetToAddress(FromAddress);
  AreafixOut^.SetFromAddress(ToAddress);
  AreafixOut^.MessageBody^.KludgeBase^.SetKludge('PID:',constPID);

  Assign(T,Templates^.BadPass^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  AreafixOut^.MessageBody^.AddToMsgBodyStream(ReceiptLink);

  AreafixOut^.MessageBody^.SetTearLine('--- '+constPID);

  AreafixOut^.WriteMessage;
  AreafixOut^.CloseMessage;

  objDispose(ReceiptLink);
end;

Procedure TAreafix.ReadUplinksLists;
Var
  i:longint;
  TempUplink : PUplink;
begin
  For i:=0 to UplinkBase^.Uplinks^.Count-1 do
    begin
      TempUplink:=UplinkBase^.Uplinks^.At(i);

      If TempUplink^.Arealist.ListType=ltNone then continue;

      Case TempUplink^.Arealist.ListType of
        ltEchoList : TempUplink^.Arealist.List:=New(PEchoList,Init);
        ltBCL      : TempUplink^.Arealist.List:=New(PBCL,Init);
        ltFastecho : TempUplink^.Arealist.List:=New(PFeList,Init);
        ltSquish   : TempUplink^.Arealist.List:=New(PSqList,Init);
        ltXOfcEList: TempUplink^.Arealist.List:=New(PxOfcEList,Init);
      end;

      TempUplink^.Arealist.List^.SetFilename(TempUplink^.Arealist.Path);
      TempUplink^.Arealist.List^.Read;
    end;
end;

Procedure TAreafix.FreeUplinksLists;
Var
  i:longint;
  TempUplink : PUplink;
begin
  For i:=0 to UplinkBase^.Uplinks^.Count-1 do
    begin
      TempUplink:=UplinkBase^.Uplinks^.At(i);

      If TempUplink^.Arealist.ListType=ltNone then continue;

      objDispose(TempUplink^.Arealist.List);
    end;
end;

Function TAreafix.RequestFromUplink(S:string; Node : PNode):boolean;
Var
  i:longint;
  i2:longint;
  TempUplink : PUplink;
  Address : TAddress;
  TempForward : PForwardItem;
begin
  RequestFromUplink:=False;

  For i:=0 to UplinkBase^.Uplinks^.Count-1 do
    begin
      TempUplink:=UplinkBase^.Uplinks^.At(i);

      If TempUplink^.Arealist.ListType=ltNone then continue;
      If Node^.Level<TempUplink^.ForwardLevel then continue;

      If Pos(TempUplink^.AutocreateGroup,Node^.Groups)=0
               then continue;

      If TempUplink^.Unconditional then i2:=0 else
         i2:=TempUplink^.Arealist.List^.FindArea(S);

      If i2<>-1 then
        begin
          TempUplink^.Requests^.Insert(NewStr('+'+S));

          New(TempForward);
          FillChar(TempForward^,SizeOf(TempForward^),#0);
          TempForward^.AreaName:=S;
          TempForward^.Address:=Node^.Address;
          TempForward^.UplinkAddress:=TempUplink^.Address;
          TempForward^.Date:=dtmGetDateTimeUnix;
          ForwardFile^.ForwardCollection^.Insert(TempForward);

          objStreamWriteLn(ReceiptLink,
               #32#32+'Requested from uplink.');

          RequestFromUplink:=True;
          Exit;
        end;
    end;

end;

Procedure TAreafix.CheckForwards;
Var
  ForwardItem : PForwardItem;
  i:longint;
  i2:longint;
  DateTime : longint;
  TempNode : PNode;
begin
  If AreafixOut=nil then
    begin
       AreafixOut:=MessageBasesEngine^.OpenOrCreateBase(AreafixOutPath^);
       If AreafixOut=nil then exit;
       AreafixOut^.SetBaseType(btNetmail);
    end;

  DateTime:=dtmGetDateTimeUnix;

  i:=0;

  While i <= ForwardFile^.ForwardCollection^.Count-1 do
    begin
      ForwardItem:=ForwardFile^.ForwardCollection^.At(i);

      If (DateTime-ForwardItem^.Date) div 86400 > PreserveRequests then
        begin
          TempNode:=NodeBase^.FindNode(ForwardItem^.Address);

          If TempNode<>nil then
            begin
              AreafixOut^.CreateMessage(True);

              AreafixOut^.SetFrom('AreaFix');
              AreafixOut^.SetTo(TempNode^.SysopName^);
              AreafixOut^.SetSubj('Area request expired');
              AreafixOut^.SetToAddress(TempNode^.Address);
              AreafixOut^.SetFromAddress(TempNode^.UseAKA);
              AreafixOut^.MessageBody^.KludgeBase^.SetKludge('PID:',constPID);

              AreafixOut^.MessageBody^.PutMsgString('Area '+ForwardItem^.AreaName
                      +' is not available from uplink.');

              AreafixOut^.MessageBody^.SetTearLine('--- '+constPID);

              AreafixOut^.WriteMessage;
              AreafixOut^.CloseMessage;
            end;

          ForwardFile^.ForwardCollection^.AtFree(i);
          Dec(i);
        end;
      Inc(i);
    end;
  AreafixOut^.Close;
end;

Procedure TAreafix.ProcessRules;
Var
  RulesPoster : PPoster;
  sTemp : string;
  TempCol : PStringsCollection;
  i : longint;
  TempArea : PArea;
begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

  RulesPoster:=New(PPoster,Init);

  RulesPoster^.FromName:='AreaFix';
  RulesPoster^.ToName:=FromName;
  RulesPoster^.Subj:='List of available conference rules';
  RulesPoster^.ToAddress:=FromAddress;
  RulesPoster^.FromAddress:=ToAddress;
  RulesPoster^.PID:='PID:';
  RulesPoster^.CutBytes:=MaxAreafixMsgSize;

  Assign(T,Templates^.Rules^);
  Reset(T);
  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      sTemp:=strTrimR(sTemp,[#32]);

      If strUpper(sTemp)='@BEGINAREA@' then
        begin
          TempCol:=New(PStringsCollection,Init($10,$10));

          ReadLn(T,sTemp);
          sTemp:=strTrimR(sTemp,[#32]);
          While strUpper(sTemp)<>'@ENDAREA@' do
            begin
              If sTemp='' then sTemp:=' ';
              TempCol^.Insert(NewStr(sTemp));
              ReadLn(T,sTemp);
              sTemp:=strTrimR(sTemp,[#32]);
            end;

          For i:=0 to AreaBase^.Areas^.Count-1 do
            begin
              TempArea:=AreaBase^.Areas^.At(i);

{              If TempArea^.RulesFile<>nil then
                WriteArea(TempArea,ReceiptLink,TempCol,wUnLinked,nullAddress);}
            end;

          objDispose(TempCol);
          continue;
        end;

      MacroEngine^.ProcessString(sTemp);
      objStreamWriteLn(ReceiptLink,sTemp);
    end;

  Close(T);

  RulesPoster^.MessageBody:=ReceiptLink;
  RulesPoster^.TearLine:='--- '+constPID;

  RulesPoster^.Post(ptMsg,AreafixOut);

  objDispose(RulesPoster);
end;

Procedure SendBCL(FromAddress, ToAddress:TAddress);
Var
  EchoList : PBCL;
  TempGroup : PGroup;
  TempArea : PArea;
  TempNode : PNode;
  TempAreaItem : PEArealistitem;
  i  : longint;
  i2 : longint;
begin
  EchoList:=New(PBCL,Init);
  EchoList^.SetFilename(QueuePath+'\'+ftnPktName+'.BCL');
  EchoList^.SetAddress(FromAddress);
  EchoList^.SetMgrName('Areafix');

  TempNode:=NodeBase^.FindNode(ToAddress);

  For i:=0 to GroupBase^.Areas^.Count-1 do
    begin
      TempGroup:=GroupBase^.Areas^.At(i);

      If Pos(TempGroup^.Name^,TempNode^.Groups)=0 then continue;

      For i2:=0 to TempGroup^.ItemBase^.Areas^.Count-1 do
        begin
          TempArea:=TempGroup^.ItemBase^.Areas^.At(i2);

          TempAreaItem:=New(PEArealistitem,
                    Init(TempArea^.Name^,TempArea^.Desc^));

          Echolist^.Areas^.Insert(TempAreaItem);
        end;
    end;

  EchoList^.Write;

  OpenOutbounds;

  WriteLn('Packing '+dosGetFileName(EchoList^.Filename^)+' for '
     +ftnAddressToStrEx(ToAddress)+'...');

  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  TempNode^.Outbound^.AddToBundle(EchoList^.Filename^,FromAddress,ToAddress,TempNode^.Archiver^,
          TempNode^.Flavour,TempNode^.MaxArcSize);

  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  Case ArcEngine^.Status of
     arcOk : dosErase(EchoList^.Filename^);
     arcPackerError : WriteLn(' þ Packer error. Exit code: ',
                      ArcEngine^.ErrorLevel,'.');
     arcUnknownPacker : WriteLn(' þ  ERROR: Unknown packer type.');
  end;

  WriteLn;

  CloseOutbounds;

  objDispose(EchoList);
end;

Procedure ReceiveBCL;
Var
  SR : SearchRec;
  EchoList : PBCL;
  TempAddress : TAddress;
  i : longint;
  TempUplink : PUplink;
begin
  FindFirst(TempInboundPath+'\*.BCL',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      EchoList:=New(PBCL,Init);
      EchoList^.SetFilename(TempInboundPath+'\'+SR.Name);
      EchoList^.Read;

      EchoList^.GetAddress(TempAddress);
      TempUplink:=UplinkBase^.FindUplink(TempAddress);

      If TempUplink<>nil then
        If TempUplink^.AreaList.ListType=ltBCL then
          begin
            WriteLn('New BCL has arrived from '+EchoList^.GetAddressStr);
            objDispose(EchoList);
            dosMove(TempInboundPath+'\'+SR.Name,TempUplink^.AreaList.Path);
          end;

      objDispose(EchoList);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TAreafix.SendRule(TempArea:PArea);
Var
  RulesPoster : PPoster;
  TempStream : PStream;
  sTemp:string;
begin
(*  TempStream:=New(PMemorystream,Init(0,cBuffSize));

  RulesPoster:=New(PPoster,Init);

  RulesPoster^.FromName:='AreaFix';
  RulesPoster^.ToName:=FromName;
  RulesPoster^.Subj:='Rules of '+TempArea^.Name^;
  RulesPoster^.ToAddress:=FromAddress;
  RulesPoster^.FromAddress:=ToAddress;
  RulesPoster^.PID:='PID:';
  RulesPoster^.CutBytes:=MaxAreafixMsgSize;

  Assign(T,AreaBase^.RulesDir+'\'+TempArea^.RulesFile^);
{$I-}
  Reset(T);
{$I+}
  If IOResult<>0 then exit;

  If not Eof(T) then ReadLn(T,sTemp);

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      objStreamWriteLn(TempStream,sTemp);
    end;
  Close(T);

  RulesPoster^.MessageBody:=TempStream;
  RulesPoster^.TearLine:='--- '+constPID;

  RulesPoster^.Post(ptMsg,AreafixOut);

  objDispose(RulesPoster);

  LogFile^.SendStr('Sending rules of '
        +TempArea^.Name^+' to '+ftnAddressToStr(FromAddress)+'...','<');
*)
end;

Procedure TAreafix.KillMessage;
begin
  If KeepRequests then
    begin
      AreafixIn^.SetFlag(flgReceived);
      AreafixIn^.WriteMessage;
    end
    else AreafixIn^.KillMessage;
end;

Procedure TAreafix.CopyMessage;
Var
  TempAddress:TAddress;
  BodyStream : PStream;
  Flags  : longint;
  Datetime : TDatetime;
begin
  CopyBase^.CreateMessage(False);

  CopyBase^.SetTo(AreafixIn^.GetTo);
  CopyBase^.SetFrom(AreafixIn^.GetFrom);
  CopyBase^.SetSubj(AreafixIn^.GetSubj);
  AreafixIn^.GetFlags(Flags);
  CopyBase^.SetFlags(Flags);

  AreafixIn^.GetDateWritten(DateTime);
  CopyBase^.SetDateWritten(DateTime);

  BodyStream:=AreafixIn^.MessageBody^.GetMsgBodyStream;
  CopyBase^.MessageBody^.AddToMsgBodyStream(BodyStream);

  objDispose(BodyStream);

  AreafixIn^.GetFromAddress(TempAddress);
  CopyBase^.SetFromAddress(TempAddress);

  AreafixIn^.GetToAddress(TempAddress);
  CopyBase^.SetToAddress(TempAddress);

  CopyBase^.WriteMessage;
  CopyBase^.CloseMessage;
end;

Procedure TAreafix.CheckForBad;
Var
  sTemp : string;
  TempNode : PNode;
  i : longint;
begin
  OpenOutbounds;

  TempNode:=NodeBase^.FindNode(FromAddress);

  AreafixIn^.MessageBody^.SetPos(0);
  While not AreafixIn^.MessageBody^.EndOfMessage do
    begin
      sTemp:=strTrimB(strUpper(AreafixIn^.MessageBody^.GetMsgString),[#32]);
      sTemp:=dosMakeValidString(sTemp);

      TempNode^.Outbound^.AddToBundle(sTemp,ToAddress,FromAddress,TempNode^.Archiver^,
              TempNode^.Flavour,TempNode^.MaxArcSize);
    end;

  CloseOutbounds;
end;

Procedure TAreafix.CreateMessage(From:PNode;const Command:string);
Var
  BodyStream : PStream;
begin
  If AreafixIn=nil then
    begin
      AreafixIn:=MessageBasesEngine^.OpenOrCreateBase(AreafixInPath^);
      If AreafixIn=nil then exit;
      AreafixIn^.SetBaseType(btNetmail);
    end;

  AreafixIn^.CreateMessage(True);

  AreafixIn^.SetTo('Areafix');
  AreafixIn^.SetFrom('Sysop');
  If From^.AreafixPassword<>nil
     then AreafixIn^.SetSubj(From^.AreafixPassword^);

  BodyStream:=New(PMemorystream,Init(0,cBuffSize));
  objStreamWriteLn(BodyStream, Command);
  objStreamWriteLn(BodyStream, '--- '+constPID);

  AreafixIn^.MessageBody^.AddToMsgBodyStream(BodyStream);

  objDispose(BodyStream);

  AreafixIn^.SetFromAddress(From^.Address);
  AreafixIn^.SetToAddress(From^.UseAKA);

  AreafixIn^.WriteMessage;
  AreafixIn^.CloseMessage;

  AreafixIn^.Close;
end;

end.
