#️ Community Backend

## ️ Technical Stack
* **Backend:** FastAPI (Python 3.11+)
* **Database:** SQLite w/ SQLAlchemy ORM (Migrated from `community.json`)
* **Session Management:** Starlette SessionMiddleware (Signed Cookies) (JWT token)

---

## 🏗️ Core Architecture


### 2. Data Model (`tables.py`)
* **Users:** Unique identities, display details linked to credentials.
* **Credentials:** Unique identities for registering and login check

---

## 🛰️ API Reference (v1)

### Authentication
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register/{user}` | Register new user. |
| `POST` | `/api/v1/auth/login/{user}` | Verify assertion & return JWT. |

---

## 📂 Project Structure
```text
community_backend/
├── app/
│   ├── api/v1/         # Versioned controllers (auth.py, matches.py)
│   ├── core/           # Security, JWT
│   ├── db/             # SQLAlchemy (database.py, tables.py)
│   └── main.py         # App entry, CORS, & Session Middleware
└── requirements.txt    # FastAPI, sqlalchemy
```

---

## 📝 Critical Implementation Notes
* **Cross-Origin Security:** `api.js` utilizes `credentials: 'include'` to ensure session cookies are passed correctly across the `v1` API surface.
* **Stigmergic Development:** This README serves as the source of truth for task breakdown. Use GitHub Issues to track the transition of remaining endpoints to the `v1` prefix.

---

## 🛠️ Development Setup

1.  **Install Environment:**
    ```bash
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    ```

2.  **Run Server:**
    ```bash
    uvicorn app.main:app --reload --port 8000
    ```
