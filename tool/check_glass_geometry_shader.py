"""Check the compiled GPU uniform layout; Flutter widget tests only cover SkSL."""

import argparse
import json
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("impellerc", type=Path, help="Flutter SDK's impellerc executable")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    shaders = root / "third_party/liquid_glass_widgets/shaders"
    expected = [
        ("uOpticalProps", 4),
        ("uShapeSettings", 2),
        ("uShapeData", 112),
        ("uNativeEdge", 1),
    ]
    with tempfile.TemporaryDirectory() as directory:
        output = Path(directory) / "geometry.json"
        subprocess.run([
            str(args.impellerc),
            "--runtime-stage-metal", "--runtime-stage-gles", "--runtime-stage-gles3",
            "--runtime-stage-vulkan", "--iplr", "--json", "--input-type=frag",
            f"--input={shaders / 'liquid_glass_geometry_blended.frag'}",
            f"--include={shaders}",
            f"--include={args.impellerc.parent / 'shader_lib'}",
            f"--sl={output}", f"--spirv={output}.spv",
        ], check=True)
        stages = json.loads(output.read_text())
        for backend in ("metal", "opengles", "opengles3", "sksl"):
            actual = [
                (uniform["name"], uniform["rows"] * uniform["columns"] *
                 max(1, uniform["array_elements"]))
                for uniform in stages[backend]["uniforms"]
            ]
            if actual != expected:
                raise AssertionError(f"{backend}: expected {expected}, got {actual}")
            print(f"{backend}: all 119 uniform slots retained")
        # Vulkan reflects one packed block rather than individual uniforms.
        if "vulkan" not in stages:
            raise AssertionError("Vulkan shader was not compiled")
        print("vulkan: compiled successfully")


if __name__ == "__main__":
    main()
