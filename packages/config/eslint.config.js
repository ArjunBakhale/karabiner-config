/** @type {import("eslint").Linter.Config} */
export default {
  env: {
    es2022: true,
    node: true
  },
  extends: ["eslint:recommended"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    sourceType: "module"
  },
  plugins: ["@typescript-eslint"],
  rules: {
    "@typescript-eslint/consistent-type-imports": "error",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "no-constant-condition": ["error", { "checkLoops": false }],
    "no-console": ["warn", { "allow": ["error", "info", "warn"] }],
    "no-unused-vars": "off"
  }
};
