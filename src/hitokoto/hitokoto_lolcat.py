#!/usr/bin/python3

from __future__ import print_function, division
import os
import sys
import random
import requests
import unicodedata
from math import sin, pi
from typing import List


################################################
#                                              #
#               lolcat implement               #
#                                              #
#  https://github.com/Abhishek8394/lol-cat-py  #
################################################

def detect_windows_terminal() -> bool:
    """
    Returns True if detects to be running in a powershell, False otherwise.
    """
    # return sys.platform == 'win32' and os.environ.get('WT_SESSION', None) is not None
    return os.name == 'nt'


def supports_color() -> bool:
    """
    Returns True if the running system's terminal supports color, and False
    otherwise.
    """
    plat = sys.platform
    supported_platform = (plat != 'Pocket PC' and ('ANSICON' in os.environ)) \
        or (plat.lower() == 'linux' and os.environ.get('TERM', '').endswith('256color'))
    is_wnd_term = detect_windows_terminal()
    # isatty is not always implemented, #6223.
    is_a_tty = hasattr(sys.stdout, 'isatty') and sys.stdout.isatty()
    if supported_platform:
        return True
    if (not supported_platform and is_wnd_term and is_a_tty):
        return True
    if not supported_platform or not is_a_tty:
        return False
    return True


def rainbow(freq: int, i: int) -> tuple:
    """Creates RGB values, inspired from https://github.com/busyloop/lolcat

    Args
    ------
        - `freq`: Frequency, more the value; more the colours
        - `i`: Current character position, used to set colours at character level

    Returns
    ------
        - tuple: Contains integers R, G, B
    """
    red = sin(freq * i + 0) * 127 + 128
    green = sin(freq * i + 2*pi/3) * 127 + 128
    blue = sin(freq * i + 4*pi/3) * 127 + 128
    return int(red), int(green), int(blue)


def print_rainbow_text(text, freq: int = 220, end: str = "\n"):
    """Prints rainbow text if terminal support for colour text is detected, 
       else falls back to default terminal settings.

    Args
    ------
        - `text` (str/list(str)): String or list of str. Provide list to make the whole
                              paragraph look consistent
        - `freq`: Frequency determines rate of colour change. It's a sine wave so 
                              changing values on extremes might not help. Sweet spot is 220,
                              stick to it.
        - `end`: Similar to `end` param in print function
    """
    if not supports_color():
        # print to stderr so doesn't mess with IO redirections.
        sys.stderr.write(
            "No support for colour on this terminal. Try bash/zsh/cygwin/Windows Terminal." + os.linesep)
        if type(text) == list:
            print("\n".join(text), end=end)
        else:
            print(text, end=end)
        return
    seed = random.randrange(0, 256)
    for i, c in enumerate(text):
        if type(text) != list:
            r, g, b = rainbow(freq, i + seed)
            color2 = "\033[38;2;%d;%d;%dm" % (r, g, b)
            print(color2+c+"\033[0m", end="")
        else:
            for j, cagain in enumerate(c):
                # this formula helps colours spread on whole paragraph.
                r, g, b = rainbow(freq, i*10 + seed + j)
                color2 = "\033[38;2;%d;%d;%dm" % (r, g, b)
                print(color2 + cagain + "\033[0m", end="")
            print()
    print(end=end)


##########################################
#                                        #
#                hitokoto                #
#                                        #
##########################################

def str_display_width(s: str) -> int:
    """Calculate the display width of a string"""
    def get_char_display_width(unicode_str):
        r = unicodedata.east_asian_width(unicode_str)
        if r == "F":    # Fullwidth
            return 2
        elif r == "H":  # Half-width
            return 1
        elif r == "W":  # Wide
            return 2
        elif r == "Na":  # Narrow
            return 1
        elif r == "A":  # Ambiguous, go with 2
            return 1
        elif r == "N":  # Neutral
            return 1
        else:
            return 1

    s = unicodedata.normalize('NFC', s)
    w = 0
    for c in s:
        w += get_char_display_width(c)
    return w


