#include <iostream>
#include <string>
#include <vector>
#include <cmath>
#include <random>
#include <regex>
#include <curl/curl.h>

using namespace std;

// ================= 数据结构优化 =================
struct Fortune {
    string hitokoto;
    string from;
};

const vector<Fortune> kFortune = {
    {"那些听不见音乐的人认为那些跳舞的人疯了。", "笑：论滑稽的意义"},
    {"太阳落山并不代表他输了，而是他来了。", "安讯七旬"},
    {"恰沐春风共同游，终只叹，木已舟。", "{网易云"},
    {"阶砖不会拒绝磨蚀，窗花不可幽禁落霞。", "喜帖街"},
    {"跌跌撞撞的成长，又美又疼才是本质。", "哥斯拉不说话"},
    {"真正珍惜时间的人不会找任何借口……可惜我不是。", "原创"},
    {"暗恋不会窥见天光，青梅抵不过天降，永远没有旧情复燃破镜重圆。", "互联网"},
    {"一个细胞里，却分裂出了两种截然不同的命运。", "法医秦明"},
    {"执手相看泪眼，竟无语凝噎。", "雨霖铃·寒蝉凄切"},
    {"猫是可爱的，狼是很帅的。就是说，孤独又可爱又帅。", "我的青春恋爱物语果然有问题"},
    {"人生用特写镜头来看是悲剧，长镜头来看则是喜剧。", "名人名言"},
    {"幸福破灭之时，总是伴随着血腥味。", "鬼灭之刃"},
    {"因为你喜欢海，所以我一直浪。", "君"},
    {"正因为知道可以在空中翱翔，才会畏惧展翅的那一刻而忘却疾风。", "空之境界"},
    {"世界是那么阒寂，而昨天的我已离我远去。", "人间失格·皮肤与心"},
    {"纵深于黑夜之中化作黎明！", "林清凝"},
    {"这个世界上没有忽然崩溃的感情，只有压弯骆驼的最后一根稻草。", "知乎匿名用户"},
    {"千秋无绝色，悦目为佳人。", "神游"},
    {"前方的路途还很遥远，前进！", "坎公骑冠剑"},
    {"最最好的，与最最痛苦的，是一样的。", "文学与少女"}
};

// 生成随机数
int generate_random_int(int min, int max) {
    static random_device rd;
    static mt19937 gen(rd());
    uniform_int_distribution<> dis(min, max);
    return dis(gen);
}

// 彩虹颜色生成
tuple<int, int, int> rainbow(int freq, int i) {
    double red = sin(freq * i + 0) * 127 + 128;
    double green = sin(freq * i + 2 * M_PI / 3) * 127 + 128;
    double blue = sin(freq * i + 4 * M_PI / 3) * 127 + 128;
    return {static_cast<int>(red), static_cast<int>(green), static_cast<int>(blue)};
}

// 简化版的显示宽度计算
int get_display_width(const string &utf8_str) {
    int width = 0;
    for (size_t i = 0; i < utf8_str.size(); i++) {
        unsigned char c = utf8_str[i];
        if (c < 0x80) {
            width += 1;  // ASCII字符宽度为1
        } else if ((c & 0xE0) == 0xC0) {
            // 双字节UTF-8字符
            if (i + 1 < utf8_str.size()) {
                unsigned char c2 = utf8_str[i + 1];
                if ((c2 & 0xC0) == 0x80) {
                    width += 2;  // 大多数中文、日文、韩文等宽度为2
                    i += 1;
                }
            }
        } else if ((c & 0xF0) == 0xE0) {
            // 三字节UTF-8字符
            if (i + 2 < utf8_str.size()) {
                width += 2;  // 大多数CJK字符宽度为2
                i += 2;
            }
        } else if ((c & 0xF8) == 0xF0) {
            // 四字节UTF-8字符
            if (i + 3 < utf8_str.size()) {
                width += 2;  // 假设这些字符宽度为2
                i += 3;
            }
        }
    }
    return width;
}

