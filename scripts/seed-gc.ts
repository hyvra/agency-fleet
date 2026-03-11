/**
 * Seed agency-fleet agents into Ground Control.
 *
 * Reads all .md agent specs, parses frontmatter, and POSTs to GC's
 * bulk seed API. Agents are prefixed with "agency-" to avoid collision
 * with the host's existing agent fleet.
 *
 * Usage: npx tsx scripts/seed-gc.ts
 */

import fs from 'fs';
import path from 'path';
import http from 'http';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const AGENT_DIRS = [
  'engineering',
  'design',
  'marketing',
  'testing',
  'specialized',
  'product',
  'project-management',
  'support',
  'spatial-computing',
  'paid-media',
  'game-development',
];

const GC_URL = process.env.GC_API_URL ?? 'http://localhost:3456';

interface AgentSpec {
  name: string;
  displayName: string;
  category: string;
  description: string;
  instructions: string;
}

function parseYamlFrontmatter(content: string): Record<string, string> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const result: Record<string, string> = {};
  for (const line of match[1].split('\n')) {
    const colonIdx = line.indexOf(':');
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    const value = line.slice(colonIdx + 1).trim();
    if (key && value) result[key] = value;
  }
  return result;
}

function slugify(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

async function seed() {
  const repoRoot = path.resolve(__dirname, '..');
  const agents: AgentSpec[] = [];

  for (const dir of AGENT_DIRS) {
    const dirPath = path.join(repoRoot, dir);
    if (!fs.existsSync(dirPath)) continue;

    for (const file of fs.readdirSync(dirPath)) {
      if (!file.endsWith('.md')) continue;
      const filePath = path.join(dirPath, file);
      const content = fs.readFileSync(filePath, 'utf-8');
      const fm = parseYamlFrontmatter(content);

      if (!fm.name) continue;

      const slug = 'agency-' + slugify(fm.name);

      agents.push({
        name: slug,
        displayName: `[Agency] ${fm.name}`,
        category: dir,
        description: fm.description || '',
        instructions: content,
      });
    }
  }

  console.log(`Found ${agents.length} agents across ${AGENT_DIRS.length} divisions\n`);

  // POST to GC bulk seed endpoint
  const body = JSON.stringify({
    agents: agents.map((a) => ({
      name: a.name,
      displayName: a.displayName,
      category: a.category,
      description: a.description,
      instructions: a.instructions,
      adapterType: 'docker-remote',
      adapterConfig: { baseUrl: 'http://localhost:7890' },
    })),
  });

  const url = new URL('/api/agents/seed', GC_URL);

  const req = http.request(
    {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    (res) => {
      let respBody = '';
      res.on('data', (chunk) => (respBody += chunk));
      res.on('end', () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          const result = JSON.parse(respBody);
          console.log(`Seeded ${result.seeded} agents into Ground Control`);
          console.log('All agents registered with adapterType: docker-remote');
        } else {
          console.error(`Failed: ${res.statusCode} ${respBody}`);
        }
      });
    }
  );
  req.on('error', (e) => console.error('Connection failed:', e.message));
  req.end(body);
}

seed().catch(console.error);
