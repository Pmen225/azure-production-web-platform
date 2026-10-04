const express = require('express');

const app = express();
app.disable('x-powered-by');

app.get('/', (_, response) => {
  response.json({ service: 'azure-portfolio', status: 'healthy' });
});

// Process liveness only: this does not verify any Azure dependency.
app.get('/health', (_, response) => response.type('text').send('ok'));

if (require.main === module) {
  app.listen(process.env.PORT || 8080);
}

module.exports = app;
