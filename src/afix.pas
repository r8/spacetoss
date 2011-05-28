{
 AreaFix Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 flgKill Ά ―®αβ¥ΰ (β¨―  keep receipts)
 BCL
}
Unit Afix;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8mail,
  r8mbe,
  r8ftn,
  r8log,
  r8objs,
  r8str,
  r8abs,
  r8bcl,
  regexp,

  arc,
  bats,
  lng,
  nodes,
  areas,
  groups,
  rules,
  poster,
  modsav,
  forwards,
  elist,

  crt,
  objects;

const
  afxKeepRequests  = $00000001;

  afxSendHelp      = $00000002;
  afxSendList      = $00000004;
  afxSendLinked    = $00000008;
  afxSendUnlinked  = $00000010;
  afxSendAvail     = $00000020;
  afxSendRulesList = $00000040;
  afxSendCompress  = $00000080;

  afxReset         = afxKeepRequests;

  afxLinked        = $00000001;
  afxUnLinked      = $00000002;
  afxAll           = afxLinked+afxUnLinked;
  afxWithRules     = $00000004+afxAll;

  afxModifiers = [',','/'];
  afxAllMask = ['*','.','+','?'];

Type

  TAreaFix = object(TObject)
    Flags : longint;

    AreafixIn  : PArea;
    AreafixOut : PArea;
    CopyArea   : PArea;

    AreafixInBase : PMessageBase;
    AreafixOutBase : PMessageBase;
    CopyBase : PMessageBase;

    ModeSaver : PModeSaver;
    ForwardFile : PForwardFile;

    Aliases : PStringCollection;
    AvailArcs : PStringCollection;

    AbsMessage : PAbsMessage;
    MsgPoster  : PMsgPoster;
    ReceiptLink : PStream;

    TempNode : PNode;
    Arcer : PArcer;

    Constructor Init;
    Destructor  Done; virtual;

    Function CheckAlias(Alias:string):boolean;

    Procedure ScanNetmail;
    Procedure ProcessMessage;

    Procedure ProcessList(const S:string);
    Procedure ProcessBList;
    Procedure ProcessHelp;
    Procedure ProcessLinked;
    Procedure ProcessUnLinked;
    Procedure ProcessAvail;
    Procedure ProcessCompress(const S:string);
    Procedure ProcessPwd(const S:string);
    Procedure ProcessPktPwd(const S:string);
    Procedure ProcessSubscribe(S:string);
    Procedure ProcessUnSubscribe(S:string);
    Procedure ProcessPassive(S:string);
    Procedure ProcessActive(S:string);
    Procedure ProcessRules(S:string);

    Procedure SendHelp;
    Procedure SendList;
    Procedure SendLinked;
    Procedure SendUnLinked;
    Procedure SendCompress;
    Procedure SendAvail;
    Procedure SendRulesList;
    Procedure SendBCL(FromAddress, ToAddress:TAddress);

    Procedure ProcessUnknownNode;
    Procedure ProcessBadPassword;

    Procedure CopyMessage;
    Procedure KillMessage;

    Function RequestFromUplink(const S:string):boolean;

    Procedure WriteArea(const Area:PArea;const St:PStream;
      const TPL:PStringsCollection;const Mode:longint;const Node:TAddress);
    Procedure WriteGroup(const GroupName:string;const St:PStream;
      const TPL:PStringsCollection;const Mode:longint;const Node:TAddress);

    Procedure CreateMessage(From:PNode;const Command:string);
  end;
  PAreaFix = ^TAreaFix;

implementation

Uses
  r8alst,

  uplinks,
  global;

Constructor TAreaFix.Init;
begin
  inherited Init;

  Flags:=0;

  CopyBase:=nil;

  AreafixIn:=nil;
  AreafixOut:=nil;
  CopyArea:=nil;

  AbsMessage:=nil;

  Aliases:=New(PStringCollection,Init($10,$10));
  Aliases^.Duplicates:=True;
  Aliases^.Insert(NewStr('AREAFIX'));
  AvailArcs:=New(PStringCollection,Init($10,$10));

  ForwardFile:=New(PForwardFile,Init(DataPath^+'\forward.dat'));
  ForwardFile^.PostArea:=NetmailArea;
end;

Destructor  TAreaFix.Done;
begin
  objDispose(ForwardFile);

  objDispose(Aliases);
  objDispose(AvailArcs);

  AreaBase^.CheckForPassive;
  If AreaBase^.Modified then AreaBase^.SaveConfig;

  inherited Done;
end;

Function TAreaFix.CheckAlias(Alias:string):boolean;
var
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  CheckAlias:=Aliases^.Search(@Alias,i);
end;

Procedure TAreafix.WriteGroup(const GroupName:string;const St:PStream;
           const TPL:PStringsCollection;const Mode:longint;const Node:TAddress);
