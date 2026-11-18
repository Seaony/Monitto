"""正面摇摆走路的企鹅。"""

WIDTH = 22
CENTER = 9

BODY = (
    "M9 .55 C6.1 .55 4.35 2.2 4.35 4.9 "
    "C4.35 6.2 3.9 7.7 3.8 9.6 C3.6 12.8 5.8 14.2 9 14.2 "
    "C12.2 14.2 14.4 12.8 14.2 9.6 C14.1 7.7 13.65 6.2 13.65 4.9 "
    "C13.65 2.2 11.9 .55 9 .55 Z"
    " M5.9 3.3 a.8 .8 0 1 0 1.6 0 a.8 .8 0 1 0 -1.6 0 Z"
    " M10.5 3.3 a.8 .8 0 1 0 1.6 0 a.8 .8 0 1 0 -1.6 0 Z"
    " M7.45 5 L10.55 5 L9 7 Z"
    " M9 8.5 C7.35 8.5 5.95 9.45 5.95 10.8 "
    "C5.95 12 7.05 12.6 9 12.6 C10.95 12.6 12.05 12 12.05 10.8 "
    "C12.05 9.45 10.65 8.5 9 8.5 Z"
)

FLIPPER = (
    "M5.55 6.55 C3.95 6.35 2.15 6.7 .7 7.65 "
    "C-.05 8.14 .15 9.23 1.02 9.35 C2.6 9.6 4.28 9.08 5.55 8.3 Z"
)

FOOT = (
    "M6.15 13.05 C5.35 13.05 4.65 13.95 4.65 14.65 "
    "Q4.65 15.5 5.55 15.5 H7.35 Q8.3 15.5 8.3 14.55 "
    "C8.2 14 7.5 13.45 6.15 13.05 Z"
)

# 两脚轮流落在同一条地线上，鳍臂随身体向两侧摆。
POSES = (
    # 身体倾角、左鳍角、右鳍角、左脚抬起高度、右脚抬起高度。
    (0, -5, 10, 0, 0),
    (-6, 18, -12, 0, 1.2),
    (-10, 37, -23, 0, 2.5),
    (-7, 20, -20, 0, 1.15),
    (0, 10, -5, 0, 0),
    (6, -12, 18, 1.2, 0),
    (10, -23, 37, 2.5, 0),
    (7, -20, 20, 1.15, 0),
)


def frame(lean, left_wing, right_wing, left_step, right_step):
    margin = WIDTH / 2 - CENTER
    mirror = CENTER * 2
    return (
        f'<g transform="translate({margin:g} 0)">\n'
        f'  <path d="{FOOT}" transform="translate({-left_step * .6:g} {-left_step:g})"/>\n'
        f'  <path d="{FOOT}" transform="translate({mirror + right_step * .6:g} {-right_step:g}) scale(-1 1)"/>\n'
        f'  <g transform="translate({lean * .04:g} 0) rotate({lean} {CENTER} 14)">\n'
        f'    <path d="{FLIPPER}" transform="rotate({left_wing} 5 7.4)"/>\n'
        f'    <path d="{FLIPPER}" transform="translate({mirror} 0) scale(-1 1) rotate({right_wing} 5 7.4)"/>\n'
        f'    <path fill-rule="evenodd" d="{BODY}"/>\n'
        '  </g>\n'
        '</g>'
    )


FRAMES = tuple(frame(*pose) for pose in POSES)
