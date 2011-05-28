{
 Rules stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit rules;

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
  r8dos,
  r8str,
  r8dtm,
  r8ftn,

  nodes,
  poster,
  lng,

  dos,
  objects;

const
  constRulesSig = 'r8Rules';

type

  TRule = object(TObject)
    Name : PString;
    FileName : PString;
    FileTime : longint;

    Constructor Init;
    Destructor  Done; virtual;
  end;
  PRule = ^TRule;

  TRuleCollection = object(TSortedCollection)
    Procedure FreeItem(item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PRuleCollection = ^TRuleCollection;

  TSendQueueElement = object(TObject)
    Name : PString;
    Node : PNode;

    Constructor Init(const AName:string;const ANode:PNode);
    Destructor  Done; virtual;
  end;
  PSendQueueElement = ^TSendQueueElement;

  TSendQueue = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PSendQueue = ^TSendQueue;

  TRulesBase = object(TObject)
    RulesId : PStringCollection;
    RulesDirs : PStringCollection;
    RulesCollection : PRuleCollection;
    SendQueue : PSendQueue;

    Constructor Init;
    Destructor  Done; virtual;
    Procedure LoadRules;
    Procedure CompileRules;

    Function FindRule(const Name:string):PRule;

    Procedure ProcessSend;
  end;
  PRulesBase = ^TRulesBase;

implementation

Uses
  global;

Constructor TRule.Init;
begin
  inherited Init;

  Name:=nil;
  FileName:=nil;
  FileTime:=0;
end;

Destructor  TRule.Done;
begin
  DisposeStr(Name);
  DisposeStr(FileName);
  FileTime:=0;

  inherited Done;
end;

Procedure TRuleCollection.FreeItem(Item:pointer);
Begin
  If Item<>nil then objDispose(PRule(Item));
End;

{$IFDEF VER70}
Function TRuleCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TRuleCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  S1,S2:String;
begin
  S1:=PRule(Key1)^.Name^;
  S2:=PRule(Key2)^.Name^;

  If S1>S2 then Compare:=1 else
  If S1<S2 then Compare:=-1 else
  Compare:=0;
end;

Procedure TSendQueue.FreeItem(Item:pointer);
Begin
  If Item<>nil then objDispose(PSendQueueElement(Item));
End;

Constructor TRulesBase.Init;
begin
  inherited Init;

  RulesDirs:=New(PStringCollection,Init($10,$10));
  RulesId:=New(PStringCollection,Init($10,$10));

  RulesCollection:=New(PRuleCollection,Init($100,$100));
  SendQueue:=New(PSendQueue,Init($100,$100));
end;

Destructor  TRulesBase.Done;
begin
  objDispose(RulesDirs);
  objDispose(RulesId);
  objDispose(RulesCollection);
  objDispose(SendQueue);

  inherited Done;
end;

Procedure TRulesBase.LoadRules;
var
  i : longint;
  S : PStream;
  Sig : string[7];
  TempRule : PRule;
begin
  If not dosFileExists(DataPath^+'\rules.dat') then
    begin
      CompileRules;
      exit;
    end;

  S:=New(PBufStream,Init(DataPath^+'\rules.dat',fmOpen or fmRead or fmDenyAll,$4000));
  i:=S^.GetSize;

  S^.Read(Sig,SizeOf(Sig));

  If Sig<>constRulesSig then
    begin
      objDispose(S);
      CompileRules;
      exit;
    end;

  While S^.GetPos<i-1 do
    begin
      TempRule:=New(PRule,Init);
      TempRule^.Name:=S^.ReadStr;
      TempRule^.FileName:=S^.ReadStr;
      S^.Read(TempRule^.FileTime,SizeOf(TempRule^.FileTime));

      RulesCollection^.Insert(TempRule);
    end;

  objDispose(S);
end;

Procedure TRulesBase.CompileRules;
Var
  S : PStream;
  Sig : string[7];

  Procedure ProcessDir(P:Pointer);far;
  var
    Id : PString;
    Dir : PString absolute P;
    T :text;
    sTemp : string;
    TempRule : PRule;
    SR : SearchRec;
  {$IFDEF VER70}
    i:integer;
  {$ELSE}
    i:longint;
  {$ENDIF}

    Function ProcessId(P:pointer):boolean;
    var
      TempId : PString absolute P;
    begin
      ProcessId:=False;
      If Copy(sTemp,1,Length(TempId^))=TempId^
        then ProcessId:=True;
    end;
  begin
    FindFirst(Dir^+'\*.*',AnyFile-Directory,SR);
    While DosError=0 do
      begin
        Assign(T,Dir^+'\'+SR.Name);
{$I-}
        Reset(T);
{$I+}
        If IOResult<>0 then
          begin
            FindNext(SR);
            continue;
          end;

        Readln(T,sTemp);
        Close(T);

        Id:=RulesId^.FirstThat(@ProcessId);

        If Id<>nil then
          begin
            sTemp:=Copy(sTemp,Length(Id^)+1,
                 Length(sTemp)-Length(Id^));

            sTemp:=strTrimB(sTemp,[#32,#8]);
            TempRule:=New(PRule, Init);
            TempRule^.FileName:=NewStr(Dir^+'\'+SR.Name);
            TempRule^.Name:=NewStr(strUpper(sTemp));
            TempRule^.FileTime:=dtmFileTimeUnix(TempRule^.FileName^);

            If RulesCollection^.Search(TempRule,i) then
              begin
                If PRule(RulesCollection^.At(i))^.FileTime<
                   TempRule^.FileTime then
                  begin
                    RulesCollection^.AtFree(i);
                    RulesCollection^.Insert(TempRule);
                  end;
              end
            else RulesCollection^.Insert(TempRule);
          end;

        FindNext(SR);
      end;
  {$IFNDEF VER70}
    FindClose(SR);
  {$ENDIF}
  end;

  Procedure ProcessRule(P:Pointer);far;
  var
    Rule : PRule absolute P;
  begin
    S^.WriteStr(Rule^.Name);
    S^.WriteStr(Rule^.FileName);
    S^.Write(Rule^.FileTime,SizeOf(Rule^.FileTime));
  end;
begin
  If (RulesId=nil) or (RulesDirs^.Count=0) then exit;

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngIndexingRules)),#32);

  RulesDirs^.ForEach(@ProcessDir);

  If RulesCollection^.Count=0 then exit;

  S:=New(PBufStream,Init(DataPath^+'\rules.dat',fmCreate or fmWrite or fmDenyAll,$4000));
  Sig:=constRulesSig;
  S^.Write(Sig,SizeOf(Sig));
  RulesCollection^.ForEach(@ProcessRule);
  objDispose(S);

  LngFile^.AddVar(strIntToStr(RulesCollection^.Count));
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngIndexedRules)),#32);
end;

Function TRulesBase.FindRule(const Name:string):PRule;
Var
  TempRule : PRule;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}
begin
  FindRule:=nil;

  TempRule:=New(PRule,Init);
  TempRule^.Name:=NewStr(strUpper(Name));
  If RulesCollection^.Search(TempRule,i) then FindRule:=RulesCollection^.At(i);
  objDispose(TempRule);
end;

Procedure TRulesBase.ProcessSend;
Var
  ReceiptLink : PStream;
  T : Text;
  sTemp : string;
  MsgPoster : PPoster;

  Procedure ProcessItem(Item:pointer);far;
  Var
    SendItem : PSendQueueElement absolute Item;
    TempRule : PRule;
  begin
    TempRule:=FindRule(SendItem^.Name^);
    If TempRule=nil then exit;

    LngFile^.AddVar(SendItem^.Name^);
    LngFile^.AddVar(ftnAddressToStrEx(SendItem^.Node^.Address));
    sTemp:=LngFile^.GetString(LongInt(lngSendingRulesTo));
    If AreafixLogFile<>nil
       then AreafixLogFile^.SendStr(sTemp,'@');
    LogFile^.SendStr(sTemp,'@');

    ReceiptLink:=New(PMemoryStream,Init(0,cBuffSize));

    Assign(T,TempRule^.FileName^);
{$I-}
    Reset(T);
{$I+}

    If IOResult<>0 then
      begin
        sTemp:=LngFile^.GetString(LongInt(lngctlCantFindFile));
        sTemp:=sTemp+#32+TempRule^.FileName^;

        If AreafixLogFile<>nil
           then AreafixLogFile^.SendStr(sTemp,'!');
        LogFile^.SendStr(sTemp,'!');

        exit;
      end;

    While not Eof(T) do
      begin
        ReadLn(T,sTemp);
        objStreamWriteLn(ReceiptLink,sTemp);
      end;
    Close(T);

    MsgPoster:=New(PMsgPoster,Init(Areafix^.AreafixOutBase));

    MsgPoster^.FromName:=NewStr('Areafix');

    MsgPoster^.ToName:=NewStr(SendItem^.Node^.SysopName^);

    LngFile^.AddVar(SendItem^.Name^);
    MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngSendingRulesSubj)));

    MsgPoster^.FromAddress:=SendItem^.Node^.UseAka;
    MsgPoster^.ToAddress:=SendItem^.Node^.Address;
    MsgPoster^.Body:=ReceiptLink;
    MsgPoster^.CutBytes:=MsgSplitSize;

    MsgPoster^.Post;
    objDispose(MsgPoster);
  end;
begin
  SendQueue^.ForEach(@ProcessItem);
  SendQueue^.FreeAll;
end;


Constructor TSendQueueElement.Init(const AName:string;const ANode:PNode);
begin
  inherited Init;

  Name:=NewStr(AName);
  Node:=ANode;
end;

Destructor  TSendQueueElement.Done;
begin
  DisposeStr(Name);

  inherited Done;
end;

end.
