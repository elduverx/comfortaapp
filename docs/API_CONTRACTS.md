# API Contracts

## Trip Booking API

### Create Trip
- POST `/api/trips`
- Request body:
  - `pickupLocation: Location?`
  - `destinationLocation: Location`
  - `vehicleType: VehicleType`
  - `scheduledAt: ISO8601?`
  - `notes: string?`
- Response:
  - `tripId: string`
  - `estimatedFare: number`
  - `estimatedDuration: number`

### Trip Detail
- GET `/api/trips/{id}`
- Response:
  - `trip: Trip`

## Auth API

### Apple Sign In
- POST `/api/auth/login/apple`
- Request body:
  - `identityToken: string`
  - `authorizationCode: string?`
  - `user: { name?: { firstName?: string, lastName?: string }, email?: string }?`
- Response:
  - `accessToken: string`
  - `refreshToken: string`
  - `user: APIUser`

### Refresh Token
- POST `/api/auth/refresh`
- Request body:
  - `refreshToken: string`

### Logout
- POST `/api/auth/logout`
- Request body:
  - `refreshToken: string?`
  - `deviceToken: string?`

## Device Tokens

### Register Token
- POST `/api/device-tokens`
- Request body:
  - `userId: string`
  - `deviceToken: string`
  - `platform: "ios"`
  - `appVersion: string`
  - `deviceModel: string`
  - `osVersion: string`
  - `timestamp: number`

## Admin API

### Admin Trips
- GET `/api/admin/viajes`
- Response:
  - `trips: [AdminTrip]`

### Admin Users
- GET `/api/admin/users`
- Response:
  - `users: [AdminUser]`
