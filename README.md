# Otter Drift API

[![codecov](https://codecov.io/github/dchapman1988/otter_drift_api/graph/badge.svg?token=FDSYVQQYMR)](https://codecov.io/github/dchapman1988/otter_drift_api)

Backend API server for **[Otter Drift](https://github.com/dchapman1988/otter_drift)**, a Flutter/Flame mobile game where players navigate as an otter to avoid logs, collect lilies and hearts, and compete for high scores.

## About

Otter Drift API is a Rails 8 JSON API that handles player authentication, game sessions, achievements, and leaderboards. Built with JWT authentication and fully documented with Swagger/OpenAPI via rswag.

## Tech Stack

- **Ruby**: 3.4.7
- **Rails**: 8.1.1 (API mode)
- **Database**: PostgreSQL
- **Authentication**: Devise + JWT (devise-jwt)
- **Testing**: RSpec + FactoryBot + Faker + Shoulda Matchers
- **API Documentation**: rswag (Swagger/OpenAPI)
- **Web Server**: Puma

## Prerequisites

- Ruby 3.4.7
- PostgreSQL
- Bundler

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd otter_drift_api
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

Configure your PostgreSQL connection via environment variables or accept the defaults:

```bash
# Optional: Set database connection parameters
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGPASSWORD=your_password
```

Create and setup databases:

```bash
# Create all databases (primary, cache, queue, cable)
bundle exec rails db:create

# Run migrations for all databases
bundle exec rails db:migrate

# Seed the database (optional)
bundle exec rails db:seed
```

### 4. Start the Server

For local development with Flutter mobile app, bind to `0.0.0.0` to allow connections from the mobile device:

```bash
rails server -b 0.0.0.0
```

The API will be available at `http://0.0.0.0:3000`

For local development only (desktop browser/Postman):

```bash
rails server
```

## API Documentation

Interactive API documentation is available via Swagger UI once the server is running:

```
http://localhost:3000/api-docs
```

### Generating API Documentation

The API documentation is generated from RSpec request specs using rswag:

```bash
# Generate swagger.json from specs
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Or run specs and generate docs in one command
bundle exec rspec
```

## Testing

This project uses RSpec for testing with the following tools:

- **RSpec**: Test framework
- **FactoryBot**: Test data factories
- **Faker**: Realistic fake data generation
- **Shoulda Matchers**: Clean one-liner tests for common Rails functionality
- **rswag-specs**: API documentation testing

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Test Files

```bash
bundle exec rspec spec/models/player_spec.rb
bundle exec rspec spec/requests/api/v1/game_sessions_spec.rb
```

### Run with Coverage

```bash
COVERAGE=true bundle exec rspec
```

## API Endpoints

### Authentication

#### Player Registration
```
POST /players
```

#### Player Login
```
POST /players/sign_in
```

#### Player Logout
```
DELETE /players/sign_out
```

### Client Authentication

```
POST /api/v1/auth/login
```

### Player Profile & Stats

```
GET    /api/v1/players/profile
PATCH  /api/v1/players/profile
GET    /api/v1/players/stats
```

### Game Sessions

```
POST   /api/v1/game_sessions
GET    /api/v1/game_sessions
```

### Achievements

```
GET    /api/v1/achievements
GET    /api/v1/players/:username/achievements
```

### Game History

```
GET    /api/v1/players/:username/game-history
```

Retrieves complete game history for a player, including:
- All completed game sessions ordered by most recent
- Game statistics (lilies collected, obstacles avoided, hearts collected, max speed)
- High scores for each game
- Achievements earned during each game
- Pagination support with `limit` and `offset` query parameters

**Query Parameters:**
- `limit`: Number of games to return (default: 20, max: 100)
- `offset`: Offset for pagination (default: 0)

**Example:**
```bash
curl http://localhost:3000/api/v1/players/testplayer/game-history?limit=10&offset=0
```

### Leaderboards

```
GET    /api/v1/leaderboard
```

## Database Architecture

The application uses Rails 8's multi-database configuration:

- **Primary**: Main application data (players, game sessions, achievements, etc.)
- **Cache**: Solid Cache storage
- **Queue**: Solid Queue job processing
- **Cable**: Solid Cable for Action Cable

## Models

- `Player`: User accounts with Devise authentication
- `PlayerProfile`: Extended player information
- `GameSession`: Individual game play sessions
- `HighScore`: Player high scores
- `Achievement`: Available achievements
- `EarnedAchievement`: Player-earned achievements
- `JwtDenylist`: Revoked JWT tokens

## Development

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix offenses
bundle exec rubocop -a
```

### Security Scanning

```bash
# Run Brakeman security scanner
bundle exec brakeman
```

### N+1 Query Detection

This project uses Bullet to detect N+1 queries and other performance issues.

**In Development:**
- Bullet is enabled and will log warnings to the console and Rails logger
- Check `log/bullet.log` for detailed reports
- Warnings appear in the terminal when N+1 queries are detected

**In Tests:**
- Bullet is configured to raise errors if N+1 queries are detected
- Tests will fail if performance issues are introduced
- This ensures optimal database queries are maintained

**Common Bullet Notifications:**
- **N+1 Query**: Use eager loading (`.includes()`)
- **Unused Eager Loading**: Remove unnecessary `.includes()`
- **Counter Cache**: Consider adding counter cache columns for frequently counted associations

### Console

```bash
bundle exec rails console
```

## Deployment

Deploy using your preferred method (Heroku, DigitalOcean, AWS, etc.). Ensure environment variables are properly configured in your deployment environment.

## Environment Variables

Key environment variables:

```bash
# Database
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGPASSWORD=your_password
PGDATABASE=otter_drift_api_development

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5

# JWT Secret (auto-generated by devise-jwt)
DEVISE_JWT_SECRET_KEY=your_secret_key
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is **not open source**.
All rights are reserved by the author.


## Support

For issues and questions, please open an issue in the repository.
