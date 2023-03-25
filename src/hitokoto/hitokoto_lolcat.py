#!/usr/bin/python3

import atexit
import math
import os
import random
import re
import sys
import time
import requests
import unicodedata
from typing import Iterable


##########################################
#                                        #
#            lolcat implement            #
#                                        #
##########################################

# "THE BEER-WARE LICENSE" (Revision 43~maze)
#
# <maze@pyth0n.org> wrote these files. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.

PY3 = sys.version_info >= (3,)

# override default handler so no exceptions on SIGPIPE
if os.name != 'nt':
    from signal import signal, SIGPIPE, SIG_DFL
    signal(SIGPIPE, SIG_DFL)

# Reset terminal colors at exit
def reset():
    sys.stdout.write('\x1b[0m')
    sys.stdout.flush()

atexit.register(reset)


STRIP_ANSI = re.compile(r'\x1b\[(\d+)(;\d+)?(;\d+)?[m|K]')
COLOR_ANSI = (
    (0x00, 0x00, 0x00), (0xcd, 0x00, 0x00),
    (0x00, 0xcd, 0x00), (0xcd, 0xcd, 0x00),
    (0x00, 0x00, 0xee), (0xcd, 0x00, 0xcd),
    (0x00, 0xcd, 0xcd), (0xe5, 0xe5, 0xe5),
    (0x7f, 0x7f, 0x7f), (0xff, 0x00, 0x00),
    (0x00, 0xff, 0x00), (0xff, 0xff, 0x00),
    (0x5c, 0x5c, 0xff), (0xff, 0x00, 0xff),
    (0x00, 0xff, 0xff), (0xff, 0xff, 0xff),
)


class stdoutWin():
    def __init__(self):
        self.output = sys.stdout
        self.string = ''
        self.i = 0

    def isatty(self):
        return self.output.isatty()

    def write(self,s):
        self.string = self.string + s

    def flush(self):
        return self.output.flush()

    def prints(self):
        string = 'echo|set /p="%s"' %(self.string)
        os.system(string)
        self.i += 1
        self.string = ''

    def println(self):
        # print()
        self.prints()


class LolCat(object):
    def __init__(self, mode=256, output=sys.stdout):
        self.mode =mode
        self.output = output

    def _distance(self, rgb1, rgb2):
        return sum(map(lambda c: (c[0] - c[1]) ** 2,
            zip(rgb1, rgb2)))

    def ansi(self, rgb):
        r, g, b = rgb

        if self.mode in (8, 16):
            colors = COLOR_ANSI[:self.mode]
            matches = [(self._distance(c, map(int, rgb)), i) for i, c in enumerate(colors)]
            matches.sort()
            color = matches[0][1]

            return '3%d' % (color,)
        else:
            gray_possible = True
            sep = 2.5

            while gray_possible:
                if r < sep or g < sep or b < sep:
                    gray = r < sep and g < sep and b < sep
                    gray_possible = False

                sep += 42.5

            if gray:
                color = 232 + int(float(sum(rgb) / 33.0))
            else:
                color = sum([16]+[int(6 * float(val)/256) * mod
                    for val, mod in zip(rgb, [36, 6, 1])])

            return '38;5;%d' % (color,)

    def wrap(self, *codes):
        return '\x1b[%sm' % (''.join(codes),)

    def rainbow(self, freq, i):
        r = math.sin(freq * i) * 127 + 128
        g = math.sin(freq * i + 2 * math.pi / 3) * 127 + 128
        b = math.sin(freq * i + 4 * math.pi / 3) * 127 + 128
        return [r, g, b]

    def cat(self, content: Iterable, options):
        if options.animate:
            self.output.write('\x1b[?25l')

        for line in content:
            options.os += 1
            self.println(line, options)

        if options.animate:
            self.output.write('\x1b[?25h')

    def println(self, s, options):
        s = s.rstrip()
        if options.force or self.output.isatty():
            s = STRIP_ANSI.sub('', s)

        if options.animate:
            self.println_ani(s, options)
        else:
            self.println_plain(s, options)

        self.output.write('\n')
        self.output.flush()
        if os.name == 'nt':
            print()
            self.output.println()

    def println_ani(self, s, options):
        if not s:
            return

        for i in range(1, options.duration):
            self.output.write('\x1b[%dD' % (len(s),))
            self.output.flush()
            options.os += options.spread
            self.println_plain(s, options)
            time.sleep(1.0 / options.speed)

    def println_plain(self, s, options):
        for i, c in enumerate(s if PY3 else s.decode(options.charset_py2, 'replace')):
            rgb = self.rainbow(options.freq, options.os + i / options.spread)
            self.output.write(''.join([
                self.wrap(self.ansi(rgb)),
                c if PY3 else c.encode(options.charset_py2, 'replace'),
            ]))
        if os.name == 'nt':
            self.output.println()


def detect_mode(term_hint='xterm-256color'):
    '''
    Poor-mans color mode detection.
    '''
    if 'ANSICON' in os.environ:
        return 16
    elif os.environ.get('ConEmuANSI', 'OFF') == 'ON':
        return 256
    else:
        term = os.environ.get('TERM', term_hint)
        if term.endswith('-256color') or term in ('xterm', 'screen'):
            return 256
        elif term.endswith('-color') or term in ('rxvt',):
            return 16
        else:
            return 256 # optimistic default
        

class Options:
    """ lolcat 运行所需参数
    Parameters
    ------
        - `spread`: Rainbow spread, default=3.0
        - `freq`: Rainbow frequency, default=0.1
        - `seed`: Rainbow seed, default=0
        - `animate`: Enable psychedelics, default=False
        - `duration`: Animation duration, default=12
        - `speed`: Animation speed, default=20.0
        - `force`: Force colour even when stdout is not a tty, default=False
    """
    def __init__(self, spread=3.0, freq=0.1, seed=0, animate=False,
                 duration=12, speed=20.0, force=False) -> None:
        self.spread = spread
        self.freq = freq
        self.seed = seed
        self.animate = animate
        self.duration = duration
        self.speed = speed
        self.force = force
        self.os = random.randint(0, 256) if seed == 0 else seed
        self.mode = detect_mode()


def run_lolcat(text_list: list):
    """运行 lolcat
    
    Parameters
    ------
    `text_list`: 用于输出的文本列表, 列表的元素为一行文本 (str)
    """
    options = Options()
    if os.name == 'nt':
        lolcat = LolCat(mode=options.mode,output=stdoutWin())
    else:
        lolcat = LolCat(mode=options.mode)

    lolcat.cat(text_list, options)


##########################################
#                                        #
#                hitokoto                #
#                                        #
##########################################

def str_display_width(s: str) -> int:
    def get_char_display_width(unicode_str):
        r = unicodedata.east_asian_width(unicode_str)
        if r == "F":    # Fullwidth
            return 2
        elif r == "H":  # Half-width
            return 1
        elif r == "W":  # Wide
            return 2
        elif r == "Na": # Narrow
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



def main():
    """从一言获取每日一言"""
    url = 'https://v1.hitokoto.cn/?encode=json'
    proxies = { "http": None, "https": None}
    try:
        res = requests.get(url, proxies=proxies, timeout=(3.05,0.5)).json()
    except Exception:
        res = fortune[random.randint(0, 20)]
    hitokoto = res['hitokoto'].strip()
    it_from  = res['from'].strip()
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

    run_lolcat(text_list)


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

