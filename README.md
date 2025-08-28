# MaxGallery - Secure Encrypted File Storage System

[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7.20+-orange.svg)](https://phoenixframework.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://postgresql.org/)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)

**MaxGallery** is a high-security file storage system built with Phoenix LiveView that provides end-to-end encryption for all files and metadata using AES-256-CTR encryption. The system ensures that encryption keys remain exclusively with the user, providing zero-knowledge storage architecture.

🌐 **Live Demo**: [www.exemple.com](https://www.exemple.com)

![Screenshot.png](https://i.imgur.com/4pW9wJa.png)

## ✨ Key Features

### 🔒 **Military-Grade Security**
- **AES-256-CTR Encryption**: Industry-standard encryption for all files and metadata
- **Zero-Knowledge Architecture**: Encryption keys never stored on server
- **Phantom Validation**: Built-in integrity checking and tamper detection
- **Secure Key Derivation**: SHA-256 hashing with cryptographically strong IVs

### 📁 **Advanced File Management**
- **Hierarchical Organization**: Unlimited nested groups and subgroups
- **Real-time Interface**: Phoenix LiveView for instant updates
- **Bulk Operations**: Move, copy, delete multiple files efficiently
- **ZIP Export/Import**: Preserve folder structure with encryption
- **File Chunking**: Efficient handling of large files

### 🚀 **Modern Architecture**
- **Phoenix LiveView**: Real-time web interface without JavaScript complexity
- **PostgreSQL Backend**: Reliable data persistence with ACID compliance
- **S3-Compatible Storage**: Scalable binary storage (BlackBlaze B2, AWS S3)
- **Fault-Tolerant**: Elixir's actor model for high availability
- **Docker Ready**: Containerized deployment with PostgreSQL

### 🛡️ **Enterprise Security Features**
- **User Authentication**: Secure password hashing with salt
- **Session Management**: Encrypted session handling
- **Storage Limits**: Configurable per-user storage quotas
- **Audit Trail**: Comprehensive logging and monitoring
- **Data Validation**: Multi-layer integrity checking

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│  Phoenix LiveView │───▶│  Context Layer  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Encryption Module│    │ PostgreSQL DB   │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ AES-256-CTR      │    │ S3 Storage      │
                       │ Cipher           │    │ (Encrypted)     │
                       └──────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Elixir** 1.14+ and **Erlang/OTP** 25+
- **PostgreSQL** 16+
- **Node.js** 18+ (for asset compilation)
- **Docker** (optional, for containerized database)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/MaxGallery.git
   cd MaxGallery
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Set up the database**
   ```bash
   # Option A: Using Docker (Recommended)
   docker-compose up -d postgres
   
   # Option B: Local PostgreSQL
   # Ensure PostgreSQL is running and configure config/dev.exs
   ```

4. **Configure the application**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your settings
   # DATABASE_URL, S3 credentials, etc.
   ```

5. **Set up the database schema**
   ```bash
   mix ecto.setup
   ```

6. **Install and build assets**
   ```bash
   mix assets.setup
   mix assets.build
   ```

7. **Start the server**
   ```bash
   mix phx.server
   ```

8. **Access the application**
   
   Open your browser and navigate to: **http://localhost:4000**

## 📋 System Requirements

### Development Environment
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 2GB free space
- **OS**: Linux, macOS, or Windows with WSL2

### Production Environment
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB+ depending on file storage needs
- **CPU**: 2+ cores recommended
- **Network**: HTTPS required for production

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Database Configuration
DATABASE_URL=postgresql://admin:admin@localhost:5432/datas_dev

# S3/BlackBlaze B2 Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name

# Email Configuration (Optional)
SMTP_RELAY=smtp.gmail.com
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_PORT=587

# Application Settings
SECRET_KEY_BASE=your_secret_key_base
PHX_HOST=localhost
PHX_PORT=4000
```

### Storage Configuration

MaxGallery supports multiple storage backends:

- **Local Storage** (Development)
- **AWS S3** (Production)
- **BlackBlaze B2** (Cost-effective alternative)
- **MinIO** (Self-hosted S3-compatible)

## 🎯 Core Functionality

### File Operations

```elixir
# Upload and encrypt a file
{:ok, file_id} = MaxGallery.Context.cypher_insert(
  "/path/to/file.pdf", 
  user_id,
  "encryption-key",
  group: group_id
)

# Retrieve and decrypt a file
{:ok, file_data} = MaxGallery.Context.decrypt_one(
  user_id,
  file_id, 
  "encryption-key"
)

# Update file content
{:ok, updated} = MaxGallery.Context.cypher_update(
  user_id,
  file_id,
  %{name: "new_name.pdf", blob: new_content},
  "encryption-key"
)
```

### Group Management

```elixir
# Create encrypted folder
{:ok, group_id} = MaxGallery.Context.group_insert(
  "Documents",
  user_id,
  "encryption-key",
  group: parent_group_id
)

# List folder contents
{:ok, contents} = MaxGallery.Context.decrypt_all(
  user_id,
  "encryption-key",
  group: group_id
)

# Export as ZIP
{:ok, zip_path} = MaxGallery.Context.zip_content(
  user_id,
  group_id,
  "encryption-key",
  group: true
)
```

## 🔐 Security Model

### Encryption Details

- **Algorithm**: AES-256 in CTR (Counter) mode
- **Key Derivation**: SHA-256 hash of user-provided key
- **IV Generation**: Cryptographically strong random bytes (16 bytes)
- **Data Integrity**: Phantom validation markers for tamper detection

### Security Guarantees

1. **Zero-Knowledge**: Server never sees plaintext data or encryption keys
2. **Forward Secrecy**: Each encryption uses unique IVs
3. **Tamper Detection**: Built-in integrity checking
4. **Secure Deletion**: Cryptographic erasure when keys are lost

### Threat Model

**Protected Against:**
- Server-side data breaches
- Database compromise
- Man-in-the-middle attacks (with HTTPS)
- Unauthorized access to stored files

**Not Protected Against:**
- Client-side key compromise
- Malicious client-side code
- Physical access to unlocked devices
- Social engineering attacks

## 🧪 Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/max_gallery/context_test.exs

# Run tests in watch mode
mix test.watch
```

## 📦 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `phoenix` | ~> 1.7.20 | Web framework |
| `phoenix_live_view` | ~> 1.0.0 | Real-time UI |
| `ecto_sql` | ~> 3.10 | Database wrapper |
| `postgrex` | ~> 0.20.0 | PostgreSQL driver |
| `bandit` | ~> 1.5 | HTTP server |

### Security & Encryption

| Package | Version | Purpose |
|---------|---------|---------|
| `crypto` | Built-in | AES encryption |
| `phoenix_live_dashboard` | ~> 0.8.3 | Monitoring |

### Storage & Cloud

| Package | Version | Purpose |
|---------|---------|---------|
| `ex_aws` | ~> 2.5 | AWS SDK |
| `ex_aws_s3` | ~> 2.5 | S3 operations |
| `hackney` | ~> 1.20 | HTTP client |

### Development Tools

| Package | Version | Purpose |
|---------|---------|---------|
| `credo` | ~> 1.7 | Code analysis |
| `phoenix_live_reload` | ~> 1.2 | Hot reloading |
| `floki` | >= 0.30.0 | HTML parsing (tests) |

## 🚀 Deployment

### Docker Deployment

```bash
# Build production image
docker build -t maxgallery:latest .

# Run with docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

### Manual Deployment

```bash
# Set production environment
export MIX_ENV=prod

# Install dependencies
mix deps.get --only prod

# Compile assets
mix assets.deploy

# Create release
mix release

# Run migrations
_build/prod/rel/max_gallery/bin/max_gallery eval "MaxGallery.Release.migrate"

# Start the application
_build/prod/rel/max_gallery/bin/max_gallery start
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `mix test`
5. Run code analysis: `mix credo`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

## 📄 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [Project Wiki](https://github.com/your-username/MaxGallery/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-username/MaxGallery/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/MaxGallery/discussions)
- **Email**: support@maxgallery.com

## 🙏 Acknowledgments

- **Phoenix Framework** team for the excellent web framework
- **Elixir** community for the robust ecosystem
- **Tailwind CSS** for the utility-first CSS framework
- **PostgreSQL** team for the reliable database system

---

**Built with ❤️ using Elixir and Phoenix**

*MaxGallery - Where your files are truly yours.*
