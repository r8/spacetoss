{
 Router for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit Route;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  arc,
  nodes,
  r8abs,
  r8ctl,
  r8pkt,
  r8pkt2p,
  r8str,
  r8ftn,
  r8objs,
  r8mail,
  r8dtm,
  r8out,

  lng,
  color,

  crt,
  objects;

Var
  NeedsPack : boolean;
  NetBase : PMessageBase;

Type

  TRouteRule = object(TObject)
    Flavour : word;
    RouteTo : PString;
    RouteFrom : PStringsCollection;

    Constructor Init;
    Destructor Done;virtual;
    Function CheckAddress(AbsMessage:PAbsMessage):boolean;
    Procedure PackMessage(AbsMessage:PAbsMessage);
  end;
  PRouteRule = ^TRouteRule;

  TRouteRules = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PRouteRules = ^TRouteRules;

  TRouter = object(TObject)
    RouteCTL : PCTLFile;
    RouteRules : PRouteRules;

    QueueDir : PPktDir;
    Arcer : PArcer;

    Constructor Init(const Name:string);
    Destructor Done;virtual;

    Procedure Route;
    Procedure ProcessMessage;

    Procedure ScanMainNetmail;
  end;
  PRouter = ^TRouter;

implementation

Uses
  global;

Constructor TRouter.Init(const Name:string);
Var
  i,i2 : longint;
  TempParameter : PParsedItem;
  TempRouteRule : PRouteRule;
  sTemp:string;
begin
  inherited Init;

  RouteRules:=New(PRouteRules,Init($10,$10));

  RouteCTL:=New(PCtlFile,Init);

  RouteCTL^.AddKeyword('Crash');
  RouteCTL^.AddKeyword('Direct');
  RouteCTL^.AddKeyword('Hold');
  RouteCTL^.AddKeyword('Normal');
  RouteCTL^.AddKeyword('Immediate');

  RouteCTL^.SetCTLName(Name);
  RouteCTL^.LoadCTL;

  If RouteCTL^.CTLError<>ctlErrNone
      then ErrorOut(RouteCTL^.ExplainStatus(RouteCTL^.CTLError));

  For i:=0 to RouteCTL^.Parsed^.Count-1 do
    begin
      TempParameter:=RouteCTL^.Parsed^.At(i);

      TempRouteRule:=New(PRouteRule,Init);
      RouteRules^.Insert(TempRouteRule);

      TempParameter^.Keyword^:=strUpper(TempParameter^.Keyword^);

      If TempParameter^.Keyword^='CRASH' then TempRouteRule^.Flavour:=flvCrash
         else
      If TempParameter^.Keyword^='DIRECT' then TempRouteRule^.Flavour:=flvDirect
         else
      If TempParameter^.Keyword^='NORMAL' then TempRouteRule^.Flavour:=flvNormal
         else
      If TempParameter^.Keyword^='HOLD' then TempRouteRule^.Flavour:=flvHold
         else
      If TempParameter^.Keyword^='IMMEDIATE'
         then TempRouteRule^.Flavour:=flvImmediate;

      TempRouteRule^.RouteTo:=NewStr(strParser(TempParameter^.Value^,1,[#32,#9]));
      If TempRouteRule^.RouteTo=nil
             then ErrorOut('Invalid route rule in '+Name);

      For i2:=1 to strNumbOfTokens(TempParameter^.Value^,[#32,#9])-1 do
        begin
          sTemp:=strParser(TempParameter^.Value^,1+i2,[#32,#9]);
          TempRouteRule^.RouteFrom^.Insert(NewStr(sTemp));
        end;
    end;
  objDispose(RouteCTL);
end;

Destructor TRouter.Done;
begin
  objDispose(RouteRules);
  objDispose(RouteCTL);
  objDispose(Arcer);

  inherited Done;
end;

Procedure TRouter.ProcessMessage;
Var
  AbsMessage : PAbsMessage;

  Function CheckMessage(P:pointer):boolean;far;
  Var
    RouteRule : PRouteRule absolute P;
  begin
    CheckMessage:=RouteRule^.CheckAddress(AbsMessage);
  end;
begin
  AbsMessage:=NetBase^.GetAbsMessage;

  If AddressBase^.FindAddress(AbsMessage^.ToAddress)<>nil then exit;

  RouteRules^.FirstThat(@CheckMessage);
end;

Procedure TRouteRules.FreeItem(Item:pointer);
begin
  objDispose(PRouteRule(item));
end;

Procedure TRouter.ScanMainNetmail;
Var
  i:integer;
  sTemp : string;
begin
  NetBase:=EchoQueue^.OpenBase(NetmailArea);

  If NetBase=nil then
    begin
      LngFile^.AddVar(NetmailArea^.Name^);
      sTemp:=LngFile^.GetString(LongInt(lngFailedToOpenBase));
      WriteLn(sTemp);
      LogFile^.SendStr(sTemp,'!');
    end;

  NetBase^.SetBaseType(btNetmail);

  NetBase^.Seek(1);
  For i:=0 to NetBase^.GetCount-1 do
    begin
      NetBase^.OpenMessage;

      If (not NetBase^.CheckFlag(flgLocked)) and
        (not NetBase^.CheckFlag(flgSent)) then ProcessMessage;

      NetBase^.CloseMessage;
      NetBase^.SeekNext;
    end;
  NetBase^.Close;
end;

Procedure TRouter.Route;
begin
  NeedsPack:=false;
  TosserOutbounds^.OpenOutbounds;

  Writeln(LngFile^.GetString(LongInt(lngRoutingMessages)));
  WriteLn;
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngRoutingMessages)),#32);

  ScanMainNetmail;

  TosserOutbounds^.CloseOutbounds;

  If NeedsPack then
    begin
      QueueDir:=New(PPktDir,Init);
      QueueDir^.SetPktExtension('QQQ');
      QueueDir^.OpenDir(QueuePath);
      QueueDir^.FastOpen:=True;

      TextColor(colOperation);
      Writeln(LngFile^.GetString(LongInt(lngPackingOutboundMail)));
      TextColor(colLongline);
      Writeln(constLongLine);
      TextColor(7);
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngPackingOutboundMail)),#32);

      Arcer:=New(PArcer,Init);
      Arcer^.PackQueue;
      objDispose(Arcer);
    end;

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
end;

Constructor TRouteRule.Init;
begin
  inherited Init;

  RouteFrom:=New(PStringsCollection,Init($10,$10));
  RouteTo:=nil;
end;

Destructor TRouteRule.Done;
begin
  objDispose(RouteFrom);
  DisposeStr(RouteTo);

  inherited Done;
end;

Function TRouteRule.CheckAddress(AbsMessage:PAbsMessage):boolean;
Var
  StringAddress : string;
  StringAddressFull : string;

  Function ProcessAddress(P:Pointer):boolean;
  var
    Address : PString absolute p;
  begin
    If (strWildCard(StringAddressFull,Address^)) or
       (strWildCard(StringAddress,Address^)) then
         begin
             ProcessAddress:=True;
             PackMessage(AbsMessage);
         end
    else ProcessAddress:=False;
  end;

begin
  CheckAddress:=False;

  StringAddressFull:=ftnAddressToStr(AbsMessage^.ToAddress);
  StringAddress:=ftnAddressToStrEx(AbsMessage^.ToAddress);

  If RouteFrom^.Count=0 then CheckAddress:=ProcessAddress(RouteTo)
    else CheckAddress:=RouteFrom^.FirstThat(@ProcessAddress)<>nil;
end;

Procedure TRouteRule.PackMessage(AbsMessage:PAbsMessage);
Var
  TempNode : PNode;
  i:longint;
  Packet : PPacket2p;

  sTemp : string;
  TempAddress:TAddress;
  BodyStream : PStream;
  Flags  : longint;
  Datetime : TDateTime;
begin
  TempNode:=NodeBase^.FindNode(AbsMessage^.ToAddress);

  If TempNode=nil then
    begin
      TempNode:=New(PNode,Init(AbsMessage^.ToAddress));
      TempNode^.ChangeSysopName('DEFAULT');
      TempNode^.OutBound:=TosserOutbounds^.Default;
      TempNode^.Flavour:=flvNormal;
      AddressBase^.FindNearest(TempNode^.Address,TempNode^.UseAKA);
    end;

  Packet:=TempNode^.Outbound^.GetPacket(AbsMessage^.ToAddress,Flavour);

  Packet^.SetFromAddress(TempNode^.UseAKA);
  Packet^.SetToAddress(AbsMessage^.ToAddress);
  Packet^.WritePkt;

  Packet^.CreateNewMsg(False);

  Packet^.SetAbsMessage(AbsMessage,False);

  If Packet^.MessageBody^.ViaLink=nil
    then Packet^.MessageBody^.ViaLink:=New(PMemoryStream,Init(0,$1000));
  objStreamWriteLn(Packet^.MessageBody^.ViaLink,
      #1'Via '+ftnAddressToStrEx(TempNode^.UseAKA)
      +' @'+dtmFTNPackedDate+' '+constPid);

  LngFile^.AddVar(ftnAddressToStrEx(AbsMessage^.ToAddress));
  LngFile^.AddVar(ftnAddressToStrEx(TempNode^.Address));
  sTemp:=LngFile^.GetString(LongInt(lngRoutingMessage));

  WriteLn(sTemp);
  LogFile^.SendStr(sTemp,'@');

  Packet^.WriteMsg;
  Packet^.MessageBody:=nil;
  Packet^.ClosePkt;
  objDispose(AbsMessage);

  NetBase^.SetFlag(flgSent);
  NetBase^.WriteHeader;

  If (NetBase^.CheckFlag(flgKill))
     or (KillAfterRoute)
            then NetBase^.KillMessage;

  NetBase^.CloseMessage;

  If TempNode^.Outbound^.GetOutType=outAMA then NeedsPack:=True;
  If TempNode^.SysopName^='DEFAULT' then objDispose(TempNode);
end;

end.
