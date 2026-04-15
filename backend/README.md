## Running the Rev Finder API Locally via Docker

To ensure everyone on the team is running the exact same environment, we are using Docker for local testing. 

### Prerequisites
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2. Ask Hanz for the `.env` file, it has our API keys.
3. Place the `.env` file directly inside the `backend/` folder. **Do not commit this file.**

### Build the Image
Open your terminal, navigate to the `backend/` directory, and run:
```bash
docker build -t rev_finder_api .