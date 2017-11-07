PROGRAM Snake2;
{                                 
An improved version of the game snake
}

USES    GraphWin;

TYPE   Vector          =RECORD
                               x        :INTEGER;
                               y        :INTEGER;
                        END;
TYPE   Colour          =RECORD
                              r, g, b   :BYTE;
                        END;            

CONST   PerimeterX      =120;
        PerimeterY      =120;                         
        Scale           =3;
        Offset          :Vector=(x:50; y:50);

        Up              :Vector=(x: 0; y:-1);
        Down            :Vector=(x: 0; y: 1);
        Left            :Vector=(x:-1; y: 0);
        Right           :Vector=(x: 1; y: 0);



TYPE   Snake           =RECORD
                               Head     :Vector;
                               Direction:Vector;
                               NewD     :Vector;
                               Col      :Colour;
                        END;




VAR     World           :ARRAY[0..PerimeterX, 0..PerimeterY] OF BOOLEAN;
        Player1         :Snake;
        Player2         :Snake;
        Player3         :Snake;
        Inkey           :CHAR;
        Exit            :BOOLEAN;
        DelayLoop       :INTEGER;

PROCEDURE PlotSquare(Position:VECTOR);
          BEGIN
               SetBrushStyle(1);
               DrawOblong(Offset.x+(Position.x*Scale)      , Offset.y+(Position.y*Scale),
                          Offset.x+Scale+(Position.x*Scale), Offset.y+Scale+(Position.y*Scale));
          END;
{ENDPROC}

PROCEDURE EraseSquare(Position:VECTOR);
          BEGIN
               EraseOblong(Offset.x+(Position.x*Scale)      , Offset.y+(Position.y*Scale),
                          Offset.x+Scale+(Position.x*Scale), Offset.y+Scale+(Position.y*Scale));
          END;
{ENDPROC}

PROCEDURE ClearWorld;
          VAR Position:Vector;
          BEGIN
               FOR Position.x:=0 TO PerimeterX DO
                   FOR Position.y:=0 TO PerimeterY DO
                       BEGIN

                            World[Position.x, Position.y]:=FALSE;
                            IF ((Position.x=0) OR (Position.y=0) OR (Position.x=PerimeterX)
                              OR (Position.y>(PerimeterY-1))) THEN
                              BEGIN
                                   World[Position.x, Position.y]:=TRUE;
                                   SetPenColour(0,0,0);
                                   SetBrushColour(0,0,0);
                                   PlotSquare(Position);

                              END;
                            {ENDIF}
                       END;
                   {ENDFOR}
               {ENDFOR}
          END;


PROCEDURE Wait (Time:INTEGER);
          BEGIN
	       Sleep(Time / 10000.0);
          END;
{ENDPROC}