// 输出彩色文本
void print_rainbow_text(const vector<string> &lines, int freq = 220) {
    int seed = generate_random_int(0, 255);

    for (size_t i = 0; i < lines.size(); ++i) {
        const string &line = lines[i];
        regex utf8_char_re(R"(([\x00-\x7F]|[\xC0-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF]{2}|[\xF0-\xF7][\x80-\xBF]{3}))");
        auto begin = sregex_iterator(line.begin(), line.end(), utf8_char_re);
        auto end = sregex_iterator();

        int j = 0;
        for (auto it = begin; it != end; ++it, ++j) {
            auto [r, g, b] = rainbow(freq, static_cast<int>(i) * 10 + seed + j);
            cout << "\033[38;2;" << r << ";" << g << ";" << b << "m" << it->str() << "\033[0m";
        }
        cout << endl;
    }
}

// ================= CURL回调 =================
size_t WriteCallback(void* contents, size_t size, size_t nmemb, string* data) {
    data->append((char*)contents, size * nmemb);
    return size * nmemb;
}

// ================= 获取一言 =================
Fortune fetch_hitokoto() {
    CURL* curl = curl_easy_init();
    string buffer;
    
    if (!curl || curl_easy_setopt(curl, CURLOPT_URL, "https://v1.hitokoto.cn") != CURLE_OK) {
        return kFortune[generate_random_int(0, kFortune.size()-1)];
    }
    
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buffer);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 2L);
    
    if (curl_easy_perform(curl) != CURLE_OK) {
        curl_easy_cleanup(curl);
        return kFortune[generate_random_int(0, kFortune.size()-1)];
    }
    
    curl_easy_cleanup(curl);
    
    // 手动解析JSON
    auto extract_field = [&](const string& field) -> string {
        size_t pos = buffer.find("\"" + field + "\":\"");
        if (pos == string::npos) return "";
        pos += field.length() + 4;
        size_t end = buffer.find('"', pos);
        return (end != string::npos) ? buffer.substr(pos, end-pos) : "";
    };
    
    string hitokoto = extract_field("hitokoto");
    string from = extract_field("from");
    
    return !hitokoto.empty() && !from.empty() 
        ? Fortune{hitokoto, from} 
        : kFortune[generate_random_int(0, kFortune.size()-1)];
}

// 格式化一言
vector<string> format_hitokoto(const string &quote, const string &from, int max_width = 30) {
    vector<string> result;
    result.push_back("『");

    regex utf8_char_re(R"(([\x00-\x7F]|[\xC0-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF]{2}|[\xF0-\xF7][\x80-\xBF]{3}))");
    auto begin = sregex_iterator(quote.begin(), quote.end(), utf8_char_re);
    auto end = sregex_iterator();

    string line;
    int line_width = 0;
    bool over30 = false;

    for (auto it = begin; it != end; ++it) {
        string ch = it->str();
        int w = get_display_width(ch);
        if (line_width + 1 > max_width) {
            result.push_back(line);
            line.clear();
            line_width = 0;
            over30 = true;
        }
        line += ch;
        ++line_width;
    }

    if (!line.empty()) {
        if (over30) {
            int space = (max_width - line_width) / 2;
            result.push_back(string(space, ' ') + line);
        } else {
            result.push_back("    " + line);
        }
    }

    string cite = "----" + from;
    if (over30) {
        result.push_back(string(60, ' ') + "』");
        result.push_back(string(60 - get_display_width(cite), ' ') + cite);
    } else {
        int qwidth = get_display_width(quote);
        if (!quote.empty()) {
            string last_char = quote.substr(quote.size() - 3);
            if (last_char == "！" || last_char == "。" || last_char == "？") {
                qwidth -= 1;
            }
        }

        result.push_back(string(qwidth + 6, ' ') + "』");
        result.push_back(string(qwidth - get_display_width(cite) + 6, ' ') + cite);
    }

    return result;
}

// 主函数
int main() {
    const auto [quote, from] = fetch_hitokoto();   
    auto lines = format_hitokoto(quote, from);
    print_rainbow_text(lines);
    
    return 0;
}