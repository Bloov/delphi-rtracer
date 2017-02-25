{$IFDEF Min}
begin
  if A < B then
    Result := A
  else
    Result := B;
end;
{$ENDIF}

{$IFDEF Max}
begin
  if A > B then
    Result := A
  else
    Result := B;
end;
{$ENDIF}

{$IFDEF Swap}
begin
  Tmp := A;
  A := B;
  B := Tmp;
end;
{$ENDIF}

{$IFDEF Clamp}
begin
  if AMin > AMax then
    Swap(AMin, AMax);

  Result := Min(Max(AValue, AMin), AMax);
end;
{$ENDIF}

{$IFDEF Sign}
begin
  if AValue < 0 then
    Result := -1
  else
    Result := 1;
end;
{$ENDIF}

{$IFDEF NearZero}
begin
  Result := (Abs(AValue) < Eps);
end;
{$ENDIF}

{$IFDEF NearValue}
begin
  Result := (Abs(AValue - ATarget) < Eps);
end;
{$ENDIF}
