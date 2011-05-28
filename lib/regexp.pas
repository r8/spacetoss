{
 Regular Expressions Support

 (c) author unknown :-( received from Alex Denisenko
 (c) portions by raVen
 (c) style/code fixes by sk // [rAN], Feb 2001.
 (c) some code fixes by Sergey Storchay, 2001.

 Supported compilers: Borland Pascal 7
                      Virtual Pascal 2
                      FPC 1.0
                      Delphi 5

 wildcards из regexp тоже должны быть extended.
}
Unit RegExp;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}
{&Cdecl-,OrgName+,Use32-,LocInfo+}

{.$DEFINE DEBUGREGEXP}

interface
uses
{$IFDEF DELPHI}
     Classes,
     SysUtils;
{$ELSE}
     Strings,
     Objects;
{$ENDIF}

const
 RegExp_NSubExp         = 128;
 RegExp_Max_NSubExp     = RegExp_NSubExp - 1;

 RegExp_MaxPCharLen     : Longint     = 65520;
 RegExp_MaxSize         : Longint     = 32767;

type
 PSubExpArr = ^TSubExpArr;
 TSubExpArr = array[0..RegExp_NSubExp - 1] of PChar;

 PRegExpr = ^TRegExpr;
 TRegExpr = packed record
  StartP, EndP: TSubExpArr;
  RegStart, RegAnch: Char;        { internal use only }
  RegMust: PChar;                 { internal use only }
  RegMLen: Word;                  { internal use only }
  RegProgram: array[0..0] of Char;  { unwarranted chumminess with compiler }
 end;

 PStringTable = ^TStringTable;
 TStringTable = array[0..0] of PChar;

 PRegExp = ^TRegExp;
 TRegExp = {$IFDEF DELPHI} class(TPersistent) public {$ELSE} object(TObject) {$ENDIF}
  constructor Init(const AMask: PChar);
  constructor InitStr(const AMask: String);
  constructor InitWildcard(const AWildcard: String);
  destructor Done; virtual;
  procedure SetReplaceMask(const AReplaceMask: PChar);
  procedure SetReplaceMaskStr(const AReplaceMask: String);
  function IsValid: Boolean;
  function MaskMatch(const Addr: PChar; CaseSensitive: Boolean): Boolean;
  function MaskMatchStr(const Addr: String; CaseSensitive: Boolean): Boolean;
  function GetErrorMsg: String;
  function GetRegExp: PChar;
 private
  RegParse: PChar;              { input-scan pointer }
  RegReplace: PChar;            { mask for replace }
  RegCase: Boolean;             { case sensitivity }
  RegNPar: Integer;             { () count }
  RegDummy: Char;               { stuff }
  RegCode: PChar;               { code-emit pointer; &regdummy = don't }
  RegSize: Longint;             { code size }
  RegErrorMsg: ^String;         { pointer to an error message }
  RegInput: PChar;              { string-input pointer }
  RegBol: PChar;                { beginning of input, for ^ check }
  RegStartP: PStringTable;      { pointer to startp array }
  RegEndP: PStringTable;        { ditto for endp }
  Mask: PRegExpr;               { the mask }
  RegExp: PChar;

  procedure RegError(const ErrStr: String);
  function RegComp(Exp: PChar): PRegExpr;
  function RegExec(Prog: PRegExpr; St: PChar): boolean;
  function Reg(Paren: Word; var FlagP: Word): PChar;
  function RegBranch(var FlagP: Word): PChar;
  function RegPiece(var FlagP: Word): PChar;
  function RegAtom(var FlagP: Word): PChar;
  function RegNode(Op: Char): PChar;
  function RegNext(P: PChar): PChar;
  procedure RegInsert(Op: Char; Opnd: PChar);
  procedure RegTail(P, Val: PChar);
  procedure RegOpTail(P, Val: PChar);
  function RegTry(Prog: PRegExpr; St: PChar): Boolean;
  function RegMatch(Prog: PChar): Boolean;
  function RegRepeat(P: PChar): Word;
  procedure RegSub(Prog: PRegExpr; Source, Dest: PChar);
  procedure RegC(B: Char);
{$IFDEF DEBUGREGEXP}
  procedure RegDump(R: PRegExpr);
  function RegProp(Op: PChar): String;
{$ENDIF}
 end;

function GrepCheck(Mask:string;const  Data: String; CaseSensitive: Boolean): Boolean;
function GrepCheckPChar(const Mask, Data: PChar; CaseSensitive: Boolean): Boolean;

function GrepReplace(const Mask, Data, ReplaceTo: String; CaseSensitive: Boolean): String;
function GrepReplacePChar(const Mask, Data, ReplaceTo: PChar; CaseSensitive: Boolean): PChar;

function StrAlloc(const S: String): PChar;

function PreprocessWildcard(const AWildcard: String): String;

implementation

{ internal types and constants }

type
 PRegOp = ^TRegOp;
 TRegOp = packed record
  Op: Byte;
  Next: Word;
 end;

const
 OpHdr          = SizeOf(TRegOp);

 MaxBrackets    = 50;

 MAGIC          = #234;

 PEND           =  0;                { no   } { End of program }
 BOL            =  1;                { no   } { Match "" at beginning of line }
 EOL            =  2;                { no   } { Match "" at end of line }
 ANY            =  3;                { no   } { Match any one character }
 ANYOF          =  4;                { str  } { Match any character in this string }
 ANYBUT         =  5;                { str  } { Match any character not in this string }
 BRANCH         =  6;                { node } {  Match this alternative, or the next }
 BACK           =  7;                { no   } { Match "", "next" ptr points backward }
 EXACTLY        =  8;                { str  } { Match this string }
 NOTHING        =  9;                { no   } { Match empty string }
 STAR           = 10;                { node } { Match this (simple) thing 0 or more times }
 PLUS           = 11;                { node } { Match this (simple) thing 1 or more times }
 OPEN           = 20;                { no   } { Mark this point in input as start of #n OPEN+1 is number 1 etc }
 CLOSE          = 20 + MaxBrackets;  { no   } { Analogous to OPEN }

 Worst          = 0;   { Worst case }
 HasWidth       = 1;   { Known never to match null string }
 Simple         = 2;   { Simple enough to be STAR/PLUS operand }
 SPStart        = 4;   { Starts with * or + }

 Meta           : array[0..11] of Char = ('^', '$', '.', '[', '(', ')',
                                          '|', '?', '+', '*', '\', #0);

{ internal routine
  Escape }

const
 NOT_HEX = 16;
 ET_END  = 7;

type
 ET = record
  I, O: Char;
 end;

const
 Hex_Val: array[0..(Ord('f') - Ord('A'))] of Byte =
          (10, 11, 12, 13, 14, 15,  0,  0,
            0,  0,  0,  0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,  0,  0,  0,
            0,  0,  0,  0,  0,  0,  0,  0,
           10, 11, 12, 13, 14, 15 );

 Escape_Test: array[0..ET_END] of ET =
              ((I: 'n'; o: #10),
               (I: 't'; o: #09),
               (I: 'f'; o: #12),
               (I: 'b'; o: #08),
               (I: 'r'; o: #13),
               (I: 'a'; o: #07),
               (I: 'v'; o: #11),
               (I: #00; o: #00));

function Escape(var P: PChar): Char;
 function CToHex(C: Char): Byte; { interpret 1 character as hex }
  var
   T: Byte;
  begin
   if C in ['0'..'9'] then
    begin
     CToHex:=Ord(C) - Ord('0');

     Exit;
    end;

   if C in ['A'..'f'] then
    begin
     T:=Hex_Val[Ord(C) - Ord('A')];

     if T <> 0 then
      begin
       CToHex:=T;

       Exit;
      end;
    end;

   CToHex:=Not_Hex;
  end;
 var
  I, K, L: Word;
 begin
  if P^ = Chr(0) then
   begin
    Escape:='\';

    Exit;
   end;

  Escape_Test[ET_END].I:=P^;

  I:=0;

  while Escape_Test[I].I <> P^ do
   Inc(I);

  if I <> ET_END then
   begin
    Inc(P);

    Escape:=Escape_Test[I].O;
   end else
  if P^ in ['0'..'7'] then
   begin
    K:=Ord(P^) - Ord('0');

    Inc(P);

    if P^ in ['0'..'7'] then
     begin
      K:=(K shl 3) + (Ord(P^) - Ord('0'));

      Inc(P);

      if P^ in ['0'..'7'] then
       begin
        K:=(K shl 3) + (Ord(P^) - Ord('0'));

        Inc(P);
       end;
     end;

    Escape:=Chr(K);
   end else
  if P^ = 'x' then
   begin
    Inc(P);

    K:=CToHex(P^);

    if K = NOT_HEX then
     Escape:='x'
    else
     begin
      Inc(P);

      L:=CToHex(P^);

      if L <> NOT_HEX then
       begin
        K:=(K shl 4) + L;

        Inc(P);
       end;

      Escape:=Chr(K);
     end;
   end
  else
   begin
    Escape:=P^;

    Inc(P);
   end;
 end;

{ internal routine, intended to perform case-insensitive scan
  StrIScan }

type
 TSearcher = function({$IFDEF DELPHI}const{$ENDIF}Str: PChar; C: Char): PChar;
 TComparer = function({$IFDEF DELPHI}const{$ENDIF}Str1, Str2: PChar;
                      MaxLen: {$IFDEF DELPHI}cardinal{$ELSE}
                      {$IFDEF VER70}Word{$ELSE}Longint{$ENDIF}
                      {$ENDIF}):{$IFDEF VER70}Integer{$ELSE}Longint{$ENDIF};

var
 Searcher: TSearcher;
 Comparer: TComparer;

{$UNDEF CODE32}

{$IFDEF DELPHI}
 {$DEFINE CODE32}
{$ENDIF}

{$IFDEF FPC}
 {$DEFINE CODE32}
{$ENDIF}

{$IFDEF VIRTUALPASCAL}
 {$DEFINE CODE32}
{$ENDIF}

const
 LocaseTable: array[#$40..#$FF] of Byte = (
    $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$5B,$5C,$5D,$5E,$5F,
    $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F,
    $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,
    $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
    $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,
    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF,
    $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
    $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,
    $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
    $F1,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

 UpcaseTable: array[#$40..#$FF] of Byte = (
    $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,
    $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,
    $60,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,
    $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$7B,$7C,$7D,$7E,$7F,
    $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,
    $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,
    $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F,
    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF,
    $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
    $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,
    $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,
    $F0,$F0,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

{ strings }

function Locase(const Ch: Char): Char; assembler; {&USES EBX}
 asm
  mov al, Ch
  cmp al, $40
  jb @@1
  sub al, 40h
  {$IFDEF CODE32}
  lea ebx, LocaseTable
  {$ELSE}
  mov bx, seg LocaseTable
  push bx
  pop ds
  mov bx, offset LocaseTable
  {$ENDIF}
  xlat
 @@1:
 end;

function Upcase(const Ch: Char): Char; assembler; {&USES EBX}
 asm
  mov al, Ch
  cmp al, $40
  jb @@1
  sub al, 40h
  {$IFDEF CODE32}
  lea ebx, UpcaseTable
  {$ELSE}
  mov bx, seg UpcaseTable
  push bx
  pop ds
  mov bx, offset UpcaseTable
  {$ENDIF}
  xlat
 @@1:
 end;

procedure LocaseAsm; assembler; {&USES EBX}
 asm
  cmp   al, $40
  jb    @@1
  sub   al, 40h
  {$IFDEF CODE32}
  lea   ebx, LocaseTable
  {$ELSE}
  push  ds
  mov   bx, seg LocaseTable
  push  bx
  pop   ds
  mov   bx, offset LocaseTable
  {$ENDIF}
  xlat
  {$IFNDEF CODE32}
  pop   ds
  {$ENDIF}
 @@1:
 end;

procedure UpcaseAsm; assembler; {&USES EBX}
 asm
  cmp   al, $40
  jb    @@1
  sub   al, 40h
  {$IFDEF CODE32}
  lea   ebx, UpcaseTable
  {$ELSE}
  push  ds
  mov   bx, seg UpcaseTable
  push  bx
  pop   ds
  mov   bx, offset UpcaseTable
  {$ENDIF}
  xlat
  {$IFNDEF CODE32}
  pop   ds
  {$ENDIF}
 @@1:
 end;

function StrIScan({$IFDEF DELPHI}const{$ENDIF}Str: PChar; C: Char): PChar; far;
 var
  P1, P2: PChar;
  C1, C2: Char;
 begin
  C1:=UpCase(C);
  C2:=LoCase(C);

  if C1 = C2 then
   StrIScan:=StrScan(Str, C)
  else
   begin
    P1:=StrScan(Str, C1);
    P2:=StrScan(Str, C2);

    if P1 <> nil then
     begin
      StrIScan:=P1;

      if (P2 <> nil) and (P2 < P1) then
       StrIScan:=P2;
     end
    else
     StrIScan:=P2;
   end;
 end;

{$IFNDEF CODE32}
function StrLIComp(Str1, Str2: PChar; MaxLen: Word): Integer; assembler;
asm
        PUSH    DS
        CLD
        LES     DI,Str2
        MOV     SI,DI
        MOV     AX,MaxLen
        MOV     CX,AX
        JCXZ    @@4
        XCHG    AX,BX
        XOR     AX,AX
        CWD
        REPNE   SCASB
        SUB     BX,CX
        MOV     CX,BX
        MOV     DI,SI
        LDS     SI,Str1
@@1:    REPE    CMPSB
        JE      @@4
        MOV     AL,DS:[SI-1]
        CALL    UpcaseAsm
@@2:    MOV     DL,ES:[DI-1]
        PUSH    AX
        MOV     AX, DX
        CALL    UpcaseAsm
        MOV     DX, AX
        POP     AX
@@3:    SUB     AX,DX
        JE      @@1
@@4:    POP     DS
end;
{$ELSE}
{$IFDEF DELPHI}
function StrLIComp({$IFDEF DELPHI}const{$ENDIF}Str1, Str2: PChar; MaxLen: Cardinal): Longint; assembler;
 {&USES esi,edi} {&FRAME-}
{$ELSE}
function StrLIComp(Str1, Str2: PChar; MaxLen: Longint): Longint; assembler; {&USES esi,edi} {&FRAME-}
{$ENDIF}
asm
                mov     edi,Str2
                mov     esi,edi
                mov     eax,MaxLen
                mov     ecx,eax
                jecxz   @@4
                cld
                mov     edx,eax
                xor     eax,eax
                repne   scasb
                sub     edx,ecx
                mov     ecx,edx
                mov     edi,esi
                mov     esi,Str1
                xor     edx,edx
              @@1:
                repe    cmpsb
                je      @@4
                mov     al,[esi-1]
                call    UpcaseAsm
              @@2:
                mov     dl,[edi-1]
                push    ax
                mov     ax, dx
                call    UpcaseAsm
                mov     dx, ax
                pop     ax
              @@3:
                sub     eax,edx
                je      @@1
              @@4:
end;
{$ENDIF}

{ IsMult }

function IsMult(C: Char): Boolean;
 begin
  IsMult:=(C = '*') or (C = '+') or (C = '?');
 end;

{ strcspn }

function strcspn(S1, S2: PChar): Word;
 var
  Scan1, Scan2: PChar;
  Count: Word;
 begin
  Count:=0;
  Scan1:=S1;

  while Scan1^ <> #0 do
   begin
    Scan2:=S2;

    while Scan2^ <> #0 do
     begin
      if Scan1^ = Scan2^ then
       begin
        strcspn:=Count;

        Exit;
       end;

      Inc(Scan2);
     end;

    Inc(Count);
    Inc(Scan1);
   end;

  strcspn:=Count;
 end;

{ main regexp constructor
  TRegExp.Init }

constructor TRegExp.Init(const AMask: PChar);
 begin
  {$IFDEF DELPHI}
  inherited Create;
  {$ELSE}
  inherited Init;
  {$ENDIF}
  RegParse:=nil;
  RegReplace:=nil;
  RegNPar:=0;
  RegDummy:=Chr(0);
  RegCode:=nil;
  RegSize:=0;
  RegInput:=nil;
  RegBol:=nil;
  RegStartp:=nil;
  RegEndP:=nil;
  RegErrorMsg:=nil;
  RegExp:=StrNew(AMask);
  Mask:=RegComp(RegExp);
 end;

{ additional regexp constructor
  TRegExp.InitStr }

constructor TRegExp.InitStr(const AMask: String);
 var
  MaskPChar: PChar;
 begin
  MaskPChar:=StrAlloc(AMask);

  Init(MaskPChar);

  StrDispose(MaskPChar);
 end;

{ just another additional regexp constructor
  TRegExp.InitWildcard }

constructor TRegExp.InitWildcard(const AWildcard: String);
 begin
  InitStr(PreprocessWildcard(AWildcard));
 end;

{ regexp destructor
  TRegExp.Done }

destructor TRegExp.Done;
 begin
  StrDispose(RegExp);

  if Mask <> nil then
   FreeMem(Mask, SizeOf(TRegExpr) + Word(RegSize));

  StrDispose(RegReplace);

  {$IFDEF DELPHI}
  inherited Destroy;
  {$ELSE}
  inherited Done;
  {$ENDIF}
 end;

{ TRegExp.SetReplaceMask }

procedure TRegExp.SetReplaceMask(const AReplaceMask: PChar);
 begin
  if RegReplace <> nil then
   StrDispose(RegReplace);

  RegReplace:=StrNew(AReplaceMask);
 end;

{ TRegExp.SetReplaceMaskStr }

procedure TRegExp.SetReplaceMaskStr(const AReplaceMask: String);
 begin
  if RegReplace <> nil then
   StrDispose(RegReplace);

  RegReplace:=StrAlloc(AReplaceMask);
 end;

{ TRegExp.IsValid }

function TRegExp.IsValid: Boolean;
 begin
  IsValid:=Mask <> nil;
 end;

{ TRegExp.MaskMatch }

function TRegExp.MaskMatch(const Addr: PChar; CaseSensitive: Boolean): Boolean;
 begin
  RegCase:=CaseSensitive;

  if Mask = nil then
   MaskMatch:=False
  else
   MaskMatch:=RegExec(Mask, Addr);
 end;

{ TRegExp.MaskMatchStr }

function TRegExp.MaskMatchStr(const Addr: String; CaseSensitive: Boolean): Boolean;
 var
  AddrPChar: PChar;
 begin
  RegCase:=CaseSensitive;

  AddrPChar:=StrAlloc(Addr);

  if Mask = nil then
   MaskMatchStr:=False
  else
   MaskMatchStr:=RegExec(Mask, AddrPChar);

  StrDispose(AddrPChar);
 end;

{ TRegExp.GetErrorMsg }

function TRegExp.GetErrorMsg: String;
 begin
  if RegErrorMsg = nil then
   GetErrorMsg:=''
  else
   GetErrorMsg:=RegErrorMsg^;
 end;

{ TRegExp.GetRegExp }

function TRegExp.GetRegExp: PChar;
 begin
  GetRegExp:=RegExp;
 end;

{ here follows private methods of TRegExp }

{ TRegExp.RegError }

procedure TRegExp.RegError(const ErrStr: String);
 begin
  RegErrorMsg:=@ErrStr;
 end;

{ compile a regular expression into internal code
  TRegExp.RegComp }

function TRegExp.RegComp(Exp: PChar): PRegExpr;
 var
  R: PRegExpr;
  Scan, Longest: PChar;
  Len, Flags: Word;
 begin
  if Exp = nil then
   begin
    RegError('NULL argument');

    RegComp:=nil;

    Exit;
   end;

  { first pass: determine size, legality }

  RegParse:=Exp;
  RegNPar:=1;
  RegSize:=0;
  RegCode:=@RegDummy;
  RegC(MAGIC);

  if Reg(0, Flags) = nil then
   begin
    RegComp:=nil;

    Exit;
   end;

  { small enough for pointer-storage convention? }

  if RegSize >= RegExp_MaxSize then
   begin
    RegError('regexp too big');

    RegComp:=nil;

    Exit;
   end;

  { allocate space }

  GetMem(R, SizeOf(TRegExpr) + Word(RegSize));

  if R = nil then
   begin
    RegError('out of space');

    RegComp:=nil;

    Exit;
   end;

  { second pass: emit code }

  RegParse:=Exp;
  RegNPar:=1;
  RegCode:=R^.RegProgram;
  RegC(Magic);

  if Reg(0, Flags) = nil then
   begin
    RegComp:=nil;

    Exit;
   end;

  { dig out information for optimizations }

  R^.RegStart:=#0; { worst-case defaults }
  R^.RegAnch:=#0;
  R^.RegMust:=nil;
  R^.RegMLen:=0;

  Scan:=R^.RegProgram;

  Inc(Scan); { first BRANCH }

  if PRegOp(RegNext(Scan))^.Op = PEnd then { only one top-level choice }
   begin
    Inc(Scan, OpHdr);

    { starting-point info }

    if PRegOp(Scan)^.Op = EXACTLY then
     R^.RegStart:=(Scan + OpHdr)^
    else
     if PRegOp(Scan)^.Op = BOL then
      Inc(R^.RegAnch);

    if Flags and SPStart <> 0 then
     begin
      Longest:=nil;

      Len:=0;

      while Scan <> nil do
       begin
        if (PRegOp(Scan)^.Op = Exactly) and (StrLen(Scan + OpHdr) >= Len) then
         begin
          Longest:=Scan + OpHdr;

          Len:=StrLen(Scan + OpHdr);
         end;

        Scan:=RegNext(Scan);
       end;

      R^.RegMust:=Longest;
      R^.RegMLen:=Len;
     end
   end;

  {$IFDEF DEBUGREGEXP}
  RegDump(R);
  {$ENDIF}

  RegComp:=R;
 end;

{ regexec - match a regexp against a string
  TRegExp.RegExec }

function TRegExp.RegExec(Prog: PRegExpr; St: PChar): Boolean;
 var
  S: PChar;
 begin
  if (Prog = nil) or (St = nil) then
   begin
    RegError('NULL parameter');

    RegExec:=False;

    Exit;
   end;

  if Prog^.RegProgram[0] <> Magic then
   begin
    RegError('corrupted program');

    RegExec:=False;

    Exit;
   end;

  if RegCase then
   begin
    Searcher:=StrScan;
    Comparer:=StrLComp;
   end
  else
   begin
    Searcher:=StrIScan;
    Comparer:=StrLIComp;
   end;

  if Prog^.RegMust <> nil then
   begin
    S:=St;

    S:=Searcher(S, Prog^.RegMust^);

    while S <> nil do
     begin
      if Comparer(S, Prog^.RegMust, Prog^.RegMLen) = 0 then
       Break;

      Inc(S);

      S:=Searcher(S, Prog^.RegMust^);
     end;

    if S = nil then
     begin
      RegExec:=False;

      Exit;
     end;
   end;

  RegBol:=St;

  if Ord(Prog^.RegAnch) <> 0 then
   begin
    RegExec:=RegTry(Prog, St);

    Exit;
   end;

  S:=St;

  if Ord(Prog^.RegStart) <> 0 then
   begin
    S:=Searcher(S, Prog^.RegStart);

    while S <> nil do
     begin
      if RegTry(Prog, S) then
       begin
        RegExec:=True;

        Exit;
       end;

      Inc(S);

      S:=Searcher(S, Prog^.RegStart);
     end
   end
  else
   begin
    Dec(S);

    repeat
     Inc(S);

     if RegTry(Prog, S) then
      begin
       RegExec:=True;

       Exit;
      end;
    until S^ = #0;
   end;

  RegExec:=False;
 end;

{ reg - regular expression, I.e. main body or parenthesized thing
  TRegExp.Reg }

function TRegExp.Reg(Paren: Word; var FlagP: Word): PChar;
 var
  Ret, Br, Ender: PChar;
  ParNo, Flags: Word;
 begin
  FlagP:=HasWidth;

  { make an OPEN node, if parenthesized }

  if Paren <> 0 then
   begin
    if (RegNPar >= RegExp_NSubExp) or (RegNPar >= MaxBrackets) then
     begin
      RegError('too many ()');

      Reg:=nil;

      Exit;
     end;

    ParNo:=RegNPar;

    Inc(RegNPar);

    Ret:=RegNode(Chr(OPEN + ParNo));
   end
  else
   Ret:=nil;

  { pick up the branches, linking them together }

  Br:=RegBranch(Flags);

  if Br = nil then
   begin
    Reg:=nil;

    Exit;
   end;

  if Ret <> nil then
   RegTail(ret, br)
  else
   Ret:=Br;

  if (Flags and HasWidth) = 0 then
   FlagP:=FlagP and (not HasWidth);

  FlagP:=FlagP or (Flags and SPStart);

  while RegParse^ = '|' do
   begin
    Inc(RegParse);

    Br:=RegBranch(Flags);

    if Br = nil then
     begin
      Reg:=nil;

      Exit;
     end;

    RegTail(Ret, Br);

    if Flags and HasWidth = 0 then
     FlagP:=FlagP and (not HasWidth);

    FlagP:=FlagP or (Flags and SPStart);
   end;

  { make a closing node, and hook it on the end }

  if Paren <> 0 then
   Ender:=RegNode(Chr(Close + ParNo))
  else
   Ender:=RegNode(Chr(PEnd));

  RegTail(Ret, Ender);

  { hook the tails of the branches to the closing node }

  Br:=Ret;

  while Br <> nil do
   begin
    RegOpTail(Br, Ender);

    Br:=RegNext(Br);
   end;

  { check for proper termination }

  if (Paren <> 0) and (RegParse^ <> ')') then
   begin
    Inc(RegParse);

    RegError('unmatched ()');

    Reg:=nil;

    Exit;
   end
  else
   begin
    if Paren <> 0 then
     Inc(RegParse);

    if (Paren = 0) and (RegParse^ <> #0) then
     begin
      if RegParse^ = ')' then
       begin
        RegError('unmatched ()');

        Reg:=nil;

        Exit;
       end
      else
       begin
        RegError('junk on end');

        Reg:=nil;

        Exit;
       end;
     end;
   end;

  Reg:=Ret;
 end;

{ regbranch - one alternative of an | operator
  TRegExp.RegBranch }

function TRegExp.RegBranch(var FlagP: Word): PChar;
 var
  Ret, Chain, Latest: PChar;
  Flags: Word;
 begin
  FlagP:=Worst;

  Ret:=RegNode(Chr(Branch));

  Chain:=nil;

  while not (RegParse^ in [#0, '|', ')']) do
   begin
    Latest:=RegPiece(Flags);

    if Latest = nil then
     begin
      RegBranch:=nil;

      Exit;
     end;

    FlagP:=FlagP or (Flags and HasWidth);

    if Chain = nil then
     FlagP:=FlagP or (Flags and SpStart)
    else
     RegTail(Chain, Latest);

    Chain:=Latest;
   end;

  if Chain = nil then
   RegNode(Chr(Nothing));

  RegBranch:=Ret;
 end;

{ regpiece - something followed by possible [*+?]
  TRegExp.RegPiece }

function TRegExp.RegPiece(var FlagP: Word): PChar;
 var
  Ret, Next: PChar;
  Op: Char;
  Flags: Word;
 begin
  Ret:=RegAtom(Flags);

  if Ret = nil then
   begin
    RegPiece:=nil;

    Exit;
   end;

  Op:=RegParse^;

  if not IsMult(Op) then
   begin
    Flagp:=Flags;

    RegPiece:=Ret;

    Exit;
   end;

  if (Flags and HasWidth = 0) and (Op <> '?') then
   begin
    RegError('*+ operand could be empty');

    RegPiece:=nil;

    Exit;
   end;

  if Op = '+' then
   FlagP:=Worst or HasWidth
  else
   FlagP:=Worst or SPStart;

  if (Op = '*') and (Flags and Simple <> 0) then
   RegInsert(Chr(Star), Ret)
  else
   if Op = '*' then
    begin
     RegInsert(Chr(Branch), Ret);           { Either x }
     RegOptail(Ret, RegNode(Chr(Back)));    { and loop }
     RegOptail(Ret, Ret);                   { back }
     RegTail(Ret, Regnode(Chr(Branch)));    { or }
     RegTail(Ret, Regnode(Chr(Nothing)));   { null }
    end
   else
    if (Op = '+') and (Flags and Simple <> 0) then
     RegInsert(Chr(Plus), Ret)
    else
     if Op = '+' then
      begin
       Next:=RegNode(Chr(Branch));            { Either }
       RegTail(Ret, Next);
       RegTail(Regnode(Chr(Back)), Ret);      { loop back }
       RegTail(Next, RegNode(Chr(Branch)));   { or }
       RegTail(Ret, RegNode(Chr(Nothing)));   { null }
      end
     else
      if Op = '?' then
       begin
        RegInsert(Chr(Branch), Ret);           { Either x }
        RegTail(Ret, RegNode(Chr(Branch)));    { or }
        Next:=RegNode(Chr(Nothing));           { null }
        RegTail(Ret, Next);
        RegOptail(Ret, Next);
       end;

  Inc(RegParse);

  if IsMult(RegParse^) then
   begin
    RegError('nested *?+');

    RegPiece:=nil;

    Exit;
   end;

  RegPiece:=Ret;
 end;

{ regatom - the lowest level
  TRegExp.RegAtom }

function TRegExp.RegAtom(var FlagP: Word): PChar;
 var
  Ret: PChar;
  Flags: Word;
  C, Ender: Char;
  Len, ClassThe, ClassEnd: Word;
 begin
  FlagP:=Worst;

  C:=RegParse^;

  Inc(RegParse);

  case C of
   '^': Ret:=RegNode(Chr(Bol));
   '$': Ret:=RegNode(Chr(Eol));
   '.':
    begin
     Ret:=RegNode(Chr(Any));

     FlagP:=FlagP or (HasWidth or Simple);
    end;
   '[':
    begin
     if RegParse^ = '^' then
      begin
       Ret:=RegNode(Chr(AnyBut));

       Inc(RegParse);
      end
     else
      Ret:=RegNode(Chr(AnyOf));

     if (RegParse^ = ']') or (RegParse^ = '-') then
      begin
       RegC(RegParse^);

       Inc(RegParse);
      end;

     while (RegParse^ <> #0) and (RegParse^ <> ']') do
      begin
       if RegParse^ = '-' then
        begin
         Inc(RegParse);

         if (RegParse^ = ']') or (RegParse^ = #0) then
          RegC('-')
         else
          begin
           ClassThe:=Ord((RegParse - 2)^) + 1;
           ClassEnd:=Ord(RegParse^);

           if ClassThe > ClassEnd + 1 then
            begin
             RegError('invalid [] range');

             RegAtom:=nil;

             Exit;
            end;

           while ClassThe <= ClassEnd do
            begin
             RegC(Chr(ClassThe));

             Inc(ClassThe);
            end;

           Inc(RegParse);
          end;
        end
       else
        begin
         if RegParse^ = '\' then
          begin
           Inc(RegParse);

           RegC(Escape(RegParse));
          end
         else
          begin
           RegC(RegParse^);

           Inc(RegParse);
          end;
        end;
      end;

     RegC(#0);

     if RegParse^ <> ']' then
      begin
       RegError('unmatched []');

       RegAtom:=nil;

       Exit;
      end;

     Inc(RegParse);

     FlagP:=FlagP or (HasWidth or Simple);
    end;
   '(':
    begin
     Ret:=Reg(1, Flags);

     if Ret = nil then
      begin
       RegAtom:=nil;

       Exit;
      end;

     FlagP:=FlagP or (Flags and (HasWidth or SpStart));
    end;
   #0, '|', ')':
    begin
     RegError('internal urp');

     RegAtom:=nil;

     Exit;
    end;
  '?', '+', '*':
    begin
     RegError('?+* follows nothing');

     RegAtom:=nil;

     Exit;
    end;
  '\':
    begin
     if RegParse^ = #0 then
      begin
       RegError('trailing \');

       RegAtom:=nil;

       Exit;
      end;

     Ret:=RegNode(Chr(Exactly));

     RegC(Escape(RegParse));
     RegC(#0);

     FlagP:=FlagP or (HasWidth or Simple);
    end;
  else
   Dec(RegParse);

   Len:=strcspn(RegParse, @Meta);

   if Integer(Len) <= 0 then
    begin
     RegError('internal disaster');

     RegAtom:=nil;

     Exit;
    end;

   Ender:=(RegParse + Len)^;

   if (Len > 1) and IsMult(Ender) then
    Dec(Len);

   FlagP:=FlagP or HasWidth;

   if Len = 1 then
    FlagP:=FlagP or Simple;

   Ret:=RegNode(Chr(Exactly));

   while (Len > 0) do
    begin
     RegC(RegParse^);

     Inc(RegParse);

     Dec(Len);
    end;

   Regc(#0);
  end;

  RegAtom:=Ret;
 end;

{ regnode - emit a node
  TRegExp.RegNode }

function TRegExp.RegNode(Op: Char): PChar;
 var
  Ret, P: PChar;
 begin
  Ret:=RegCode;

  if Ret = @RegDummy then
   begin
    Inc(RegSize, OpHdr);

    RegNode:=Ret;

    Exit;
   end;

  P:=Ret;
  P^:=Op;

  Inc(P);

  P^:=#0; { null "next" pointer }

  Inc(P);

  P^:=#0;

  Inc(P);

  RegCode:=P;
  RegNode:=Ret;
 end;

{ regnext - dig the "next" pointer out of a node
  TRegExp.RegNext }

function TRegExp.RegNext(P: PChar): PChar;
 var
  Offset: Word;
 begin
  if P = @RegDummy then
   begin
    RegNext:=nil;

    Exit;
   end;

  Offset:=PRegOp(P)^.Next;

  if Offset = 0 then
   begin
    RegNext:=nil;

    Exit;
   end;

  if PRegOp(P)^.Op = Back then
   RegNext:=P - Offset
  else
   RegNext:=P + Offset;
 end;

{ reginsert - insert an operator in front of already-emitted operand
  TRegExp.RegInsert }

procedure TRegExp.RegInsert(Op: Char; Opnd: PChar);
 var
  Src, Dst, Place: PChar;
 begin
  if RegCode = @RegDummy then
   begin
    Inc(RegSize, OpHdr);

    Exit;
   end;

  Src:=RegCode;

  Inc(RegCode, OpHdr);

  Dst:=RegCode;

  while (Src > Opnd) do
   begin
    Dec(Dst);

    Dec(Src);

    Dst^:=Src^;
   end;

  Place:=Opnd;

  Place^:=Op;

  Inc(Place);

  Place^:=#0;

  Inc(Place);

  Place^:=#0;

  Inc(Place);
 end;

{ regtail - set the next-pointer at the end of a node chain
  TRegExp.RegTail }

procedure TRegExp.RegTail(P, Val: PChar);
 var
  Scan, Temp: PChar;
  Offset: Word;
 begin
  if P = @RegDummy then
   Exit;

  { find last node }

  Scan:=P;

  while True do
   begin
    Temp:=RegNext(Scan);

    if Temp = nil then
     Break;

    Scan:=Temp;
   end;

  if PRegOp(Scan)^.Op = Back then
   Offset:=Scan - Val
  else
   Offset:=Val - Scan;

  PRegOp(Scan)^.Next:=Offset;
 end;

{ regoptail - regtail on operand of first argument; nop if operandless
  TRegExp.RegOpTail }

procedure TRegExp.RegOpTail(P, Val: PChar);
 begin
  { "Operandless" and "Op != BRANCH" are synonymous in practice }

  if (P <> nil) and (P <> @RegDummy) and (PRegOp(P)^.Op = Branch) then
   RegTail(P + OpHdr, Val);
 end;

{ regtry - try match at specific point
  TRegExp.RegTry }

function TRegExp.RegTry(Prog: PRegExpr; St: PChar): Boolean;
 var
  I: Word;
  Sp, Ep: PStringTable;
 begin
  RegInput:=St;
  RegStartp:=@Prog^.StartP;
  RegEndP:=@Prog^.EndP;

  Sp:=@Prog^.StartP;
  Ep:=@Prog^.EndP;

  for I:=1 to RegExp_Max_NSubExp do
   begin
    Sp^[I]:=nil;
    Ep^[I]:=nil;
   end;

  if RegMatch(PChar(@Prog^.RegProgram) + 1) then
   begin
    Prog^.StartP[0]:=St;
    Prog^.EndP[0]:=RegInput;

    RegTry:=True;
   end
  else
   RegTry:=False;
 end;

{ regmatch - main matching routine
  TRegExp.RegMatch }

function TRegExp.RegMatch(Prog: PChar): Boolean;
 var
  Scan, Next, Opnd, Save: PChar;
  Len, No, Min: Integer;
  NextCh: Char;
 begin
  Scan:=Prog;

  while Scan <> nil do
   begin
    Next:=RegNext(Scan);

    case PRegOp(Scan)^.Op of
     Bol:
      if RegInput <> RegBol then
       begin
        RegMatch:=False;

        Exit;
       end;
     Eol:
      if RegInput^ <> #0 then
       begin
        RegMatch:=False;

        Exit;
       end;
     Any:
      begin
       if RegInput^=#0 then
        begin
         RegMatch:=False;

         Exit;
        end;

       Inc(RegInput);
      end;
     Exactly:
      begin
       Opnd:=Scan + OpHdr;

       if (RegCase and (opnd^ <> RegInput^)) or ((not RegCase) and (UpCase(Opnd^) <> UpCase(RegInput^))) then
        begin
         RegMatch:=False;

         Exit;
        end;

       Len:=StrLen(Opnd);

       if (Len > 1) and (Comparer(Opnd, RegInput, Len) <> 0) then
        begin
         RegMatch:=False;

         Exit;
        end;

       Inc(RegInput, Len);
      end;
     AnyOf:
      begin
       if (RegInput^ = #0) or (StrScan(Scan + OpHdr, RegInput^) = nil) then
        begin
         RegMatch:=False;

         Exit;
        end;

       Inc(RegInput);
      end;
     AnyBut:
      begin
       if (RegInput^ = #0) or (StrScan(Scan + OpHdr, RegInput^) <> nil) then
        begin
         RegMatch:=False;

         Exit;
        end;

       Inc(RegInput);
      end;
     Nothing:;
     Back:;
     Open + 1..Open + MaxBrackets - 1:
      begin
       No:=PRegOp(Scan)^.Op - Open;

       Save:=RegInput;

       if RegMatch(Next) then
        begin
         if RegStartP^[No] = nil then
          RegStartP^[No]:=Save;

         RegMatch:=True;

         Exit;
        end
       else
        begin
         RegMatch:=False;

         Exit;
        end;
      end;
     Close + 1..Close + MaxBrackets - 1:
      begin
       No:=PRegOp(Scan)^.Op - Close;

       Save:=RegInput;

       if RegMatch(Next) then
        begin
         if RegEndP^[No] = nil then
          RegEndP^[No]:=Save;

         RegMatch:=True;

         Exit;
        end
       else
        begin
         RegMatch:=False;

         Exit;
        end;
      end;
     Branch:
      begin
       if PRegOp(Next)^.Op <> Branch then
        Next:=Scan + OpHdr
       else
        begin
         repeat
          Save:=RegInput;

          if RegMatch(Scan + OpHdr) then
           begin
            RegMatch:=True;

            Exit;
           end;

          RegInput:=Save;

          Scan:=RegNext(Scan);
         until (Scan = nil) or (PRegOp(Scan)^.Op <> Branch);

         RegMatch:=False;

         Exit;
        end;
      end;
     Star,
     Plus:
      begin
       NextCh:=Chr(0);

       if PRegOp(Next)^.Op = Exactly then
        NextCh:=(Next + OpHdr)^;

       if PRegOp(Scan)^.Op = Star then
        Min:=0
       else
        Min:=1;

       Save:=RegInput;

       No:=RegRepeat(Scan + OpHdr);

       while No >= Min do
        begin
         if (NextCh = #0) or (RegInput^ = NextCh) then
          if RegMatch(Next) then
           begin
            RegMatch:=True;

            Exit;
           end;

         Dec(No);

         RegInput:=Save;

         Inc(RegInput, No);
        end;

       RegMatch:=False;

       Exit;
      end;
     Pend:
      begin
       RegMatch:=True;

       Exit;
      end;
    else
     RegError('memory corruption');

     RegMatch:=False;

     Exit;
    end;

    Scan:=Next;
   end;

  RegError('corrupted pointers');

  RegMatch:=False;
 end;

{ regrepeat - repeatedly match something simple, report how many
  TRegExp.RegRepeat }

function TRegExp.RegRepeat(P: PChar): Word;
 var
  Count: Word;
  Scan, Opnd: PChar;
 begin
  Count:=0;

  Scan:=RegInput;

  Opnd:=P + OpHdr;

  case PRegOp(P)^.Op of
   Any:
    begin
     Count:=StrLen(Scan);

     Inc(Scan, Count);
    end;
   Exactly:
    while (Opnd^ = Scan^) or ((not RegCase) and (UpCase(Opnd^) = UpCase(Scan^))) do
     begin
      Inc(Count);

      Inc(Scan);
     end;
   AnyOf:
    while (Scan^ <> #0) and (StrScan(Opnd, Scan^) <> nil) do
     begin
      Inc(Count);

      Inc(Scan);
     end;
   AnyBut:
    while (Scan^ <> #0) and (StrScan(Opnd, Scan^) = nil) do
     begin
      Inc(Count);

      Inc(Scan);
     end;
  else
   RegError('internal foulup');

   Count:=0;
  end;

  RegInput:=Scan;
  RegRepeat:=Count;
 end;

{ regsub - perform substitutions after a regexp match
  TRegExp.RegSub }

procedure TRegExp.RegSub(Prog: PRegExpr; Source, Dest: PChar);
 var
  Src, Dst: PChar;
  C: Char;
  No: Integer;
  Len: Word;
 begin
  if (Prog = nil) or (Source = nil) or (Dest = nil) then
   begin
    RegError('NULL parm to regsub');

    Exit;
   end;

  if Prog^.RegProgram[0] <> Magic then
   begin
    RegError('damaged regexp fed to regsub');

    Exit;
   end;

  Src:=Source;
  Dst:=Dest;

  C:=Src^;

  Inc(Src);

  while C <> #0 do
   begin
    if C = '&' then
     No:=0
    else
     if (C = '\') and (Ord('0') <= Ord(Src^)) and (Ord(Src^) <= Ord('9')) then
      begin
       No:=Ord(Src^) - Ord('0') + 1;

       Inc(Src);
      end
     else
      No:=-1;

    if No < 0 then
     begin
      if C = '\' then
       C:=Escape(Src);

      Dst^:=C;

      Inc(Dst);
     end
    else
     if (Prog^.StartP[No] <> nil) and (Prog^.EndP[No] <> nil) then
      begin
       Len:=Prog^.EndP[No] - Prog^.StartP[No];

       StrLCopy(Dst, Prog^.StartP[No], Len);

       Inc(Dst, Len);

       if (Len <> 0) and ((Dst - 1)^ = Chr(0)) then
        begin
         RegError('damaged match string');

         Exit;
        end;
      end;

    C:=Src^;

    Inc(Src);
   end;

  Dst^:=Chr(0);
 end;

{ emit (if appropriate) a byte of code
  TRegExp.RegC }

procedure TRegExp.RegC(b: Char);
 begin
  if RegCode <> @RegDummy then
   begin
    RegCode^:=B;

    Inc(RegCode);
   end
  else
   Inc(RegSize);
 end;

{$IFDEF DEBUGREGEXP}
{ regdump - dump a regexp onto stdout in vaguely comprehensible form
  TRegExp.RegDump }

procedure TRegExp.RegDump(R: PRegExpr);
 var
  S, Next: PChar;
  Op: Byte;
 begin
  Op:=Exactly;

  S:=R^.RegProgram;

  Inc(S);

  while Op <> PEnd do
   begin
    Op:=PRegOp(S)^.Op;

    Write(Integer(S - R^.RegProgram), RegProp(S), ' ');

    Next:=RegNext(S);

    if Next = nil then
     Write('(0) ')
    else
     Write('(', Integer(S - R^.RegProgram) + Integer(Next - S), ') ');

    Inc(S, OpHdr);

    if (Op = AnyOf) or (Op = AnyBut) or (Op = Exactly) then
     begin
      while S^ <> Chr(0) do
       begin
        Write(S^);

        Inc(S);
       end;

      Inc(S);
     end;

    WriteLn;
   end;

  if R^.RegStart <> Chr(0) then Write('start "', R^.RegStart, '"');
  if R^.RegAnch <> Chr(0) then Write('anchored ');
  if R^.RegMust <> nil then Write('must have "', StrPas(R^.RegMust), '"');

  WriteLn;
  WriteLn('--');
  WriteLn;
 end;

{ regprop - printable representation of opcode
  TRegExp.RegProp }

function TRegExp.RegProp(Op: PChar): String;
 var
  Buf, P: String;
 begin
  Buf:=':';

  case PRegOp(Op)^.Op of
   Bol:     P:='Bol';
   Eol:     P:='Eol';
   Any:     P:='Any';
   AnyOf:   P:='AnyOf';
   AnyBut:  P:='AnyBut';
   Branch:  P:='Branch';
   Exactly: P:='Exactly';
   Nothing: P:='Nothing';
   Back:    P:='Back';
   Pend:    P:='End';
   Star:    P:='Star';
   Plus:    P:='Plus';
   Open + 1..Open + MaxBrackets - 1:
    begin
     Str(PRegOp(Op)^.Op - Open, P);

     Buf:=Buf + 'Open' + P;

     P:='';
    end;
   Close + 1..Close + MaxBrackets - 1:
    begin
     Str(PRegOp(Op)^.Op - Close, P);

     Buf:=Buf + 'Close' + P;

     P:='';
    end;
  else
   RegError('corrupted opcode');
  end;

  if P <> '' then
   Buf:=Buf + P;

  RegProp:=Buf;
 end;
{$ENDIF}

{ GrepCheck }

function GrepCheck(Mask:string;const  Data: String; CaseSensitive: Boolean): Boolean;
 var
  RgExp: TRegExp;
  Len : byte absolute Mask;
  Ret : boolean;
 begin
  if (Mask = '') or (Data = '') then
   GrepCheck:=False
  else
   begin
    If (Mask[1]='/') and (Mask[Len]='/') then
      begin
        Delete(Mask,Len,1);
        Delete(Mask,1,1);
        RgExp.InitStr(Mask);
      end else RgExp.InitWildcard(Mask);

    GrepCheck:=RgExp.MaskMatchStr(Data, CaseSensitive);

    RgExp.Done;
   end;
 end;

{ GrepCheckPChar }

function GrepCheckPChar(const Mask, Data: PChar; CaseSensitive: Boolean): Boolean;
 var
  RgExp: TRegExp;
  NewMask : PChar;
  Len : word;
 begin
  if (Mask = nil) or (Data = nil) then
   GrepCheckPChar:=False
  else
   begin
    Len:=StrLen(Mask);
    If (Mask[0]='/') and (Mask[Len-1]='/') then
      begin
        GetMem(NewMask,Len-2);
        StrLCopy(NewMask,@Mask[1],Len-2);
        RgExp.Init(NewMask);
        StrDispose(NewMask);
      end else RgExp.InitWildcard(StrPas(Mask));

    GrepCheckPChar:=RgExp.MaskMatch(Data, CaseSensitive);

    RgExp.Done;
   end;
 end;

{ GrepReplace }

function GrepReplace(const Mask, Data, ReplaceTo: String; CaseSensitive: Boolean): String;
 var
  MaskPChar, DataPChar, ReplaceToPChar: PChar;
 begin
  MaskPChar:=StrAlloc(Mask);
  DataPChar:=StrAlloc(Data);

  ReplaceToPChar:=GrepReplacePChar(MaskPChar, DataPChar, ReplaceToPChar, CaseSensitive);

  GrepReplace:=StrPas(ReplaceToPChar);

  StrDispose(ReplaceToPChar);
  StrDispose(DataPChar);
  StrDispose(MaskPChar);
 end;

{ GrepReplacePChar }

function GrepReplacePChar(const Mask, Data, ReplaceTo: PChar; CaseSensitive: Boolean): PChar;
 var
  RgExp: TRegExp;
  ReplaceResult: PChar;
 begin
  if (Mask = nil) or (Data = nil) or (ReplaceTo = nil) then
   GrepReplacePChar:=nil
  else
   begin
    RgExp.Init(Mask);

    if not RgExp.MaskMatch(Data, CaseSensitive) then
     begin
      RgExp.Done;

      GrepReplacePChar:=nil;

      Exit;
     end;

    GetMem(ReplaceResult, RegExp_MaxPCharLen);

    RgExp.RegSub(RgExp.Mask, ReplaceTo, ReplaceResult);

    GrepReplacePChar:=StrNew(ReplaceResult);

    FreeMem(ReplaceResult, RegExp_MaxPCharLen);

    RgExp.Done;
   end;
 end;

{ StrAlloc }

function StrAlloc(const S: String): PChar;
 var
  P: PChar;
 begin
  GetMem(P, Length(S) + 1);

  StrPCopy(P, S);

  StrAlloc:=P;
 end;

{ PreprocessWildcard }

function PreprocessWildcard(const AWildcard: String): String;
 var
  AMask: String;
  K: Integer;
 begin
  { cw "*" -> re ".*" }
  { cw "?" -> re "."  }

  { beforebackslash on "\.^$[]|+()" }

  if AWildcard = '' then
   AMask:='^$'
  else
   if AWildcard = '*' then
    AMask:='.*'
   else
    begin
     AMask:='^';

     for K:=1 to Length(AWildcard) do
      case AWildcard[K] of
       '*': AMask:=Concat(AMask, '.*');
       '?': AMask:=Concat(AMask, '.');
       '^',
       '$',
       '\',
       '.',
       '[',
       ']',
       '|',
       '+',
       '(',
       ')': AMask:=Concat(AMask, '\', AWildcard[K]);
      else
       AMask:=Concat(AMask, AWildcard[K]);
      end;

     AMask:=Concat(AMask, '$');
    end;

  PreprocessWildcard:=AMask;
 end;

end.
