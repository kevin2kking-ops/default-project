/**
 * The Skyline Problem
 * Time Complexity: O(n log n) where n is the number of buildings
 * Space Complexity: O(n) for events and heap
 * 
 * Approach: Sweep line algorithm with max heap.
 * - Create start/end events for each building
 * - Sort events by x-coordinate, with starts before ends at same x
 * - Use max heap to track active building heights
 * - Record key points when max height changes
 */

export function getSkyline(buildings: number[][]): number[][] {
    if (buildings.length === 0) return [];

    // Create events: [x, height, isStart]
    // For start events, use negative height to sort taller buildings first
    // For end events, use positive height to sort shorter buildings first
    const events: number[][] = [];
    for (const [left, right, height] of buildings) {
        events.push([left, -height, 1]);  // start event
        events.push([right, height, 0]);   // end event
    }

    // Sort events:
    // 1. By x-coordinate ascending
    // 2. At same x: start events before end events (isStart descending)
    // 3. At same x and both starts: taller building first (height ascending since negative)
    // 4. At same x and both ends: shorter building first (height ascending)
    events.sort((a, b) => {
        if (a[0] !== b[0]) return a[0] - b[0];
        if (a[2] !== b[2]) return b[2] - a[2]; // start (1) before end (0)
        return a[1] - b[1]; // for starts: more negative (taller) first; for ends: smaller first
    });

    // Max heap for active heights (using negative values for max-heap behavior with min-heap)
    const heap: number[] = [0]; // Initialize with ground level 0
    const result: number[][] = [];
    let prevMaxHeight = 0;

    // Helper to push to max heap (using negative values)
    const heapPush = (val: number) => {
        heap.push(-val);
        // Sift up
        let i = heap.length - 1;
        while (i > 0) {
            const parent = (i - 1) >> 1;
            if (heap[parent] <= heap[i]) break;
            [heap[parent], heap[i]] = [heap[i], heap[parent]];
            i = parent;
        }
    };

    // Helper to remove a specific value from heap
    const heapRemove = (val: number) => {
        const negVal = -val;
        const idx = heap.indexOf(negVal);
        if (idx === -1) return;
        // Replace with last element and sift
        const last = heap.pop()!;
        if (idx < heap.length) {
            heap[idx] = last;
            // Sift down
            let i = idx;
            while (true) {
                const left = (i << 1) + 1;
                const right = left + 1;
                let smallest = i;
                if (left < heap.length && heap[left] < heap[smallest]) smallest = left;
                if (right < heap.length && heap[right] < heap[smallest]) smallest = right;
                if (smallest === i) break;
                [heap[i], heap[smallest]] = [heap[smallest], heap[i]];
                i = smallest;
            }
            // Sift up if needed
            while (i > 0) {
                const parent = (i - 1) >> 1;
                if (heap[parent] <= heap[i]) break;
                [heap[parent], heap[i]] = [heap[i], heap[parent]];
                i = parent;
            }
        }
    };

    // Helper to get max height (top of heap)
    const getMaxHeight = (): number => -heap[0];

    for (const [x, height, isStart] of events) {
        if (isStart === 1) {
            // Start event: add building height
            heapPush(-height); // height is negative for start events
        } else {
            // End event: remove building height
            heapRemove(height); // height is positive for end events
        }

        const currMaxHeight = getMaxHeight();
        if (currMaxHeight !== prevMaxHeight) {
            result.push([x, currMaxHeight]);
            prevMaxHeight = currMaxHeight;
        }
    }

    return result;
}