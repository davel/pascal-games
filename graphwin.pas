unit GraphWin;

interface

procedure SetBrushStyle(style:integer);
procedure DrawOblong(x1,y1,x2,y2:integer);
procedure EraseOblong(x1,y1,x2,y2:integer);
procedure SetPenColour(r,g,b:byte);
procedure SetBrushColour(r,g,b:byte);
procedure ReDisplay;
procedure WriteMoo(msg:string);
procedure Sleep(time:real);
procedure InitGraphWin;

function KeyPressed: boolean;
function ReadKey: Char;

implementation

var	BrushStyle:integer;
	BrushR, BrushG, BrushB: byte;
	PenR, PenG, PenB: byte;

procedure InitGraphWin;
begin
	WriteLn('{"action":"init"}');
end;

procedure SetBrushStyle(style:integer);
begin
	BrushStyle := style;
end;

procedure DrawOblong(x1,y1,x2,y2:integer);
begin
	WriteLn('{"action":"drawoblong",',
		'"x1":',x1,',',
		'"y1":',y1,',',
		'"x2":',x2,',',
		'"y2":',y2,',',
		'"style":',BrushStyle,',',
		'"penr":',PenR,',',
		'"peng":',PenG,',',
		'"penb":',PenB,',',
		'"brushr":',BrushR,',',
		'"brushg":',BrushG,',',
		'"brushb":',BrushB,'}'
	);
end;

procedure EraseOblong(x1,y1,x2,y2:integer);
begin
	WriteLn('{"action":"eraseoblong",',
		'"x1":',x1,',',
		'"y1":',y1,',',
		'"x2":',x2,',',
		'"y2":',y2,',',
		'"style":',BrushStyle,',',
		'"penr":',PenR,',',
		'"peng":',PenG,',',
		'"penb":',PenB,',',
		'"brushr":',BrushR,',',
		'"brushg":',BrushG,',',
		'"brushb":',BrushB,'}'
	);

end;

procedure SetPenColour(r,g,b:byte);
begin
	PenR := r;
	PenG := g;
	PenB := b;
end;

procedure SetBrushColour(r,g,b:byte);
begin
	BrushR := r;
	BrushG := g;
	BrushB := b;
end;

procedure ReDisplay;
begin
end;

function KeyPressed: boolean;
begin
	KeyPressed := false;
end;
	
function ReadKey: Char;
begin
	ReadKey := 'x';
end;

procedure WriteMoo(msg:string);
begin
end;

procedure Sleep(time:real);
begin
end;

begin
	BrushStyle := 0;
	PenR := 0;
	PenG := 0;
	PenB := 0;

	BrushR := 0;
	BrushG := 0;
	BrushB := 0;
end.
