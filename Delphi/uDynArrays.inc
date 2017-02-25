{$IFDEF IsIn}
var
  I: Integer;
begin
  Result := False;
  for I := Low(AValues) to High(AValues) do
    if AValue = AValues[I] then
      Exit(True);
end;
{$ENDIF}

{$IFDEF GetIndex}
var
  I: Integer;
begin
  Result := -1;
  for I := Low(AValues) to High(AValues) do
    if AValue = AValues[I] then
      Exit(I);
end;
{$ENDIF}

{$IFDEF FindMinMaxValue}
var
  I: Integer;
begin
  AMax := 0;
  AMin := 0;
  Result := Length(AnArray) > 0;
  if not Result then
    Exit;

  AMax := AnArray[Low(AnArray)];
  AMin := AMax;
  for I := Low(AnArray) to High(AnArray) do
    if AMax < AnArray[I] then
      AMax := AnArray[I]
    else if AMin > AnArray[I] then
      AMin := AnArray[I];
end;
{$ENDIF}

{$IFDEF FindMinValue}
var
  I: Integer;
begin
  AMin := 0;
  Result := Length(AnArray) > 0;
  if not Result then
    Exit;

  AMin := AnArray[Low(AnArray)];
  for I := Low(AnArray) to High(AnArray) do
    if AMin > AnArray[I] then
      AMin := AnArray[I];
end;
{$ENDIF}

{$IFDEF FindMaxValue}
var
  I: Integer;
begin
  AMax := 0;
  Result := Length(AnArray) > 0;
  if not Result then
    Exit;

  AMax := AnArray[Low(AnArray)];
  for I := Low(AnArray) to High(AnArray) do
    if AMax < AnArray[I] then
      AMax := AnArray[I];
end;
{$ENDIF}
