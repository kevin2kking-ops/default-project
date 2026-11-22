/**
 * The Skyline Problem (LeetCode 218)
 *
 * Approach: sweep line over sorted start/end events + a max-heap of active heights
 * backed by a multiset (a Map of height -> active count) with lazy deletion.
 *
 * Time complexity:  O(B log B), where B is the number of buildings
 *                   (O(B) events, each event costs one O(log B) heap operation;
 *                    sorting is O(B log B)).
 * Space complexity: O(B) for the event arrays, the heap, and the count map.
 *
 * Key correctness idea: every event sharing the same x-coordinate is fully
 * processed before a key point is emitted for that x, so intra-x ordering
 * (start vs. end, ties among starts/ends) does not matter. A key point is only
 * emitted when the resulting max height differs from the previously emitted
 * height, which guarantees:
 *   - no two adjacent horizontal segments share a height, and
 *   - the final point always has height 0 (all buildings end at some finite x).
 */

export function getSkyline(buildings: number[][]): number[][] {
  const result: number[][] = [];
  if (!buildings || buildings.length === 0) return result;

  // --- Collect events: separate start and end lists, each [x, height]. ---
  const starts: Array<[number, number]> = [];
  const ends: Array<[number, number]> = [];
  for (const b of buildings) {
    if (!b || b.length < 3) continue;
    const [left, right, height] = b;
    if (height <= 0 || right <= left) continue; // degenerate: no visible segment
    starts.push([left, height]);
    ends.push([right, height]);
  }
  if (starts.length === 0) return result;

  starts.sort((a, b) => a[0] - b[0]);
  ends.sort((a, b) => a[0] - b[0]);

  // --- Max-heap of heights (values), multiset via `counts` for lazy deletion. ---
  const heap: number[] = [];
  const counts = new Map<number, number>();

  const heapPush = (v: number): void => {
    heap.push(v);
    let i = heap.length - 1;
    while (i > 0) {
      const parent = (i - 1) >> 1;
      if (heap[parent] >= heap[i]) break;
      const tmp = heap[parent];
      heap[parent] = heap[i];
      heap[i] = tmp;
      i = parent;
    }
  };

  const heapPop = (): number => {
    const top = heap[0];
    const last = heap.pop() as number;
    if (heap.length > 0) {
      heap[0] = last;
      let i = 0;
      for (;;) {
        const l = 2 * i + 1;
        const r = l + 1;
        let m = i;
        if (l < heap.length && heap[l] > heap[m]) m = l;
        if (r < heap.length && heap[r] > heap[m]) m = r;
        if (m === i) break;
        const tmp = heap[m];
        heap[m] = heap[i];
        heap[i] = tmp;
        i = m;
      }
    }
    return top;
  };

  // Max currently-active height; stale heap entries are popped lazily.
  const currentMax = (): number => {
    while (heap.length > 0) {
      const top = heap[0];
      if ((counts.get(top) ?? 0) > 0) return top;
      heapPop(); // all entries with this value are inactive
    }
    return 0;
  };

  // --- Sweep: merge the two event streams, grouped by x-coordinate. ---
  let i = 0;
  let j = 0;
  let lastHeight = -1; // sentinel: differs from any possible first height
  while (i < starts.length || j < ends.length) {
    let x: number;
    if (i < starts.length && j < ends.length) {
      x = Math.min(starts[i][0], ends[j][0]);
    } else if (i < starts.length) {
      x = starts[i][0];
    } else {
      x = ends[j][0];
    }

    // Process ALL events at this x (both removals and insertions) before
    // emitting, so ordering within the same x cannot affect the result.
    while (i < starts.length && starts[i][0] === x) {
      const h = starts[i++][1];
      counts.set(h, (counts.get(h) ?? 0) + 1);
      heapPush(h);
    }
    while (j < ends.length && ends[j][0] === x) {
      const h = ends[j++][1];
      counts.set(h, (counts.get(h) ?? 0) - 1);
    }

    const height = currentMax();
    if (height !== lastHeight) {
      result.push([x, height]);
      lastHeight = height;
    }
  }

  return result;
}