#!/usr/bin/env python3

import json
import requests
import sys

# --- CẤU HÌNH ---
# Nếu không truyền địa điểm vào command line, sẽ dùng mặc định này
DEFAULT_LOCATION = "Hanoi" 

def format_time(time_str):
    return time_str.zfill(4)[:2] + ":" + time_str.zfill(4)[2:]

def main():
    # Lấy địa điểm từ tham số dòng lệnh (nếu có)
    location = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_LOCATION
    
    # URL lấy dữ liệu JSON từ wttr.in
    url = f"https://wttr.in/{location}?format=j1"
    
    try:
        # Gọi API
        response = requests.get(url)
        data = response.json()
        
        # 1. Lấy thông tin hiện tại
        current = data['current_condition'][0]
        temp = current['temp_C']
        desc = current['weatherDesc'][0]['value']
        
        # Mapping icon thời tiết (bạn có thể thêm nếu muốn)
        # wttr.in trả về text, ta cần ánh xạ sang icon
        # Đây là ví dụ đơn giản, nếu muốn icon động theo đúng mô tả thì cần list dài hơn
        # Mặc định ta lấy icon Text đơn giản hoặc dùng ký tự có sẵn
        
        # Format text hiển thị trên thanh Bar
        # Ví dụ: ⛅ 25°C
        # Ta dùng luôn format %c %t của wttr.in cho đơn giản ở phần text
        # Nhưng để đồng bộ, ta tự build string:
        text_output = f"{temp}°C - {desc}"

        # 2. Tạo Tooltip (Dự báo)
        tooltip_text = f"<b>Location: {location}</b>\n"
        tooltip_text += f"<b>Condition:</b> {desc}\n"
        tooltip_text += f"<b>Humidity:</b> {current['humidity']}%\n"
        tooltip_text += f"<b>Wind:</b> {current['windspeedKmph']} km/h\n\n"
        
        # Dự báo 3 ngày tới
        for day in data['weather']:
            date = day['date']
            maxtemp = day['maxtempC']
            mintemp = day['mintempC']
            tooltip_text += f"<b>📅 {date}:</b> {maxtemp}°C {mintemp}°C\n"
            
            # Chi tiết từng buổi trong ngày (Sáng/Trưa/Chiều/Tối)
            # Uncomment đoạn dưới nếu muốn chi tiết quá mức (sẽ làm tooltip rất dài)
            # for hour in day['hourly']:
            #     time = format_time(hour['time'])
            #     tooltip_text += f"   {time} {hour['tempC']}°C {hour['weatherDesc'][0]['value']}\n"
        
        # 3. Xuất JSON cho Waybar
        out_data = {
            "text": text_output,
            "tooltip": tooltip_text,
            "class": "weather"
        }
        
        print(json.dumps(out_data))
        
    except Exception as e:
        # Nếu lỗi (mất mạng, server lỗi), hiển thị icon báo lỗi
        print(json.dumps({"text": "⚠️ Offline", "tooltip": str(e)}))

if __name__ == "__main__":
    main()
