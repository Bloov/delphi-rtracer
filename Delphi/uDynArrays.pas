unit uDynArrays;

interface

type
  TDynIntArray = array of Integer;
  TDynSingleArray = array of Single;
  TDynDoubleArray = array of Double;

{ TDynIntArray }
function AsDynArray(const AValues: array of Integer): TDynIntArray; overload;
function IsIn(AValue: Integer; const AValues: array of Integer): Boolean; overload;
function GetIndex(AValue: Integer; const AValues: array of Integer): Integer; overload;
function FindMinMaxValue(const AnArray: array of Integer; out AMin, AMax: Integer): Boolean; overload;
function FindMinValue(const AnArray: array of Integer; out AMin: Integer): Boolean; overload;
function FindMaxValue(const AnArray: array of Integer; out AMax: Integer): Boolean; overload;

{ TDynSingleArray }
function AsDynArray(const AValues: array of Single): TDynSingleArray; overload;
function IsIn(AValue: Single; const AValues: array of Single): Boolean; overload;
function GetIndex(AValue: Single; const AValues: array of Single): Integer; overload;
function FindMinMaxValue(const AnArray: array of Single; out AMin, AMax: Single): Boolean; overload;
function FindMinValue(const AnArray: array of Single; out AMin: Single): Boolean; overload;
function FindMaxValue(const AnArray: array of Single; out AMax: Single): Boolean; overload;

{ TDynDoubleArray }
function AsDynArray(const AValues: array of Double): TDynDoubleArray; overload;
function IsIn(AValue: Double; const AValues: array of Double): Boolean; overload;
function GetIndex(AValue: Double; const AValues: array of Double): Double; overload;
function FindMinMaxValue(const AnArray: array of Double; out AMin, AMax: Double): Boolean; overload;
function FindMinValue(const AnArray: array of Double; out AMin: Double): Boolean; overload;
function FindMaxValue(const AnArray: array of Double; out AMax: Double): Boolean; overload;

implementation

function AsDynArray(const AValues: array of Integer): TDynIntArray;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    system.Move(AValues[Low(AValues)], Result[0], Length(AValues) * SizeOf(Integer));
end;

function AsDynArray(const AValues: array of Single): TDynSingleArray;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    system.Move(AValues[Low(AValues)], Result[0], Length(AValues) * SizeOf(Single));
end;

function AsDynArray(const AValues: array of Double): TDynDoubleArray;
begin
  SetLength(Result, Length(AValues));
  if Length(AValues) > 0 then
    system.Move(AValues[Low(AValues)], Result[0], Length(AValues) * SizeOf(Double));
end;

{$DEFINE IsIn}
function IsIn(AValue: Integer; const AValues: array of Integer): Boolean; {$I uDynArrays.inc}
function IsIn(AValue: Single; const AValues: array of Single): Boolean; {$I uDynArrays.inc}
function IsIn(AValue: Double; const AValues: array of Double): Boolean; {$I uDynArrays.inc}
{$UNDEF IsIn}

{$DEFINE GetIndex}
function GetIndex(AValue: Integer; const AValues: array of Integer): Integer; {$I uDynArrays.inc}
function GetIndex(AValue: Single; const AValues: array of Single): Integer; {$I uDynArrays.inc}
function GetIndex(AValue: Double; const AValues: array of Double): Double; {$I uDynArrays.inc}
{$UNDEF GetIndex}

{$DEFINE FindMinMaxValue}
function FindMinMaxValue(const AnArray: array of Integer; out AMin, AMax: Integer): Boolean; {$I uDynArrays.inc}
function FindMinMaxValue(const AnArray: array of Single; out AMin, AMax: Single): Boolean; {$I uDynArrays.inc}
function FindMinMaxValue(const AnArray: array of Double; out AMin, AMax: Double): Boolean; {$I uDynArrays.inc}
{$UNDEF FindMinMaxValue}

{$DEFINE FindMinValue}
function FindMinValue(const AnArray: array of Integer; out AMin: Integer): Boolean; {$I uDynArrays.inc}
function FindMinValue(const AnArray: array of Single; out AMin: Single): Boolean; {$I uDynArrays.inc}
function FindMinValue(const AnArray: array of Double; out AMin: Double): Boolean; {$I uDynArrays.inc}
{$UNDEF FindMinValue}

{$DEFINE FindMaxValue}
function FindMaxValue(const AnArray: array of Integer; out AMax: Integer): Boolean; {$I uDynArrays.inc}
function FindMaxValue(const AnArray: array of Single; out AMax: Single): Boolean; {$I uDynArrays.inc}
function FindMaxValue(const AnArray: array of Double; out AMax: Double): Boolean; {$I uDynArrays.inc}
{$UNDEF FindMaxValue}

end.
