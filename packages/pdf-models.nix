{
  lib,
  fetchurl,
  runCommand,
  src,
}: let
  manifest = builtins.fromTOML (builtins.readFile "${src}/ATTRIBUTION.toml");
  models = builtins.filter (asset: (asset.kind or "") == "model") manifest.fetched;
  stage = model: let
    data = fetchurl {
      name = model.file;
      url = model.url;
      sha256 = model.sha256;
    };
    notice = fetchurl {
      name = "${model.file}.LICENCE.txt";
      url = model.licence_url;
      sha256 = model.licence_sha256;
    };
  in
    assert model.licence == "CC-BY-SA-4.0";
    assert builtins.elem model.file ["text-detection.onnx" "text-recognition.onnx"]; ''
      install -Dm444 ${data} "$out/${model.file}"
      install -Dm444 ${notice} "$out/${model.file}.LICENCE.txt"
    '';
in
  assert builtins.sort builtins.lessThan (map (model: model.file) models) == ["text-detection.onnx" "text-recognition.onnx"];
    runCommand "pdfcraft-ocr-models" {
      meta.license = lib.licenses.cc-by-sa-40;
    } ''
      mkdir -p "$out"
      ${lib.concatMapStrings stage models}
      cp ${src}/ATTRIBUTION.toml "$out/ATTRIBUTION.toml"
    ''
