#!/usr/bin/env node
import { isMain } from './runtime/program.js';
import { main } from './runtime/build_index.js';

export * from './runtime/build_index.js';

if (isMain(import.meta.url)) process.exitCode = main();
