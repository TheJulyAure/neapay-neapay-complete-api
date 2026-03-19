const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.NODE_ENV || 'development';
const HEALTH_PAYLOAD = Object.freeze({ status: 'ok', service: 'penthouse-api' });
const READY_JSON = JSON.stringify({ ready: true });
const VERSION_JSON = JSON.stringify({ version: '1.0.0', environment: ENVIRONMENT });

app.disable('x-powered-by');
app.use(cors());

// Health check endpoint
app.get('/health', (req, res) => {
  res
    .type('application/json')
    .send(JSON.stringify(HEALTH_PAYLOAD));
});

// Ready check endpoint
app.get('/ready', (req, res) => {
  res
    .type('application/json')
    .send(READY_JSON);
});

// API endpoints
app.get('/api/health', (req, res) => {
  res.json({ ...HEALTH_PAYLOAD, timestamp: new Date().toISOString() });
});

app.get('/api/version', (req, res) => {
  res
    .type('application/json')
    .send(VERSION_JSON);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`NeaPay API running on port ${PORT}`);
  console.log(`Environment: ${ENVIRONMENT}`);
});
