# Kachingko API

Backend API for Kachingko - Handles credit card statement parsing, transaction categorization, and data management.

## Features

- **PDF Statement Parsing** — Extract transactions from RCBC and EastWest Bank statements
- **Transaction Processing** — Automatic categorization with machine learning
- **Data Management** — Secure storage and retrieval of financial data
- **Budget API** — Set limits and track spending across categories
- **Analytics Engine** — Generate spending insights and trend analysis
- **RESTful API** — Clean, documented endpoints for frontend integration
- **Real-time Updates** — WebSocket support for live data updates

## Tech Stack

- [Elixir](https://elixir-lang.org) — Functional programming language
- [Phoenix](https://phoenixframework.org) — Web framework
- [Ecto](https://hexdocs.pm/ecto/Ecto.html) — Database wrapper and query generator
- [PostgreSQL](https://postgresql.org) — Primary database
- [PyMuPDF](https://pymupdf.readthedocs.io) — PDF processing (via Erlport)

## Supported Banks

- [x] RCBC
- [x] EastWest
- [ ] BPI
- [ ] BDO
- [ ] Metrobank

## Quick Start

### Prerequisites

- Elixir 1.15+
- Phoenix 1.7+
- PostgreSQL 14+
- Python 3.8+ (for PDF processing)

### Installation

```bash
# Clone repository
git clone https://github.com/braynm/kachingko-api.git
cd kachingko-api

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

API will be available at http://localhost:4000

## Environment Variables

Create `.env`:

```bash
DATABASE_URL=postgres://user:pass@localhost/kachingko_dev
SECRET_KEY_BASE=your_secret_key_here
PHX_HOST=localhost
PORT=4000
```

## Available Commands

```bash
mix phx.server       # Start Phoenix server
mix test             # Run tests
mix format           # Format code
mix credo            # Lint code
mix phx.routes       # Show all routes
mix ecto.migrate     # Run database migrations
mix ecto.reset       # Reset database
```

## API Endpoints

### Authentication
```
POST   /api/auth/login
POST   /api/auth/register
DELETE /api/auth/logout
```

### Transactions
```
GET    /api/transactions           # List transactions
POST   /api/transactions/upload    # Upload statement
PUT    /api/transactions/:id       # Update transaction
DELETE /api/transactions/:id       # Delete transaction
```

### Categories
```
GET    /api/categories             # List categories
POST   /api/categories             # Create category
PUT    /api/categories/:id         # Update category
```

### Analytics
```
GET    /api/analytics/spending     # Spending analysis
GET    /api/analytics/trends       # Trend analysis
GET    /api/analytics/budgets      # Budget overview
```

Full API documentation available at `/api/docs` when running the server.

## Project Structure

```
lib/
├── kachingko/              # Core business logic
│   ├── accounts/           # User management
│   ├── transactions/       # Transaction processing
│   ├── categories/         # Category management
│   ├── analytics/          # Analytics engine
│   └── parsers/           # PDF parsing logic
├── kachingko_web/         # Phoenix web layer
│   ├── controllers/       # API controllers
│   ├── views/            # JSON views
│   └── router.ex         # Route definitions
└── kachingko/
    ├── repo.ex           # Database interface
    └── application.ex    # Application supervisor
```

## Development

### Database Migrations

```bash
# Create migration
mix ecto.gen.migration add_new_field

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback
```

### Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/kachingko/transactions_test.exs

# Run with coverage
mix test --cover
```

### Adding New Bank Parser

1. Create parser module in `lib/kachingko/parsers/`
2. Implement `StatementParser` behaviour
3. Add bank configuration to `config/config.exs`
4. Write tests in `test/kachingko/parsers/`

## Deployment

### Using Docker

TODO: add `Docker` setup

### Using releases

```bash
# Set environment
export MIX_ENV=prod

# Install dependencies and compile
mix deps.get --only prod
mix compile

# Build release
mix release

# Run release
_build/prod/rel/kachingko/bin/kachingko start
```

## Contributing

Contributions are welcome! Please read our [contributing guide](https://github.com/yourusername/kachingko-docs/blob/main/CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Related Repositories

- **Web App**: [kachingko-web](https://github.com/braynm/kachingko-web) - Frontend application
- **Docs**: [kachingko-docs](https://github.com/braynm/kachingko) - Documentation

## License

This project is licensed under the Apache 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [kachingko-docs](https://github.com/yourusername/kachingko-docs)
- **Issues**: [GitHub Issues](https://github.com/yourusername/kachingko-api/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/kachingko-api/discussions)
