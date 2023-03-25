import requests
import random
import unicodedata


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
    print("『")
    remain = hitokoto
    while len(remain) > 30:
        over30 = True
        print(remain[:30])
        remain = remain[30:]
    if over30 and len(remain) > 0:
        print(' ' * ((30 - len(remain)) // 2), end="")
    else:
        print('    ', end="")
    print(remain)
    cite = f'----{it_from}'
    if over30:
        print(' ' * 60 + '』')
        print(f'{cite:>60}')
    else:
        w_hitokoto = str_display_width(hitokoto)
        if hitokoto[-1] in ('！', '。', '？'):
            w_hitokoto -= 1
        w_cite = str_display_width(cite)
        print(' ' * (w_hitokoto + 6) + '』')
        print(' ' * (w_hitokoto - w_cite + 6) + cite)


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

    main()