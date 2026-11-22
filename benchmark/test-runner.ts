/**
 * Test harness for the Skyline Problem benchmark.
 * Grades both candidate solutions against a comprehensive test suite.
 */

type Building = [number, number, number]; // [left, right, height]
type KeyPoint = [number, number]; // [x, height]

type SkylineFn = (buildings: number[][]) => number[][];

function eq(a: number[][], b: number[][]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i].length !== b[i].length) return false;
    for (let j = 0; j < a[i].length; j++) {
      if (a[i][j] !== b[i][j]) return false;
    }
  }
  return true;
}

interface TestCase {
  name: string;
  input: number[][];
  expected: number[][];
}

const TESTS: TestCase[] = [
  {
    name: "Example 1 (classic)",
    input: [[2, 9, 10], [3, 7, 15], [5, 12, 12], [15, 20, 10], [19, 24, 8]],
    expected: [[2, 10], [3, 15], [7, 12], [12, 0], [15, 10], [20, 8], [24, 0]],
  },
  {
    name: "Example 2 (adjacent same height, should merge)",
    input: [[0, 2, 3], [2, 5, 3]],
    expected: [[0, 3], [5, 0]],
  },
  {
    name: "Empty input",
    input: [],
    expected: [],
  },
  {
    name: "Single building",
    input: [[1, 5, 4]],
    expected: [[1, 4], [5, 0]],
  },
  {
    name: "Fully nested building (short inside tall)",
    input: [[1, 10, 10], [3, 6, 5]],
    expected: [[1, 10], [10, 0]],
  },
  {
    name: "Identical overlapping buildings",
    input: [[1, 5, 4], [1, 5, 4]],
    expected: [[1, 4], [5, 0]],
  },
  {
    name: "Same start x, different heights (taller wins)",
    input: [[1, 6, 3], [1, 6, 7]],
    expected: [[1, 7], [6, 0]],
  },
  {
    name: "Partial overlap, later building taller",
    input: [[1, 8, 4], [4, 12, 8]],
    expected: [[1, 4], [4, 8], [12, 0]],
  },
  {
    name: "Partial overlap, later building shorter (valley)",
    input: [[1, 8, 8], [4, 12, 4]],
    expected: [[1, 8], [8, 4], [12, 0]],
  },
  {
    name: "Touching edges (end == next start), no gap",
    input: [[1, 4, 5], [4, 8, 5]],
    expected: [[1, 5], [8, 0]],
  },
  {
    name: "Valley between buildings (gap)",
    input: [[1, 3, 5], [5, 8, 3]],
    expected: [[1, 5], [3, 0], [5, 3], [8, 0]],
  },
  {
    name: "Triple overlap, heights drop then rise",
    input: [[0, 6, 2], [1, 4, 6], [2, 8, 4]],
    expected: [[0, 2], [1, 6], [4, 4], [8, 0]],
  },
  {
    name: "Staircase ascending",
    input: [[0, 3, 1], [1, 4, 2], [2, 5, 3]],
    expected: [[0, 1], [1, 2], [2, 3], [5, 0]],
  },
  {
    name: "Descending staircase",
    input: [[0, 3, 3], [1, 4, 2], [2, 5, 1]],
    expected: [[0, 3], [3, 2], [4, 1], [5, 0]],
  },
  {
    name: "Tall building appearing late covers all",
    input: [[1, 4, 2], [2, 5, 3], [3, 6, 9]],
    expected: [[1, 2], [2, 3], [3, 9], [6, 0]],
  },
  {
    name: "Zero-height building should be ignored",
    input: [[1, 5, 0], [2, 6, 3]],
    expected: [[2, 3], [6, 0]],
  },
  {
    name: "Duplicate x events (start+end same x, different heights)",
    input: [[1, 5, 3], [5, 9, 6], [9, 12, 2]],
    expected: [[1, 3], [5, 6], [9, 2], [12, 0]],
  },
  {
    name: "Large random-ish stress pattern",
    input: [
      [0, 100, 5], [10, 50, 10], [20, 40, 15], [25, 35, 20],
      [30, 32, 25], [45, 90, 8], [60, 80, 12], [70, 75, 16],
    ],
    expected: [
      [0, 5], [10, 10], [20, 15], [25, 20], [30, 25], [32, 20], [35, 15],
      [40, 10], [50, 8], [60, 12], [70, 16], [75, 12], [80, 8], [90, 5], [100, 0],
    ],
  },
];

export function runSuite(name: string, fn: SkylineFn): { passed: number; failed: number; failures: string[]; ms: number } {
  const failures: string[] = [];
  let passed = 0;
  const t0 = performance.now();
  for (const t of TESTS) {
    let actual: number[][];
    try {
      actual = fn(t.input);
    } catch (e) {
      failures.push(`✗ ${t.name}: threw ${(e as Error).message}`);
      continue;
    }
    if (eq(actual, t.expected)) {
      passed++;
    } else {
      failures.push(`✗ ${t.name}\n    input:    ${JSON.stringify(t.input)}\n    expected: ${JSON.stringify(t.expected)}\n    got:      ${JSON.stringify(actual)}`);
    }
  }
  const ms = performance.now() - t0;
  return { passed, failed: TESTS.length - passed, failures, ms };
}
