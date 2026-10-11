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
- **Docker** and **Docker Compose** (for running MongoDB locally), or a locally installed MongoDB server
- **Git** and access to the [SINFO data repository](https://github.com/sinfo/data)
- [MongoDB Database Tools](https://www.mongodb.com/docs/database-tools/installation/) (`mongorestore`) if using a local MongoDB daemon; the Docker container already includes it
- *(Optional)* [go-swagger](https://goswagger.io/install.html) to build or serve API docs locally:
  ```bash
  go install github.com/go-swagger/go-swagger/cmd/swagger@latest
  ```

## Local Setup

### 1. Environment Variables

Create `backend/.env` with the following settings:

```dotenv
DECK2_HOST=localhost
DECK2_PORT=8080
DECK2_DB_URL=mongodb://localhost:27017
DECK2_DB_NAME=deck2
DECK2_CALLBACK_URL=http://localhost:8080
DECK2_AUTH_REDIRECTION_URL=http://localhost:5173
DECK2_PRODUCTION=false

DECK2_GOOGLE_OAUTH_CLIENT_ID=
DECK2_GOOGLE_OAUTH_CLIENT_SECRET=
DECK2_JWT_SECRET=
DECK2_DO_PAT=
DECK2_DO_SPACES_NAME=
DECK2_DO_SPACES_KEY=
DECK2_DO_SPACES_SECRET=
```

Keep `DECK2_PRODUCTION=false` for local development. Uploads will use the `deck2-dev` prefix in your Spaces bucket.

Ask the SINFO dev team for the development OAuth and DigitalOcean credentials, or set up your own using the links below. Fill in all the empty values:

| Variable | Value |
| --- | --- |
| `DECK2_GOOGLE_OAUTH_CLIENT_ID` | A **Web application** OAuth client ID from the [Google Cloud Console](https://console.cloud.google.com/apis/credentials). Configure the consent screen and add your account as a test user if the app is in testing. |
| `DECK2_GOOGLE_OAUTH_CLIENT_SECRET` | The secret for that OAuth client. |
| `DECK2_JWT_SECRET` | A local signing secret. Generate one with `openssl rand -hex 32`. |
| `DECK2_DO_PAT` | A [personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) for the account that owns the bucket, with `cdn:read` permission. |
| `DECK2_DO_SPACES_NAME` | The development bucket name. Its CDN must be enabled. |
| `DECK2_DO_SPACES_KEY` | A [Spaces access key](https://docs.digitalocean.com/products/spaces/how-to/manage-access/) with Read/Write/Delete permissions for the development bucket. |
| `DECK2_DO_SPACES_SECRET` | The matching Spaces secret, saved when the key was created. |

In the Google OAuth client settings, add `http://localhost:5173` as an **Authorized JavaScript origin** and `http://localhost:8080/auth/callback` as an **Authorized redirect URI**. See the [Google OAuth setup documentation](https://developers.google.com/identity/protocols/oauth2/web-server). Deck login requires a `@sinfo.org` account whose SINFO ID exists in the restored `members` collection.

Create the frontend environment file:

```bash
cp frontend/.env.example frontend/.env
```

| Variable | Value |
| --- | --- |
| `VITE_GOOGLE_CLIENT_ID` | Replace the placeholder with your `DECK2_GOOGLE_OAUTH_CLIENT_ID`. |
| `VITE_GOOGLE_SCOPE` | Keep the default scope, which includes permission to compose email through Gmail. |
| `VITE_API_URL` | Keep `http://localhost:8080` for local development. |

Keep secrets in `backend/.env`; frontend `VITE_*` variables are visible in the browser. Do not commit `.env` files. The backend connects to DigitalOcean Spaces at startup, including in development, so it needs working credentials.

### 2. Install Dependencies

The root `npm install` installs `concurrently`, which lets `npm run dev` start MongoDB, the backend, and the frontend with one command.

From the project root:

```bash
# Root tooling (concurrently)
npm install

# Frontend
cd frontend && npm install && cd ..

# Backend
cd backend && go mod download && cd ..
```

### 3. Database & Initial Data

Clone the [SINFO data repository](https://github.com/sinfo/data) alongside Deck 2, or update your existing copy. Ask the team for access if needed. Run this from the project root:

```bash
git clone https://github.com/sinfo/data.git ../data
```

Use [`dump/deck2`](https://github.com/sinfo/data/tree/master/dump/deck2); `dump/deck` is the older database. Keep the `.bson` and `.metadata.json` files together to restore collection options and indexes along with the data.

#### Using Docker

Start MongoDB using `docker-compose.test.yml`:

```bash
npm run start:db
```

This starts MongoDB on `localhost:27017` without building the backend test image.

Once MongoDB is ready, copy the Deck 2 dump into the container and restore it:

```bash
docker exec deck2_testing_mongodb mkdir -p /tmp/deck2-dump/deck2
docker cp ../data/dump/deck2/. deck2_testing_mongodb:/tmp/deck2-dump/deck2
docker exec deck2_testing_mongodb mongorestore --uri="mongodb://localhost:27017" --nsInclude="deck2.*" /tmp/deck2-dump
```

#### Using Local MongoDB

Start your local MongoDB service on `localhost:27017`, or run this in a separate terminal:

```bash
mkdir -p /tmp/deck2-mongodb
mongod --dbpath /tmp/deck2-mongodb --bind_ip 127.0.0.1 --port 27017
```

Once MongoDB is running, restore the dump from the project root:

```bash
mongorestore --uri="mongodb://localhost:27017" --nsInclude="deck2.*" ../data/dump
```

Both restore commands target `deck2`, matching `DECK2_DB_NAME`. Use an empty local database and check for errors after the restore. Existing collections are kept, so repeating the restore may cause duplicate-key errors.

### 4. Running the Project

If using Docker, start the database, backend, and frontend all together:

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

Run each service in a separate terminal, starting from the project root. If you use local MongoDB, leave it running and skip the Docker command:

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
