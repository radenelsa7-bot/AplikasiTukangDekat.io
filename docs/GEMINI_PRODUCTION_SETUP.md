# Gemini Production Configuration & Secrets

This document describes how to configure the Gemini API for production and securely store the required secrets.

1) Required environment variables (set in production environment or CI secret manager):

- `GEMINI_API_ENDPOINT` — production endpoint. Example:
  `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent`
- `GEMINI_API_KEY` — Google Cloud API key or service account credential token (keep secret)
- `GEMINI_API_MODEL` — the model id (defaults to `gemini-1.0`)

2) Recommended secret stores

- GitHub Actions: Use `Settings -> Secrets and variables -> Actions -> New repository secret` and add `GEMINI_API_KEY` (example secret name `GEMINI_API_KEY`).
- GitLab CI: Use CI/CD -> Variables and set as protected masked variable.
- AWS Secrets Manager / Parameter Store: store the key and inject into the runtime environment via IAM role.
- Google Secret Manager: ideal for Google Cloud deployments; grant access to the service account running the backend.

3) Sample GitHub Actions snippet

```yaml
# .github/workflows/deploy.yml (excerpt)
env:
  GEMINI_API_ENDPOINT: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent
  GEMINI_API_MODEL: gemini-1.0

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Use secrets
        run: echo "Setting up environment"
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}

      # Example: deploy to server with env injection or update secret store
```

4) Local testing (do NOT commit real keys)

- Add the following to local `.env` for development only (use `.env.example` as a template):

```
GEMINI_API_ENDPOINT=https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent
GEMINI_API_KEY=your-test-key
GEMINI_API_MODEL=gemini-1.0
```

5) Security notes

- Never commit `GEMINI_API_KEY` to the repository.
- Use least-privilege keys or service accounts and rotate regularly.
- For production, prefer short-lived credentials or service accounts with limited scopes.

6) Troubleshooting

- If you receive 401/403 responses: verify the API key permissions and that the key is active.
- For rate-limits: monitor `X-RateLimit-*` headers from the backend and tune application throttle as needed.


