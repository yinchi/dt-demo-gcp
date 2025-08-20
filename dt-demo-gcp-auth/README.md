# dt_demo_gcp.auth module

App-wide authentication using [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token).  Users and their hashed passwords are stored in a database, managed by the `dt-demo-gcp-db-auth` Python subproject.

Creates a FastAPI server with the following key endpoints:

- `login`: Login page with username and password prompt
    - Uses `WSGIMiddleware` to host a `dash` webpage, [which requires Flask](https://fastapi.tiangolo.com/advanced/wsgi/)
- `token`: Validates a login attempt and returns a JWT token
- `user_management`: e.g. change password

Valid tokens are tracked using a Redis container (`redis://redis:6379`).  Tokens can be invalidated by logout, change of password, or change in user permissions.

**See:** <https://github.com/yinchi/test_project/blob/main/api_backend/src/api_backend/api.py> for an existing partial implementation (no Redis backing or UI).

## Mechanism

See: <https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/#handle-jwt-tokens>

For each endpoint requiring authentication, we use a `Depends()` to authenticate the current user against a permissions database, which in turn uses a `Depends()` to read in a JWT token.

- If no token is present or the token is invalid (ID not found in the Redis store), we redirect the user to the login page.
- If the token represents a valid user but with insufficient permissions, an HTTP 401 (Unauthorized) error is returned.
- Tokens can be invalidated by removing them from the Redis store, e.g. for logout.

Note that a FastAPI router can have global dependencies, ensuring security for all endpoints in a service: <https://fastapi.tiangolo.com/tutorial/dependencies/global-dependencies/>.  These can be overridden at the individual endpoint level.

### Mounts

Mounted applications, such as Dash apps hosted via `WSGIMiddleware`, cannot directly use FastAPI's dependency injection mechanism for authentication and authorization. Instead, these applications must implement their own mechanisms to validate users. This can be achieved by checking the "`Authorization: Bearer <jwt_value>`" HTTP header and verifying the JWT token.

### Logout

We keep a Redis cache to track valid JWTs, allowing users to be truly logged out (instead of simply trusting them to forget their JWTs).  This also allows users to be banned by purging their login data from the database and immediately revoking their JWTs.
