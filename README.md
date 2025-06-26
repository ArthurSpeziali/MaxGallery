# Max Gallery - Secure Encrypted File Storage

![Max Gallery Screenshot](https://i.imgur.com/avg2pIH.png)

Max Gallery is a secure file storage system built with Phoenix that encrypts all files and metadata before storage using AES-256-CTR encryption. The encryption key remains exclusively with the user.

## Features

- 🔒 End-to-end encryption (AES-256-CTR) for files and metadata
- 📁 Hierarchical organization with groups and subgroups
- ⚡ LiveView real-time interface
- 🐳 Docker container with MongoDB 4.4
- 🔍 Full-text search capability
- 📦 ZIP export functionality
- 🛡️ Phantom mode protection
- 🗃️ MongoDB 4.4 backend with GridFS

## Docker Quick Start

```bash
# Start the MongoDB container
docker-compose up -d mongodb

# Stop the container
docker-compose down
```

The included `docker-compose.yml` provides:
- MongoDB 4.4 container with persistent storage
- Pre-configured for MaxGallery connection

## Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/ArthurSpeziali/MaxGallery
cd max_gallery
```

2. Install dependencies:
```bash
mix deps.get
```

3. Set up the database:
```bash
mix ecto.setup
```

4. Start the server:
```bash
mix phx.server
```

The application will be running at:
**http://localhost:4000**

--- 

## Accessing the Application

After starting the server (either via Docker or manual installation), open your web browser and navigate to:

```
http://localhost:4000
```

You'll be presented with:
- Secure login interface
- Main dashboard showing your encrypted files
- Navigation menu for accessing different sections


## Context API Examples

### File Operations
```elixir
# Insert file
{:ok, file_id} = MaxGallery.Context.cypher_insert(
  "/path/to/file.txt", 
  "user-secret-key"
)

# Retrieve file  
{:ok, file} = MaxGallery.Context.decrypt_one(
  file_id,
  "user-secret-key"
)
```

### Group Operations
```elixir
# Create group
{:ok, group_id} = MaxGallery.Context.group_insert(
  "Documents",
  "user-secret-key"
)

# List contents
{:ok, contents} = MaxGallery.Context.decrypt_all(
  "user-secret-key", 
  group: group_id
)
```

## License

GNU General Public License v3.0 - See [LICENSE](LICENSE) for full terms.
