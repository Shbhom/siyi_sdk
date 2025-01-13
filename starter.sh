#!/bin/bash

# Virtual environment path
VENV_PATH="$PWD/serve"

# Define log function first
log() {
  local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
  echo "$message"
}

# Check for webhook URL environment variable
if [ -z "${ERROR_WEBHOOK_URL}" ]; then
    log "WARNING: ERROR_WEBHOOK_URL not set. Error logs will not be sent to webhook."
fi

# Define base log directory first and ensure it exists
BASE_LOG_DIR="$PWD/logs"
if [ ! -d "$BASE_LOG_DIR" ]; then
    mkdir -p "$BASE_LOG_DIR"
    log "Created base log directory at: $BASE_LOG_DIR"
fi

# Get current timestamp for log directories
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Define and create specific log directories
STREAM_LOG_DIR="$BASE_LOG_DIR/stream/$TIMESTAMP"
SERVER_LOG_DIR="$BASE_LOG_DIR/server/$TIMESTAMP"
STARTER_LOG_DIR="$BASE_LOG_DIR/starter/$TIMESTAMP"
MAVPROXY_LOG_DIR="$BASE_LOG_DIR/mavproxy/$TIMESTAMP"

# Create all required log directories
mkdir -p "$STREAM_LOG_DIR"
mkdir -p "$SERVER_LOG_DIR"
mkdir -p "$STARTER_LOG_DIR"
mkdir -p "$MAVPROXY_LOG_DIR"

log "Created log directories for timestamp: $TIMESTAMP"

# Set up logging for starter script
exec 1> >(tee -a "$STARTER_LOG_DIR/starter.log")
exec 2> >(tee -a "$STARTER_LOG_DIR/starter.error.log")

log() {
  local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
  echo "$message"
}

log "Starting Tailscale setup script."

# Function to check internet connectivity
check_internet() {
  log "Checking internet connection..."
  if ping -c 3 8.8.8.8 &> /dev/null; then
    log "Internet connection available."
  else
    log "Internet connection is not available. Exiting."
    exit 1
  fi
}

# Function to check if Tailscale is installed
check_tailscale_installed() {
  log "Checking if Tailscale is installed..."
  if ! command -v tailscale &> /dev/null; then
    log "Tailscale is not installed. Installing..."
    curl -fsSL https://tailscale.com/install.sh | sudo bash
    if [ $? -ne 0 ]; then
      log "Failed to install Tailscale. Exiting."
      exit 1
    fi
    log "Tailscale installed successfully."
  else
    log "Tailscale is already installed."
  fi
}

# Function to check if Tailscale service is running
check_tailscale_service() {
  log "Checking if Tailscale service is running..."
  if ! systemctl is-active --quiet tailscaled; then
    log "Tailscale service is not running. Starting service..."
    sudo systemctl start tailscaled
    if [ $? -ne 0 ]; then
      log "Failed to start Tailscale service. Exiting."
      exit 1
    fi
    log "Tailscale service started successfully."
  else
    log "Tailscale service is already running."
  fi
}

# Function to authenticate Tailscale
authenticate_tailscale() {
  log "Authenticating Tailscale..."
  AUTH_KEY="tskey-auth-kFpCSTWccr11CNTRL-nUiRPdPJeNTTJfnSuidFPTPm4G1HqBWN"
  sudo tailscale up --authkey "$AUTH_KEY" --advertise-tags="tag:OMC-5G"
  if [ $? -ne 0 ]; then
    log "Failed to authenticate Tailscale. Exiting."
    exit 1
  fi
  log "Tailscale authenticated successfully with tag OMC-5G."
}

# Function to find the VM's IP
find_vm_ip() {
  VM_NAME="dabaa"
  log "Looking for VM with name: $VM_NAME..."
  VM_IP=$(tailscale status | grep "$VM_NAME" | awk '{print $1}')
  if [ -z "$VM_IP" ]; then
    log "No device found with the name $VM_NAME on the network. Need to authenticate."
    return 1
  fi
  log "Found VM: $VM_NAME with IP: $VM_IP"
  return 0
}

check_rtsp_server() {
    log "Checking RTSP server availability..."
    RTSP_URL="rtsp://192.168.144.25:8554/main.264"
    CAMERA_IP="192.168.144.25"
    
    # First check if camera is pingable
    log "Pinging camera at $CAMERA_IP..."
    if ! ping -c 3 $CAMERA_IP &> /dev/null; then
        log "Camera is not responding to ping at $CAMERA_IP. Exiting."
        exit 1
    fi
    log "Camera is responding to ping."
    
    # Wait for camera to fully initialize
    log "Waiting for camera to initialize..."
    sleep 5
}

