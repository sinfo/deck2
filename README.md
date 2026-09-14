# Deck 2

Deck 2 is SINFO's internal management platform and CRM. It is used by the organizing team to coordinate each edition of the conference, including speakers, sponsors, companies, team members, meetings, and assets.

## Stack

- **Backend:** Go (`gorilla/mux`, official MongoDB driver)
- **Frontend:** Vue 3, Vite, TypeScript, Tailwind CSS, Pinia
- **Database:** MongoDB
- **Storage:** DigitalOcean Spaces (S3 compatible)
- **Docs:** Swagger / OpenAPI

## Prerequisites

- **Go** (>= 1.23)
- **Node.js** (>= 20) and **npm**
- **Docker** and **Docker Compose** (for running MongoDB locally)
- *(Optional)* [go-swagger](https://goswagger.io/install.html) to build or serve API docs locally:
  ```bash
  go install github.com/go-swagger/go-swagger/cmd/swagger@latest
  ```

## Local Setup

### 1. Environment Variables

Create `.env` files for both the backend and frontend:

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

The defaults in `.env.example` are preconfigured for local development (local MongoDB on port `27017`, backend on `http://localhost:8080`, and frontend on `http://localhost:5173`).

### 2. Install Dependencies

From the project root:

```bash
# Root tooling (concurrent runner)
npm install

# Frontend
cd frontend && npm install && cd ..

# Backend
cd backend && go mod download && cd ..
```

### 3. Database & Seed Data

Start the MongoDB container:

```bash
npm run start:db
```

To populate the database with initial test data (a sample event edition, team, member, company, and speaker):

```bash
cd backend
go run scripts/dev.go
cd ..
```

The script will prompt for your member name, SINFO ID (e.g. `john.doe`), and credential level (enter `4` for Admin).

### 4. Running the Project

To start the database, backend, and frontend all together:

```bash
npm run dev
```

Once running:
- Frontend: `http://localhost:5173`
- Backend API: `http://localhost:8080`

To stop the background MongoDB container:

```bash
npm run stop
```

#### Running Services Separately

If you prefer running services across separate terminal tabs:

```bash
# 1. MongoDB
npm run start:db

# 2. Backend
cd backend && go run src/main.go

# 3. Frontend
cd frontend && npm run dev
```

## API Documentation

To generate and view the API documentation locally using Swagger UI:

```bash
cd backend
make run-doc
```

## Contributing

1. Create a new branch off `master`:
   ```bash
   git checkout -b <type>/<description>
   ```
2. Make your changes and ensure linting and tests pass:
   - **Frontend:**
     ```bash
     cd frontend
     npm run lint
     npm run format
     npm run build
     ```
   - **Backend:**
     ```bash
     cd backend
     go test ./...
     ```
3. Commit using [Conventional Commits](https://www.conventionalcommits.org/) (enforced by Husky and commitlint), for example:
   - `feat: add filter for confirmed speakers`
   - `fix: handle empty company description`
4. Push your branch and open a Pull Request against `master`.

## License

[MIT](LICENSE)