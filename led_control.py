import sys
from gpiozero import LED
from time import sleep

# Define GPIO pins for LEDs
GREEN_LED_PIN = 17  # GPIO 17 for green LED
RED_LED_PIN = 27    # GPIO 27 for red LED

# Initialize LEDs
green_led = LED(GREEN_LED_PIN)
red_led = LED(RED_LED_PIN)

def indicate_status(status, duration):
    if status == "pass":
        print(f"Green LED ON for {duration} seconds: Check Passed.")
        green_led.on()
        sleep(duration)  # Keep the green LED on for the specified duration
        green_led.off()

    elif status == "check":
        print(f"Green LED BLINKING for {duration} seconds: Check in Progress.")
        end_time = duration
        while end_time > 0:
            green_led.on()
            sleep(0.5)
            green_led.off()
            sleep(0.5)
            end_time -= 1

    elif status == "fail":
        print(f"Red LED BLINKING SLOWLY for {duration} seconds: Check Failed.")
        end_time = duration
        while end_time > 0:
            red_led.on()
            sleep(1)
            red_led.off()
            sleep(1)
            end_time -= 2

    else:
        print("Invalid status. Use 'pass', 'check', or 'fail'.")
        sys.exit(1)

if __name__ == "__main__":
    # Validate command-line arguments
    if len(sys.argv) != 3:
        print("Usage: python3 led_control.py <pass|check|fail> <duration_in_seconds>")
        sys.exit(1)

    # Read the arguments
    status = sys.argv[1].lower()
    try:
        duration = int(sys.argv[2])
    except ValueError:
        print("Duration must be an integer.")
        sys.exit(1)

    # Indicate the status
    indicate_status(status, duration)