Var
  i,i2:integer;
  sTemp:string;
  TempCol : PStringsCollection;

  TempGroup : PGroup;

  Procedure ProcessArea(P:Pointer);far;
  var
    Area : PArea absolute P;
  begin
    WriteArea(Area,St,TempCol,Mode,Node);
  end;

  Procedure ProcessString(P:Pointer);far;
  var
    pTemp : PString absolute P;
  begin
    sTemp:='';
    If pTemp<>nil then sTemp:=pTemp^;

    If TempCol=nil then
      begin
        If strUpper(sTemp)='@BEGINAREA@' then
          begin
            TempCol:=New(PStringscollection,Init($10,$10));
            exit;
          end;
      end else
      begin
        If strUpper(sTemp)='@ENDAREA@' then
          begin
            TempGroup^.ItemBase^.Areas^.ForEach(@ProcessArea);
            objDispose(TempCol);
            exit;
          end else
          begin
            TempCol^.Insert(NewStr(sTemp));
            exit;
          end;
      end;

    MacroEngine^.ProcessString(sTemp);
    objStreamWriteLn(St,sTemp);
  end;
begin
  TempGroup:=Pointer(GroupBase^.FindArea(GroupName));

  MacroModifier^.SetGroupName(TempGroup^.Name^);
  MacroModifier^.SetGroupDesc(TempGroup^.Desc^);
  MacroModifier^.DoMacros;

  TempCol:=nil;
  TPL^.ForEach(@ProcessString);
end;

Procedure TAreafix.WriteArea(const Area:PArea;const St:PStream;
           const TPL:PStringsCollection;const Mode:longint;const Node:TAddress);
Var
  i : longint;
  sTemp : string;
  Link : PNodelistItem;
  TempMode : word;

  Procedure ProcessString(P:Pointer);far;
  var
    pTemp : PString absolute P;
  begin
    sTemp:='';
    If pTemp<>nil then sTemp:=pTemp^;
    MacroEngine^.ProcessString(sTemp);
    objStreamWriteLn(St,sTemp);
  end;
begin
  If (Area^.BaseType<>btEchomail) or (Area^.CheckFlag('H')) then exit;

  Link:=Area^.FindLink(Node);

  If (Link=nil) and (Mode and afxUnlinked<>afxUnlinked) then exit else
    If (Link<>nil) and (Mode and afxLinked<>afxLinked) then exit else
      If (Mode and afxWithRules=afxWithRules) and (RulesBase^.FindRule(Area^.Name^)=nil)
         then exit;
  If Link<>nil then
    begin
      TempMode:=Link^.Mode;

      If PNode(Link^.Node)^.Level<Area^.ReadLevel
        then TempMode:=TempMode-modRead;
      If PNode(Link^.Node)^.Level<Area^.WriteLevel
        then TempMode:=TempMode-modWrite;

      Case TempMode of
        modRead          : MacroModifier^.SetMode('r');
        modWrite         : MacroModifier^.SetMode('w');
        modRead+modWrite : MacroModifier^.SetMode('*');
        modLocked        : MacroModifier^.SetMode('l');
        modPassive       : MacroModifier^.SetMode('p');
      else MacroModifier^.SetMode('l')
      end
     end
  else MacroModifier^.SetMode(' ');

  MacroModifier^.SetAreaName(Area^.Name^);
  If Area^.Desc=nil then MacroModifier^.SetAreaDesc('')
     else MacroModifier^.SetAreaDesc(Area^.Desc^);
  MacroModifier^.DoMacros;

  TPL^.ForEach(@ProcessString);
end;

Procedure TAreaFix.ProcessList(const S:string);
var
  sTemp : string;
begin
  If strTrimB(strParser(S,2,afxModifiers),[#32])='B' then
    begin
      ProcessBList;
      exit;
    end;

  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngListWillFollow)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingListTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendList;
end;

Procedure TAreaFix.ProcessBList;
var
  sTemp : string;
begin
  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngBCLWillBeSent)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingBCLTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  SendBCL(AbsMessage^.ToAddress,AbsMessage^.FromAddress);
end;

Procedure TAreaFix.ProcessAvail;
var
  sTemp : string;
begin
  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngAvailWillFollow)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingAvailTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendAvail;
end;

Procedure TAreaFix.ProcessHelp;
var
  sTemp : string;
begin
  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngHelpWillFollow)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingHelpTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendHelp;
end;

Procedure TAreaFix.ProcessLinked;
var
  sTemp : string;
begin
  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngLinkedWillFollow)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingLinkedTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendLinked;
end;

Procedure TAreaFix.ProcessUnLinked;
var
  sTemp : string;
begin
  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngUnLinkedWillFollow)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingUnLinkedTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendUnLinked;
end;

