{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Route;

interface

Uses
  global,
  arc,
  nodes,
  r8ctl,
  r8pkt,
  r8pkt2p,
  r8str,
  r8ftn,
  r8objs,
  r8dtm,
  r8out,
  objects;

Type

  TRouteRule = object(TObject)
    Flavour : word;
    RouteTo : string;
    RouteFrom : PStringsCollection;

    Constructor Init;
    Destructor Done;virtual;
    Function CheckAddress(Address:TAddress):boolean;
    Procedure PackMessage(Address:TAddress);
  end;

  PRouteRule = ^TRouteRule;

  TRouteRules = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;

  PRouteRules = ^TRouteRules;

  TRouteFile = object(TObject)
    RouteCTL : PCTLFile;
    RouteRules : PRouteRules;

    Constructor Init(const Name:string);
    Destructor Done;virtual;

    Procedure RouteMessage;
  end;

  PRouteFile = ^TRouteFile;

Var
  NeedsPack : boolean;
  QueueDir : PPktDir;


Procedure DoRoute;

implementation

Var
  RouteFile : PRouteFile;

Constructor TRouteFile.Init(const Name:string);
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

      TempRouteRule^.RouteTo:=strParser(TempParameter^.Value^,1,[#32,#9]);
      If TempRouteRule^.RouteTo=''
             then ErrorOut('Invalid route rule in '+Name);

      For i2:=1 to strNumbOfTokens(TempParameter^.Value^,[#32,#9])-1 do
        begin
          sTemp:=strParser(TempParameter^.Value^,1+i2,[#32,#9]);
          TempRouteRule^.RouteFrom^.Insert(NewStr(sTemp));
        end;
    end;
  objDispose(RouteCTL);
end;

Destructor TRouteFile.Done;
begin
  objDispose(RouteRules);
  objDispose(RouteCTL);

  inherited Done;
end;

Procedure TRouteFile.RouteMessage;
Var
  i : longint;
  TempRouteRule : PRouteRule;

  TempAddress : TAddress;
begin
{  NetmailDir^.GetToAddress(TempAddress);

  If AddressBase^.FindAddress(TempAddress)<>nil then exit;

  For i:=0 to RouteRules^.Count-1 do
    begin
      TempRouteRule:=RouteRules^.At(i);

      If TempRouteRule^.CheckAddress(TempAddress) then break;
    end;}
end;

Procedure TRouteRules.FreeItem(Item:pointer);
begin
  objDispose(PRouteRule(item));
end;

Procedure ScanMainNetmail;
Var
  i:integer;
begin
{  NetmailDir^.Seek(0);
  For i:=0 to NetmailDir^.GetCount-1 do
    begin
      NetmailDir^.OpenMessage;

      If (not NetmailDir^.CheckFlag(flgLocked)) and
        (not NetmailDir^.CheckFlag(flgSent))  then RouteFile^.RouteMessage;

      NetmailDir^.CloseMessage;
      NetmailDir^.SeekNext;
    end;

  NetmailDir^.Close;}
end;

Procedure DoRoute;
begin
  TosserOutbounds^.OpenOutbounds;

  RouteFile:=New(PRouteFile,Init(RouteFileName^));
  NeedsPack:=false;

  ScanMainNetmail;

  TosserOutbounds^.CloseOutbounds;

  If NeedsPack then
    begin
      QueueDir:=New(PPktDir,Init);
      QueueDir^.SetPktExtension('QQQ');
      QueueDir^.OpenDir(QueuePath);
      QueueDir^.FastOpen:=True;

{      PackQueue;}
    end;
  objDispose(RouteFile);
end;

Constructor TRouteRule.Init;
begin
  inherited Init;

  RouteFrom:=New(PStringsCollection,Init($10,$10));
end;

Destructor TRouteRule.Done;
begin
  objDispose(RouteFrom);

  inherited Done;
end;

Function TRouteRule.CheckAddress(Address:TAddress):boolean;
Var
  StringAddress : string;
  StringAddressFull : string;
  pTemp:PString;
  TempAddress : TAddress;
  i:integer;
begin
  CheckAddress:=False;

  StringAddressFull:=ftnAddressToStr(Address);
  StringAddress:=ftnAddressToStrEx(Address);

  If RouteFrom^.Count=0 then
    begin
      If (strWildCard(StringAddressFull,RouteTo)) or
         (strWildCard(StringAddress,RouteTo)) then
           begin
             CheckAddress:=True;
             PackMessage(Address);
           end;
    end
    else
    begin
      for i:=0 to RouteFrom^.Count-1 do
        begin
          pTemp:=RouteFrom^.At(i);

          If (strWildCard(StringAddressFull,pTemp^)) or
             (strWildCard(StringAddress,pTemp^)) then
            begin
              CheckAddress:=True;
              ftnStrToAddress(RouteTo,TempAddress);
              PackMessage(TempAddress);
            end;
        end;
    end;
end;

Procedure TRouteRule.PackMessage(Address:TAddress);
Var
  TempNode : PNode;
  i:longint;
  Packet : PPacket2p;

  TempAddress:TAddress;
  BodyStream : PStream;
  Flags  : longint;
  Datetime : TDateTime;
begin
{  TempNode:=NodeBase^.FindNode(Address);

  If TempNode=nil then
    begin
      TempNode:=New(PNode,Init(Address));
      TempNode^.ChangeSysopName('DEFAULT');
      TempNode^.OutBound:=DefOut;
      TempNode^.Flavour:=flvNormal;
      AddressBase^.FindNearest(TempNode^.Address,TempNode^.UseAKA);
    end;

  Packet:=TempNode^.Outbound^.GetPacket(Address,Flavour);

  Packet^.SetFromAddress(TempNode^.UseAKA);
  Packet^.SetToAddress(Address);
  Packet^.WritePkt;

  Packet^.CreateNewMsg(False);

  Packet^.SetMsgTo(NetmailDir^.GetTo);
  Packet^.SetMsgFrom(NetmailDir^.GetFrom);
  Packet^.SetMsgSubj(NetmailDir^.GetSubj);
  NetmailDir^.GetFlags(Flags);
  NetmailDir^.SetFlag(flgSent);

  Packet^.SetMsgFlags(Flags);

  NetmailDir^.GetDateWritten(DateTime);
  Packet^.SetMsgDateTime(DateTime);

  BodyStream:=NetmailDir^.MessageBody^.GetMsgBodyStream;
  Packet^.MessageBody^.AddToMsgBodyStream(BodyStream);
  objDispose(BodyStream);

  NetmailDir^.GetFromAddress(TempAddress);
  Packet^.SetMsgFromAddress(TempAddress);

  NetmailDir^.GetToAddress(TempAddress);
  Packet^.SetMsgToAddress(TempAddress);

  WriteLn('Route message to ',ftnAddressToStrEx(TempAddress),
                  ' via ',ftnAddressToStrEx(Address),'...');

  objStreamWriteLn(Packet^.MessageBody^.ViaLink,
      #1'Via '+ftnAddressToStrEx(TempNode^.UseAKA)
      +' @'+dtmFTNPackedDate+' '+constPid);

  Packet^.WriteMsg;
  Packet^.CloseMsg;
  Packet^.ClosePkt;
  objDispose(Packet);

  NetmailDir^.WriteMessage;

  If (NetmailDir^.CheckFlag(flgKill))
     or (KillAfterRoute)
            then NetmailDir^.KillMessage;
  NetmailDir^.CloseMessage;

  If TempNode^.Outbound^.GetOutType=outAMA then NeedsPack:=True;

  If TempNode^.SysopName^='DEFAULT' then objDispose(TempNode);}
end;

end.
