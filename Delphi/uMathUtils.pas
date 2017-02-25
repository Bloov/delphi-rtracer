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

procedure Swap(var A, B: Double); overload; inline;
procedure Swap(var A, B: Single); overload; inline;
procedure Swap(var A, B: Integer); overload; inline;
procedure Swap(var A, B: Cardinal); overload; inline;

function Clamp(AValue, AMin, AMax: Double): Double; overload;
function Clamp(AValue, AMin, AMax: Single): Single; overload;
function Clamp(AValue, AMin, AMax: Integer): Integer; overload;
function Clamp(AValue, AMin, AMax: Cardinal): Cardinal; overload;

function Sign(AValue: Integer): Integer; overload; inline;
function Sign(AValue: Single): Integer; overload; inline;
function Sign(AValue: Double): Integer; overload; inline;

function NearZero(AValue: Integer; Eps: Integer): Boolean; overload; inline;
function NearZero(AValue: Single; Eps: Single): Boolean; overload; inline;
function NearZero(AValue: Double; Eps: Double): Boolean; overload; inline;

function NearValue(AValue, ATarget: Integer; Eps: Integer): Boolean; overload; inline;
function NearValue(AValue, ATarget: Single; Eps: Single): Boolean; overload; inline;
function NearValue(AValue, ATarget: Double; Eps: Double): Boolean; overload; inline;

function RandomF(): Single; inline;

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

{$DEFINE Sign}
function Sign(AValue: Integer): Integer; {$I uMathUtils.inc}
function Sign(AValue: Single): Integer; {$I uMathUtils.inc}
function Sign(AValue: Double): Integer; {$I uMathUtils.inc}
{$UNDEF Sign}

{$DEFINE NearZero}
function NearZero(AValue: Integer; Eps: Integer): Boolean; {$I uMathUtils.inc}
function NearZero(AValue: Single; Eps: Single): Boolean; {$I uMathUtils.inc}
function NearZero(AValue: Double; Eps: Double): Boolean; {$I uMathUtils.inc}
{$UNDEF NearZero}

{$DEFINE NearValue}
function NearValue(AValue, ATarget: Integer; Eps: Integer): Boolean; {$I uMathUtils.inc}
function NearValue(AValue, ATarget: Single; Eps: Single): Boolean; {$I uMathUtils.inc}
function NearValue(AValue, ATarget: Double; Eps: Double): Boolean; {$I uMathUtils.inc}
{$UNDEF NearValue}

function RandomF(): Single;
begin
  Result := Random(MaxInt) / MaxInt;
end;

end.
