# -*- coding: utf-8 -*-

#
# 这个脚本是用来将https://my.clippings.io/# 导出的txt转换成本博客所用md辅助工具，也方便后续的修改格式及调整之类

import os
import sys


def adjust_format(line, lines):
    #print lines
    if author is not None:
        # 读到引文
        if line.startswith(author):
            line = '***\n\n* ' + line
            for i, l in enumerate(lines):
                if len(l)>3 and not l.startswith('Notes:'):
                    lines[i] = '>' + l
                    lines[i-1] = line
                    break
            return True
        else:
            lines.append(line)
    return False
            

if __name__ == "__main__":
    lines = list()

    if len(sys.argv) < 1:
        exit()
    # 第一个参数为文件名
    file_name = sys.argv[1]
    file_path = file_name
    author = None
    if not file_path.endswith('.txt'):
        file_path += '.txt'
    else:
        file_name = file_name[:-4]
    with open(file_path, 'r', encoding='UTF-8') as f1, open(file_name+'.md','w', encoding='UTF-8') as f2:
        first_line = f1.readline()
        author = first_line.split(',')[-1].strip()
        for line in f1.readlines():
            if adjust_format(line, lines):
                #print lines
                f2.writelines(lines)
                lines = list()