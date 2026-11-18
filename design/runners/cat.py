"""大耳、圆脸、翘尾的小猫，用两组对角步交替小跑。"""

WIDTH = 26

# 每组对角脚先向前落地，再蹬地收脚。两组错开半个周期。
STRIDE = (
    (1.6, 11.1, 3.0, 14.1),
    (0.7, 11.5, 1.1, 14.1),
    (-0.9, 11.7, -1.6, 14.1),
    (-2.0, 11.4, -2.7, 13.3),
    (-0.8, 11.5, -0.3, 12.5),
    (1.0, 11.4, 1.9, 13.1),
)
BOB = (-0.35, 0.0, 0.35, 0.25, -0.05, -0.4)
TAIL_SWING = (-5, -2, 3, 5, 2, -3)


def leg(hip_x, hip_y, phase, bend, depth=0):
    knee_x, knee_y, toe_x, toe_y = STRIDE[phase]
    return (
        f'<path d="M {hip_x} {hip_y:g} '
        f'Q {hip_x + knee_x + bend:g} {knee_y - depth:g} '
        f'{hip_x + toe_x:g} {toe_y - depth:g}" '
        'fill="none" stroke="black" stroke-width="2" stroke-linecap="round"/>'
    )


def frame(phase):
    bob = BOB[phase]
    other = (phase + 3) % len(STRIDE)
    legs = "\n".join((
        leg(8.2, 10.0 + bob, phase, 0.45, 0.6),
        leg(19.1, 9.9 + bob, other, -0.5, 0.6),
        leg(10.7, 10.4 + bob, other, 0.5),
        leg(17.1, 10.3 + bob, phase, -0.6),
    ))
    return f'''{legs}
<g transform="translate(0 {bob:g})" fill="black">
  <path d="M 8.3 9.6 C 5.4 10.5 2.8 8.6 2.6 6.1 C 2.5 4.6 3.1 3.5 4.1 3.2"
        transform="rotate({TAIL_SWING[phase]} 8.3 9.6)"
        fill="none" stroke="black" stroke-width="2.2" stroke-linecap="round"/>
  <ellipse cx="12.65" cy="9.35" rx="6.45" ry="3.9"/>
  <path fill-rule="evenodd" d="M 15.25 7.45
    C 15.2 6.5 15.55 5.45 16.28 4.65
    L 16.15 1.85 Q 16.17 0.9 17.04 1.4 L 19.65 3.28
    Q 20.08 3.13 20.44 3.21
    L 22.16 1.43 Q 22.89 0.73 23.14 1.6 L 23.55 4.78
    Q 24.15 5.45 24.26 6.38 L 24.75 6.72
    Q 25.28 7.04 25.17 7.73 C 24.83 9.5 23.05 10.68 20.53 10.89
    C 17.59 11.11 15.25 9.69 15.25 7.45 Z
    M 23.15 6.55 A 1.1 1.02 0 1 0 20.95 6.55 A 1.1 1.02 0 1 0 23.15 6.55 Z"/>
</g>'''


FRAMES = tuple(frame(phase) for phase in range(len(STRIDE)))
