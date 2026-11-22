#!/usr/bin/env node
import { createServer as httpServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { ROOT } from './index_store.js';
import { searchJson } from './search.js';
import { getRuntime } from './retrieval.js';
import { MODES, THRESHOLDS, validateMode } from './rejection.js';
import { isMain } from './program.js';
function json(response, value, status = 200) {
    response.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
    response.end(JSON.stringify(value));
}
export function createServer() {
    return httpServer(async (request, response) => {
        const pathname = new URL(request.url || '/', 'http://localhost').pathname;
        if (request.method === 'GET') {
            if (pathname === '/api/health') {
                json(response, { ok: true, model: 'jieba_v6', modes: MODES, default_mode: 'default', thresholds: THRESHOLDS });
                return;
            }
            if (pathname === '/api/evaluation') {
                try {
                    json(response, JSON.parse(readFileSync(resolve(ROOT, 'evaluate/jieba_ts_results.json'), 'utf8')));
                }
                catch {
                    json(response, { error: '尚未生成评测结果' }, 404);
                }
                return;
            }
            const assets = {
                '/': ['web/index.html', 'text/html; charset=utf-8'],
                '/index.html': ['web/index.html', 'text/html; charset=utf-8'],
                '/styles.css': ['web/styles.css', 'text/css; charset=utf-8'],
                '/app.js': ['dist/web/app.js', 'text/javascript; charset=utf-8'],
            };
            const asset = Object.hasOwn(assets, pathname) ? assets[pathname] : undefined;
            if (!asset) {
                json(response, { error: 'Not found' }, 404);
                return;
            }
            try {
                const content = readFileSync(resolve(ROOT, asset[0]));
                response.writeHead(200, { 'Content-Type': asset[1] });
                response.end(content);
            }
            catch {
                json(response, { error: '静态资源未随 scripts 替换包提供' }, 503);
            }
            return;
        }
        if (request.method !== 'POST' || !['/api/search', '/api/explain'].includes(pathname)) {
            json(response, { error: 'Not found' }, 404);
            return;
        }
        try {
            const chunks = [];
            let size = 0;
            for await (const chunk of request) {
                size += chunk.length;
                if (size > 1_048_576) {
                    json(response, { error: '请求过大' }, 413);
                    return;
                }
                chunks.push(Buffer.from(chunk));
            }
            const body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
            if (!body || typeof body !== 'object' || Array.isArray(body))
                throw new Error('JSON body 必须是对象');
            const data = body;
            if (typeof data.query !== 'string' || data.query.length > 32768)
                throw new Error('query 必须是字符串且不超过 32768 字符');
            const mode = validateMode(data.mode ?? 'default');
            const top = data.top ?? data.top_k ?? 10;
            if (typeof top !== 'number' || !Number.isInteger(top) || top < 1)
                throw new Error('top 必须是正整数');
            if (data.category !== undefined && typeof data.category !== 'string')
                throw new Error('category 必须是字符串');
            const withSnippet = data.withSnippet ?? data.snippet ?? false;
            if (typeof withSnippet !== 'boolean')
                throw new Error('snippet 必须是布尔值');
            const options = { mode, top, category: data.category, withSnippet };
            json(response, pathname === '/api/search' ? searchJson(data.query, options) : getRuntime().explain(data.query, options));
        }
        catch (error) {
            json(response, { error: error instanceof Error ? error.message : String(error) }, 400);
        }
    });
}
if (isMain(import.meta.url)) {
    const args = process.argv.slice(2);
    let host = '127.0.0.1', port = 8766;
    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--host')
            host = args[++i];
        else if (args[i] === '--port')
            port = Number(args[++i]);
        else
            throw new Error('未知服务参数: ' + args[i]);
    }
    if (!host || !Number.isInteger(port) || port < 0 || port > 65535)
        throw new Error('无效 host/port');
    createServer().listen(port, host, () => console.log('Jieba OR 检索服务 http://' + host + ':' + port));
}
