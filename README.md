# Cercanías Schedule App

A simple Flutter app to show the train schedule for Cercanías (Renfe) from San Vicente Centre to Alicante.

<p align="center">
  <img src=".github/assets/WhatsApp%20Image%202025-04-20%20at%2015.48.46.jpeg" alt="Cercanías Schedule Screenshot 1" width="350" />
  <img src=".github/assets/WhatsApp%20Image%202025-04-20%20at%2015.48.46%20(1).jpeg" alt="Cercanías Schedule Screenshot 2" width="350" />
</p>

## Features
- Fetches schedules from the official Renfe API (no API key required)
- Select origin and destination stations from a searchable list
- Swap origin and destination with a single tap
- Pick travel date (today/tomorrow/next 7 days)
- Shows departure, arrival, duration, and train number
- Indicates accessible trains
- Filter to show/hide past trains for today
- Language selection: Spanish and English
- Save preferred language and default stations (persistent settings)
- Modern Material 3 design and smooth gradients
- Share your schedule as a screenshot (with image export)
- Skeleton loading screens for better UX
- Responsive UI for phones and tablets
- No ads, no tracking, open source

## Getting Started
1. Ensure you have Flutter installed: https://docs.flutter.dev/get-started/install
2. Run `flutter pub get` to install dependencies.
3. Run the app on your emulator or device:
   ```
   flutter run
   ```

## API Reference
Uses the endpoint: `https://horarios.renfe.com/cer/HorariosServlet` with POST/JSON body.

---

This project is for educational/demo purposes only.
