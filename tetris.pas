program Tetris;


uses GraphWin; {System}

{ The constant below is the current version of the game, see the history
  below in the comments. }

const Version = '1.41 (22/04/1998)';

{
  INSTRUCTIONS
  ------------

  INTRODUCTION
This is an implementation of the game Tetris, written in Turbo Pascal. It
supports an infinite number of players, although the speed will suffer. The
highest score is saved, and simple sound support exists.

  THE KEYS
Currently all the keys are in lower case, although they can be modified
below, in the main program. You could easily fix it so the case is ignored,
if you wanted to.

/---------------------------------------\
|ACTION | PLAYER 1 | PLAYER 2 | PLAYER 3 |
|----------------------------------------|
|  LEFT | z        | j        | 4        |
| RIGHT | x        | l        | 6        |
|ROTATE | c        | i        | 8        |
|  DROP | <SPACE>  | m        | 2        |
\---------------------------------------/

  OTHER BITS TO CHANGE
CONSTANTS    Players                      The number of Players
             Interactive                  Should it be a multiplayer
                                           interactive?
             Player<x>                    The position of the tetris bucket
             Scale                        The size of the blocks
ASSIGNMENTS  Speed (TGame.Create)         The slowness of the game, reduce
                                           to go faster.


  WHY DID IT CRASH
* If you have added more buckets / enlarged them, and you start getting
mysterious crashes, try and increase the constant BoxesTotal.

* If you can't recompile, you need probably need GraphWin.tpu.

* If you're getting runtime errors, it probably can't find the highscore
file, try and add an empty (zero length) file called 'TetHi.dat' in the
same folder of the executeable.

  WHAT CAN I DO?
Well, as well as playing the game, you could also try playing with the
constants, and other assignments. If you have some time, you could try and
implement some of the features in the to-do list below. For maschists, there
is always the documentation the really should be written.

To Do:
   Make constructor TPiece.Create a pure virtual function, and make each
    of the different Pieces types.
   Make the area pushed up greater.
   Raise start position of blocks
   Remember what the cheats actually are.
   Move hi-score code into the main program where in belongs - campaign
    against globals!
   Move sound support into procedures, to allow real sound later (different
    effects for example.)
   Make it cope with the high score file not being present.
   Make a nice user interface with setup, restart, real high-score table,
    GUI etc.
   Add serial support for use in C102. ;-)

History:
  1.0              First fully working version
  1.1  17/03/1998  Added several cheats
  1.2  19/03/1998  Now exits when all players are dead
                   Rotation of Square piece fixed
  1.3  26/03/1998  Added high score.
  1.4  02/04/1998  Added sound effects!
  1.41 21/04/1998  Added some documentation.


If you manage to find where I put the cheats in this program, could you
tell me, as I have now forgotten where they were. Thanks.

}

{uses ToolHelp;}

type TColour = record
                     r, g, b:BYTE;
               end;

     TCoord = record
                    x, y:INTEGER;
              end;

     TRealCoord = record
                        x, y:REAL;
                  end;


const Scale           =15;
      Offset          :TCoord=(x:00; y:70);

      Left            :TCoord=(x:-1; y: 0);
      Right           :TCoord=(x: 1; y: 0);
      Up              :TCoord=(x: 0; y:-1);
      Down            :TCoord=(x: 0; y: 1);

      TopLeft         :TCoord=(x: 0; y: 0);
      SomeWhere       :TCoord=(x: 5; y: 5);

      Black           :TColour=(r:  0; g:  0; b:  0);
      Pink            :TColour=(r:255; g:100; b:  0);
      Red             :TColour=(r:255; g:  0; b:  0);
      Green           :TColour=(r:  0; g:255; b:  0);
      Blue            :TColour=(r:  0; g:  0; b:255);
      Cyan            :TColour=(r:  0; g:255; b:255);
      Grey            :TColour=(r:128; g:128; b:128);
      Yellow          :TColour=(r:255; g:  0; b:255);
      CheatActive     :TColour=(r:  1; g:  0; b:  1);
      LightBlue       :TColour=(r:128; g: 20; b:128);

      BoxesTotal      =2000;

      PieceSize       =4;


var HiScoreF   : FILE OF LONGINT;
    HiScore    : LONGINT;


{ Used ahead by TSolidSquare.SafeMove
}
function TestPosition(Pos:TCoord):BOOLEAN; forward;

FUNCTION Rad(Degrees:REAL) :REAL;
         BEGIN
              Rad:=(Degrees/180)*PI
         END;
{ENDFN}

FUNCTION Pythagoras(Vec:TRealCoord) :REAL;
         BEGIN
              Pythagoras:=SQRT((Vec.x*Vec.x)+(Vec.y*Vec.y))
         END;
{END FN}

FUNCTION Distance(Vec1, Vec2:TRealCoord) :REAL;
         VAR Temp:TRealCoord;
         BEGIN
              Temp.x:=Vec1.x-Vec2.x;
              Temp.y:=Vec1.y-Vec2.y;
              Distance:=Pythagoras(Temp);
         END;

function GStr(Num:INTEGER):STRING;
         var Temp:STRING;

         begin
              Str(Num, Temp);
              GStr:=Temp;
         end;

