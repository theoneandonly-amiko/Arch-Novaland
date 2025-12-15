#!/bin/bash

bar=" ▂▃▄▅▆▇█"
dict="s/;//g;"

# Tạo độ dài chuỗi thay thế
i=0
while [ $i -lt ${#bar} ]
do
    dict="${dict}s/$i/${bar:$i:1}/g;"
    i=$((i=i+1))
done

# Config tạm cho Cava để output raw data
config_file="/tmp/waybar_cava_config"
echo "
[general]
bars = 10
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
" > $config_file

# Chạy cava và pipe qua sed để thay thế số thành ký tự bar
cava -p $config_file | sed -u "$dict"
