#!/usr/bin/env node
import { isMain } from './runtime/program.js';
import { main } from './runtime/search.js';

export * from './runtime/search.js';

if (isMain(import.meta.url)) process.exitCode = main();