{ *************************************************************************
  **** Base graphics routines ****
  *************************************************************************}
procedure SetGraphics (Pen, Brush:TColour; BrushT:INTEGER);
          begin
               SetPenColour(Pen.r, Pen.g, Pen.b);
               SetBrushColour(Brush.r, Brush.g, Brush.b);
               SetBrushStyle(BrushT);
          end;
{endproc}

procedure PlotSquare (Location:TCoord);
          begin
               drawoblong((Location.x*Scale)+Offset.x      , (Location.y*Scale)+Offset.y,
                          (Location.x*Scale)+Offset.x+Scale, (Location.y*Scale)+Offset.y+Scale);
          end;
{endproc}

procedure EraseSquare (Location:TCoord);
          begin
               eraseoblong((Location.x*Scale)+Offset.x      , (Location.y*Scale)+Offset.y,
                           (Location.x*Scale)+Offset.x+Scale, (Location.y*Scale)+Offset.y+Scale);
          end;
{endproc}

procedure PlotString (Location:TCoord; text:STRING);
          begin
               drawtext((Location.x*Scale)+Offset.x, (Location.y*Scale)+Offset.y,text);
          end;
{end proc}

procedure EraseString (Location:TCoord; text:STRING);
          begin
               erasetext((Location.x*Scale)+Offset.x, (Location.y*Scale)+Offset.y,text);
          end;
{end proc}


{ *************************************************************************
  **** The TSquare object ****    
  *************************************************************************}
