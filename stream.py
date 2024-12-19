#!/usr/bin/env python3
"""
RTSP Stream Rebroadcaster
Receives RTSP stream from camera and rebroadcasts it to MediaMTX server
"""
import subprocess
import logging
import signal
import sys
import platform
import re
import threading

class RTSPRebroadcaster:
    def __init__(self, input_url="rtsp://192.168.144.25:8554/main.264", 
                 output_ip="0.0.0.0",
                 debug=False):
        # Configure logging
        self._debug = debug
        self._logger = logging.getLogger(self.__class__.__name__)
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(
            logging.Formatter('[%(levelname)s] %(asctime)s [RTSPRebroadcaster]: %(message)s')
        )
        self._logger.addHandler(console_handler)
        self._logger.setLevel(logging.DEBUG if debug else logging.INFO)

        self.input_url = input_url
        self.output_url = f"rtsp://{output_ip}:8554/live"
        self.process = None
        
        # Extract camera IP from input URL
        ip_match = re.search(r'rtsp://([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):', input_url)
        self.camera_ip = ip_match.group(1) if ip_match else None

    def _log_stream(self, stream, prefix):
        """Log FFmpeg output stream in real-time"""
        for line in stream:
            if line:
                line_str = line.decode('utf-8', errors='replace').strip()
                if line_str:
                    self._logger.info(f"{prefix}: {line_str}")

    def ping_camera(self):
        """Check if the camera is reachable via ping"""
        if not self.camera_ip:
            self._logger.error("Could not extract camera IP from URL")
            return False

        param = '-n' if platform.system().lower() == 'windows' else '-c'
        command = ['ping', param, '1', self.camera_ip]
        
        try:
            self._logger.info(f"Checking connection to A8 mini camera at {self.camera_ip}")
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return result.returncode == 0
        except Exception as e:
            self._logger.error(f"Ping check failed: {str(e)}")
            return False

    def start(self):
        """Start the FFmpeg process to rebroadcast the stream"""
        # Check camera connectivity first
        if not self.ping_camera():
            self._logger.error(f"Unable to reach A8 mini at {self.camera_ip}")
            sys.exit(1)

        command = [
            'ffmpeg',
            '-rtsp_transport', 'tcp',  # Use TCP for input
            '-i', self.input_url,
            '-c', 'copy',  # Copy the stream without re-encoding
            '-f', 'rtsp',
            self.output_url
        ]

        self._logger.info("FFmpeg command: " + " ".join(command))
        self._logger.info(f"Starting rebroadcast from {self.input_url} to {self.output_url}")
        
        try:
            self.process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=1,
                universal_newlines=False
            )

            # Start threads to handle stdout and stderr streams
            stdout_thread = threading.Thread(
                target=self._log_stream, 
                args=(self.process.stdout, "FFMPEG")
            )
            stderr_thread = threading.Thread(
                target=self._log_stream, 
                args=(self.process.stderr, "FFMPEG ERROR")
            )

            stdout_thread.daemon = True
            stderr_thread.daemon = True
            
            stdout_thread.start()
            stderr_thread.start()

            self._logger.info("FFmpeg process started successfully")
        except Exception as e:
            self._logger.error(f"Failed to start FFmpeg process: {str(e)}")
            sys.exit(1)

    def stop(self):
        """Stop the FFmpeg process"""
        if self.process:
            self._logger.info("Stopping FFmpeg process...")
            self.process.terminate()
            self.process.wait()
            self._logger.info("FFmpeg process stopped")

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    print("\nReceived signal to terminate...")
    if rebroadcaster:
        rebroadcaster.stop()
    sys.exit(0)

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='RTSP Stream Rebroadcaster')
    parser.add_argument('--input', default="rtsp://192.168.144.25:8554/main.264",
                        help='Input RTSP URL')
    parser.add_argument('--output-ip', default="127.0.0.1",
                        help='Output MediaMTX server IP')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug logging')
    
    args = parser.parse_args()

    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and start the rebroadcaster
    rebroadcaster = RTSPRebroadcaster(
        input_url=args.input,
        output_ip=args.output_ip,
        debug=args.debug
    )
    
    rebroadcaster.start()
    
    # Keep the main thread running
    try:
        rebroadcaster.process.wait()
    except KeyboardInterrupt:
        rebroadcaster.stop()
