import { runSuite } from "./test-runner";

const CANDIDATES: Array<{ name: string; path: string }> = [
  { name: "Ultra 550B", path: "./skyline-ultra" },
  { name: "Step 5 Preview", path: "./skyline-step5" },
];

async function main() {
  for (const c of CANDIDATES) {
    let mod: Record<string, unknown>;
    try {
      mod = await import(c.path);
    } catch (e) {
      console.log(`\n=== ${c.name}: FILE NOT FOUND / FAILED TO LOAD (${(e as Error).message.split("\n")[0]}) ===`);
      continue;
    }
    const fn = mod.getSkyline as ((b: number[][]) => number[][]) | undefined;
    if (typeof fn !== "function") {
      console.log(`\n=== ${c.name}: no getSkyline export found ===`);
      continue;
    }
    const r = runSuite(c.name, fn);
    console.log(`\n=== ${c.name}: ${r.passed}/18 passed, ${r.ms.toFixed(1)}ms ===`);
    for (const f of r.failures) console.log(f);
  }
}

main();
