#!/bin/bash
set -euo pipefail

echo "=== Agency Fleet Container ==="
echo "Agents loaded: $(ls /home/agency/.claude/agents/*.md 2>/dev/null | wc -l)"
echo "Waiting for tasks..."

GC_URL="${GC_API_URL:-http://host.docker.internal:3456}"

node -e "
const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');

const agents = fs.readdirSync('/home/agency/.claude/agents/')
  .filter(f => f.endsWith('.md'))
  .map(f => f.replace('.md', ''));

console.log('Registered agents:', agents.length);

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', agents: agents.length }));
    return;
  }

  if (req.method === 'GET' && req.url === '/agents') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(agents));
    return;
  }

  if (req.method === 'POST' && req.url === '/task') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const task = JSON.parse(body);
        const { agent, prompt, run_id } = task;

        if (!agent || !prompt) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'agent and prompt required' }));
          return;
        }

        const specPath = '/home/agency/.claude/agents/' + agent + '.md';
        if (!fs.existsSync(specPath)) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Agent not found: ' + agent }));
          return;
        }

        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'accepted', run_id }));

        const args = [
          '--print', prompt,
          '--output-format', 'text',
          '--append-system-prompt-file', specPath,
          '--max-turns', '10'
        ];

        console.log('Starting:', agent, 'run_id:', run_id);

        const proc = spawn('claude', args, {
          cwd: '/home/agency/workspace',
          stdio: ['ignore', 'pipe', 'pipe'],
          env: {
            ...process.env,
            GROUND_CONTROL_RUN_ID: run_id || '',
            GROUND_CONTROL_AGENT: agent
          }
        });

        let stdout = '';
        let stderr = '';
        proc.stdout.on('data', d => { stdout += d; });
        proc.stderr.on('data', d => { stderr += d; console.error('STDERR:', d.toString().slice(0, 200)); });
        proc.on('error', (err) => { console.error('Spawn error:', agent, err.message); });

        proc.on('close', (code) => {
          const gcUrl = process.env.GC_API_URL || 'http://host.docker.internal:3456';
          const report = JSON.stringify({
            agent_name: agent,
            status: code === 0 ? 'success' : 'failed',
            output_summary: stdout.slice(0, 2000),
            error_message: code !== 0 ? stderr.slice(0, 500) : undefined,
            invocation_source: 'agency-fleet-docker',
          });

          const reportReq = http.request(gcUrl + '/api/executions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(report) }
          });
          reportReq.on('error', (e) => console.error('GC report failed:', e.message));
          reportReq.end(report);

          console.log('Completed:', agent, 'exit:', code);
        });
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(7890, '0.0.0.0', () => {
  console.log('Agency Fleet listening on :7890');
});
"
