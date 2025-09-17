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
export DATABASE_URL=
export PORT=8888
export SECRET_KEY_BASE=
export CLOAK_KEY=
export GUARDIAN_SECRET_KEY=

# generate SECRET_KEY_BASE and GUARDIAN_SECRET_KEY
mix phx.gen.secret

# generate CLOAK_KEY
iex> :crypto.strong_rand_bytes(32) |> Base.encode64()

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

## Project Structure

```
.
├── README.md
├── lib
│   ├── kachingko_api
│   │   ├── application.ex
│   │   ├── authentication
│   │   ├── charts
│   │   ├── encrypted_types.ex
│   │   ├── mailer.ex
│   │   ├── repo.ex
│   │   ├── shared
│   │   ├── statements
│   │   ├── utils
│   │   └── vault.ex
│   ├── kachingko_api.ex
        ├── application.ex
        ├── authentication
        ├── charts
        ├── encrypted_types.ex
        ├── mailer.ex
        ├── repo.ex
        ├── shared
        ├── statements
        ├── utils
        └── vault.ex
│   ├── kachingko_api_web
│   │   ├── auth_error_handler.ex
│   │   ├── components
│   │   ├── controllers
│   │   ├── endpoint.ex
│   │   ├── gettext.ex
│   │   ├── guardian.ex
│   │   ├── plugs
│   │   ├── router.ex
│   │   └── telemetry.ex
│   └── kachingko_api_web.ex
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

1. Create parser module in `lib/kachingko_api/statements/infra/parsers/`
2. Implement `BankParser` behaviour
3. Add bank configuration to `config/config.exs` inside `:supported_banks`
4. Write tests in `test/kachingko_api/statements/infra/parsers/`

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
_build/prod/rel/kachingko_api/bin/kachingko_api start
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

- **Documentation**: [kachingko-docs](https://github.com/braynm/kachingko-api)
- **Discussions**: [GitHub Discussions](https://github.com/braynm/kachingko-api/discussions)
