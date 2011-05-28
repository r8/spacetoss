{
 SpaceScript API for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}

Var
  Messages : PAbsMessageCollection;

Function RunProc(Id:Pointer;Const ProcName:String;Params:PVariableManager;res:PCajVariant):TCS2Error; Far;
Var
  p : PCajVariant;

  Message : PAbsMessage;
  NewMessage : PAbsMessage;

  s1,s2 : string;
  T : text;
begin
  RunProc:=ENoError;

  Message:=nil;

  If ProcName='SPCMSGGETFROMNAME' then
    begin
      SetString(res,'');
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
         If Message^.FromName<>nil then SetString(res,Message^.FromName^);
    end else

  If ProcName='SPCMSGGETTONAME' then
    begin
      SetString(res,'');
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
         If Message^.ToName<>nil then SetString(res,Message^.ToName^);
    end else

  If ProcName='SPCMSGGETAREA' then
    begin
      SetString(res,'');
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
         If Message^.Area<>nil then SetString(res,Message^.Area^);
    end else

  If ProcName='SPCMSGSETAREA' then
    begin
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      p:=GetVarLink(VM_Get(Params,1));
      If Message<>nil
           then AssignStr(Message^.Area,p^.CV_Str);
    end else

  If ProcName='SPCMSGSETKLUDGE' then
    begin
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
         If (Message^.MessageBody<>nil) and
           ((Message^.MessageBody^.KludgeBase<>nil)) then
              begin
                p:=GetVarLink(VM_Get(Params,1));
                s1:=p^.CV_Str;
                p:=GetVarLink(VM_Get(Params,2));
                s2:=p^.CV_Str;

                Message^.MessageBody^.KludgeBase^.SetKludge(s1,s2);
              end;
    end else

  If ProcName='SPCMSGSETTEARLINE' then
    begin
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      p:=GetVarLink(VM_Get(Params,1));
      If Message<>nil then
         If Message^.MessageBody<>nil
           then AssignStr(Message^.MessageBody^.TearLine,p^.CV_Str);
    end else

  If ProcName='SPCMSGINSERTLINE' then
    begin
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
         If (Message^.MessageBody<>nil) and
           ((Message^.MessageBody^.MsgBodyLink<>nil)) then
              begin
                p:=GetVarLink(VM_Get(Params,1));

                Message^.MessageBody^.MsgBodyLink^.Seek(0);
                objStreamInsertStr(Message^.MessageBody^.MsgBodyLink,p^.CV_Str);
              end;
    end else



  If ProcName='SPCMSGCOPYTOAREA' then
    begin
      SetInteger(res,-1);
      p:=GetVarLink(VM_Get(Params,0));

      If Messages<>nil then
        begin
          If (p^.CV_SInt32<0) or (p^.CV_SInt32>Messages^.Count-1) then exit;
          Message:=Messages^.At(p^.CV_SInt32);
        end;

      If Message<>nil then
        begin
          p:=GetVarLink(VM_Get(Params,1));

          NewMessage:=absCopyAbsMessage(Message);
          AssignStr(NewMessage^.Area,p^.CV_Str);
          Messages^.Insert(NewMessage);

          SetInteger(res,Messages^.Count-1);
        end;
    end else

  If ProcName='SPCLOGWRITELN' then
    begin
      p:=GetVarLink(VM_Get(Params,0));
      LogFile^.SendStr(p^.CV_Str,'@');
    end else

  If ProcName='WRITELN' then
    begin
      p:=GetVarLink(VM_Get(Params,0));
      s1:=p^.CV_Str;

      p:=GetVarLink(VM_Get(Params,1));
      s2:=p^.CV_Str;

      If s1='' then WriteLn(s2) else
        begin
          Assign(T,s1);

          If not dosFileExists(s1) then
            begin
            {$I-}
              Rewrite(T);
            {$I+}
              If IOResult<>0 then exit
            end else
            begin
            {$I-}
              Append(T);
            {$I+}
              If IOResult<>0 then exit
            end;

          WriteLn(T,s2);
          Close(T);
        end;
    end;
end;


Function OnUses (Id:Pointer;Sender:PCs2PascalScript;Name:String):TCs2Error;Far;
begin
  If Name='SYSTEM' then
    begin
      RegisterStdLib(Sender);

      PM_Add(Sender^.Procedures,'8 SPCMSGGETFROMNAME MSG 6',@runproc);
      PM_Add(Sender^.Procedures,'8 SPCMSGGETTONAME MSG 6',@runproc);
      PM_Add(Sender^.Procedures,'8 SPCMSGGETAREA MSG 6',@runproc);

      PM_Add(Sender^.Procedures,'8 SPCMSGSETAREA MSG 6 AREA 8',@runproc);

      PM_Add(Sender^.Procedures,'0 SPCMSGINSERTLINE MSG 6 LINE 8',@runproc);
      PM_Add(Sender^.Procedures,'0 SPCMSGSETKLUDGE MSG 6 NAME 8 VALUE 8',@runproc);
      PM_Add(Sender^.Procedures,'0 SPCMSGSETTEARLINE MSG 6 S 8',@runproc);

      PM_Add(Sender^.Procedures,'6 SPCMSGCOPYTOAREA MSG 6 AREA 8',@runproc);

      PM_Add(Sender^.Procedures,'0 SPCLOGWRITELN S 8',@runproc);

      PM_Add(Sender^.Procedures,'0 WRITELN FILENAME 8 S 8',@runproc);

      OnUses:=ENoError;
    end
    else OnUses:=EUnknownIdentifier;
end;
