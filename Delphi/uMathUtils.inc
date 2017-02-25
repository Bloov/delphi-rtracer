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
