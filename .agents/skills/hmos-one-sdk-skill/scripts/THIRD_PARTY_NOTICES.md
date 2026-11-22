# Third-party notices

## Jieba 0.42.1

The accurate-mode DAG / HMM implementation in `document_tokenizer.ts` is
a TypeScript adaptation of Jieba 0.42.1. It supports the document-building path,
not the entire Jieba API (POS, paddle, parallel cutting and user dictionaries are not exposed).

Primary sources:

- https://github.com/fxsjy/jieba/tree/v0.42.1/jieba
- https://github.com/fxsjy/jieba/blob/v0.42.1/LICENSE
- https://pypi.org/project/jieba/0.42.1/

The assets in `data/jieba-0.42.1/` are data, not Python executable code:

| Asset | Origin | Compressed SHA-256 |
| --- | --- | --- |
| dict.txt.gz | Exact upstream jieba/dict.txt, recompressed | 437089f5d8ec2546c5fb629e93b99e851f23b04db9d0c5b63528d6175226c942 |
| hmm.json.gz | Numeric P tables from finalseg/prob_start.py, prob_trans.py, prob_emit.py, converted to JSON | 74ea31b14ff15731c41f1e84f5edfe99c51b53fbd6dfb6e6577dc5a34ae8281d |
| casefold.json.gz | Unicode casefold overrides where CPython casefold differs from lowercase; JSON mapping only | 11806f01daa2d64d339029aaed41d3dc96fa34e8de61d11fa718b8a31c7c4fad |

PyPI source distribution SHA-256:
`055ca12f62674fafed09427f176506079bc135638a14e23e25be909131928db2`.

Source distribution:
https://files.pythonhosted.org/packages/c6/cb/18eeb235f833b726522d7ebed54f2278ce28ba9438e3135ab0278d9792a2/jieba-0.42.1.tar.gz

Model data was converted once during migration. Building, querying, testing and
evaluating now require only Node.js; they do not execute Python, download assets,
load native addons, or invoke external services.

### Jieba license

The MIT License (MIT)

Copyright (c) 2013 Sun Junyi

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
