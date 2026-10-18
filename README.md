# Simple CRUD API

A REST API for tracking items and the locations where they are stored, built with Django and Django REST Framework. It supports full Create, Read, Update and Delete operations on both resources, with validation, filtering, pagination and an automated test suite.

## Features

- Full CRUD for `Location` and `Item`, with the correct HTTP status codes (201, 200, 204, 400, 404)
- Input validation: required fields, maximum lengths, unique location names, and a valid location for every item
- Filter items by location with `?location=<id>`
- Page-number pagination (20 results per page) with a stable ordering
- Versioned URLs under `/api/v1/`
- Configuration through environment variables, so no secrets are stored in the code
- 36 automated tests covering success cases, failure cases and pagination

## Tech Stack

Python, Django, Django REST Framework, SQLite.

## Data Model

| Model    | Field          | Type                       | Rules                        |
| -------- | -------------- | -------------------------- | ---------------------------- |
| Location | `locationName` | text, up to 100 characters | required, must be unique     |
| Item     | `itemName`     | text, up to 100 characters | required                     |
| Item     | `itemLocation` | foreign key to Location    | required, must exist         |
| Item     | `date_added`   | date                       | set by the server, read-only |

Deleting a location also deletes every item stored in it.

## API Endpoints

Base URL when running locally: `http://127.0.0.1:8000/api/v1/`

| Method | Path               | Purpose                                              | Success |
| ------ | ------------------ | ---------------------------------------------------- | ------- |
| GET    | `/items/`          | List items (paginated, filter with `?location=<id>`) | 200     |
| POST   | `/items/`          | Create an item                                       | 201     |
| GET    | `/items/<id>/`     | Read one item                                        | 200     |
| PUT    | `/items/<id>/`     | Replace an item (all fields required)                | 200     |
| PATCH  | `/items/<id>/`     | Change only the fields you send                      | 200     |
| DELETE | `/items/<id>/`     | Delete an item                                       | 204     |
| GET    | `/locations/`      | List locations (paginated)                           | 200     |
| POST   | `/locations/`      | Create a location                                    | 201     |
| GET    | `/locations/<id>/` | Read one location                                    | 200     |
| PUT    | `/locations/<id>/` | Replace a location                                   | 200     |
| PATCH  | `/locations/<id>/` | Change only the fields you send                      | 200     |
| DELETE | `/locations/<id>/` | Delete a location and its items                      | 204     |

Errors: `400` for invalid input (the body names each failing field) and `404` when an ID does not exist. Lists accept `?page=<n>`. A page past the end returns `404`.

## Example Requests

Create a location:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/locations/ \
  -H "Content-Type: application/json" \
  -d '{"locationName": "Warehouse"}'
```

```json
{ "id": 1, "locationName": "Warehouse" }
```

Create an item in that location:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/items/ \
  -H "Content-Type: application/json" \
  -d '{"itemName": "Laptop", "itemLocation": 1}'
```

```json
{ "id": 1, "itemName": "Laptop", "date_added": "2026-10-18", "itemLocation": 1 }
```

List the items in a location (paginated):

```bash
curl "http://127.0.0.1:8000/api/v1/items/?location=1"
```

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "itemName": "Laptop",
      "date_added": "2026-10-18",
      "itemLocation": 1
    }
  ]
}
```

Update one field:

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/items/1/ \
  -H "Content-Type: application/json" \
  -d '{"itemName": "Laptop (13 inch)"}'
```

A missing required field returns `400`:

```json
{ "itemLocation": ["This field is required."] }
```

## Getting Started

You need Python 3 and Git.

```bash
git clone https://github.com/Bla-vk/Simple-CRUD-API.git
cd Simple-CRUD-API

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Create your settings file from the example, then put a real secret key in it:

```bash
cp .env.example .env
python -c "import secrets; print(secrets.token_urlsafe(50))"   # paste the output into .env
```

Load the settings, create the database and start the server:

```bash
set -a; source .env; set +a
python manage.py migrate
python manage.py runserver
```

The API is now at `http://127.0.0.1:8000/api/v1/`. Django REST Framework also provides a browsable page in your browser at `/api/v1/items/`. To use the admin site at `/admin/`, run `python manage.py createsuperuser` first.

You need to run the `source .env` line in each new terminal before starting the server.

## Configuration

All settings come from environment variables, so no secrets live in the code.

| Variable               | Purpose                                                                   | Default               |
| ---------------------- | ------------------------------------------------------------------------- | --------------------- |
| `DJANGO_SECRET_KEY`    | Signs sessions and tokens. Required: the app refuses to start without it. | none                  |
| `DJANGO_DEBUG`         | Set to `1` to turn on debug mode for local work                           | off                   |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated host names the app will serve                             | `localhost,127.0.0.1` |

The `.env` file is listed in `.gitignore`. Commit only `.env.example`, which holds placeholder values.

## Running the Tests

```bash
set -a; source .env; set +a
python manage.py test
```

The 36 tests use a temporary database, so your real data is never touched. They cover:

- Creating, reading, updating (PUT and PATCH) and deleting items and locations
- Validation failures: blank, missing and over-long names, duplicate location names, and missing or unknown locations
- 404 responses for IDs that do not exist
- The server-set `date_added`, and the cascade delete from a location to its items
- The `?location=` filter, and pagination (page size, last page, no overlap between pages, pages past the end)

## Project Structure

```
.
├── api/
│   ├── models.py          # Location and Item
│   ├── serializers.py     # JSON conversion and validation
│   ├── views.py           # the list and detail endpoints
│   ├── urls.py            # routes for items and locations
│   └── tests.py           # automated tests
├── storage/
│   ├── settings.py        # configuration read from environment variables
│   └── urls.py            # admin and /api/v1/ routes
├── manage.py
├── requirements.txt
├── .env.example           # template for local settings
└── .gitignore             # keeps .env, .venv and databases out of Git
```

## Known Limitations

- The database is SQLite, which is fine for development and learning but not for several servers or heavy use.
- There is no authentication yet, so anyone who can reach the API can change data.
- `DEBUG` is off by default. The app is not yet configured for production hosting (static files, a production web server, HTTPS).

## What I Learned

- Moving the secret key out of the code and into an environment variable, and keeping the database file out of Git
- Designing REST endpoints with the right status codes, validation and consistent plural, lowercase, versioned URLs
- Why paginated lists need a defined order, so pages do not repeat or skip rows
- Writing API tests for failure cases as well as the happy path

## Next Steps

- Add authentication and permissions
- Move to PostgreSQL
- Containerise the API with Docker and deploy it on AWS ECS with Terraform
- Run the tests automatically with GitHub Actions on every push