type TSquare = object
                     PenColour:TColour;
                     BrushColour:TColour;
                     BrushType:INTEGER;
                     Place:TCoord;


                     procedure Move (OPlace:TCoord);
                     procedure MoveTo (NPlace:TCoord);
                     procedure SoftMove(NPlace:TCoord);
                     procedure SoftMoveTo(NPlace:TCoord);

                     constructor Create (NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
                     destructor Destroy;
               end;

procedure TSquare.move (OPlace:TCoord);
          begin
               if (OPlace.x=0) AND (OPlace.y=0) then
               else
                   begin
                        SetGraphics(PenColour, BrushColour, BrushType);
                        EraseSquare(Place);
                        Place.x:=Place.x+OPlace.x;
                        Place.y:=Place.y+OPlace.y;
                        PlotSquare(Place);
                   end;
               {endif}
          end;
{end proc}

procedure TSquare.MoveTo(NPlace:TCoord);
          begin
               if NOT ((NPlace.x=Place.x) AND (NPlace.y=Place.y)) then
                  begin
                       SetGraphics(PenColour, BrushColour, BrushType);
                       EraseSquare(Place);
                       Place.x:=NPlace.x;
                       Place.y:=NPlace.y;
                       PlotSquare(Place);
                  end;
               {endif}
          end;
{end proc}

procedure TSquare.SoftMove(NPlace:TCoord);
          begin
               Place.x:=Place.x+NPlace.x;
               Place.y:=Place.y+NPlace.y;
          end;
{end proc}

procedure TSquare.SoftMoveTo(NPlace:TCoord);
          begin
               Place.x:=NPlace.x;
               Place.y:=NPlace.y;
          end;
{end proc}

constructor TSquare.Create (NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
            begin
                 PenColour:=NPenColour;
                 BrushColour:=NBrushColour;
                 BrushType:=NBrushType;
                 Place:=NPlace;
                 SetGraphics(PenColour, BrushColour, BrushType);
                 PlotSquare(Place);
            end;
{endproc}

destructor TSquare.Destroy;
           begin
                SetGraphics(PenColour, BrushColour, BrushType);
                EraseSquare(Place);
           end;

{ *************************************************************************
  **** The TSolidSquare object ****
  *************************************************************************}

type TSolidSquare = object (TSquare)
                           Number:INTEGER;
                           Indestructable:BOOLEAN;

                           function    SafeMove(OPlace:TCoord):BOOLEAN;
                           constructor Create (NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
                           constructor Indes  (NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
                           destructor  Destroy;
                    end;

var TSolidSquareList:ARRAY[1..BoxesTotal] of ^TSolidSquare;



function TSolidSquare.SafeMove (OPlace:TCoord):BOOLEAN;
         var Finally:TCoord;
             Result :BOOLEAN;
         begin
              Finally.x:=Place.x+OPlace.x;
              Finally.y:=Place.y+OPlace.y;
              Result:=TestPosition(Finally);
              if (NOT Result) then move(OPlace);
              SafeMove:=Result;
         end;
{end fn}

function Collide(Ob:TSolidSquare):BOOLEAN;
         var Search: INTEGER;
             Test  :^TSolidSquare;
             Crash : BOOLEAN;
         begin
              Crash:=FALSE;
              for Search:=1 to BoxesTotal do
                  begin
                       Test:=TSolidSquareList[Search];
                       if (Test<>nil) then
                          if (Test^.Number<>Ob.Number) then
                             begin
                                  if ((Test^.Place.x=Ob.Place.x) AND (Test^.Place.y=Ob.Place.y)) then Crash:=TRUE;
                             end;
                          {end if}
                       {end if}
                  end;
              {end for}            
              {WRITELN(Crash);}
              Collide:=Crash;
         end;
{end fn}

function TestPosition(Pos:TCoord):BOOLEAN;
         var Search: INTEGER;
             Test  :^TSolidSquare;
             Crash : BOOLEAN;

         begin
              Crash:=FALSE;
              for Search:=1 to BoxesTotal do
                  begin
                       Test:=TSolidSquareList[Search];
                       if (Test<>nil) then
                          begin
                               if ((Test^.Place.x=Pos.x) AND (Test^.Place.y=Pos.y)) then Crash:=TRUE;
                          end;
                       {end if}
                  end;
              {end for}            
              {WRITELN(Crash);}
              TestPosition:=Crash;
         end;
{end proc}

function DestroyMe(One:TCoord):BOOLEAN;
         var Progress:INTEGER;
             Caught  :^TSolidSquare;

         begin
              for Progress:=1 to BoxesTotal do
                  if (TSolidSquareList[Progress]<>nil) then
                     if ((TSolidSquareList[Progress]^.Place.x=One.x) AND (TSolidSquareList[Progress]^.Place.y=One.y)) then
                        Caught:=TSolidSquareList[Progress];
              DestroyMe:=NOT Caught^.Indestructable;
              {dispose(Caught);}

              {Caught^.Move(Left); }
         end;
{end function}

constructor TSolidSquare.Create (NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
            var Search:INTEGER;
            begin
                 Search:=1;
                 while (TSolidSquareList[Search]<>nil) do Search:=Search+1;
                 {TSolidSquareList:=Self;}
                 Number:=Search;
                 TSolidSquareList[Search]:=@Self;
                 TSquare.Create(NPenColour, NBrushColour, NBrushType, NPlace);
                 Indestructable:=FALSE;
            end;
{end proc}

constructor TSolidSquare.Indes(NPenColour, NBrushColour:TColour; NBrushType:INTEGER; NPlace:TCoord);
            begin
                 Create(NPenColour, NBrushColour, NBrushType, NPlace);
                 Indestructable:=TRUE;
            end;
{end proc}

destructor TSolidSquare.Destroy;
           begin
                SetGraphics(PenColour, BrushColour, BrushType);
                EraseSquare(Place);
                TSolidSquareList[Number]:=nil;
           end;
{end proc}

{ *************************************************************************
  **** The Area Object ****
  *************************************************************************}

type TSolidNess = (Solid, Ghostly, Dodgy);

type TArea = object
                   Start     : TCoord;
                   Finish    : TCoord;

                   function AnythingIn :BOOLEAN;
                   function AllFull    :BOOLEAN;
                   procedure Fill(Pen, Brush:TColour; BrushType:INTEGER; SolidNess:TSolidNess);
                   procedure Move(Direction:TCoord);
                   procedure Zap;

                   constructor Create(S, F:TCoord);
                   constructor HLine(Place:TCoord; Len:INTEGER); 
             end;

function TArea.AnythingIn:BOOLEAN;
         var Something :BOOLEAN;
             Progress  :TCoord;

         begin
              Something:=FALSE;
              for Progress.x:=Start.x to Finish.x do
                  for Progress.y:=Start.y to Finish.y do
                      if TestPosition(Progress) then Something:=TRUE;
                  {end for}
              {end for}
              AnythingIn:=Something;
         end;
{end function}

function TArea.AllFull:BOOLEAN;
         var Full      :BOOLEAN;
             Progress  :TCoord;
             newob     :^TSolidSquare;

         begin
              Full:=TRUE;
              for Progress.x:=Start.x to Finish.x do
                  for Progress.y:=Start.y to Finish.y do
                      begin
                           {WRITELN(Progress.x, '  ',Progress.y); }
                           if (NOT TestPosition(Progress)) then begin
                              Full:=FALSE;
                              {WRITELN(Progress.x, '  ',Progress.y);}
                              {new(newob, Create(Red, Red, 1, Progress));}
                           end;
                      end;
                  {end for}
              {end for}
              AllFull:=Full;
         end;
{end function}


{ Now with added obfustication absolutly free! }
procedure TArea.Fill(Pen, Brush:TColour; BrushType:INTEGER; SolidNess:TSolidNess);
          var Progress  : TCoord;
              GhostOb   :^TSquare;
              SolidOb   :^TSolidSquare;

          begin
               for Progress.x:=Start.x to Finish.x do
                   for Progress.y:=Start.y to Finish.y do
                       begin
                            if (SolidNess=Solid  ) then new(SolidOb, Create(Pen, Brush, BrushType, Progress));
                            if (SolidNess=Ghostly) then new(GhostOb, Create(Pen, Brush, BrushType, Progress));
                            if (SolidNess=Dodgy  ) then new(SolidOb, Indes (Pen, Brush, BrushType, Progress));
                       end;
               {WRITELN('Finished');
               READLN;
               {Dummy}
          end;

procedure TArea.Move(Direction:TCoord);
          var Progress:INTEGER;

          begin
               
               for Progress:=1 to BoxesTotal do
                   if TSolidSquareList[Progress]<>nil then
                      with TSolidSquareList[Progress]^ do
                           if ((Place.x>=Start.x)  AND (Place.y>=Start.y) AND
                               (Place.x<=Finish.x) AND (Place.y<=Finish.y)) then TSolidSquareList[Progress]^.Move(Direction);
               

                                 

          end;
{end proc}

procedure TArea.Zap;
          var Progress:INTEGER;

          begin
               for Progress:=1 to BoxesTotal do
                   if TSolidSquareList[Progress]<>nil then
                      with TSolidSquareList[Progress]^ do
                           if ((Place.x>=Start.x)  AND (Place.y>=Start.y) AND
                               (Place.x<=Finish.x) AND (Place.y<=Finish.y)) then dispose(TSolidSquareList[Progress], Destroy);
                           { end if}
                      {end with}
                   {end if}
               {end if}     
          end;
{end proc}

constructor TArea.Create(S, F:TCoord);
            begin
                 Start :=S;
                 Finish:=F;
            end;

constructor TArea.HLine(Place:TCoord; Len:INTEGER);
            var Sta, Fin:TCoord;

            begin
                 Sta:=Place;
                 Fin.x:=Place.x+Len;
                 Fin.y:=Place.y;

                 Create(Sta, Fin);
            end;     

{ *************************************************************************
  **** The TGfxString object ****      
  *************************************************************************}

type TGfxString = object
                        Place   :TCoord;
                        Col     :TColour;
                        Text    :STRING;

                        procedure Change(Str:STRING);

                        constructor Create(Where:TCoord; Respray:TColour; Str:STRING);
                        destructor  Destroy;
                  end;

procedure TGfxString.Change (Str:STRING);
          begin
               SetPenColour(Col.r, Col.g, Col.b);
               EraseString(Place, Text);

               Text:=Str;
               PlotString(Place, Text);
          end;

constructor TGfxString.Create(Where:TCoord; Respray:TColour; Str:STRING);
            begin
                 {WRITELN('Hello Dave');}
                 Place:=Where;
                 Col:=Respray;
                 SetPenColour(Col.r, Col.g, Col.b);

                 SetGraphics(Black, Black, 0);
                 Text:=Str;
                 PlotString(Place,Str);
            end;

destructor TGfxString.Destroy;
           begin
                SetPenColour(Col.r, Col.g, Col.b);
                EraseString(Place, Text);
           end;




{ *************************************************************************
  **** The TScore object ****      
  *************************************************************************}

type TScore = object
                    Score       :LONGINT;

                    Image       :^TGfxString;

                    procedure Change(Scr:LONGINT);
                    procedure Increase(Inc:LONGINT);

                    function Read:LONGINT;

                    constructor Create(Where:TCoord; Scr:LONGINT);
                    constructor Reset (Where:TCoord);
                    destructor Destroy;
              end;

procedure TScore.Change(Scr:LONGINT);
          begin
               if (Score<>Scr) then
                  begin
                       Score:=Scr;
                       Image^.Change(GStr(Score));
                  end;
               {end if}
          end;
{end proc}

procedure TScore.Increase(Inc:LONGINT);
          var Temp:LONGINT;

          begin
               Temp:=Score+Inc;
               Change(Temp);
          end;
{end proc}

function TScore.Read:LONGINT;
         begin
              Read:=Score;
         end;
{end function}

constructor TScore.Create(Where:TCoord; Scr:LONGINT);
            begin
                 Score:=Scr;
                 new(Image, Create(Where, Black, GStr(Score)));
            end;

constructor TScore.Reset(Where:TCoord);
            begin
                 Create(Where,0);
            end;


destructor TScore.Destroy;
           begin
                dispose(Image);
           end;



{ *************************************************************************
  **** The TPiece object ****      
  *************************************************************************}

type PieceType = (SquarePiece, LPiece, LongThinPiece, TeePiece, EssPiece,
                  EssPieceI, LPieceI);
                     
type TPiece = object
                    Squares        :array[1..PieceSize] of ^TSolidSquare;
                    Centre         :TCoord;
                    Rotateable     :BOOLEAN; {Squares shouldn't rotate }

                    procedure   FillSquare(NPenColour, NBrushColour:TColour; NBrushType:INTEGER;
                                           WhichOne, Location:TCoord);
                    function    Move(Direction:TCoord; Update:BOOLEAN):BOOLEAN;
                    procedure   Rotate;
                    function    MoveTo(Target:TCoord):BOOLEAN;

                    constructor Any(Offset:TCoord);
                    constructor Create (Piece:PieceType; Offset:TCoord);
                    destructor  Destroy;
                    destructor  LeaveSquares;
              end;

procedure TPiece.FillSquare (NPenColour, NBrushColour:TColour; NBrushType:INTEGER;
                             WhichOne, Location:TCoord);
          var Position:TCoord;
              Index   :INTEGER;
          begin
               Position.x:=WhichOne.x+Location.x;
               Position.y:=WhichOne.y+Location.y;

               Index:=1;

               while ((Squares[Index]<>nil) AND (Index<PieceSize)) do Index:=Index+1;

               New(Squares[Index], Create(NPenColour, NBrushColour, NBrushType, Position));
          end;
{end proc}

function TPiece.Move(Direction:TCoord; Update:BOOLEAN):BOOLEAN;
         var Pos       :INTEGER;
             Inverted  :TCoord;
             dummy     :BOOLEAN;
             Failed    :BOOLEAN;

         const GetDown   :TCoord=(x:1; y:-1);
         begin
              {WRITE(CHR(7)); }
              Failed:=FALSE;

              { To iterate is human, to recurse if divine }
              for Pos:=1 to PieceSize do
                  begin
                       if Squares[Pos]<>nil then
                          Squares[Pos]^.SoftMove(Direction);
                       {end if}
                  end;
              {end for}

             for Pos:=1 to PieceSize do
                 begin
                      if Squares[Pos]<>nil then
                         if Collide(Squares[Pos]^) then Failed:=TRUE;
                      {end if}
                 end;
             {end for}

             Inverted.x:=0-Direction.x;
             Inverted.y:=0-Direction.y;

             {
             Centre.x:=Centre.x+Direction.x;
             Centre.y:=Centre.y+Direction.y;
             }

             for Pos:=1 to PieceSize do
                 begin
                      if Squares[Pos]<>nil then
                         Squares[Pos]^.SoftMove(Inverted);
                      {end if}
                 end;
             {end for}

             Move:=Failed;

             if NOT Failed then
                begin
                     if Update then Centre.x:=Centre.x+Direction.x;
                     if Update then Centre.y:=Centre.y+Direction.y;
                     for Pos:=1 to PieceSize do
                         if Squares[Pos]<>nil then
                            Squares[Pos]^.Move(Direction);
                         {end if}
                     {end for}
                end;
             {end if}        

         end;     
              
procedure TPiece.Rotate;
         var Index      :INTEGER;
         var NewPlace   :TCoord;
             VNewPlace  :TCoord;
             Failed     :BOOLEAN;
         begin
              WriteMoo(CHR(7));
              if Rotateable then
                 begin
                      Failed:=FALSE;
                      for Index:=1 to PieceSize do
                          if (Squares[Index]<>nil) then
                             begin
                                  NewPlace.x:=Squares[Index]^.Place.x-Centre.x;
                                  NewPlace.y:=Squares[Index]^.Place.y-Centre.y;

                                  VNewPlace.x:=0-NewPlace.y;
                                  VNewPlace.y:=NewPlace.x;
                          
                                  NewPlace.x:=VNewPlace.x+Centre.x;
                                  NewPlace.y:=VNewPlace.y+Centre.y;                                            

                                  Squares[Index]^.MoveTo(NewPlace);
                                  {WRITELN;}
                             end;
                          {end if}
                      {end for}

                      for Index:=1 to PieceSize do
                          if (Squares[Index]<>nil) then
                             if Collide(Squares[Index]^) then Failed:=TRUE;
                          {endif}
                      {end for}

                      if Failed then TPiece.Rotate;
                 end;
              {end if}
         end;

function TPiece.MoveTo(Target:TCoord):BOOLEAN;
          var Movement:TCoord;
          begin
               Movement.x:=Target.x-Centre.x;
               Movement.y:=Target.y-Centre.y;

               MoveTo:=Self.Move(Movement, TRUE);
          end;
{end proc}

constructor TPiece.Any(Offset:TCoord);
            var Temp:INTEGER;
            begin
                 Temp:=Random(7);
                 if KeyPressed then
                    begin
                         if (Readkey='e') then
                            Temp:=CheatActive.r;
                         {end if}
                    end;
                 {end if}
                 case Temp of
                      0: Create(SquarePiece,   Offset);
                      1: Create(LongThinPiece, Offset);
                      2: Create(LPiece,        Offset);
                      3: Create(TeePiece,      Offset);
                      4: Create(EssPiece,      Offset);
                      5: Create(EssPieceI,     Offset);
                      6: Create(LPieceI,       Offset);
                 end;
            end;

constructor TPiece.Create(Piece:PieceType; Offset:TCoord);
            var Pos  : TCoord;
                Dodge: array[1..4, 1..4] of TCoord;
            begin
                 for Pos.x:=1 to 4 do
                     for Pos.y:=1 to 4 do
                         begin
                              Squares[Pos.x]:=nil;
                              Dodge[Pos.x, Pos.y].x:=Pos.x;
                              Dodge[Pos.x, Pos.y].y:=Pos.y;
                         end;
                     {end next}
                 {end next}

                 Centre.x:=Offset.x+2;
                 Centre.y:=Offset.y+2;


                 Rotateable:=TRUE;

                 case Piece of
                      SquarePiece: begin
                                        FillSquare(Black, Red, 1, Dodge[1, 1], Offset);
                                        FillSquare(Black, Red, 1, Dodge[1, 2], Offset);
                                        FillSquare(Black, Red, 1, Dodge[2, 1], Offset);
                                        FillSquare(Black, Red, 1, Dodge[2, 2], Offset);
                                        Rotateable:=FALSE;
                                   end;

                      LongThinPiece: begin
                                          FillSquare(Black, Green, 1, Dodge[2, 1], Offset);
                                          FillSquare(Black, Green, 1, Dodge[2, 2], Offset);
                                          FillSquare(Black, Green, 1, Dodge[2, 3], Offset);
                                          FillSquare(Black, Green, 1, Dodge[2, 4], Offset);
                                     end;
                      LPiece: begin
                                   FillSquare(Black, Blue, 1, Dodge[1,1], Offset);
                                   FillSquare(Black, Blue, 1, Dodge[2,1], Offset);
                                   FillSquare(Black, Blue, 1, Dodge[3,1], Offset);
                                   FillSquare(Black, Blue, 1, Dodge[3,2], Offset);
                              end;
                      TeePiece: begin
                                     FillSquare(Black, Pink, 1, Dodge[1,2], Offset);
                                     FillSquare(Black, Pink, 1, Dodge[2,2], Offset);
                                     FillSquare(Black, Pink, 1, Dodge[3,2], Offset);
                                     FillSquare(Black, Pink, 1, Dodge[2,3], Offset);
                                end;
                     EssPiece: begin
                                     FillSquare(Black, Cyan, 1, Dodge[1,2], Offset);
                                     FillSquare(Black, Cyan, 1, Dodge[2,2], Offset);
                                     FillSquare(Black, Cyan, 1, Dodge[2,3], Offset);
                                     FillSquare(Black, Cyan, 1, Dodge[3,3], Offset);
                                end;
                     EssPieceI: begin
                                      FillSquare(Black, LightBlue, 1, Dodge[3,2], Offset);
                                      FillSquare(Black, LightBlue, 1, Dodge[2,2], Offset);
                                      FillSquare(Black, LightBlue, 1, Dodge[2,3], Offset);
                                      FillSquare(Black, LightBlue, 1, Dodge[1,3], Offset);
                                 end;

                     LPieceI: begin
                                   FillSquare(Black, Yellow, 1, Dodge[1,2], Offset);
                                   FillSquare(Black, Yellow, 1, Dodge[2,2], Offset);
                                   FillSquare(Black, Yellow, 1, Dodge[3,2], Offset);
                                   FillSquare(Black, Yellow, 1, Dodge[3,1], Offset);
                              end;

                 end;
            end;

destructor TPiece.Destroy;
           var Pos:INTEGER;
           begin
                WriteMoo(CHR(7));
                for Pos:=1 to PieceSize do
                    if Squares[Pos]<>nil then
                       Dispose(Squares[Pos], Destroy);
                    {end if}
                {end for}
           end;

destructor TPiece.LeaveSquares;
           begin
           end;
{ *************************************************************************
  **** TGame object ****
  *************************************************************************}

type TGame = object
                   Frame      :INTEGER;
                   Offset     :TCoord;
                   Size       :TCoord;
                   Start      :TCoord;
                   ToStart    :TCoord;
                   Next       :TCoord;

                   Score      :LONGINT;
                   Fast       :BOOLEAN;
                   Speed      :INTEGER;

                   CurrentPiece        :^TPiece;
                   NextPiece           :^TPiece;

                   CeasedToBe :BOOLEAN;
                   ToTake     :INTEGER;

                   Points     :^TScore;

                   procedure Poll;
                   procedure GoLeft;
                   procedure GoRight;
                   procedure Drop;
                   procedure Rot;

                   function TakeLines:INTEGER;
                   procedure PushUp;
                   procedure PushDown;
                   function SpareLines:BOOLEAN;
                   function Alive:BOOLEAN;

                   constructor Create(Where:TCoord);
             end;
var Cheat:BOOLEAN;

procedure TGame.Poll;
          var AreaObject:^TArea;
              Bot, Top:TCoord;
              ToGo:INTEGER;
              Line:TCoord;
              Highest:TCoord;

          begin
               if CeasedToBe then
                  begin
                       {Bugger All}
                  end
               else
                   begin
                        if (Frame=Speed) OR Fast then
                           begin
                                if (CurrentPiece^.Move(Down, TRUE)) then
                                   begin
                                        Fast:=FALSE;
                                        dispose(CurrentPiece, LeaveSquares);                              

                                        Line.x:=Offset.x+1;
                                        Line.y:=Offset.y-1;
                                        Top.x:=Offset.x+1;
                                        Top.y:=Offset.y-Size.y;
                                        Bot.x:=Offset.x+Size.x-1;
                                        Bot.y:=Offset.y-2;

                                        Points^.Increase(10);

                                        while (Line.y>(Offset.y-Size.y)) do
                                              begin
                                                   new(AreaObject, HLine(Line, Size.x-2));
                                                   if AreaObject^.AllFull AND (DestroyMe(Line)) then
                                                      begin
                                                           AreaObject^.Zap;
                                                           {AreaObject^.Fill(Green, Pink, 1);}
                                                           dispose(AreaObject);

                                                           new(AreaObject, Create(Top, Bot));


                                                           {AreaObject^.Fill(Green, Pink, 1);

                                                           {Dummy}
                                                  
                                                           AreaObject^.Move(Down);
                                                  
                                                           dispose(AreaObject);

                                                           Points^.Increase(100);
                                                           ToTake:=ToTake+1;
                                                      end
                                                   else
                                                       begin
                                                            Bot.y:=Bot.y-1;
                                                            Line.y:=Line.y-1;
                                                            dispose(AreaObject);
                                                       end;
                                              end;

                                        
                                        CurrentPiece:=NextPiece;
                                        {WRITELN(Start.x,'  ',Start.y);}

                                        If CurrentPiece^.MoveTo(Start) then
                                           begin
                                                CeasedToBe:=TRUE;
                                                {WRITELN('Dead!');
                                                WriteMoo(Points^.Read);
                                                WriteMoo(HiScore);}
                                                if (Points^.Read>HiScore) then
                                                   begin
                                                        WriteMoo('Written!');
                                                        REWRITE(HiScoreF);
                                                        Score:=Points^.Read;
                                                        WRITE(HiScoreF, Score);
                                                        CLOSE(HiScoreF);
                                                   end;
                                                {end if}
                                           end;
                                        {end if}

                                        If (NOT CeasedToBe) then new(NextPiece,Any(Next));
                                   end
                                else
                                    begin
                                         if Fast then Points^.Increase(3) else Points^.Increase(1);
                                    end;
                                Frame:=0;
                           end
                        else
                            Frame:=Frame+1;
                        {endif}
                   end;
               {endif}
               Cheat:=FALSE;

          end;
{end proc}

procedure TGame.GoLeft;
          var dummy:BOOLEAN;
          begin
               if NOT CeasedToBe then dummy:=CurrentPiece^.Move(Left, TRUE);
          end;
{end proc}

procedure TGame.GoRight;
          var dummy:BOOLEAN;
          begin
               if NOT CeasedToBe then dummy:=CurrentPiece^.Move(Right, TRUE);
          end;
{end proc}

procedure TGame.Drop;
          begin
               if NOT CeasedToBe then Fast:=TRUE;
               { If there weren't any women in the world, mankind would be
                 buggered. }
          end;
{end proc}

procedure TGame.Rot;
          begin
               if NOT CeasedToBe then CurrentPiece^.Rotate;
          end;
{end proc}

function TGame.TakeLines:INTEGER;
         begin
              TakeLines:=ToTake DIV 2;
              ToTake:=0;
         end;
{end function}

procedure TGame.PushUp;
          var AreaObject:^TArea;
              Top, Bot:TCoord;
          begin
               Top.x:=Offset.x+1;
               Top.y:=Offset.y-Size.y-44;
               Bot.x:=Offset.x+Size.x-1;
               Bot.y:=Offset.y-1;

               new(AreaObject, Create(Top, Bot));
               AreaObject^.Move(Up);

               dispose(AreaObject);

               Bot.x:=Offset.x+1;
               new(AreaObject, HLine(Bot, Size.x-2));
               AreaObject^.Fill(LightBlue, Red, -6, Dodgy);
               dispose(AreaObject);

               CurrentPiece^.Move(Down, FALSE);
          end;
{end proc}

procedure TGame.PushDown;
          var AreaObject:^TArea;
              Top, Bot:TCoord;
          begin
               Top.x:=Offset.x+1;
               Top.y:=Offset.y-1;

               new(AreaObject, HLine(Top, Size.x-2));
               AreaObject^.Zap;      
               Dispose(AreaObject);

               Top.x:=Offset.x+1;
               Top.y:=Offset.y-Size.y;
               Bot.x:=Offset.x+Size.x-1;
               Bot.y:=Offset.y-2;

               new(AreaObject, Create(Top, Bot));
               {AreaObject^.Fill(Pink, Green, 1, Ghostly);}
               AreaObject^.Move(Down);
               dispose(AreaObject);

          end;
{end proc}

function TGame.SpareLines:BOOLEAN;
         var Progress:INTEGER;
             Caught:^TSolidSquare;
             One:TCoord;
         begin
              Caught:=nil;
              One.x:=Offset.x+1;
              One.y:=Offset.y-Size.y+1;

              for Progress:=1 to BoxesTotal do
                  if (TSolidSquareList[Progress]<>nil) then
                     if ((TSolidSquareList[Progress]^.Place.x=One.x) AND (TSolidSquareList[Progress]^.Place.y=One.y)) then
                        Caught:=TSolidSquareList[Progress]; WRITE;
              if Caught<>nil then
                 SpareLines:=DestroyMe(One)
              else
                  SpareLines:=FALSE;

              SpareLines:=FALSE;

         end;

function TGame.Alive:BOOLEAN;
         begin
              Alive:=NOT CeasedToBe;
         end;


constructor TGame.Create(Where:TCoord);
            var Fill:TCoord;
                Waste:^TSolidSquare;
                Waste2:^TSquare;
                Place:TCoord;

            begin
                 CeasedToBe:=FALSE;
                 ToTake:=0;
                 Offset.x:=Where.x;
                 Offset.y:=Where.y;

                 Size.x:=10;
                 Size.y:=16;

                 Start.x:=Where.x+4;
                 Start.y:=Where.y-Size.y;


                 Next.x:=Where.x+Size.x;
                 Next.y:=Where.y-Size.y;
                 
                 Frame:=0;
                 Score:=0;

                 Speed:=10000;

                 Fast:=FALSE;

                 Place.x:=Where.x+1;
                 Place.y:=Where.y-Size.y-5;

                 new(Points,Reset(Place));
                 {plotstring(Place, 'fsfd');}

                 new(CurrentPiece,Any(Start));


                 for Fill.x:=Where.x to Where.x+Size.x do
                     for Fill.y:=Where.y-Size.y-3 to Where.y do
                         begin
                              if ((Where.y-10)>(Fill.y)) AND (CheatActive.g=1) then
                                 begin
                                      if (Fill.x=Where.x)        then New(Waste2, Create(Black , Grey , 1, Fill));
                                      if (Fill.x=Where.x+Size.x) then New(Waste2, Create(Black , Grey , 1, Fill));
                                 end
                              else
                                  begin
                                       if (Fill.x=Where.x)        then New(Waste, Create(Black , Grey , 1, Fill));
                                       if (Fill.x=Where.x+Size.x) then New(Waste, Create(Black , Grey , 1, Fill));
                                       if (Fill.y=Where.y)        then New(Waste, Create(Black , Grey , 1, Fill));
                                  end;
                              {end if}
                         end;
                     {end for}
                 {end for}

                 new(NextPiece,Any(Next));
            end;    




{ *************************************************************************
  **** Main Program ****
  *************************************************************************}   
var Games      :array [1..3] of ^TGame;
                                                                  
    counter    : INTEGER;
    LinesToGo  : INTEGER;
    PlayersToGo: INTEGER;

    Inkey      : CHAR;
    Quit       : BOOLEAN;

const Player1  :TCoord=(x:00; y:20);
      Player2  :TCoord=(x:15; y:20);
      Player3  :TCoord=(x:30; y:20);

      Players                 = 3;
      Interactive             = TRUE;

begin
     RANDOMIZE;
     {WriteMoo('Playing version ', Version, ' with ', Players, ' players.');}
     WriteMoo('Written by DFL');

     ASSIGN(HiScoreF, 'TetHi.dat');
     RESET(HiScoreF);
     if (EOF(HiScoreF)) then
        begin
             HiScore:=0;
             CLOSE(HiScoreF);
             REWRITE(HiScoreF);
             {WRITELN('File is blank');}
        end
     else
         READ(HiScoreF, HiScore);
     {end if}

     CLOSE(HiScoreF);

     {WriteMoo('High score is ', HiScore);}

     for counter:=1 to BoxesTotal do
         begin
              TSolidSquareList[counter]:=nil;
         end;
     {end for}

     for counter:=1 to 3 do Games[counter]:=nil;

     New (Games[1],Create(Player1));
     if (Players>1) then New (Games[2],Create(Player3));
     if (Players>2) then New (Games[3],Create(Player2));

     {Dummy}

     repeat
           if KeyPressed then
              inkey:=ReadKey
           else
               inkey:=chr(0);

           for Counter:=1 to 3 do
               if (Games[Counter]<>nil) then
                  Games[Counter]^.Poll;
               {end if}
           {end for}

           {Dummy}

           if (Games[1]<>nil) then
              case inkey of
                   'z': Games[1]^.GoLeft;
                   'x': begin Cheat:=FALSE; Games[1]^.GoRight; end;
                   ' ': Games[1]^.Drop;
                   'c': Games[1]^.Rot;
                   'v': begin Cheat:=TRUE;  Games[1]^.GoRight; end;
                   'q': if (Games[2]<>nil) then Games[2]^.Drop;
                   'w': if (Games[3]<>nil) then Games[3]^.Drop;
              end;

              {'p': if TwoPlayer then Game2^.PushDown;

              {Dummy Craig Story}
           if (Games[3]<>nil) then

              case inkey of
                   'j': Games[3]^.GoLeft;
                   'l': Games[3]^.GoRight;
                   'b': Games[3]^.Drop;
                   'k': Games[3]^.Rot;
              end;

           if (Games[2]<>nil) then
              case inkey of  
                   '4': Games[2]^.GoLeft;
                   '6': Games[2]^.GoRight;
                   '2': Games[2]^.Drop;
                   '8': Games[2]^.Rot;
              end;              

           if Interactive then
              begin
                   for Counter:=1 to Players do
                       begin
                            LinesToGo:=Games[Counter]^.TakeLines;

                            while (LinesToGo>0) do
                                  begin
                                       for PlayersToGo:=1 to Players do
                                           if ((Counter<>PlayersToGo) AND Games[PlayersToGo]^.Alive) then
                                              Games[PlayersToGo]^.PushUp;
                                           {endif}
                                       {end for}
                                       LinesToGo:=LinesToGo-1;
                                  end;
                            {end while}
                       end;
                   {end for}
              end;
           {end if}

           Quit:=TRUE;

           for Counter:=1 to Players do
               begin
                    if (Games[Counter]<>nil) then
                       if Games[Counter]^.Alive then
                          Quit:=FALSE;
                       {end if}
                    {end if}
               end;
           {end for}
           
     until Quit;
end.
