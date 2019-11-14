<img src="https://github.com/itggot-adrian-almetunsmeds/train-booking/workflows/Ruby%20tests%20-%20Push/badge.svg" alt="Build status">

# Train Booking
A digital platform where customers can book train tickets.


### Functionality

#### Non registered users
* Can <i>book trips</i> between two locations on a specific <i>service</i>
* Have the ability to book <i>multiple seats</i> on a single train
* Have the ability to <i>prefer specific seats</i> during booking
* Users can choose between <i>multiple tickets</i>. Tickets with different prices / points
* Can <i>register an account</i>

#### Registered users
* Same as Non registered users
* <i>Collect points</i> on bookings
* Signed-in users have the ability to <i>cancel their booking</i>

#### Administrator
* Administrators have the ability to <i>change points</i> of users and <i>cancel user bookings</i>
* See all bookings made to a specific service

### Description of entities

#### Registered users
* Have a name
* Have an email
* Have a password
* Have points
* Might have admin rights

#### Bookings
* Have a booking nr
* Have a booking time
* Have a user associated with it
* Have a total price sum
* Have seats associated with it

### Trains
* Are of a specific model
* Have a operational status
* Have a home location
* Are associated with services

### Train models
* Have a name
* Have a capacity
* Might have a cafe on board

### Seats
* Might be occupied

### Services
* Have a departure location
* Have a arrival location
* Have a departure time
* Have a arrival time
* Might have empty seats
* Are associated with a specific train
  
### Tickets
* Have a name
* Have a price
* Give points

### Stations
* Have a name
* Have platforms
