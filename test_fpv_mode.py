"""
@file test_fpv_mode.py
@Description: This is a test script for using the ZR10 SDK Python implementation to set FPV mode
@Author: Mohamed Abdelkader
@Contact: mohamedashraf123@gmail.com
All rights reserved 2022
"""

from zr10_python import ZR10SDK

def test():
    cam = ZR10SDK(server_ip="192.168.144.25", port=37260)

    val = cam.setFPVMode()
    print("Setting FPV mode: ", val)

if __name__ == "__main__":
    test()