# Function to check virtual environment
check_venv() {
    log "Checking virtual environment..."
    if [ ! -d "$VENV_PATH" ]; then
        log "Virtual environment not found at $VENV_PATH. Exiting."
        exit 1
    fi
    if [ ! -f "$VENV_PATH/bin/activate" ]; then
        log "Virtual environment appears to be corrupted (no activate script). Exiting."
        exit 1
    fi
    log "Virtual environment found."
}

# Function to start MAVProxy with retries
start_mavproxy() {
    log "Starting MAVProxy..."
    MAX_RETRIES=3
    RETRY_COUNT=0
    
    # Configure MAVProxy command based on environment
    #if [ "$RUNNING_ENV" = "prod" ]; then
    #    MAVPROXY_CMD="mavproxy.py --master=/dev/ttyACM0 \
    #        --out=127.0.0.1:14550 \
    #        --out=127.0.0.1:14551 \
    #        --out=127.0.0.1:14552"
    #elif [ "$RUNNING_ENV" = "dev" ]; then
    MAVPROXY_CMD="mavproxy.py --master=tcp:127.0.0.1:5760 \
            --out=127.0.0.1:14550"
    
    #else
    #    log "Error: RUNNING_ENV must be set to 'prod' or 'dev'"
    #    exit 1
    #fi
    
    #while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        #log "Starting MAVProxy attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"
        
        # Start MAVProxy with logging
        $MAVPROXY_CMD > "$MAVPROXY_LOG_DIR/mavproxy.log" 2>&1 &
        MAVPROXY_PID=$!
        echo $MAVPROXY_PID > "$MAVPROXY_LOG_DIR/mavproxy.pid"
        
        # Wait for MAVProxy to initialize
        #sleep 15
        
        ## Check for multiple success indicators in the log
        #if grep -q "Detected vehicle" "$MAVPROXY_LOG_DIR/mavproxy.log" && \
        #   grep -q "online system" "$MAVPROXY_LOG_DIR/mavproxy.log" && \
        #   grep -q "ArduCopter" "$MAVPROXY_LOG_DIR/mavproxy.log"; then
        #    log "MAVProxy started successfully - vehicle detected and connected"
        #    return 0
        #else
        #    log "MAVProxy failed to establish connection"
        #    kill $MAVPROXY_PID 2>/dev/null
        #    ((RETRY_COUNT++))
        #    sleep 2
        #fi
    #done
    
    log "Failed to start MAVProxy after $MAX_RETRIES attempts"
    cleanup "mavproxy"
    return 1
}

start_services() {
    log "Starting stream rebroadcaster and API server..."
    
    # Start stream.py with logging
    python3 stream.py --debug > "$STREAM_LOG_DIR/stream.log" 2>&1 &
    STREAM_PID=$!
    log "Stream rebroadcaster started with PID: $STREAM_PID"
    
    # Start api_server.py with logging using virtual environment
    log "Starting API server with virtual environment..."
    source "$VENV_PATH/bin/activate"
    
    # Add retry logic for API server
    MAX_RETRIES=3
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        PORT=5000 python3 api_server.py > "$SERVER_LOG_DIR/api_server.log" 2>&1 &
        API_PID=$!
        
        # Wait for API server to start
        sleep 5
        
        # Check if API is responding
        if curl -s http://localhost:5000/docs > /dev/null; then
            log "API server started successfully with PID: $API_PID"
            break
        else
            log "API server failed to start, attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"
            kill $API_PID 2>/dev/null
            ((RETRY_COUNT++))
            sleep 2
        fi
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log "Failed to start API server after $MAX_RETRIES attempts"
        cleanup "server"
        exit 1
    fi
    
    deactivate
    
    # Save PIDs for cleanup
    echo $STREAM_PID > "$STREAM_LOG_DIR/stream.pid"
    echo $API_PID > "$SERVER_LOG_DIR/api_server.pid"
}

