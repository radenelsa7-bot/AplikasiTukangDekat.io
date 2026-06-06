# n8n Integration Plan - feature/backend-124-n8n-integration

**Branch:** feature/backend-124-n8n-integration
**Owner:** BE3 (Fatinasy7)
**Goal:** Integrate n8n workflow automation for notification delivery and event logging.

## Objective

Implement backend support for n8n event dispatch and notification logging so that:
- backend actions can trigger n8n workflows
- notifications can be sent via WhatsApp and email
- notification events are audited in `notification_logs`
- integration setup is ready for staging and production

## Scope

### Deliverables
- `backend/N8N_INTEGRATION_PLAN.md` (this plan)
- API endpoint: `POST /api/integrations/n8n/events`
- `NotificationLog` model and migration
- `NotificationService` or `N8nIntegrationService`
- `WebhookController` or `IntegrationController`
- `docs/api/API_DOCUMENTATION_TukangDekat_v1.0.md` update if needed
- tests for event dispatch and validation
- PR for `feature/backend-124-n8n-integration`

## Tasks

1. Setup n8n environment
   - Verify `docker-compose` includes n8n service
   - Confirm n8n UI access and credentials
   - Add environment vars to `backend/.env.example` if missing:
     - `N8N_WEBHOOK_URL`
     - `N8N_WEBHOOK_SECRET`
     - `N8N_API_KEY` (optional)

2. Create Integration API endpoint
   - Route: `POST /api/integrations/n8n/events`
   - Request body payload example:
     ```json
     {
       "event": "order_created",
       "order_id": 123,
       "customer_id": 10,
       "provider_id": 20
     }
     ```
   - Validate required fields and event type
   - Forward event to n8n webhook URL with auth/secret
   - Return `200 OK` on success or `422`/`500` on failure

3. Add NotificationLog audit trail
   - Create `notification_logs` migration if missing
   - Fields: `id`, `event`, `recipient`, `channel`, `payload`, `status`, `response`, `sent_at`
   - Create `NotificationLog` model
   - Write records for each outgoing n8n event

4. Design n8n workflows
   - Event: `order_created` → WA customer + WA provider
   - Event: `order_accepted` → WA customer
   - Event: `order_rejected` → WA customer
   - Event: `dp_paid` → WA customer + provider
   - Event: `order_completed` → WA customer (request final payment)
   - Event: `final_paid` → WA all parties

5. Implement backend event dispatch
   - Add service for event formatting
   - Add controller action to trigger n8n
   - Unit/feature tests to cover event dispatch and log creation

6. Documentation
   - Update API docs with `POST /api/integrations/n8n/events`
   - Add example payloads and expected response
   - Add operation notes to `TESTING_GUIDE_ORDERS.md`
   - Update BE3 status docs if needed

## Acceptance Criteria

- [ ] `feature/backend-124-n8n-integration` branch exists
- [ ] `backend/N8N_INTEGRATION_PLAN.md` created and committed
- [ ] Endpoint `POST /api/integrations/n8n/events` implemented
- [ ] Notification logs audit is built
- [ ] n8n payload formatting supports required events
- [ ] Tests cover dispatch and validation
- [ ] PR created for branch

## Notes

- This branch should be reviewed after `feature/backend-123-deploy-smoke` is merged, but it can be developed in parallel if needed.
- Keep changes focused on integration and avoid touching unrelated backend API functionality.
