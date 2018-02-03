unit uBenchmarks;

interface

procedure BenchmarkAABB(var TotalHits, TotalAsm, TotalNative: Single);
procedure BenchmarkCamera(var TotalRays, TotalTime: Single);
procedure BenchmarkHit(var TotalHits, TotalTime: Single);
procedure BenchmarkRotate(var TotalRotates, TotalAsm, TotalNative: Single; var Success: Boolean);

implementation

uses
  Windows, Math, SysUtils,
  uAABB, uVectors, uMathUtils, uSamplingUtils, uColor,
  uCamera, uRay, uHitable, uMaterial, uRenderer, uImage2D;

procedure BenchmarkAABB(var TotalHits, TotalAsm, TotalNative: Single);
const
  cTestRays = 16 * 1024;
  cTestAABB = 4 * 1024;
var
  I, J: Integer;
  Camera: TPerspectiveCamera;
  TestRays: array of TRay;
  TestAABB: array of TAABB;
  MinP, MaxP, Diff: TVec3F;
  MinD, MaxD: Single;
  StartTime, EndTime, Freq: Int64;
begin
  Camera := TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 45, 0.05, 10);
  try
    Camera.SetupView(1024, 1024);
    RandSeed := 123456;

    TotalHits := cTestRays * (1.0 * cTestAABB);
    SetLength(TestRays, cTestRays);
    for I := 0 to cTestRays - 1 do
      TestRays[I] := Camera.GetRay(RandomF, RandomF);

    SetLength(TestAABB, cTestAABB);
    for I := 0 to cTestAABB - 1 do
    begin
      MinP := Vec3F(0.1, 0.1, 0.1) + 0.8 * Vec3F(RandomF, RandomF, RandomF);
      Diff := Vec3F(1.0, 1.0, 1.0) - MinP;
      MaxP := MinP + Diff.CMul(Vec3F(0.1 + 0.9 * RandomF, 0.1 + 0.9 * RandomF, 0.1 + 0.9 * RandomF));
      TestAABB[I] := TAABB.Create(MinP, MaxP);
    end;

    QueryPerformanceCounter(StartTime);
      for I := 0 to cTestAABB - 1 do
        for J := 0 to cTestRays - 1 do
        begin
          MinD := 0;
          MaxD := MaxSingle;
          TestAABB[I].Hit{Native}(TestRays[J], MinD, MaxD);
        end;
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);
    TotalAsm := (EndTime - StartTime) / Freq;

    QueryPerformanceCounter(StartTime);
      for I := 0 to cTestAABB - 1 do
        for J := 0 to cTestRays - 1 do
        begin
          MinD := 0;
          MaxD := MaxSingle;
          TestAABB[I].HitNative(TestRays[J], MinD, MaxD);
        end;
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);
    TotalNative := (EndTime - StartTime) / Freq;
  finally
    FreeAndNil(Camera);
  end;
end;

procedure BenchmarkCamera(var TotalRays, TotalTime: Single);
const
  cViewSize = 1024;
  cInvSize: Single = 1 / cViewSize;
  cSPP = 10;
var
  Camera: TPerspectiveCamera;
  StartTime, EndTime, Freq: Int64;
  X, Y, S: Integer;
  U, V: Single;
  Ray: TRay;
begin
  Camera := TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 45, 0.05, 10);
  try
    Camera.SetupView(cViewSize, cViewSize);
    QueryPerformanceCounter(StartTime);
      for Y := 0 to cViewSize - 1 do
        for X := 0 to cViewSize - 1 do
        begin
          U := X * cInvSize;
          V := Y * cInvSize;
          for S := 1 to cSPP do
            Ray := Camera.GetRay(U, V);
        end;
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);

    TotalTime := (EndTime - StartTime) / Freq;
    TotalRays := 1024 * 1024 * cSPP;
  finally
    FreeAndNil(Camera);
  end;
end;

procedure BenchmarkHit(var TotalHits, TotalTime: Single);
const
  cTestRays = 8 * 1024;
  cTestSpheres = 8 * 1024;
var
  I, J: Integer;
  TestSpheres: array of THitable;
  TestRays: array of TRay;
  Origin: TVec3F;
  Hit: TRayHit;
  MinD, MaxD: Single;
  StartTime, EndTime, Freq: Int64;
begin
  RandSeed := 123456;

  SetLength(TestSpheres, cTestSpheres);
  for I := 0 to cTestSpheres - 1 do
  begin
    Origin := RandomInUnitSphere * 3;
    if RandomF > 0.8 then
      TestSpheres[I] := TMovingSphere.Create(Origin, Origin - Vec3F(1, 1, 1), 1, 0, 1, TMetal.Create(ColorVec(100, 100, 100)))
    else
      TestSpheres[I] := TSphere.Create(Origin, 1, TMetal.Create(ColorVec(100, 100, 100)));
  end;

  SetLength(TestRays, cTestRays);
  for I := 0 to cTestRays - 1 do
  begin
    Origin := RandomOnUnitSphere * 10;
    TestRays[I] := TRay.Create(Origin, Vec3F(0, 0, 0) - Origin, RandomF);
  end;

  QueryPerformanceCounter(StartTime);
    for I := 0 to cTestRays - 1 do
      for J := 0 to cTestSpheres - 1 do
      begin
        MinD := 0;
        MaxD := MaxSingle;
        TestSpheres[J].Hit{Native}(TestRays[I], MinD, MaxD, Hit);
      end;
  QueryPerformanceCounter(EndTime);
  QueryPerformanceFrequency(Freq);

  TotalTime := (EndTime - StartTime) / Freq;
  TotalHits := cTestRays * cTestSpheres;
end;

procedure BenchmarkRotate(var TotalRotates, TotalAsm, TotalNative: Single; var Success: Boolean);
const
  cTestVecs = 8 * 1024;
var
  I, J: Integer;
  Rot, RotN, Diff: TVec3F;

  TestVecs: array of TVec3F;
  StartTime, EndTime, Freq: Int64;
begin
  RandSeed := 123456;
  SetLength(TestVecs, cTestVecs);
  for I := 0 to cTestVecs - 1 do
    TestVecs[I] := RandomOnUnitHemisphere;
  TotalRotates := cTestVecs * (cTestVecs - 1) / 2;

  QueryPerformanceCounter(StartTime);
    for I := 0 to cTestVecs - 2 do
      for J := I + 1 to cTestVecs - 1 do
        TestVecs[I].Rotate(TestVecs[J]);
  QueryPerformanceCounter(EndTime);
  QueryPerformanceFrequency(Freq);
  TotalAsm := (EndTime - StartTime) / Freq;

  QueryPerformanceCounter(StartTime);
    for I := 0 to cTestVecs - 2 do
      for J := I + 1 to cTestVecs - 1 do
        TestVecs[I].RotateNative(TestVecs[J]);
  QueryPerformanceCounter(EndTime);
  QueryPerformanceFrequency(Freq);
  TotalNative := (EndTime - StartTime) / Freq;

  Success := True;
  for I := 0 to cTestVecs - 2 do
  begin
    if not Success then
      Break;

    for J := I + 1 to cTestVecs - 1 do
    begin
      RotN := TestVecs[I].RotateNative(TestVecs[J]);
      Rot := TestVecs[I].Rotate(TestVecs[J]);
      Diff := Rot - RotN;
      if Diff.Length > 1e-5 then
      begin
        Success := False;
        Break;
      end;
    end;
  end;
end;

end.
