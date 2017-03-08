unit uMathUtils;

interface

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

function RandomF(): Single; //inline;

implementation

uses
  Math;

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
const
  cTwoIn23 = 16777216; // To fall in to a single precision range
begin
  Result := Random(cTwoIn23) / cTwoIn23;
end;

end.
