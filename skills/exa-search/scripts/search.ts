#!/usr/bin/env bun
/**
 * Exa web search CLI
 * Usage: EXA_API_KEY=... bun run search.ts "query" [--type web|company|news] [--limit 5]
 */
import Exa from 'exa-js';

const apiKey = process.env.EXA_API_KEY;
if (!apiKey) { console.error('EXA_API_KEY not set'); process.exit(1); }

const query = process.argv[2];
if (!query) { console.error('Usage: bun run search.ts "query" [--type web|company] [--limit N]'); process.exit(1); }

const typeFlag = process.argv.indexOf('--type');
const limitFlag = process.argv.indexOf('--limit');
const searchType = typeFlag !== -1 ? process.argv[typeFlag + 1] : 'web';
const limit = limitFlag !== -1 ? parseInt(process.argv[limitFlag + 1]) : 5;

const exa = new Exa(apiKey);
const results = await exa.searchAndContents(query, { numResults: limit, type: searchType as 'web' | 'news' });
console.log(JSON.stringify(results, null, 2));
