# UMT RideShare

UMT RideShare is a campus carpooling app that helps passengers find drivers travelling along a similar route. It uses FastAPI and MySQL for the backend, with HTML, CSS, Bootstrap, and JavaScript for the interface.

Drivers can add a car, choose pickup and destination points on a map, and offer rides with a date, seat count, and price. Passengers can search by their own pickup and destination, view matching driver routes, and reserve a seat. Both sides can manage their rides or bookings.

The map uses Geoapify for place search, map tiles, and driving routes. A ride matches when the passenger's pickup and destination are near the driver's route in the right travel order.

Passengers can pay the driver in cash or use Stripe Checkout to choose an available online payment method, such as card or FPX.
