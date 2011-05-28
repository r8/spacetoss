{
 Scripts Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit scripts;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  cs2,
  cs2_var,

  lng,

  r8objs,
  r8dos,
  r8abs,
  r8str,
  r8pkt,
  r8ftn,

  dos,
  objects;

Type

  TScriptCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PScriptCollection = ^TScriptCollection;

  TScriptsEngine = object(TObject)
    ScriptsDir : PString;
    ScriptCollection : PScriptCollection;

    ScriptMessage : PAbsMessage;

    Constructor Init;
    Destructor Done;virtual;

    Procedure LoadScripts;
    Procedure PostMessages;

    Function TosserHook(HookName:string):boolean;
    Procedure RunHook(HookName:string);
  end;
  PScriptsEngine = ^TScriptsEngine;

implementation

Uses
  global;

{$I spsapi.pas}

Procedure TScriptCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then Dispose(PCs2PascalScript(Item),Destroy);
end;

Constructor TScriptsEngine.Init;
begin
  inherited Init;

  ScriptCollection:=New(PScriptCollection,Init($20,$20));
  Messages:=New(PAbsMessageCollection,Init($10,$10));;
  ScriptsDir:=nil;
  ScriptMessage:=nil;
end;

Destructor TScriptsEngine.Done;
begin
  objDispose(ScriptCollection);
  objDispose(Messages);
  DisposeStr(ScriptsDir);

  inherited Done;
end;

Procedure TScriptsEngine.LoadScripts;
Var
  SR : SearchRec;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}

  TempScript : PCs2PascalScript;
  pTemp : PChar;
  F : File;
  l : longint;
begin
  If (ScriptsDir=nil) or (not dosDirExists(ScriptsDir^)) then exit;

  SLoadWrite(LngFile^.GetString(LongInt(lngReadScripts)));

  FindFirst(ScriptsDir^+'\*.sps',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      Assign (F,ScriptsDir^+'\'+SR.Name);
{$I-}
      Reset (F, 1);
{$I+}

      If IOResult<>0 then continue;

      l:=FileSize(F);
      If l>65520 then continue;

      GetMem(pTemp,l+1);
      BlockRead(F,pTemp[0],l);
      pTemp[l]:=#0;

      Close (F);

      TempScript:=New(PCs2PascalScript,Create(Nil));
      TempScript^.OnUses:=OnUses;
      TempScript^.SetText(pTemp);

      If TempScript^.ErrorCode<>ENoError then
        begin
          WriteLn('Error loading '+SR.Name+': '+strIntToStr(TempScript^.ErrorCode));
          Dispose(TempScript,Destroy);
        end
        else ScriptCollection^.Insert(TempScript);

      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  SLoadOk;
end;

Procedure TScriptsEngine.PostMessages;
Var
  PktDir : PPktDir;

  Procedure PostMessage(P:pointer);far;
  var
    AbsMessage : PAbsMessage absolute P;
  begin
    PktDir^.CreateNewPkt;
    PktDir^.Packet^.SetPktAreaType(btEchomail);

    If (AbsMessage^.Area=nil) or (AbsMessage^.Area^='NETMAIL')
        then PktDir^.Packet^.SetPktAreaType(btNetmail);

    PktDir^.Packet^.SetToAddress(NullAddress);
    PktDir^.Packet^.SetFromAddress(NullAddress);
    PktDir^.Packet^.SetPassword('');
    PktDir^.Packet^.WritePkt;

    PktDir^.Packet^.CreateNewMsg(False);
    PktDir^.Packet^.SetAbsMessage(AbsMessage,False);
    PktDir^.Packet^.WriteMsg;
    PktDir^.Packet^.MessageBody:=nil;
    PktDir^.Packet^.CloseMsg;
  end;
begin
  If Messages^.Count=0 then exit;

  PktDir:=New(PPktDir,Init);
  PktDir^.SetPktExtension('PKT');
  PktDir^.OpenDir(LocalInboundPath);
  PktDir^.PktType:=ptType2p;

  Messages^.ForEach(@PostMessage);

  PktDir^.ClosePkt;
  PktDir^.CloseDir;
  objDispose(PktDir);

  Messages^.FreeAll;
end;

Function TScriptsEngine.TosserHook(HookName:string):boolean;
Var
  pTemp : pointer;

  Function ProcessHook(P:pointer):boolean;far;
  Var
    TempScript : PCs2PascalScript absolute P;
    CajVar : PCajVariant;
    VarMan : PVariableManager;
  begin
    ProcessHook:=False;

    VarMan:=VM_Create(Nil);
    VM_Add(VarMan,CreateInteger(0),'MSG');

    CajVar:=TempScript^.RunScriptProc(HookName,VarMan);
    If TempScript^.ErrorCode=ENoError then ProcessHook:=CajVar^.CV_Bool
      else If TempScript^.ErrorCode<>EUnknownProcedure
        then Writeln('ScriptError:'+strIntToStr(TempScript^.ErrorCode));

    VM_Destroy(VarMan);
    DestroyCajVariant(CajVar);
  end;
begin
  Messages^.AtInsert(0,ScriptMessage);

  pTemp:=ScriptCollection^.FirstThat(@ProcessHook);
  TosserHook:=pTemp<>nil;

  Messages^.AtDelete(0);
  PostMessages;
end;

Procedure TScriptsEngine.RunHook(HookName:string);

  Procedure ProcessHook(P:pointer);far;
  Var
    TempScript : PCs2PascalScript absolute P;
    CajVar : PCajVariant;
    VarMan : PVariableManager;
  begin
    VarMan:=VM_Create(Nil);

    CajVar:=TempScript^.RunScriptProc(HookName,VarMan);
    If TempScript^.ErrorCode<>EUnknownProcedure
        then Writeln('ScriptError:'+strIntToStr(TempScript^.ErrorCode));

    VM_Destroy(VarMan);
    DestroyCajVariant(CajVar);
  end;
begin
  ScriptCollection^.ForEach(@ProcessHook);
  PostMessages;
end;

end.
