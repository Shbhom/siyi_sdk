# SIYI A8 Mini Camera Control System

This project provides a complete system for controlling and streaming from a SIYI A8 mini camera, based on the SIYI SDK implementation.

## Features
- **RTSP Stream Rebroadcasting**: Capture and rebroadcast camera feed
- **Camera Control API**: RESTful API for camera control
  - Gimbal Control: Full control over yaw (-135° to +135°) and pitch (-90° to +25°)
  - Zoom Control: Adjustable zoom levels (1.0x to 6.0x)
  - Auto-centering
- **Auto-Network Setup**: Automatic Tailscale configuration
- **Swagger Documentation**: Interactive API documentation
- **GUI Interface**: Tkinter-based GUI for camera control

## Requirements
- Python 3.10+
- FFmpeg
- Tailscale
- Python virtual environment (for API server)
- OpenCV (`sudo apt-get install python3-opencv -y`)
- GStreamer (for video streaming)
- Additional Python packages (see Installation)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/mzahana/siyi_sdk.git
cd siyi_sdk
```

2. Network Setup:
- Connect camera to PC using the ethernet cable
- Configure PC network:
  - IP: `192.168.144.12`
  - Gateway: `192.168.144.25`
  - Netmask: `255.255.255.0`

3. Create virtual environment:
```bash
python -m venv serve
source serve/bin/activate
pip install fastapi uvicorn
```

4. Install GStreamer (Ubuntu):
```bash
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl \
    gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio -y
```

5. Install RTMP streaming requirements:
```bash
sudo apt install ffmpeg -y
pip install ffmpeg-python
```

## Usage

### API Server and Stream
Start the complete system:
```bash
chmod +x starter.sh
./starter.sh
```

Access:
- API Documentation: `http://localhost:8000/docs`
- RTSP Stream: `rtsp://localhost:8554/live`

### GUI Interface
Run the Tkinter GUI:
```bash
python3 gui/tkgui.py
```

### SDK Usage
Import in your code:
```python
from siyi_sdk import SIYISDK
```

See examples in `tests/` directory.

## Documentation
- [API Documentation](API_doc.md)
- [Contribution Guide](CONTRIBUTING.md)

## Logs
System logs are stored in:
- `logs/stream/<timestamp>/` - Stream rebroadcaster logs
- `logs/server/<timestamp>/` - API server logs

## Tools

### NGINX RTMP Server
Run using Docker:
```bash
docker run -d -p 1935:1935 --name nginx-rtmp tiangolo/nginx-rtmp
```

### Stream Player
Play RTMP stream using mpv:
```bash
mpv --profile=low-latency rtmp://127.0.0.1/live/webcam
```

## Original SDK Documentation
- [Camera-gimbal products](https://shop.siyi.biz/collections/gimbal-camera-optical-pod)
- [A8 mini Manual](https://siyi.biz/siyi_file/A8%20mini/A8%20mini%20User%20Manual%20v1.6.pdf)

**If you find this code useful, kindly give a STAR to this repository. Thanks!**
