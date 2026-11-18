"""生成菜单栏形象的矢量帧。"""

import argparse
import importlib
import json
from pathlib import Path
import shutil
import sys

sys.dont_write_bytecode = True

RUNNERS = ("cat", "hamster", "penguin", "bunny")
ASSETS = Path(__file__).resolve().parents[2] / "Monitto/Assets.xcassets/Runners"
HEIGHT = 16
FRAME_CONTENTS = {
    "images": [{"filename": "frame.svg", "idiom": "universal"}],
    "info": {"author": "xcode", "version": 1},
    "properties": {
        "preserves-vector-representation": True,
        "template-rendering-intent": "template",
    },
}


def generate(runner):
    module = importlib.import_module(runner)
    assert 0 < module.WIDTH <= 28
    assert 5 <= len(module.FRAMES) <= 10

    directory = ASSETS / runner
    directory.mkdir(parents=True, exist_ok=True)
    for old_frame in directory.glob(f"{runner}-frame-*.imageset"):
        shutil.rmtree(old_frame)

    for index, drawing in enumerate(module.FRAMES):
        imageset = directory / f"{runner}-frame-{index}.imageset"
        imageset.mkdir()
        (imageset / "Contents.json").write_text(
            json.dumps(FRAME_CONTENTS, indent=2) + "\n", encoding="utf-8"
        )
        (imageset / "frame.svg").write_text(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{module.WIDTH}" '
            f'height="{HEIGHT}" viewBox="0 0 {module.WIDTH} {HEIGHT}">\n'
            f'{drawing}\n</svg>\n', encoding="utf-8"
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=RUNNERS)
    args = parser.parse_args()
    for runner in (args.only,) if args.only else RUNNERS:
        generate(runner)
