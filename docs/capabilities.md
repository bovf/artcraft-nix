# Pinned Craft control capabilities

**Historical evidence only:** the revisions and output paths below and in `capabilities.json` predate the [2026-10-11 release update](releases-2026-10-11.md). The new release pins have not been built or tested; these MCP/editorial results do not certify their compatibility.

This matrix binds the selected producer app revisions and immutable GUI/CLI/store paths in [capabilities.json](capabilities.json). It is not a claim about mutable upstream HEAD. All thirteen installed Heavy executables matched these outputs; the starting consumer source/lock lacked the assumed ArtCraft input/selections, so that baseline discrepancy is explicit, not invented.

Twelve **native x86_64 Linux** stdio servers passed initialize/list and a meaningful synthetic operation, including a final one-launcher run with read-only raw/root and isolated per-app writes. No GUI/hardware/provider/credential/live-setting or authenticated interaction is certified. ARM/Darwin remain evaluation-only; package metadata is not runtime acceptance. ArtCraft is install-only: no fake registration.

| App (version) | Revision | Native project / import-export scope | Runtime-tested headless operation |
|---|---|---|---|
| artcraft 0.42.0-unstable-910bfe4 | `910bfe4e8494` | No verified native project/control contract in this task | Unsupported/unverified control interface |
| cadcraft 0.4.0-unstable-43e33ad | `43e33add44ff` | DXF; convert DXF/SVG/PNG (CLI source-observed); DWG fidelity unverified | new_drawing({metric:true}), inspect_drawing({}) |
| deckcraft 0.4.0-unstable-84acb49 | `84acb49895c8` | .deckcraft / PPTX / TXT / PNG (CLI source-observed) | new_presentation({}), add_text_box({x:10,y:20,w:300,text:"..."}), inspect_slide({}) |
| designcraft 0.5.0-unstable-0b69d68 | `0b69d6856ca0` | .designcraft / IDML in; PNG/JPG/PDF/IDML/EPUB out (CLI source-observed) | new_document({title:"...",pages:2}), inspect_document({}) |
| effectcraft 0.7.0-unstable-813c7c4 | `813c7c4650f0` | .ecproj; PNG frame and MP4 queue/render paths (CLI source-observed) | command_run({id:"comp.new",params:{name:"...",width:64,height:64,duration:1}}), get_project({}) |
| filmcraft 0.5.0-unstable-7bd7621 | `7bd76212629a` | .fcproj (native save/reopen tested); streaming MP4/MOV/Matroska/WebM input; H.264/AAC MP4 tested | command_run({id:"file.newSequence",params:{name:"...",width:64,height:64,fps:12}}), sequence_inspect({}) |
| gridcraft 0.4.0-unstable-13664fe | `13664fe66b95` | XLSX/CSV/TSV/JSON/HTML (CLI source-observed) | new_workbook({}), set_cell({cell:"B1",input:"=A1*2"}), get_cell({cell:"B1"}) |
| lightcraft 0.5.0-unstable-5436951 | `543695129932` | Persistent library snapshot/log; image/raw import; JPG/PNG/TIF/WebP/AVIF/DNG export (source-observed; PNG catalog import tested) | import({paths:["/fixture/raw/photo.png"],mode:"add"}), cmd_catalog_stats({}) |
| pdfcraft 0.5.0-unstable-68e91d4 | `68e91d4815ed` | PDF document; PDF edits and PNG/JPG/TIF/PAM page render (CLI source-observed) | doc_create({from:"blank",pages:2,name:"..."}), doc_inspect({}) |
| photocraft 0.6.0-unstable-d4ec2db | `d4ec2db0a797` | .pcraft / PSD / PNG / JPG / TIF / WebP / EXR conversions (CLI source-observed) | doc_new({width:64,height:48,name:"...",background:"#ff0000"}), doc_inspect({}) |
| soundcraft 0.4.0-unstable-3bc2d92 | `3bc2d92b4e3d` | .scraft save/reopen and mono PCM WAV import/gain/bounce tested; other codecs unverified | import_audio({path:"..."}), execute({command:"clip.gain",params:{clips:[RETURNED_CLIP_ID],db:-6}}), bounce_mix({...}), open_session({...}) |
| vectorcraft 0.8.0-unstable-e1599a1 | `e1599a16aaf2` | .vectorcraft/.drawcraft; SVG/PDF/AI/DXF/EPS/raster formats listed by CLI, fidelity unverified | draw_shape({shape:"rectangle",x:10,y:20,width:30,height:40,fill:"#ff0000"}), inspect_document({}) |
| wordcraft 0.4.0-unstable-a1caf22 | `a1caf22a0b4f` | Native DOCX path/text/PNG page API source-observed; text editing tested | new_document({template:"blank"}), type_text({text:"..."}), get_text({}) |

## Exact native launches

GUI entry: each exact output has `bin/<app>`; verified companions have `bin/<app>-cli`. Absolute paths/revisions and transport are in JSON. Ordinary native stdio launch is `<app>-cli mcp`; standalone PDF uses `pdfcraft-cli mcp --root /fixture`; Vector uses `vectorcraft-cli mcp --headless --automation-read-root /fixture --automation-write-root /fixture`. The packaged namespace launcher adjusts PDF read root to its private `/`, Photo/Vector write roots to the app derived directory, and Light to `--library <app-derived>/library`. These paths are private namespace paths, not a grant of host-root access. MCP is newline JSON-RPC; protocol negotiation is native, not an invented GUI bridge.

The reusable selection/MCP policy lives in **badwater-ai**, runtime/launcher/skill and portable native tests in **pi-nix**. Do not install thirteen new flakes, repackage apps, add a global consumer overlay or producer compiler/font follows. Native child processes see only read-only store/authorized raw roots plus their own application write tree and scratch space, no host HOME/credentials/network/display. Known precise banners/one healthy Light library LoadReport are retained locally, not broad stderr suppression. Unexpected diagnostics remain visible and acceptance fails.

Import/export listings are **source-observed**, not fidelity guarantees. FilmCraft native revision/conform/render and SoundCraft selected-cut speech leveling have deeper runtime evidence. Native `.fcproj` references media and cut derivatives; do not move/delete derived audio independently. No third-party timeline/caption/multicamera/semantic-understanding claim is made. Credentials are not needed for tested operations; online/provider/GUI bridge features were not invoked and require separate consent/configuration.

ArtCraft and its frontend are non-free/source-available and remain opt-in in reusable modules. Existing producer licensing, font/model pins and PDFCraft’s official Rust1.98.1 selection remain unchanged. Source-mirroring CI is unchanged. No binary/cache/CI publication or redistribution permission is authorized by this work.

Reproduce the synthetic suite with the producer outputs supplied to `pi-nix/tests/video-native/run.py --apps`; see that owner’s [video documentation](../../pi-nix/docs/video-editing.md) when repositories are siblings. The JSON `source` and output paths are immutable selected-output evidence, not source checkout runtime commands.