Procedure TAreaFix.ProcessCompress(const S:string);
var
  sTemp : string;
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  sTemp:=strUpper(strParser(S,2,[#32]));

  If sTemp='?' then
    begin
      objStreamWriteLn(ReceiptLink,'  '
        +LngFile^.GetString(LongInt(lngCompressWillFollow)));
    end
    else
      If not AvailArcs^.Search(@sTemp,i)
        then objStreamWriteLn(ReceiptLink,'  '
        +LngFile^.GetString(LongInt(lngCompressRejected))) else
          begin
            TempNode^.ChangeArchiver(sTemp);
            NodeBase^.Modified:=True;
            objStreamWriteLn(ReceiptLink,'  '
             +LngFile^.GetString(LongInt(lngCompressAccepted)));
            MacroModifier^.SetCurrentArc(TempNode^.Archiver^);
            MacroModifier^.DoMacros;

            LngFile^.AddVar(sTemp);
            LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
            sTemp:=LngFile^.GetString(LongInt(lngChangedCompress));
            If AreafixLogFile<>nil
              then AreafixLogFile^.SendStr('³ '+sTemp,'@');
            LogFile^.SendStr('³ '+sTemp,'@');
          end;

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngSendingCompressTo));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');

  Flags:=Flags or afxSendCompress;
  objStreamWriteLn(ReceiptLink,'');
end;

Procedure TAreaFix.ProcessPwd(const S:string);
var
  sTemp : string;
begin
  sTemp:=strUpper(strParser(S,2,[#32]));
  TempNode^.ChangeAreafixPassword(sTemp);
  NodeBase^.Modified:=True;

  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngPwdAccepted)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(sTemp);
  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngChangedPwd));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');
end;

Procedure TAreaFix.ProcessPktPwd(const S:string);
var
  sTemp : string;
begin
  sTemp:=strUpper(strParser(S,2,[#32]));
  TempNode^.ChangePktPassword(sTemp);
  NodeBase^.Modified:=True;

  objStreamWriteLn(ReceiptLink,'  '
    +LngFile^.GetString(LongInt(lngPktPwdAccepted)));
  objStreamWriteLn(ReceiptLink,'');

  LngFile^.AddVar(sTemp);
  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngChangedPktPwd));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp,'@');
  LogFile^.SendStr('³ '+sTemp,'@');
end;

Procedure TAreaFix.ProcessRules(S:string);
var
  sTemp : string;
  Found : boolean;
  i : longint;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    TempLink : PNodeListItem;
    sTemp2 : string;
  begin
    If not GrepCheck(sTemp,TempArea^.Name^,False) then exit;

    RulesBase^.SendQueue^.Insert(New(PSendQueueElement,Init(TempArea^.Name^,TempNode)));

    LngFile^.AddVar(TempArea^.Name^);
    objStreamWriteLn(ReceiptLink,'  '+
      LngFile^.GetString(LongInt(lngRulesWillFollow)));
    Found:=True;
  end;
begin
  S:=strUpper(strParser(S,2,[#32]));
  If S='' then S:='?';

  If S='?' then
    begin
      objStreamWriteLn(ReceiptLink,'  '
        +LngFile^.GetString(LongInt(lngRulesListWillFollow)));
      objStreamWriteLn(ReceiptLink,'');

      LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
      sTemp:=LngFile^.GetString(LongInt(lngSendingRulesListTo));
      If AreafixLogFile<>nil
         then AreafixLogFile^.SendStr('³ '+sTemp,'@');
      LogFile^.SendStr('³ '+sTemp,'@');

      Flags:=Flags or afxSendRulesList;

      exit;
    end;

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;
      AreaBase^.EchoMail^.ForEach(@ProcessArea);

      If not Found then
          objStreamWriteLn(ReceiptLink,'  '+
            LngFile^.GetString(LongInt(lngNothingToProcess)));
    end;

  objStreamWriteLn(ReceiptLink,'');
end;


Procedure TAreaFix.ProcessPassive(S:string);
var
  sTemp : string;
  Found : boolean;
  i : longint;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    TempLink : PNodeListItem;
    sTemp2 : string;
  begin
    If not GrepCheck(sTemp,TempArea^.Name^,False) then exit;

    TempLink:=TempArea^.FindLink(TempNode^.Address);
    If TempLink=nil then exit;

    Found:=True;

    If TempLink^.Mode=modPassive then
      begin
        LngFile^.AddVar(TempArea^.Name^);
        objStreamWriteLn(ReceiptLink,'  '+
          LngFile^.GetString(LongInt(lngAreaAlreadyPassive)));
        exit;
      end else
        begin
          If (TempLink^.Mode=modRead) or (TempLink^.Mode=modWrite) then
              ModeSaver^.AddMode(TempNode^.Address,TempArea^.Name^,TempLink^.Mode);
          TempLink^.Mode:=modPassive;
        end;

    LngFile^.AddVar(TempArea^.Name^);
    objStreamWriteLn(ReceiptLink,'  '+
      LngFile^.GetString(LongInt(lngAreaPassiveAccepted)));

    LngFile^.AddVar(TempArea^.Name^);
    LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
    sTemp2:=LngFile^.GetString(LongInt(lngAreaPassiveTo));
    If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp2,'@');
    LogFile^.SendStr('³ '+sTemp2,'@');

    AreaBase^.Modified:=True;
    Flags:=Flags or afxSendLinked;
  end;
begin
  S:=strUpper(strParser(S,2,[#32]));
  If S='' then S:='*';

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;
      AreaBase^.EchoMail^.ForEach(@ProcessArea);

      If not Found then
          objStreamWriteLn(ReceiptLink,'  '+
            LngFile^.GetString(LongInt(lngNothingToProcess)));
    end;

  objStreamWriteLn(ReceiptLink,'');
end;

Procedure TAreaFix.ProcessActive(S:string);
var
  sTemp : string;
  Found : boolean;
  i : longint;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    TempLink : PNodeListItem;
    sTemp2 : string;
  begin
    If not GrepCheck(sTemp,TempArea^.Name^,False) then exit;

    TempLink:=TempArea^.FindLink(TempNode^.Address);
    If TempLink=nil then exit;

    Found:=True;

    If TempLink^.Mode<>modPassive then
      begin
        LngFile^.AddVar(TempArea^.Name^);
        objStreamWriteLn(ReceiptLink,'  '+
          LngFile^.GetString(LongInt(lngAreaIsNotPassive)));
        exit;
      end else TempLink^.Mode:=ModeSaver^.GetMode(TempNode^.Address,TempArea^.Name^);

    LngFile^.AddVar(TempArea^.Name^);
    objStreamWriteLn(ReceiptLink,'  '+
      LngFile^.GetString(LongInt(lngAreaActiveAccepted)));

    LngFile^.AddVar(TempArea^.Name^);
    LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
    sTemp2:=LngFile^.GetString(LongInt(lngAreaActiveTo));
    If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp2,'@');
    LogFile^.SendStr('³ '+sTemp2,'@');

    AreaBase^.Modified:=True;
    Flags:=Flags or afxSendLinked;
  end;
begin
  S:=strUpper(strParser(S,2,[#32]));
  If S='' then S:='*';

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;
      AreaBase^.EchoMail^.ForEach(@ProcessArea);

      If not Found then
          objStreamWriteLn(ReceiptLink,'  '+
            LngFile^.GetString(LongInt(lngNothingToProcess)));
    end;

  objStreamWriteLn(ReceiptLink,' ');
end;

Procedure TAreafix.ProcessSubscribe(S:string);
var
  i : longint;
  i2 : longint;
  sTemp : string;
  Found : boolean;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    sTemp2 : string;
  begin
    If not GrepCheck(sTemp,TempArea^.Name^,False) then exit;

    Found:=True;

    If Pos(TempArea^.Group,TempNode^.Groups)=0 then
      begin
        If TempArea^.Name^=sTemp then
          begin
            LngFile^.AddVar(TempArea^.Name^);
            objStreamWriteLn(ReceiptLink,'  '+
              LngFile^.GetString(LongInt(lngAreaNotAvailable)));
          end;
        exit;
      end;

    If TempArea^.FindLink(TempNode^.Address)<>nil then
      begin
        LngFile^.AddVar(TempArea^.Name^);
        objStreamWriteLn(ReceiptLink,'  '+
          LngFile^.GetString(LongInt(lngAreaAlreadySubscribed)));
        exit;
      end;

    LngFile^.AddVar(TempArea^.Name^);
    objStreamWriteLn(ReceiptLink,'  '+
      LngFile^.GetString(LongInt(lngAreaSubscribeAccepted)));
    TempArea^.AddLink(TempNode^.Address,ModeSaver^.GetMode(TempNode^.Address,TempArea^.Name^));

    If TempNode^.CheckFlag('R') then
      RulesBase^.SendQueue^.Insert(New(PSendQueueElement,Init(TempArea^.Name^,TempNode)));

    LngFile^.AddVar(TempArea^.Name^);
    LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
    sTemp2:=LngFile^.GetString(LongInt(lngAreaSubscribedTo));
    If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp2,'@');
    LogFile^.SendStr('³ '+sTemp2,'@');

    AreaBase^.Modified:=True;
    Flags:=Flags or afxSendLinked;
  end;
begin
  S:=strTrimB(S,[#32]);

  If S[Length(S)] in afxModifiers then Dec(S[0]);
  While S[Pos(',',S)+1]=#32 do Delete(S,Pos(',',S)+1,1);
  While S[Pos('/',S)+1]=#32 do Delete(S,Pos('/',S)+1,1);

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);

      Found:=False;
      For i2:=1  to Length(S) do
        If not (S[i2] in afxAllMask) then
          begin
            Found:=true;
            break;
          end;

      If not Found then
        If not TempNode^.CheckFlag('A') then
          begin
            objStreamWriteLn(ReceiptLink,'  '+
              LngFile^.GetString(LongInt(lngUnallowedAll)));
              continue;
          end;

      Found:=False;
      AreaBase^.EchoMail^.ForEach(@ProcessArea);

      If not Found then
       If not RequestFromUplink(sTemp) then
          objStreamWriteLn(ReceiptLink,'  '+
            LngFile^.GetString(LongInt(lngUnknownAreaOrMetacommand)));
    end;

  objStreamWriteLn(ReceiptLink,' ');
end;

Procedure TAreafix.ProcessUnSubscribe(S:string);
var
  i : longint;
  sTemp : string;
  Found : boolean;
  TempLink : PNodelistItem;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    sTemp2 : string;
  begin
    If not GrepCheck(sTemp,TempArea^.Name^,False) then exit;

    Found:=True;

    TempLink:=TempArea^.FindLink(TempNode^.Address);
    If TempLink=nil then
      begin
        LngFile^.AddVar(TempArea^.Name^);
        objStreamWriteLn(ReceiptLink,'  '+
          LngFile^.GetString(LongInt(lngAreaAlreadyUnSubscribed)));
        exit;
      end;

    If TempLink^.Mode=modLocked then
      begin
        LngFile^.AddVar(TempArea^.Name^);
        objStreamWriteLn(ReceiptLink,'  '+
          LngFile^.GetString(LongInt(lngAreaIsLocked)));
        exit;
      end;

    If (TempLink^.Mode=modRead) or (TempLink^.Mode=modWrite)
      then ModeSaver^.AddMode(TempNode^.Address,TempArea^.Name^,TempLink^.Mode);

    LngFile^.AddVar(TempArea^.Name^);
    objStreamWriteLn(ReceiptLink,'  '+
      LngFile^.GetString(LongInt(lngAreaUnSubscribeAccepted)));
    TempArea^.RemoveLink(TempNode^.Address);

    LngFile^.AddVar(TempArea^.Name^);
    LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
    sTemp2:=LngFile^.GetString(LongInt(lngAreaUnSubscribedFrom));
    If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('³ '+sTemp2,'@');
    LogFile^.SendStr('³ '+sTemp2,'@');

    AreaBase^.Modified:=True;
    Flags:=Flags or afxSendLinked;
  end;
begin
  S:=strTrimB(S,[#32]);

  If S[Length(S)]=',' then Dec(S[0]);
  While S[Pos(',',S)+1]=#32 do Delete(S,Pos(',',S)+1,1);

  For i:=1 to strNumbOfTokens(S,[#32]) do
    begin
      sTemp:=strParser(S,i,[#32]);
      Found:=False;

      AreaBase^.EchoMail^.ForEach(@ProcessArea);

      If not Found then
        begin
          objStreamWriteLn(ReceiptLink,'  '+
            LngFile^.GetString(LongInt(lngUnknownAreaOrMetacommand)));
        end;
    end;

  objStreamWriteLn(ReceiptLink,'');
end;

Procedure TAreaFix.SendHelp;
var
  T : Text;
  sTemp : string;
begin
  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

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

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingHelpSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreaFix.SendList;
var
  T : Text;
  sTemp : string;
  TempCol : PStringsCollection;
  i : longint;
  Groups : string;
begin
  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

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

          Groups:=NodeBase^.GetGroups(AbsMessage^.FromAddress);

          For i:=1 to Length(Groups) do
           If GroupBase^.FindArea(Groups[i])<>nil then
             WriteGroup(Groups[i],ReceiptLink,TempCol,afxAll,AbsMessage^.FromAddress);

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

            For i:=0 to AreaBase^.Areas^.Count-1 do
             WriteArea(AreaBase^.Areas^.At(i),ReceiptLink,TempCol,
               afxAll,AbsMessage^.FromAddress);

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;

  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingListSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreaFix.SendLinked;
var
  T : Text;
  sTemp : string;
  TempCol : PStringsCollection;
  i : longint;
  Groups : string;
begin
  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

  Assign(T,Templates^.Query^);
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

          Groups:=NodeBase^.GetGroups(AbsMessage^.FromAddress);

          For i:=1 to Length(Groups) do
           If GroupBase^.FindArea(Groups[i])<>nil then
             WriteGroup(Groups[i],ReceiptLink,TempCol,afxLinked,AbsMessage^.FromAddress);

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

            For i:=0 to AreaBase^.Areas^.Count-1 do
             WriteArea(AreaBase^.Areas^.At(i),ReceiptLink,TempCol,
               afxLinked,AbsMessage^.FromAddress);

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;

  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingLinkedSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreaFix.SendUnLinked;
var
  T : Text;
  sTemp : string;
  TempCol : PStringsCollection;
  i : longint;
  Groups : string;
begin
  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

  Assign(T,Templates^.Unlinked^);
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

          Groups:=NodeBase^.GetGroups(AbsMessage^.FromAddress);

          For i:=1 to Length(Groups) do
           If GroupBase^.FindArea(Groups[i])<>nil then
             WriteGroup(Groups[i],ReceiptLink,TempCol,afxUnLinked,AbsMessage^.FromAddress);

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

            For i:=0 to AreaBase^.Areas^.Count-1 do
             WriteArea(AreaBase^.Areas^.At(i),ReceiptLink,TempCol,
               afxUnLinked,AbsMessage^.FromAddress);

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;

  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingUnLinkedSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreafix.SendCompress;
Var
  TempCol : PStringsCollection;
  T : text;
  sTemp : string;


  Procedure ProcessString(P:Pointer);far;
  var
    pTemp : PString absolute P;
    sTemp : string;
  begin
    sTemp:='';
    If pTemp<>nil then sTemp:=pTemp^;
    MacroEngine^.ProcessString(sTemp);
    objStreamWriteLn(ReceiptLink,sTemp);
  end;

  Procedure ProcessArc(P:Pointer);far;
  var
    Arc : PString absolute P;
  begin
    MacroModifier^.SetArcName(Arc^);
    MacroModifier^.DoMacros;
    TempCol^.ForEach(@ProcessString);
  end;

begin
  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));

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

            AvailArcs^.ForEach(@ProcessArc);
            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingCompressSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreaFix.SendAvail;
var
  TempCol : PStringsCollection;
  T : text;

  Procedure ProcessArea(ListItem:PEArealistItem);far;
  var
    TempArea : PArea;
  begin
    TempArea:=New(PArea,Init(ListItem^.AreaName^));

    If ListItem^.AreaDesc<>nil
      then AssignStr(TempArea^.Desc,ListItem^.AreaDesc^);

    TempArea^.BaseType:=btEchomail;

    WriteArea(TempArea,ReceiptLink,TempCol,afxUnlinked,nullAddress);
    objDispose(TempArea);
  end;
  Procedure ProcessUplink(P:Pointer);far;
  var
    Uplink : PUplink absolute P;
    i : longint;
    sTemp : string;
  begin
    If Uplink^.Arealist.ListType=ltNone then exit;
    If TempNode^.Level<Uplink^.ForwardLevel then exit;
    If Pos(Uplink^.AutocreateGroup,TempNode^.Groups)=0 then exit;

    If Uplink^.Arealist.List=nil then ReadEcholist(Uplink^.AreaList,ftnAddressToStrEx(Uplink^.Address));
    If Uplink^.Arealist.List=nil then exit;

    MacroModifier^.SetAddress(Uplink^.Address);
    MacroModifier^.DoMacros;

    ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

    Assign(T,Templates^.Avail^);
    Reset(T);

    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);


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

            Uplink^.Arealist.List^.ListAreas^.ForEach(@ProcessArea);

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;

    Close(T);
    MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));
    MsgPoster^.FromName:=NewStr('Areafix');

    If TempNode^.SysopName<>nil then
      MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
       If AbsMessage^.FromName<>nil then
         MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);


    LngFile^.AddVar(ftnAddressToStrEx(Uplink^.Address));
    MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingAvailSubj)));

    MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
    MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
    MsgPoster^.Body:=ReceiptLink;
    MsgPoster^.CutBytes:=MsgSplitSize;

    MsgPoster^.Post;
    objDispose(MsgPoster);
  end;
begin
  UplinkBase^.Uplinks^.ForEach(@ProcessUplink);
end;

Function TAreaFix.RequestFromUplink(const S:string):boolean;
  Function ProcessUplink(P:Pointer):boolean;far;
  var
    Uplink : PUplink absolute P;
    i : longint;
    sTemp : string;
  begin
    ProcessUplink:=False;

    If Uplink^.Arealist.ListType=ltNone then exit;
    If TempNode^.Level<Uplink^.ForwardLevel then exit;
    If Pos(Uplink^.AutocreateGroup,TempNode^.Groups)=0 then exit;

    If Uplink^.Unconditional then i:=1 else
      begin
        i:=-1;
        If Uplink^.Arealist.List=nil then ReadEcholist(Uplink^.AreaList,ftnAddressToStrEx(Uplink^.Address));
        If Uplink^.Arealist.List<>nil
          then i:=Uplink^.Arealist.List^.FindArea(S);
      end;

    If i=-1 then exit;

    Uplink^.Requests^.Insert(NewStr('+'+S));

    ForwardFile^.AddForward(S,Uplink^.Address,TempNode^.Address);

    LngFile^.AddVar(ftnAddressToStrEx(Uplink^.Address));
    objStreamWriteLn(ReceiptLink,
       '  '+LngFile^.GetString(LongInt(lngRequestForwarded)));

    LngFile^.AddVar(ftnAddressToStrEx(Uplink^.Address));
    LngFile^.AddVar(S);
    sTemp:=LngFile^.GetString(LongInt(lngRequestForwardedLog));
    If AreafixLogFile<>nil
       then AreafixLogFile^.SendStr('³ '+sTemp,'&');
    LogFile^.SendStr('³ '+sTemp,'&');

    ProcessUplink:=True;
  end;
begin
  RequestFromUplink:=UplinkBase^.Uplinks^.FirstThat(@ProcessUplink)<>nil;
end;

Procedure TAreaFix.SendRulesList;
var
  T : Text;
  sTemp : string;
  TempCol : PStringsCollection;
  i : longint;
  Groups : string;
begin
  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

  Assign(T,Templates^.RulesList^);
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

          Groups:=NodeBase^.GetGroups(AbsMessage^.FromAddress);

          For i:=1 to Length(Groups) do
           If GroupBase^.FindArea(Groups[i])<>nil then
             WriteGroup(Groups[i],ReceiptLink,TempCol,afxWithRules,AbsMessage^.FromAddress);

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

            For i:=0 to AreaBase^.Areas^.Count-1 do
             WriteArea(AreaBase^.Areas^.At(i),ReceiptLink,TempCol,
               afxWithRules,AbsMessage^.FromAddress);

            objDispose(TempCol);
            continue;
          end;

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;

  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingRulesListSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;


Procedure TAreaFix.ProcessMessage;
var
  sTemp : string;
begin
  AbsMessage:=AreafixInBase^.GetAbsMessage;

  If (not CheckAlias(strUpper(AbsMessage^.ToName^))) or
   (AddressBase^.FindAddress(AbsMessage^.ToAddress)=nil)
     then exit;

  MacroModifier^.SetOAddress(AbsMessage^.ToAddress);
  MacroModifier^.SetDAddress(AbsMessage^.FromAddress);
  MacroModifier^.SetAddress(AbsMessage^.FromAddress);
  MacroModifier^.DoMacros;

  If CopyBase<>nil then CopyMessage;

  TempNode:=NodeBase^.FindNode(AbsMessage^.FromAddress);

  If TempNode=nil then
    begin
      ProcessUnknownNode;
      KillMessage;
      exit;
    end;

  If (TempNode^.AreafixPassword<>nil) and
     ((AbsMessage^.Subject=nil)
       or (TempNode^.AreafixPassword^<>strUpper(AbsMessage^.Subject^)))
  then
    begin
      ProcessBadPassword;
      KillMessage;
      exit;
    end;

  MacroModifier^.SetCurrentArc(TempNode^.Archiver^);
  MacroModifier^.DoMacros;

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngProcessingRequest));

  WriteLn(sTemp);
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Υ '+sTemp,#32);
  LogFile^.SendStr('Υ '+sTemp,#32);

  ReceiptLink:=New(PMemorystream,Init(0,cBuffSize));
  Flags:=Flags and afxReset;

  AbsMessage^.MessageBody^.SetPos(0);
  While not AbsMessage^.MessageBody^.EndOfMessage do
    begin
      sTemp:=strTrimB(strUpper(AbsMessage^.MessageBody^.GetMsgString),[#32]);
      If sTemp='' then continue;
      If sTemp[1]='>' then continue;
      If Copy(sTemp,1,3)='---' then continue;
      If Copy(sTemp,1,9)=' * Origin' then continue;

      objStreamWrite(ReceiptLink,'>');
      objStreamWriteLn(ReceiptLink,sTemp);

      If Copy(sTemp,1,5)='%LIST' then ProcessList(sTemp) else
      If Copy(sTemp,1,6)='%BLIST' then ProcessBList else
      If Copy(sTemp,1,6)='%QUERY' then ProcessLinked else
      If Copy(sTemp,1,7)='%LINKED' then ProcessLinked else
      If Copy(sTemp,1,9)='%UNLINKED' then ProcessUnLinked else
      If Copy(sTemp,1,6)='%AVAIL' then ProcessAvail else
      If Copy(sTemp,1,9)='%COMPRESS' then ProcessCompress(sTemp) else
      If Copy(sTemp,1,4)='%PWD' then ProcessPwd(sTemp) else
      If Copy(sTemp,1,7)='%PKTPWD' then ProcessPktPwd(sTemp) else
      If Copy(sTemp,1,8)='%PASSIVE' then ProcessPassive(sTemp) else
      If Copy(sTemp,1,6)='%PAUSE' then ProcessPassive(sTemp) else
      If Copy(sTemp,1,7)='%ACTIVE' then ProcessActive(sTemp) else
      If Copy(sTemp,1,7)='%RESUME' then ProcessActive(sTemp) else
      If Copy(sTemp,1,6)='%RULES' then ProcessRules(sTemp) else
      If sTemp[1]='+' then ProcessSubscribe(strTrimL(sTemp,['+'])) else
      If sTemp[1]='-' then ProcessUnSubscribe(strTrimL(sTemp,['-'])) else
      If Copy(sTemp,1,4)='%SUB' then ProcessSubscribe(Copy(sTemp,5,Length(sTemp)-4)) else
      If Copy(sTemp,1,6)='%UNSUB' then ProcessUnSubscribe(Copy(sTemp,7,Length(sTemp)-6)) else
      If Copy(sTemp,1,5)='%+ALL' then ProcessSubscribe('*') else
      If Copy(sTemp,1,5)='%-ALL' then ProcessUnSubscribe('*') else
      If sTemp='%HELP' then ProcessHelp else
      ProcessSubscribe(sTemp);
    end;

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngAreafixReply)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);

  KillMessage;

  WriteLn;

  If (Flags and afxSendHelp)=afxSendHelp then SendHelp;
  If (Flags and afxSendList)=afxSendList then SendList;
  If (Flags and afxSendLinked)=afxSendLinked then SendLinked;
  If (Flags and afxSendUnLinked)=afxSendUnLinked then SendUnLinked;
  If (Flags and afxSendCompress)=afxSendCompress then SendCompress;
  If (Flags and afxSendAvail)=afxSendAvail then SendAvail;
  If (Flags and afxSendRulesList)=afxSendRulesList then SendRulesList;

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr('Τ '+LngFile^.GetString(LongInt(lngDone)),#32);
  LogFile^.SendStr('Τ '+LngFile^.GetString(LongInt(lngDone)),#32);
end;

Procedure TAreaFix.ScanNetmail;
begin
  AreafixInBase:=EchoQueue^.OpenBase(AreafixIn);
  If AreafixInBase=nil then
    begin
      LngFile^.AddVar('AreafixIn');
      ErrorOut(LngFile^.GetString(LongInt(lngFailedToOpenBase)));
    end;

  AreafixOutBase:=EchoQueue^.OpenBase(AreafixOut);
  If AreafixOutBase=nil then
    begin
      LngFile^.AddVar('AreafixOut');
      ErrorOut(LngFile^.GetString(LongInt(lngFailedToOpenBase)));
    end;

  If CopyArea<>nil then
    begin
      CopyBase:=EchoQueue^.OpenBase(CopyArea);
      If CopyBase<>nil then CopyBase^.SetBaseType(btNetmail)
      else
        begin
          LngFile^.AddVar('CopyRequests');
          ErrorOut(LngFile^.GetString(LongInt(lngFailedToOpenBase)));
        end;
    end;

  AreafixInBase^.SetBaseType(btNetmail);
  AreafixOutBase^.SetBaseType(btNetmail);

  ModeSaver:=New(PModeSaver,Init(DataPath^+'\modes.dat'));

  RulesBase^.LoadRules;

  If AreafixLogFile<>nil then
    begin
      AreafixLogFile^.SetLogMode('AREAFIX');

      AreafixLogFile^.Open;
      If AreafixLogFile^.Status<>logOK
         then ErrorOut(AreafixLogFile^.ExplainStatus(AreafixLogFile^.Status));
    end;

  TextColor(7);
  WriteLn(LngFile^.GetString(LongInt(lngScanningAreafixNetmail)));
  Writeln;

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr(LngFile^.GetString(LongInt(lngScanningAreafixNetmail)),#32);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngScanningAreafixNetmail)),#32);

  AreafixInBase^.Seek(0);
  AreafixInBase^.SeekNext;
  While AreafixInBase^.Status=mlOk do
    begin
      AreafixInBase^.OpenMessage;

      If not (AreafixInBase^.CheckFlag(flgLocked) or
         AreafixInBase^.CheckFlag(flgReceived)) then ProcessMessage;

      AreafixInBase^.CloseMessage;
      AreafixInBase^.SeekNext;
    end;

  objDispose(ModeSaver);

  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);

  RulesBase^.ProcessSend;

  AreaBase^.CheckForPassive;

  WriteLn;

  DoBeforePack;

  Arcer:=New(PArcer,Init);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngPackingOutboundMail)),#32);
  Arcer^.PackQueue;
  objDispose(Arcer);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  DoAfterPack;
end;

Procedure TAreaFix.CopyMessage;
begin
  CopyBase^.CreateMessage(False);
  CopyBase^.SetAbsMessage(AbsMessage);
  CopyBase^.WriteMessage;
  CopyBase^.MessageBody:=nil;
  CopyBase^.CloseMessage;
end;

Procedure TAreafix.KillMessage;
begin
  If (Flags and afxKeepRequests)=afxKeepRequests then
    begin
      AreafixInBase^.SetFlag(flgReceived);
      AreafixInBase^.WriteMessage;
    end
  else AreafixInBase^.KillMessage;
end;

Procedure TAreafix.ProcessUnknownNode;
var
  T : Text;
  sTemp : string;
begin
  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngUnknownNode));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr(sTemp,'!');
  LogFile^.SendStr(sTemp,'!');

  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

  Assign(T,Templates^.BadNode^);
  Reset(T);
    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        sTemp:=strTrimR(sTemp,[#32]);

        MacroEngine^.ProcessString(sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
  Close(T);

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If AbsMessage^.FromName<>nil then
    MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngUnknownNodeSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreafix.ProcessBadPassword;
var
  T : Text;
  sTemp : string;
begin
  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.FromAddress));
  sTemp:=LngFile^.GetString(LongInt(lngBadPassword));
  If AreafixLogFile<>nil
     then AreafixLogFile^.SendStr(sTemp,'!');
  LogFile^.SendStr(sTemp,'!');

  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

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

  MsgPoster:=New(PMsgPoster,Init(AreafixOutBase));

  MsgPoster^.FromName:=NewStr('Areafix');

  If TempNode^.SysopName<>nil then
    MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
     If AbsMessage^.FromName<>nil then
       MsgPoster^.ToName:=NewStr(AbsMessage^.FromName^);

  MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngBadPasswordSubj)));

  MsgPoster^.FromAddress:=AbsMessage^.ToAddress;
  MsgPoster^.ToAddress:=AbsMessage^.FromAddress;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=MsgSplitSize;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreafix.CreateMessage(From:PNode;const Command:string);
