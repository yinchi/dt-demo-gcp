# React login page

This module (`dt-demo-gcp-login`) provides a login page for the Hospital DT demo.

- Upon page load:
    - Checks for an access token (JWT) in the user's cookies and if present, validates it. If the token is valid, redirects to another page (currently `/validate` for testing purposes).
    - Parses the search portion of the URL, e.g. `?error=missing_token`, and displays an error message as appropriate. This allows for specifying an error message to display when the user is redirected to the login page for some reason.
- Upon submitting the login form, the input fields are checked to ensure they are not empty. If this check passes, the page then submits an HTTP POST to the `/token` API endpoint.
    - If the login credentials are valid, an HTTP 200 is returned and a cookie is saved contained the returned JWT. The user is then redirected to another page (currently `/validate` for testing purposes).
    - If the login is unsuccessful, an error message is shown on the page.

[Mantine with Vite](https://mantine.dev/guides/vite/) is used to render the page layout; however, using `vite build`, the final output is a static webpage, which we serve using a miniature Nginx instance behind the Traefik reverse proxy.

> [!NOTE]
> Since the app runs entirely client-side, the URLs set in the `compose.yml` environment variables should be public, instead of using the Docker internal DNS.
