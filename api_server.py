#!/usr/bin/env python3
"""
FastAPI server for controlling SIYI A8 mini camera gimbal angles
"""
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Dict, Any
import sys
import os
from typing import Optional
from cameras import A8MINI  # Import A8 mini camera specs
from time import sleep
import uvicorn

# Add parent directory to path for siyi_sdk import
current = os.path.dirname(os.path.realpath(__file__))
parent_directory = os.path.dirname(current)
sys.path.append(parent_directory)

from siyi_sdk import SIYISDK

app = FastAPI(
    title="SiYi Camera Control API",
    description="API for controlling SiYi camera gimbal and zoom functions",
    version="1.0.0"
)

# Global camera instance
camera = None

class CameraAngle:
    def __init__(self):
        self.yaw = 0
        self.pitch = 0

    def add_yaw(self, dy):
        self.yaw += dy
        if self.yaw > 45:
            self.yaw = 45
        if self.yaw < -45:
            self.yaw = -45

    def add_pitch(self, dp):
        self.pitch += dp
        if self.pitch > 25:
            self.pitch = 25
        if self.pitch < -90:
            self.pitch = -90

    def zero_yaw(self):
        self.yaw = 0

    def zero_pitch(self):
        self.pitch = 0

# Global angle tracker
cam_angle = CameraAngle()

class AngleAdjustment(BaseModel):
    adjustment: float

class AngleRequest(BaseModel):
    yaw: Optional[float] = None
    pitch: Optional[float] = None

    class Config:
        schema_extra = {
            "example": {
                "yaw": 15.0,
                "pitch": -20.0
            }
        }

@app.on_event("startup")
async def startup_event():
    global camera
    camera = SIYISDK(server_ip="192.168.144.25", port=37260)
    if not camera.connect():
        raise Exception("Failed to connect to camera")
    camera.requestFollowMode()

@app.on_event("shutdown")
async def shutdown_event():
    global camera
    if camera:
        camera.disconnect()

@app.get("/status")
async def get_status():
    """
    Get current camera status including attitude and zoom level
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    return {
        "attitude": camera.getAttitude(),
        "zoom_level": camera.getZoomLevel()
    }

@app.post("/change_angle")
async def change_angle(angles: AngleRequest):
    """
    Change gimbal yaw and/or pitch angles
    
    - Provide either yaw, pitch, or both
    - Yaw range: -45° to +45°
    - Pitch range: -90° to +25°
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    # Update only provided angles
    if angles.yaw is not None:
        cam_angle.add_yaw(angles.yaw - cam_angle.yaw)  # Adjust to target angle
    
    if angles.pitch is not None:
        cam_angle.add_pitch(angles.pitch - cam_angle.pitch)  # Adjust to target angle
    
    # Send command to camera
    camera.setGimbalRotation(cam_angle.yaw, cam_angle.pitch)
    
    return {
        "success": True,
        "current_angles": {
            "yaw": cam_angle.yaw,
            "pitch": cam_angle.pitch
        },
        "current_attitude": camera.getAttitude()
    }

@app.post("/gimbal/pitch")
async def adjust_pitch(adjustment: AngleAdjustment):
    """
    Adjust camera pitch by specified degrees
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    cam_angle.add_pitch(adjustment.adjustment)
    camera.setGimbalRotation(cam_angle.yaw, cam_angle.pitch)
    
    return {
        "success": True,
        "current_attitude": camera.getAttitude()
    }

@app.post("/gimbal/yaw")
async def adjust_yaw(adjustment: AngleAdjustment):
    """
    Adjust camera yaw by specified degrees
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    cam_angle.add_yaw(adjustment.adjustment)
    camera.setGimbalRotation(cam_angle.yaw, cam_angle.pitch)
    
    return {
        "success": True,
        "current_attitude": camera.getAttitude()
    }

@app.post("/gimbal/center")
async def center_gimbal():
    """
    Reset gimbal to center position (zero pitch and yaw)
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    cam_angle.zero_yaw()
    cam_angle.zero_pitch()
    camera.setGimbalRotation(cam_angle.yaw, cam_angle.pitch)
    
    return {
        "success": True,
        "current_attitude": camera.getAttitude()
    }

@app.post("/zoom/in")
async def zoom_in():
    """
    Zoom in camera view
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    camera.requestZoomIn()
    sleep(0.5)
    camera.requestZoomHold()
    sleep(0.5)
    
    return {
        "success": True,
        "zoom_level": camera.getZoomLevel()
    }

@app.post("/zoom/out")
async def zoom_out():
    """
    Zoom out camera view
    """
    if not camera:
        raise HTTPException(status_code=503, detail="Camera not initialized")
    
    camera.requestZoomOut()
    sleep(0.5)
    camera.requestZoomHold()
    sleep(0.5)
    
    return {
        "success": True,
        "zoom_level": camera.getZoomLevel()
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000) 