def get_hitokoto_text() -> List[str]:
    """从一言获取每日一言

    Returns
    ------
        - A string list contains the content of hitokoto.
    """
    url = 'https://v1.hitokoto.cn/?encode=json'
    proxies = {"http": None, "https": None}
    try:
        res = requests.get(url, proxies=proxies, timeout=(3.05, 0.5)).json()
    except Exception:
        res = fortune[random.randrange(0, 20)]
    hitokoto = res['hitokoto'].strip()
    it_from = res['from'].strip()
    over30 = False
    text_list = []
    text_list.append("『")
    remain = hitokoto
    while len(remain) > 30:
        over30 = True
        text_list.append(remain[:30])
        remain = remain[30:]

    if over30 and len(remain) > 0:
        line_text = ' ' * ((30 - len(remain)) // 2)
    else:
        line_text = ' ' * 4
    text_list.append(line_text + remain)
    cite = f'----{it_from}'
    if over30:
        text_list.append(' ' * 60 + '』')
        text_list.append(f'{cite:>60}')
    else:
        w_hitokoto = str_display_width(hitokoto)
        if hitokoto[-1] in ('！', '。', '？'):
            w_hitokoto -= 1
        w_cite = str_display_width(cite)
        text_list.append(' ' * (w_hitokoto + 6) + '』')
        text_list.append(' ' * (w_hitokoto - w_cite + 6) + cite)
    return text_list


def main():
    content = get_hitokoto_text()
    print_rainbow_text(content)


if __name__ == '__main__':
    fortune = [
        {
            "hitokoto": "那些听不见音乐的人认为那些跳舞的人疯了。",
            "from": "笑：论滑稽的意义"
        },
        {
            "hitokoto": "太阳落山并不代表他输了，而是他来了。",
            "from": "安讯七旬"
        },
        {
            "hitokoto": "恰沐春风共同游，终只叹，木已舟。",
            "from": "网易云"
        },
        {
            "hitokoto": "阶砖不会拒绝磨蚀，窗花不可幽禁落霞。",
            "from": "喜帖街"
        },
        {
            "hitokoto": "跌跌撞撞的成长，又美又疼才是本质。",
            "from": "哥斯拉不说话"
        },
        {
            "hitokoto": "真正珍惜时间的人不会找任何借口……可惜我不是。",
            "from": "原创"
        },
        {
            "hitokoto": "暗恋不会窥见天光，青梅抵不过天降，永远没有旧情复燃破镜重圆。",
            "from": "互联网"
        },
        {
            "hitokoto": "一个细胞里，却分裂出了两种截然不同的命运。",
            "from": "法医秦明"
        },
        {
            "hitokoto": "执手相看泪眼，竟无语凝噎。",
            "from": "雨霖铃·寒蝉凄切"
        },
        {
            "hitokoto": "猫是可爱的，狼是很帅的。就是说，孤独又可爱又帅。",
            "from": "我的青春恋爱物语果然有问题"
        },
        {
            "hitokoto": "人生用特写镜头来看是悲剧，长镜头来看则是喜剧。",
            "from": "名人名言"
        },
        {
            "hitokoto": "幸福破灭之时，总是伴随着血腥味。",
            "from": "鬼灭之刃"
        },
        {
            "hitokoto": "因为你喜欢海，所以我一直浪。",
            "from": "君"
        },
        {
            "hitokoto": "正因为知道可以在空中翱翔，才会畏惧展翅的那一刻而忘却疾风。",
            "from": "空之境界"
        },
        {
            "hitokoto": "世界是那么阒寂，而昨天的我已离我远去。",
            "from": "人间失格·皮肤与心"
        },
        {
            "hitokoto": "纵深于黑夜之中化作黎明！",
            "from": "林清凝"
        },
        {
            "hitokoto": "这个世界上没有忽然崩溃的感情，只有压弯骆驼的最后一根稻草。",
            "from": "知乎匿名用户"
        },
        {
            "hitokoto": "关门，放狗！",
            "from": "训犬者洛克希"
        },
        {
            "hitokoto": "前方的路途还很遥远，前进！",
            "from": "坎公骑冠剑"
        },
        {
            "hitokoto": "最最好的，与最最痛苦的，是一样的。",
            "from": "文学与少女"
        }
    ]

    sys.exit(main())
