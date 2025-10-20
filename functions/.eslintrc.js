module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "quotes": ["error", "double"],
    "object-curly-spacing": ["error", "never"],
    "indent": ["error", 2],
    "max-len": ["error", {"code": 120}],
    "no-unused-vars": "error",
    "require-jsdoc": "off",
    "arrow-parens": ["error", "always"],
    "no-trailing-spaces": "error",
    "eol-last": "error",
  },
};