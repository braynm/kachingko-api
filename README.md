# Kachingko API

Backend API for Kachingko - Handles credit card statement parsing, transaction categorization, and data management.

## Features

- **PDF Statement Parsing** — Extract transactions from RCBC and EastWest Bank statements
- **Transaction Processing** — Automatic categorization with machine learning
- **Data Management** — Secure storage and retrieval of financial data
- **Budget API** — Set limits and track spending across categories
- **Analytics Engine** — Generate spending insights and trend analysis
- **RESTful API** — Clean, documented endpoints for frontend integration

## Tech Stack

- [Elixir](https://elixir-lang.org) — Functional programming language
- [Phoenix](https://phoenixframework.org) — Web framework
- [Ecto](https://hexdocs.pm/ecto/Ecto.html) — Database wrapper and query generator
- [PostgreSQL](https://postgresql.org) — Primary database
- [PdfPlumber](https://github.com/jsvine/pdfplumber) and [PikePDF](https://github.com/pikepdf/pikepdf) — PDF processing (via Erlport)

## Supported Banks

- [x] RCBC
- [x] EastWest
- [ ] BPI
- [ ] BDO
- [ ] Metrobank

## Installing Elixir and Phoenix with asdf

We recommend using [asdf](https://asdf-vm.com/) to manage Elixir and Erlang versions. This ensures consistent versions across development environments.

### Install asdf

**macOS:**
```bash
# Using Homebrew
brew install asdf

# Add to your shell profile (~/.zshrc or ~/.bash_profile)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc
```

**Ubuntu/Debian:**
```bash
# Clone asdf repository
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1

# Add to shell profile
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
source ~/.bashrc
```

### Install Erlang and Elixir

```bash
# Add Erlang and Elixir plugins
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install Erlang (required for Elixir)
asdf install erlang 28.0
asdf global erlang 28.0

# Install Elixir
asdf install elixir 1.18.4-otp-28
asdf global elixir 1.18.4-otp-28

# Verify installation
elixir --version
```

### Install Phoenix

```bash
# Install Phoenix framework
mix local.hex --force
mix archive.install hex phx_new --force

# Verify Phoenix installation
mix phx.new --version
```

### Install Python

The project requires Python 3.11+ for PDF processing components.

```bash
# Add Python plugin
asdf plugin add python

# Install Python
asdf install python 3.13.0
asdf global python 3.13.0

# Verify installation
python --version

# Install required Python packages
pip install pdfplumber==0.11.6 pikepdf==9.11.0
```

### Optional: Use .tool-versions file

Create a `.tool-versions` file in your project root to lock versions:

```bash
# .tool-versions
elixir 1.18.4-otp-28
erlang 28.0
```

Then run:
```bash
asdf install  # Installs versions specified in .tool-versions
```

## Quick Start

### Prerequisites

- Elixir 1.18.4+
- Phoenix 1.8.1+
- PostgreSQL 14+
- Python 3.11+ (for PDF processing)

### Environment Variables

Create `.env`:

```bash
export DATABASE_URL=
export PORT=8888
export SECRET_KEY_BASE=
export CLOAK_KEY=
export GUARDIAN_SECRET_KEY=

# generate SECRET_KEY_BASE and GUARDIAN_SECRET_KEY
mix phx.gen.secret

# generate CLOAK_KEY for TXN details encryption
iex> :crypto.strong_rand_bytes(32) |> Base.encode64()

```

### Installation

```bash
# Clone repository
git clone https://github.com/braynm/kachingko-api.git
cd kachingko-api

# Install dependencies
mix deps.get

# Load environment variables
source .env

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

API will be available at http://localhost:8888

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
├── application.ex
├── authentication
│   ├── application
│   ├── authentication.ex
│   ├── domain
│   └── infra
├── charts
│   ├── application
│   ├── charts.ex
│   ├── domain
│   └── infra
├── encrypted_types.ex
├── mailer.ex
├── repo.ex
├── shared
│   ├── bank_formatter.ex
│   ├── errors.ex
│   ├── pagination
│   ├── result.ex
│   └── types.ex
├── statements
│   ├── application
│   ├── domain
│   ├── infra
│   └── statements.ex
├── utils
│   ├── date_timezone.ex
│   └── validator_formatter.ex
└── vault.ex
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

## Security Considerations for Self-Hosted Deployments and Localhost Setup

### Data Protection
- **Disk Encryption**: Enable FileVault (macOS), BitLocker (Windows), or LUKS (Linux) to protect database files at rest
- **Database Access**: Secure your PostgreSQL instance with strong passwords and network restrictions
- **Backups**: If backing up to cloud storage, consider encrypting dump files before upload

### Production Deployment Notes
- Use HTTPS/TLS for all connections
- Implement network firewalls
- Regular security updates for OS and PostgreSQL
- Consider application-level encryption if handling highly sensitive data

For enterprise security features (2FA, audit trails, advanced monitoring), consider our hosted SaaS solution.

## Contributing

Contributions are welcome! Please read our [contributing guide](https://github.com/yourusername/kachingko-docs/blob/main/CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'feat: add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## Related Repositories

- **Web App**: [kachingko-web](https://github.com/braynm/kachingko-web) - Frontend application
- **Docs**: [kachingko-docs](https://github.com/braynm/kachingko) - Documentation

## License

This project is licensed under the Apache 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [kachingko-docs](https://github.com/braynm/kachingko-api)
- **Discussions**: [GitHub Discussions](https://github.com/braynm/kachingko-api/discussions)
