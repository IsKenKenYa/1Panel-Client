import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
export function isMain(url) {
    return Boolean(process.argv[1]) && url === pathToFileURL(resolve(process.argv[1])).href;
}