BEGIN
     InitGraphWin;
     ReDisplay;
     RANDOMIZE;
     WriteMoo('                  TRON');
     ClearWorld;
     Exit:=FALSE;
     WHILE NOT Exit DO
           BEGIN
                ClearWorld;
                WITH Player1 DO
                     BEGIN
                          Head.x:=4;
                          Head.y:=PerimeterY DIV 2;
                          Direction.x:=1;
                          Direction.y:=0;
                          Col.r:=255;
                          Col.g:=0;
                          Col.b:=0;
                     END;
                {ENDWITH}

                 WITH Player2 DO
                     BEGIN
                          Head.x:=PerimeterX-4;
                          Head.y:=PerimeterY DIV 2;
                          Direction.x:=-1;
                          Direction.y:=0;
                          Col.r:=0;
                          Col.g:=255;
                          Col.b:=0;
                     END;
                {ENDWITH}

                 WITH Player3 DO
                     BEGIN
                          Head.x:=PerimeterX DIV 2;
                          Head.y:=4;
                          Direction.x:=0;
                          Direction.y:=1;
                          Col.r:=0;
                          Col.g:=0;
                          Col.b:=255;
                     END;
                {ENDWITH}

                REPEAT
                      
                      WITH Player1 DO
                           BEGIN
                                World[Head.x, Head.y]:=TRUE;
                                SetPenColour(Col.r, Col.g, Col.b);
                                SetBrushColour(Col.r, Col.g, Col.b);
                                PlotSquare(Head);
                           END;
                      {ENDWITH}
                      {
                      WITH Player2 DO
                           BEGIN
                                World[Head.x, Head.y]:=TRUE;
                                SetPenColour(Col.r, Col.g, Col.b);
                                SetBrushColour(Col.r, Col.g, Col.b);
                                PlotSquare(Head);
                           END;
                      {ENDWITH}

                       WITH Player3 DO
                           BEGIN
                                World[Head.x, Head.y]:=TRUE;
                                SetPenColour(Col.r, Col.g, Col.b);
                                SetBrushColour(Col.r, Col.g, Col.b);
                                PlotSquare(Head);
                           END;
                      {ENDWITH}

                      Player1.NewD:=Player1.Direction;
                      {Player2.NewD:=Player2.Direction; }
                      Player3.NewD:=Player3.Direction;
                      WHILE KeyPressed DO
                               BEGIN
                                    Inkey:=READKEY;
                                    {WRITE(Inkey);}
                                    WITH Player1 DO
                                         BEGIN
                                              CASE Inkey OF
                                                   'q', 'Q': IF (Direction.y=0) THEN NewD:=Up;
                                                   'a', 'A': IF (Direction.y=0) THEN NewD:=Down;
                                                   'z', 'Z': IF (Direction.x=0) THEN NewD:=Left;
                                                   'x', 'X': IF (Direction.x=0) THEN NewD:=Right;
                                              END;
                                          END;
                                    {ENDWITH}
                                    WITH Player2 DO
                                         BEGIN
                                              CASE Inkey OF
                                                   'p', 'P': IF (Direction.y=0) THEN NewD:=Up;
                                                   ';', ':': IF (Direction.y=0) THEN NewD:=Down;
                                                   '.', '>': IF (Direction.x=0) THEN NewD:=Left;
                                                   '/', '?': IF (Direction.x=0) THEN NewD:=Right;
                                              END;
                                          END;
                                    {ENDWITH}
                                    WITH Player3 DO
                                         BEGIN
                                              CASE Inkey OF
                                                   '8': IF (Direction.y=0) THEN NewD:=Up;
                                                   '2': IF (Direction.y=0) THEN NewD:=Down;
                                                   '4': IF (Direction.x=0) THEN NewD:=Left;
                                                   '6': IF (Direction.x=0) THEN NewD:=Right;
                                              END;
                                          END;
                                    {ENDWITH}

                               END;
                      {ENDWHILE}
                      WITH Player1 DO
                           BEGIN
                                Direction:=NewD;
                                Head.x:=Head.x+Direction.x;
                                Head.y:=Head.y+Direction.y;
                           END;
                      {ENDWITH}
                      {WITH Player2 DO
                           BEGIN
                                Direction:=NewD;
                                Head.x:=Head.x+Direction.x;
                                Head.y:=Head.y+Direction.y;
                           END;
                      {ENDWITH}
                      WITH Player3 DO
                           BEGIN
                                Direction:=NewD;
                                Head.x:=Head.x+Direction.x;
                                Head.y:=Head.y+Direction.y;
                           END;
                      {ENDWITH}

                      WAIT(1000);
                UNTIL   (World[Player1.Head.x, Player1.Head.y]
                      {OR World[Player2.Head.x, Player2.Head.y]  }
                      OR World[Player3.Head.x, Player3.Head.y]);

                IF (World[Player1.Head.x, Player1.Head.y]) THEN WriteMoo('Player one snuffs it.');
                IF (World[Player2.Head.x, Player2.Head.y]) THEN WriteMoo('Although player two *was not* smashed by a shambler the result was the same.');
                IF (World[Player3.Head.x, Player3.Head.y]) THEN WriteMoo('Player three isn`t as good as often believed.');
                Exit:=TRUE;
           END;
     {ENDWHILE}



END.
