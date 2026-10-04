const assert = require('node:assert/strict');
const { once } = require('node:events');
const { before, after, test } = require('node:test');
const app = require('./server');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  });
});

test('GET / returns the public service status', async () => {
  const response = await fetch(baseUrl);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /^application\/json/);
  assert.equal(response.headers.get('x-powered-by'), null);
  assert.deepEqual(await response.json(), {
    service: 'azure-portfolio',
    status: 'healthy',
  });
});

test('GET /health returns a plain-text liveness response', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /^text\/plain/);
  assert.equal(await response.text(), 'ok');
});

test('an unknown route does not report a healthy service', async () => {
  assert.equal((await fetch(`${baseUrl}/missing`)).status, 404);
});

test('POST /health is not accepted', async () => {
  assert.equal((await fetch(`${baseUrl}/health`, { method: 'POST' })).status, 404);
});
