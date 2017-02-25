unit uMathUtils;

interface

function Min(A, B: Double): Double; overload; inline;
function Min(A, B: Single): Single; overload; inline;
function Min(A, B: Integer): Integer; overload; inline;
function Min(A, B: Cardinal): Cardinal; overload; inline;

function Max(A, B: Double): Double; overload; inline;
function Max(A, B: Single): Single; overload; inline;
function Max(A, B: Integer): Integer; overload; inline;
function Max(A, B: Cardinal): Cardinal; overload; inline;

procedure Swap(var A, B: Double); overload;
procedure Swap(var A, B: Single); overload;
procedure Swap(var A, B: Integer); overload;
procedure Swap(var A, B: Cardinal); overload;

function Clamp(AValue, AMin, AMax: Double): Double; overload;
function Clamp(AValue, AMin, AMax: Single): Single; overload;
function Clamp(AValue, AMin, AMax: Integer): Integer; overload;
function Clamp(AValue, AMin, AMax: Cardinal): Cardinal; overload;

function RandomF(): Single;

implementation

{$DEFINE Min}
function Min(A, B: Double): Double; {$I uMathUtils.inc}
function Min(A, B: Single): Single; {$I uMathUtils.inc}
function Min(A, B: Integer): Integer; {$I uMathUtils.inc}
function Min(A, B: Cardinal): Cardinal; {$I uMathUtils.inc}
{$UNDEF Min}

{$DEFINE Max}
function Max(A, B: Double): Double; {$I uMathUtils.inc}
function Max(A, B: Single): Single; {$I uMathUtils.inc}
function Max(A, B: Integer): Integer; {$I uMathUtils.inc}
function Max(A, B: Cardinal): Cardinal; {$I uMathUtils.inc}
{$UNDEF Max}

{$DEFINE Swap}
procedure Swap(var A, B: Double);
var
  Tmp: Double;
{$I uMathUtils.inc}

procedure Swap(var A, B: Single);
var
  Tmp: Single;
{$I uMathUtils.inc}

procedure Swap(var A, B: Integer);
var
  Tmp: Integer;
{$I uMathUtils.inc}

procedure Swap(var A, B: Cardinal);
var
  Tmp: Cardinal;
{$I uMathUtils.inc}
{$UNDEF Swap}

{$DEFINE Clamp}
function Clamp(AValue, AMin, AMax: Double): Double; {$I uMathUtils.inc}
function Clamp(AValue, AMin, AMax: Single): Single; {$I uMathUtils.inc}
function Clamp(AValue, AMin, AMax: Integer): Integer; {$I uMathUtils.inc}
function Clamp(AValue, AMin, AMax: Cardinal): Cardinal; {$I uMathUtils.inc}
{$UNDEF Clamp}

function RandomF(): Single;
begin
  Result := Random(MaxInt) / MaxInt;
end;

end.
