/**
 * Architecture Constraint Tests
 *
 * These tests mechanically enforce dependency direction rules.
 * When an Agent (or human) violates the architecture, the build fails
 * with a clear error message and fix suggestion.
 *
 * Dependency direction (lower can import from higher, not reverse):
 *   types → config → repositories → services → runtime → ui
 *
 * Adapt this to your project's layer structure.
 */

import * as fs from "fs";
import * as path from "path";

// ─── Configuration ───────────────────────────────────────

/** Define your project layers in dependency order (lowest → highest) */
const LAYERS = ["types", "config", "repositories", "services", "runtime", "ui"];

/** Map layer names to directory paths (relative to src/) */
const LAYER_DIRS: Record<string, string> = {
  types: "src/types",
  config: "src/config",
  repositories: "src/repositories",
  services: "src/services",
  runtime: "src/runtime",
  ui: "src/ui",
};

/** Files/patterns to skip */
const IGNORE_PATTERNS = [
  /\.test\.(ts|tsx)$/, // Test files can import freely
  /\.spec\.(ts|tsx)$/,
  /__tests__\//,
  /\.d\.ts$/, // Type declaration files
];

// ─── Helpers ─────────────────────────────────────────────

function getLayerIndex(layerName: string): number {
  return LAYERS.indexOf(layerName);
}

function getLayerForFile(filePath: string): string | null {
  for (const [layer, dir] of Object.entries(LAYER_DIRS)) {
    if (filePath.startsWith(dir)) return layer;
  }
  return null;
}

function shouldIgnore(filePath: string): boolean {
  return IGNORE_PATTERNS.some((pattern) => pattern.test(filePath));
}

function getImports(filePath: string): string[] {
  const content = fs.readFileSync(filePath, "utf-8");
  const importRegex =
    /(?:import|from)\s+['"]([^'"]+)['"]/g;
  const imports: string[] = [];
  let match;
  while ((match = importRegex.exec(content)) !== null) {
    imports.push(match[1]);
  }
  return imports;
}

function resolveImportToLayer(
  importPath: string,
  currentFile: string
): string | null {
  // Handle relative imports
  if (importPath.startsWith(".")) {
    const resolved = path.resolve(path.dirname(currentFile), importPath);
    return getLayerForFile(resolved);
  }
  // Handle absolute/alias imports (e.g., @/services/foo)
  for (const [layer, dir] of Object.entries(LAYER_DIRS)) {
    if (importPath.includes(`/${layer}/`) || importPath.startsWith(`@/${layer}`)) {
      return layer;
    }
  }
  return null; // External package, not a layer import
}

// ─── Collect all source files ────────────────────────────

function collectFiles(dir: string, ext: string[]): string[] {
  if (!fs.existsSync(dir)) return [];
  const files: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectFiles(fullPath, ext));
    } else if (ext.some((e) => entry.name.endsWith(e))) {
      files.push(fullPath);
    }
  }
  return files;
}

// ─── Tests ───────────────────────────────────────────────

describe("Architecture Constraints", () => {
  const allFiles = collectFiles("src", [".ts", ".tsx"]);
  const violations: Array<{
    file: string;
    import: string;
    fromLayer: string;
    toLayer: string;
  }> = [];

  // Collect all violations first
  for (const file of allFiles) {
    if (shouldIgnore(file)) continue;

    const fileLayer = getLayerForFile(file);
    if (!fileLayer) continue;

    const imports = getImports(file);
    for (const imp of imports) {
      const importLayer = resolveImportToLayer(imp, file);
      if (!importLayer) continue;
      if (importLayer === fileLayer) continue;

      const fileLayerIdx = getLayerIndex(fileLayer);
      const importLayerIdx = getLayerIndex(importLayer);

      // A layer can only import from layers with LOWER index (more foundational).
      if (importLayerIdx > fileLayerIdx) {
        violations.push({
          file,
          import: imp,
          fromLayer: fileLayer,
          toLayer: importLayer,
        });
      }
    }
  }

  test("no reverse dependency direction imports", () => {
    if (violations.length > 0) {
      const report = violations
        .map(
          (v) =>
            `  ❌ ${v.file}\n` +
            `     imports "${v.import}" (${v.toLayer} layer)\n` +
            `     FIX: ${v.fromLayer} (index ${getLayerIndex(v.fromLayer)}) ` +
            `cannot import from ${v.toLayer} (index ${getLayerIndex(v.toLayer)}).\n` +
            `     Move shared code to a lower layer (e.g., types/ or config/).`
        )
        .join("\n\n");

      fail(
        `Found ${violations.length} architecture violation(s):\n\n${report}\n\n` +
          `Allowed dependency direction: ${LAYERS.join(" → ")}\n` +
          `Each layer can only import from layers to its LEFT.`
      );
    }
  });

  test("all source files belong to a defined layer", () => {
    const orphans = allFiles.filter(
      (f) => !shouldIgnore(f) && !getLayerForFile(f)
    );
    if (orphans.length > 0) {
      fail(
        `Found ${orphans.length} file(s) outside any defined layer:\n` +
          orphans.map((f) => `  - ${f}`).join("\n") +
          `\n\nFIX: Move these files into one of: ${LAYERS.join(", ")}\n` +
          `Or add a new layer definition to the architecture test.`
      );
    }
  });
});