begin
  AreafixInBase:=EchoQueue^.OpenBase(AreafixIn);
  If AreafixInBase=nil then
    begin
      LngFile^.AddVar('AreafixIn');
      ErrorOut(LngFile^.GetString(LongInt(lngFailedToOpenBase)));
    end;
  AreafixInBase^.SetBaseType(btNetmail);

  ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));
  objStreamWriteLn(ReceiptLink, Command);

  MsgPoster:=New(PMsgPoster,Init(AreafixInBase));

  MsgPoster^.ToName:=NewStr('Areafix');
  MsgPoster^.FromName:=NewStr('Sysop');
  If From^.AreafixPassword<>nil
     then MsgPoster^.Subj:=NewStr(From^.AreafixPassword^);


  NewStr(LngFile^.GetString(LongInt(lngBadPasswordSubj)));

  MsgPoster^.FromAddress:=From^.Address;
  MsgPoster^.ToAddress:=From^.UseAKA;
  MsgPoster^.Body:=ReceiptLink;
  MsgPoster^.CutBytes:=0;

  MsgPoster^.Post;
  objDispose(MsgPoster);
end;

Procedure TAreafix.SendBCL(FromAddress, ToAddress:TAddress);
Var
  EchoList : PBCL;
  TempAreaItem : PEArealistitem;
  sTemp : string;

  Procedure ProcessArea(P:Pointer);far;
  var
    TempArea : PArea absolute P;
    TempDesc : string;
  begin
    If (TempArea^.BaseType<>btEchomail)
      or (TempArea^.CheckFlag('H')) then exit;

    TempDesc:='';
    If TempArea^.Desc<>nil
      then TempDesc:=TempArea^.Desc^;

    TempAreaItem:=New(PEArealistitem,
      Init(TempArea^.Name^,TempDesc));
    Echolist^.ListAreas^.Insert(TempAreaItem);
  end;
begin
  sTemp:=QueuePath+'\'+ftnPktName+'.QQQ';
  EchoList:=New(PBCL,Init);
  EchoList^.SetFilename(sTemp);
  EchoList^.SetAddress(FromAddress);
  EchoList^.SetAddressDest(ToAddress);
  EchoList^.SetMgrName('Areafix');

  AreaBase^.Areas^.ForEach(@ProcessArea);

  EchoList^.Write;

  objDispose(EchoList);
end;

end.
