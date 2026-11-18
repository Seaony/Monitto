"""仓鼠前倾跑步，交替踩动内圈。"""

from math import cos, pi, radians, sin, sqrt

WIDTH = 20
FRAME_COUNT = 6
CENTER_X = WIDTH / 2
CENTER_Y = 7.6
RIM_RADIUS = 6.5
RIM_WIDTH = 1.6
RIM_INNER = RIM_RADIUS - RIM_WIDTH / 2
PAW_WIDTH = 1.7

# 脚向后踩过轮圈，抬起来向前摆。
STRIDE = ((1.2, 0.8), (0.35, 0), (-0.55, 0), (-1.2, 0), (-0.55, 1.35), (0.45, 1.45))


def wheel_point(angle, radius):
    return f'{CENTER_X + radius * cos(angle):.2f} {CENTER_Y + radius * sin(angle):.2f}'


def wheel(frame):
    # 顶部露出轮缘内侧的刻槽，三槽等距，每帧顺时针转 20°。
    tread_radius = 5.0
    spacing = 2 * pi / 3
    half_gap = 0.19
    top_start, top_end = radians(210), radians(330)
    treads = []
    phase = frame % FRAME_COUNT / FRAME_COUNT
    for index in range(3):
        angle = spacing * (index + phase)
        start = max(top_start, angle + half_gap)
        end = min(top_end, angle + spacing - half_gap)
        if end > start:
            treads.append(
                f'M {wheel_point(start, tread_radius)}'
                f' A {tread_radius} {tread_radius} 0 0 1 {wheel_point(end, tread_radius)}'
            )

    return f'''<path d="M 3.1 15.15 L 5.25 12.32 M 14.75 12.32 L 16.9 15.15"
    fill="none" stroke="black" stroke-width="1.55" stroke-linecap="round"/>
<circle cx="{CENTER_X}" cy="{CENTER_Y}" r="{RIM_RADIUS}"
    fill="none" stroke="black" stroke-width="{RIM_WIDTH}"/>
<path d="{' '.join(treads)}" fill="none" stroke="black" stroke-width="1.6"/>'''


def paw(x, frame):
    reach, lift = STRIDE[frame % FRAME_COUNT]
    toe_x = x + 0.85 * reach
    radius = RIM_INNER - PAW_WIDTH / 2 + 0.06
    toe_y = CENTER_Y + sqrt(radius**2 - (toe_x - CENTER_X)**2) - lift
    return f'M {x:.2f} 9.35 Q {toe_x - 0.55:.2f} {toe_y - 0.45:.2f} {toe_x:.2f} {toe_y:.2f}'


def drawing(frame):
    phase = 2 * pi * frame / FRAME_COUNT
    sway = -0.10 + 0.17 * sin(2 * phase)
    feet = f'{paw(7.9, frame)} {paw(11.9, frame + 3)}'
    return f'''{wheel(frame)}
<path d="{feet}" fill="none" stroke="black" stroke-width="{PAW_WIDTH}" stroke-linecap="round"/>
<path fill="black" fill-rule="evenodd" transform="translate(0 {sway:.2f})" d="
    M 6.9 10.25
    C 5.8 9.7 5.8 8.45 6.55 7.55
    C 7.1 6.8 8.1 6.4 9.2 6.43
    C 8.8 5.37 9.4 4.68 10.24 4.73
    C 11.14 4.79 11.52 5.5 11.31 6.32
    C 12.48 6.19 13.19 6.97 13.4 7.9
    C 14 7.9 14.28 8.42 13.92 8.92
    C 13.52 9.5 12.68 9.75 11.8 9.72
    C 10.55 10.63 8.05 10.78 6.9 10.25 Z
    M 11.85 7.05
    a .79 .79 0 1 0 0 1.58
    a .79 .79 0 1 0 0 -1.58 Z"/>'''


FRAMES = [drawing(frame) for frame in range(FRAME_COUNT)]
