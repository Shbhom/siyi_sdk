# SIYI A8 Mini Camera API Documentation

## Overview
RESTful API for controlling the SIYI A8 mini camera's gimbal and zoom functions.

## Base URL
`http://localhost:5000`

## API Endpoints

### 1. Change Gimbal Angles
Control the camera's yaw and pitch angles.

**Endpoint:** `POST /change_angle`

**Request Body:**
```json
{
    "yaw": float,    // Optional: -135° to +135°
    "pitch": float   // Optional: -90° to +25°
}
```

**Example Requests:**
```bash
# Change both angles
curl -X POST "http://localhost:5000/change_angle" \
     -H "Content-Type: application/json" \
     -d '{"yaw": 15.0, "pitch": -20.0}'

# Change only yaw
curl -X POST "http://localhost:5000/change_angle" \
     -H "Content-Type: application/json" \
     -d '{"yaw": 30.0}'

# Change only pitch
curl -X POST "http://localhost:5000/change_angle" \
     -H "Content-Type: application/json" \
     -d '{"pitch": -45.0}'
```

**Success Response:**
```json
{
    "success": true,
    "current_angles": {
        "yaw": 15.0,
        "pitch": -20.0
    },
    "actual_attitude": {
        "yaw": 15.2,
        "pitch": -19.8,
        "roll": 0.0
    }
}
```

**Error Response:**
```json
{
    "detail": "Failed to change angles: Connection error"
}
```

### 2. Center Gimbal
Reset gimbal to center position (0°, 0°).

**Endpoint:** `POST /center`

**Example Request:**
```bash
curl -X POST "http://localhost:5000/center"
```

**Success Response:**
```json
{
    "success": true,
    "current_angles": {
        "yaw": 0.0,
        "pitch": 0.0
    },
    "actual_attitude": {
        "yaw": 0.0,
        "pitch": 0.0,
        "roll": 0.0
    }
}
```

**Error Response:**
```json
{
    "detail": "Failed to center gimbal: Connection error"
}
```

### 3. Change Zoom Level
Adjust camera zoom level.

**Endpoint:** `POST /zoom`

**Request Body:**
```json
{
    "zoom": float  // 1.0 to 6.0
}
```

**Example Requests:**
```bash
# Set to 3x zoom
curl -X POST "http://localhost:5000/zoom" \
     -H "Content-Type: application/json" \
     -d '{"zoom": 3.0}'

# Set to maximum zoom
curl -X POST "http://localhost:5000/zoom" \
     -H "Content-Type: application/json" \
     -d '{"zoom": 6.0}'

# Reset to no zoom
curl -X POST "http://localhost:5000/zoom" \
     -H "Content-Type: application/json" \
     -d '{"zoom": 1.0}'
```

**Success Response:**
```json
{
    "success": true,
    "current_zoom": 3.0
}
```

**Error Response:**
```json
{
    "detail": "Failed to set A8 mini zoom: Invalid zoom level"
}
```

## Error Handling

All endpoints may return the following error status codes:

- `400 Bad Request`: Invalid parameters
- `500 Internal Server Error`: Server or camera communication error

Error responses follow this format:
```json
{
    "detail": "Error message describing what went wrong"
}
```

## Limits and Constraints

### Gimbal Angles
- **Yaw**: -135° to +135°
- **Pitch**: -90° to +25°

### Zoom
- **Minimum**: 1.0 (no zoom)
- **Maximum**: 6.0 (full zoom)

## Interactive Documentation

### Swagger UI
Access interactive API documentation and testing interface:
```
http://localhost:5000/docs
```

### ReDoc
Access alternative API documentation:
```
http://localhost:5000/redoc
```

## Notes
- All angle values are in degrees
- Zoom values are multiplicative (1.0 = no zoom)
- The API maintains the last set angles/zoom between requests
- Center operation does not affect zoom level
- All responses include actual camera attitude for verification

## Example Usage Sequence

```bash
# 1. Center the gimbal
curl -X POST "http://localhost:5000/center"

# 2. Set initial position
curl -X POST "http://localhost:5000/change_angle" \
     -H "Content-Type: application/json" \
     -d '{"yaw": 45.0, "pitch": -30.0}'

# 3. Adjust zoom
curl -X POST "http://localhost:5000/zoom" \
     -H "Content-Type: application/json" \
     -d '{"zoom": 2.5}'