{
 Announces Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 Origins
}
Unit Announce;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8objs,
  r8ftn,
  r8str,
  poster,
  objects;

Type

  TAnnounceTask = object(TObject)
    Address       : TAddress;
    UplinkAddress : TAddress;
    AreaName : PString;
    AreaDesc : PString;
    GroupName : PString;
    GroupDesc : PString;

    Constructor Init;
    Destructor  Done; virtual;
  end;

  PAnnounceTask = ^TAnnounceTask;

  TAnnounceTaskCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;

  PAnnounceTaskCollection =   ^TAnnounceTaskCollection;

  TAnnounce = object(TObject)
    Area : PString;

    FromName : PString;
    FromAddress : TAddress;
    ToName : PString;
    ToAddress : TAddress;
    Subj : PString;

    Template : PString;
    Body : PStream;
    AnnouncePoster : PPktPoster;

    Constructor Init;
    Destructor Done;virtual;

    Procedure Post(Stack:PAnnounceTaskCollection);
  end;

PAnnounce = ^TAnnounce;

TAnnounceCollection = object(TCollection)
  Procedure FreeItem(Item:pointer);virtual;
end;
PAnnounceCollection = ^TAnnounceCollection;

implementation

Uses
    global;

Procedure TAnnounceTaskCollection.FreeItem(Item:pointer);
begin
  objDispose(PAnnounceTask(Item));
end;

Constructor TAnnounceTask.Init;
begin
  inherited Init;

  AreaName:=nil;
  AreaDesc:=nil;
  GroupName:=nil;
  GroupDesc:=nil;
end;

Destructor TAnnounceTask.Done;
begin
  DisposeStr(AreaName);
  DisposeStr(AreaDesc);
  DisposeStr(GroupName);
  DisposeStr(GroupDesc);

  inherited Done;
end;

Constructor TAnnounce.Init;
begin
  inherited init;

  Area:=nil;
  FromName:=nil;
  ToName:=nil;
  Subj:=nil;
  Template:=nil;
end;

Destructor TAnnounce.Done;
begin
  DisposeStr(Area);
  DisposeStr(FromName);
  DisposeStr(ToName);
  DisposeStr(Subj);
  DisposeStr(Template);

  inherited Done;
end;

Procedure TAnnounce.Post(Stack:PAnnounceTaskCollection);
Var
  t:text;
  sTemp:string;
  pTemp:pString;
  TempCol : PStringsCollection;
  TempAnnounce : PAnnounceTask;
  i:integer;
  i2:integer;
begin
  AnnouncePoster:=New(PPktPoster,Init(LocalInboundPath));

  AssignStr(AnnouncePoster^.Area,Area^);

  AssignStr(AnnouncePoster^.FromName,FromName^);
  AssignStr(AnnouncePoster^.ToName,ToName^);

  AnnouncePoster^.ToAddress:=ToAddress;
  AnnouncePoster^.FromAddress:=FromAddress;

  AnnouncePoster^.CutBytes:=MsgSplitSize;
  AssignStr(AnnouncePoster^.Subj,Subj^);

  sTemp:='';

  If Origins^.Count>0 then
    begin
      randomize;
      pTemp:=Origins^.At(random(Origins^.Count-1));
      If pTemp<>nil then sTemp:=pTemp^;
    end;

  AssignStr(AnnouncePoster^.Origin,' * Origin: '+sTemp+' ('+ftnAddressToStrEx(FromAddress)+')');

  Body:=New(PMemoryStream,Init(0,cBuffSize));

  Assign(T,Template^);
  Reset(T);

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      sTemp:=strTrimR(sTemp,[#32,#8]);

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

        for i:=0 to Stack^.Count-1 do
          begin
            TempAnnounce:=Stack^.At(i);

            MacroModifier^.FreeMacros;

            If TempAnnounce^.AreaName<>nil then
              MacroModifier^.SetAreaName(TempAnnounce^.AreaName^);
            If TempAnnounce^.AreaDesc<>nil then
              MacroModifier^.SetAreaDesc(TempAnnounce^.AreaDesc^);
            If TempAnnounce^.GroupName<>nil then
              MacroModifier^.SetGroupName(TempAnnounce^.GroupName^);
            If TempAnnounce^.GroupDesc<>nil then
              MacroModifier^.SetGroupDesc(TempAnnounce^.GroupDesc^);

            MacroModifier^.SetAddress(TempAnnounce^.Address);
            MacroModifier^.SetOAddress(TempAnnounce^.UplinkAddress);
            MacroModifier^.DoMacros;

            For i2:=0 to TempCol^.Count-1 do
              begin
                pTemp:=TempCol^.At(i2);
                sTemp:=pTemp^;
                MacroEngine^.ProcessString(sTemp);
                objStreamWriteLn(Body,sTemp);
              end;
          end;

          objDispose(TempCol);
          continue;
        end;

      MacroEngine^.ProcessString(sTemp);
      objStreamWriteLn(Body,sTemp);
    end;

  Close(T);

  AnnouncePoster^.Body:=Body;
  AnnouncePoster^.Post;
  objDispose(AnnouncePoster);
end;

Procedure TAnnounceCollection.FreeItem(Item:pointer);
begin
  objDispose(PAnnounce(Item));
end;

end.
