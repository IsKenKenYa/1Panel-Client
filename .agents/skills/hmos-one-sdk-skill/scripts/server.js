#!/usr/bin/env node
import { isMain } from './runtime/program.js';
import { createServer } from './runtime/server.js';

export * from './runtime/server.js';

function main(args = process.argv.slice(2)) {
  let host = '127.0.0.1';
  let port = 8766;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--host') host = args[++i];
    else if (args[i] === '--port') port = Number(args[++i]);
    else throw new Error('未知服务参数: ' + args[i]);
  }
  if (!host || !Number.isInteger(port) || port < 0 || port > 65535) throw new Error('无效 host/port');
  createServer().listen(port, host, () => console.log('Jieba OR 检索服务 http://' + host + ':' + port));
}

if (isMain(import.meta.url)) main();