# Function to send logs to webhook
send_logs_to_webhook() {
    local log_file=$1
    local service_name=$2
    
    if [ -z "${ERROR_WEBHOOK_URL}" ]; then
        return
    fi
    
    if [ -f "$log_file" ]; then
        log "Sending $service_name logs to webhook..."
        
        # Create JSON payload with log content
        local log_content=$(cat "$log_file" | sed 's/"/\\"/g' | tr '\n' ' ')
        local payload="{\"service\": \"$service_name\", \"timestamp\": \"$TIMESTAMP\", \"logs\": \"$log_content\"}"
        
        # Send to webhook
        curl -s -X POST "${ERROR_WEBHOOK_URL}" \
             -H "Content-Type: application/json" \
             -d "$payload" > /dev/null
        
        if [ $? -eq 0 ]; then
            log "Logs sent successfully to webhook"
        else
            log "Failed to send logs to webhook"
        fi
    else
        log "Log file not found: $log_file"
    fi
}

cleanup() {
    log "Cleaning up processes..."
    local failed_service=$1
    local failed_log=""
    
    # Kill MAVProxy if running
    if [ -f "$MAVPROXY_LOG_DIR/mavproxy.pid" ]; then
        MAVPROXY_PID=$(cat "$MAVPROXY_LOG_DIR/mavproxy.pid")
        kill $MAVPROXY_PID 2>/dev/null
        log "Stopped MAVProxy process (PID: $MAVPROXY_PID)"
    fi
    
    # Kill SITL if running in dev mode
    if [ "$RUNNING_ENV" = "dev" ] && [ -f "$MAVPROXY_LOG_DIR/sitl.pid" ]; then
        SITL_PID=$(cat "$MAVPROXY_LOG_DIR/sitl.pid")
        kill $SITL_PID 2>/dev/null
        log "Stopped SITL process (PID: $SITL_PID)"
    fi
    
    # Kill stream.py if running
    if [ -f "$STREAM_LOG_DIR/stream.pid" ]; then
        STREAM_PID=$(cat "$STREAM_LOG_DIR/stream.pid")
        kill $STREAM_PID 2>/dev/null
        log "Stopped stream process (PID: $STREAM_PID)"
    fi
    
    # Kill api_server.py if running
    if [ -f "$SERVER_LOG_DIR/api_server.pid" ]; then
        API_PID=$(cat "$SERVER_LOG_DIR/api_server.pid")
        kill $API_PID 2>/dev/null
        log "Stopped API server process (PID: $API_PID)"
    fi
    
    # If a service failed, show its log file path and send logs to webhook
    if [ ! -z "$failed_service" ]; then
        case "$failed_service" in
            "stream")
                failed_log="$STREAM_LOG_DIR/stream.log"
                send_logs_to_webhook "$failed_log" "stream"
                ;;
            "server")
                failed_log="$SERVER_LOG_DIR/api_server.log"
                send_logs_to_webhook "$failed_log" "server"
                ;;
            "mavproxy")
                failed_log="$MAVPROXY_LOG_DIR/mavproxy.log"
                send_logs_to_webhook "$failed_log" "mavproxy"
                ;;
        esac
        log "Service failed. Check logs at: $failed_log"
        log "Starter script logs available at: $STARTER_LOG_DIR"
        
        # Also send starter script logs
        send_logs_to_webhook "$STARTER_LOG_DIR/starter.log" "starter"
    fi
}

# Set up trap for cleanup on script exit
trap cleanup EXIT

# Main execution
log "Executing setup steps..."

check_internet
check_venv
#check_tailscale_installed
#check_tailscale_service
# Try to find VM first, authenticate only if needed
#if ! find_vm_ip; then
#  log "Authenticating Tailscale as VM was not found..."
#  authenticate_tailscale
#  # Try finding VM again after authentication
#  if ! find_vm_ip; then
#    log "Still cannot find VM after authentication. Exiting."
#    exit 1
#  fi
#fi
#check_rtsp_server

# Start MAVProxy
if ! start_mavproxy; then
    log "Failed to start MAVProxy. Exiting."
    exit 1
fi

#start_services

#log "All services started. Logs are available in:"
#log "Starter logs: $STARTER_LOG_DIR"
#log "Stream logs: $STREAM_LOG_DIR"
#log "Server logs: $SERVER_LOG_DIR"
#log "API Documentation: http://localhost:5000/docs"

# Keep the script running and monitor child processes
#while true; do
#    if ! kill -0 $STREAM_PID 2>/dev/null; then
#        log "Stream process died unexpectedly!"
#        cleanup "stream"
#        exit 1
#    fi
#    if ! kill -0 $API_PID 2>/dev/null; then
#        log "API server died unexpectedly!"
#        cleanup "server"
#        exit 1
#    fi
#    if ! kill -0 $MAVPROXY_PID 2>/dev/null; then
#        log "MAVProxy died unexpectedly!"
#        cleanup "mavproxy"
#        exit 1
#    fi
#    sleep 5
#done
